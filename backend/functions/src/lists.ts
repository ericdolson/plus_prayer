// Morning admin flow (list-lifecycle.md), all ADMIN callables used by Eric's
// skills: closeList → assembleNextList → review held → print → publishList →
// publishListVideo.

import { randomUUID } from "node:crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { localDateIn, MINUTE_MS, weekday } from "./dates";
import { hasCheck, mutate, query } from "./db";
import { Deps } from "./deps";
import { normId } from "./ids";
import { blockPattern, CONTACT_PATTERN } from "./moderation";

interface ListRow {
  id: string;
  listNumber: number;
  listDate: string;
  status: string;
  currentFrom: string | null;
  closesAt: string | null;
}

async function currentList(deps: Deps): Promise<ListRow> {
  const res = await query<{ prayerLists: ListRow[] }>(deps.db, "GetCurrentList");
  const list = res.prayerLists[0];
  if (!list) throw new HttpsError("failed-precondition", "There is no current list yet (backfill lists first)");
  return list;
}

/** Sets the exact cutoff (now + 5 min) and mirrors it for the in-app banner. */
export async function closeList(deps: Deps, minutes = deps.cfg.closeListMinutes) {
  const list = await currentList(deps);
  const closesAt = new Date(deps.now().getTime() + minutes * MINUTE_MS);
  await mutate(deps.db, "CloseList", { id: list.id, closesAt: closesAt.toISOString() });
  const summary = await query<{ prayerList: { prayerCount: number } | null }>(deps.db, "GetListSummary", { id: list.id });
  await deps.live.setCurrentListClosesAt({
    listId: list.id,
    listNumber: list.listNumber,
    prayerCount: summary.prayerList?.prayerCount ?? 0,
    closesAt: closesAt.getTime(),
  });
  return { listId: list.id, listNumber: list.listNumber, closesAt: closesAt.toISOString() };
}

export interface SocialParticipant {
  platform: string;
  externalId: string;
  displayName: string;
}

function cleanSocial(raw: unknown): SocialParticipant[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) throw new HttpsError("invalid-argument", "social must be a list");
  const seen = new Set<string>();
  const out: SocialParticipant[] = [];
  for (const r of raw) {
    const platform = typeof r?.platform === "string" ? r.platform.trim().toLowerCase() : "";
    const externalId = typeof r?.externalId === "string" ? r.externalId.trim() : "";
    const displayName = typeof r?.displayName === "string" ? r.displayName.replace(/\s+/gu, " ").trim() : "";
    if (!platform || !externalId || !displayName) {
      throw new HttpsError("invalid-argument", "each social participant needs platform, externalId, displayName");
    }
    const key = `${platform}\u0000${externalId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ platform, externalId, displayName });
  }
  return out;
}

/**
 * The flip: settle N, ingest the 🙏 harvest, open N+1 (current from N's
 * closesAt) as a draft, and draft its entries in one transaction.
 * N's prayerCount/prayerSeconds are already final: only the current list's
 * counters move, and only for prayers started before its closesAt.
 */
export async function assembleNextList(deps: Deps, input: { social?: unknown; force?: boolean }) {
  const social = cleanSocial(input.social);
  const closing = await currentList(deps);
  const now = deps.now();

  let closesAt = closing.closesAt;
  if (!closesAt) {
    if (!input.force) throw new HttpsError("failed-precondition", `Run closeList for List ${closing.listNumber} first`);
    closesAt = now.toISOString();
    await mutate(deps.db, "CloseList", { id: closing.id, closesAt });
  } else if (Date.parse(closesAt) > now.getTime() && !input.force) {
    throw new HttpsError("failed-precondition", `List ${closing.listNumber} closes at ${closesAt}`);
  }

  const newListId = normId(randomUUID());
  const listNumber = closing.listNumber + 1;
  await mutate(deps.db, "AssembleList", {
    closingListId: closing.id,
    closesAt,
    lastFlipAt: closing.currentFrom ?? closesAt,
    assemblyAt: now.toISOString(),
    newListId,
    listNumber,
    listDate: localDateIn(deps.cfg.listTimeZone, now),
    gateHours: deps.cfg.gateHours,
    freeLimit: deps.cfg.freeLimit,
    softLandingDays: deps.cfg.softLandingDays,
    blockPattern: blockPattern(deps.cfg.blocklist),
    contactPattern: CONTACT_PATTERN,
    social,
  });

  const created = await query<{ prayerList: ListRow | null }>(deps.db, "GetList", { id: newListId });
  if (!created.prayerList) {
    throw new HttpsError("already-exists", `List ${listNumber} was already assembled`);
  }
  await mutate(deps.db, "RecountList", { listId: newListId, approvedOnly: false });
  await deps.live.setCurrentList({ listId: newListId, listNumber, prayerCount: 0, closesAt: null });

  const summary = await query<{ prayerList: { soulCount: number; intentionCount: number } | null }>(
    deps.db, "GetListSummary", { id: newListId },
  );
  const held = await getHeldEntries(deps, newListId);
  return {
    listId: newListId,
    listNumber,
    closedListNumber: closing.listNumber,
    soulCount: summary.prayerList?.soulCount ?? 0,
    intentionCount: summary.prayerList?.intentionCount ?? 0,
    held: held.length,
  };
}

export async function getHeldEntries(deps: Deps, listId: string) {
  const res = await query<{ prayerListEntries: unknown[] }>(deps.db, "GetHeldEntries", { listId });
  return res.prayerListEntries;
}

const MODERATION = ["APPROVED", "HELD", "EXCLUDED"] as const;
const REASONS = ["LANGUAGE", "CONTACT_OR_LINK", "NAME_CHANGES", "OTHER"] as const;

export async function moderateEntry(
  deps: Deps,
  input: { entryId?: unknown; status?: unknown; reasonCategory?: unknown; heldReason?: unknown },
) {
  const status = MODERATION.find((s) => s === input.status);
  if (typeof input.entryId !== "string" || !status) {
    throw new HttpsError("invalid-argument", "entryId and status (APPROVED | HELD | EXCLUDED) are required");
  }
  const reasonCategory = input.reasonCategory == null ? null : REASONS.find((r) => r === input.reasonCategory);
  if (reasonCategory === undefined) throw new HttpsError("invalid-argument", "unknown reasonCategory");
  if (status === "EXCLUDED" && !reasonCategory) {
    throw new HttpsError("invalid-argument", "an excluded entry needs a reasonCategory (users see it)");
  }
  const entry = await query<{ prayerListEntry: { id: string; list: { id: string; status: string } } | null }>(
    deps.db, "GetEntry", { id: input.entryId },
  );
  if (!entry.prayerListEntry) throw new HttpsError("not-found", "Entry not found");
  try {
    await mutate(deps.db, "ModerateEntry", {
      entryId: input.entryId,
      status,
      reasonCategory: status === "APPROVED" ? null : reasonCategory,
      heldReason: typeof input.heldReason === "string" ? input.heldReason : null,
    });
  } catch (err) {
    if (hasCheck(err, "ENTRY_NOT_FOUND")) throw new HttpsError("not-found", "Entry not found");
    throw err;
  }
  const list = entry.prayerListEntry.list;
  await mutate(deps.db, "RecountList", { listId: list.id, approvedOnly: list.status === "published" });
  return { entryId: input.entryId, status };
}

export async function getListForPrint(deps: Deps, listId: string) {
  return query(deps.db, "GetListForPrint", { listId });
}

/** Draft → published; the seal comes from the weekday (Sunday = 0). */
export async function publishList(deps: Deps, listId: string) {
  const res = await query<{ prayerList: ListRow | null }>(deps.db, "GetList", { id: listId });
  if (!res.prayerList) throw new HttpsError("not-found", "List not found");
  const sealVariant = weekday(res.prayerList.listDate);
  await mutate(deps.db, "PublishList", { listId, sealVariant });
  await mutate(deps.db, "RecountList", { listId, approvedOnly: true });
  return { listId, listNumber: res.prayerList.listNumber, sealVariant };
}

export interface PostLink {
  platform: string;
  url?: string | null;
  externalId?: string | null;
}

/** ~8am: video + post links; then the opt-in "list is live" push (FCM topic). */
export async function publishListVideo(deps: Deps, input: { listId?: unknown; videoPath?: unknown; posts?: unknown }) {
  if (typeof input.listId !== "string" || typeof input.videoPath !== "string" || !input.videoPath.startsWith("videos/")) {
    throw new HttpsError("invalid-argument", "listId and a videoPath under videos/ are required");
  }
  const posts = (Array.isArray(input.posts) ? input.posts : []).map((p: PostLink) => ({
    platform: String(p?.platform ?? "").trim().toLowerCase(),
    url: p?.url ?? null,
    externalId: p?.externalId ?? null,
  })).filter((p) => p.platform);
  const res = await query<{ prayerList: ListRow | null }>(deps.db, "GetList", { id: input.listId });
  if (!res.prayerList) throw new HttpsError("not-found", "List not found");
  await mutate(deps.db, "PublishListVideo", { listId: input.listId, videoPath: input.videoPath, posts });
  // Users opt in by subscribing to this topic alongside User.listLiveOptIn.
  // Copy is a placeholder until notification copy is written (notifications.md OPEN).
  await deps.notifier.sendToTopic(
    "list-live",
    `List ${res.prayerList.listNumber}`,
    "Today's list is live.",
    { listId: input.listId, listNumber: String(res.prayerList.listNumber) },
  );
  return { listId: input.listId, posts: posts.length };
}
