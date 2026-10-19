// Morning admin flow (list-lifecycle.md), all ADMIN callables used by Eric's
// skills: closeList → assembleNextList → review held → print → publishList →
// publishListVideo.
//
// closeList sets list N's exact cutoff and creates N+1 (current from that
// cutoff). assembleNextList settles N — its numbers never move again — and
// fills N+1's entries.

import { randomUUID } from "node:crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { localDateIn, MINUTE_MS, weekday } from "./dates";
import { hasCheck, mutate, query } from "./db";
import { Deps } from "./deps";
import { normId } from "./ids";
import { CONTACT_PATTERN, loadBlockTerms } from "./moderation";
import { cleanText, truncateGraphemes } from "./text";

interface ListRow {
  id: string;
  listNumber: number;
  listDate: string;
  status: string;
  currentFrom: string | null;
  closesAt: string | null;
}

/** The list being closed (oldest unsettled) and, once closeList ran, N+1. */
async function openLists(deps: Deps): Promise<{ closing: ListRow; next: ListRow | null }> {
  const res = await query<{ prayerLists: ListRow[] }>(deps.db, "GetOpenLists");
  const closing = res.prayerLists[0];
  if (!closing) throw new HttpsError("failed-precondition", "There is no current list yet (backfill lists first)");
  const next = res.prayerLists.find((l) => l.listNumber === closing.listNumber + 1) ?? null;
  return { closing, next };
}

/**
 * Sets the exact cutoff (now + 5 min), creates N+1 current from it, and
 * mirrors closesAt for the in-app banner. Re-running before the cutoff moves
 * it; after the cutoff, assemble first.
 */
export async function closeList(deps: Deps, minutes = deps.cfg.closeListMinutes) {
  const { closing } = await openLists(deps);
  const now = deps.now();
  if (closing.closesAt && Date.parse(closing.closesAt) <= now.getTime()) {
    throw new HttpsError("failed-precondition", `List ${closing.listNumber} closed at ${closing.closesAt}; run assembleNextList`);
  }
  const closesAt = new Date(now.getTime() + minutes * MINUTE_MS);
  await mutate(deps.db, "CloseList", {
    listId: closing.id,
    closesAt: closesAt.toISOString(),
    nextListId: normId(randomUUID()),
    nextListNumber: closing.listNumber + 1,
    nextListDate: localDateIn(deps.cfg.listTimeZone, closesAt),
  });
  const summary = await query<{ prayerList: { prayerCount: number } | null }>(deps.db, "GetListSummary", { id: closing.id });
  await deps.live.setCurrentListClosesAt({
    listId: closing.id,
    listNumber: closing.listNumber,
    prayerCount: summary.prayerList?.prayerCount ?? 0,
    closesAt: closesAt.getTime(),
  });
  const { next } = await openLists(deps);
  return {
    listId: closing.id,
    listNumber: closing.listNumber,
    closesAt: closesAt.toISOString(),
    nextListId: next?.id ?? null,
    nextListNumber: closing.listNumber + 1,
  };
}

export interface SocialParticipant {
  platform: string;
  externalId: string;
  displayName: string;
}

/** Validate, de-duplicate, and cap display names at 40 graphemes (truncated). */
function cleanSocial(raw: unknown, cap: number): SocialParticipant[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) throw new HttpsError("invalid-argument", "social must be a list");
  const seen = new Set<string>();
  const out: SocialParticipant[] = [];
  for (const r of raw) {
    const platform = typeof r?.platform === "string" ? r.platform.trim().toLowerCase() : "";
    const externalId = typeof r?.externalId === "string" ? r.externalId.trim() : "";
    const displayName = typeof r?.displayName === "string" ? truncateGraphemes(cleanText(r.displayName), cap).trim() : "";
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
 * The morning assembly: settle N, ingest the 🙏 harvest, and draft N+1's
 * entries in one statement. N+1 has been current since N's closesAt;
 * prayers that started before the cutoff and were committed by now counted
 * toward N, later ones toward N+1.
 */
export async function assembleNextList(deps: Deps, input: { social?: unknown; force?: boolean }) {
  const social = cleanSocial(input.social, deps.cfg.nameCap);
  let { closing, next } = await openLists(deps);
  const now = deps.now();

  if (!closing.closesAt) {
    if (!input.force) throw new HttpsError("failed-precondition", `Run closeList for List ${closing.listNumber} first`);
    await closeList(deps, 0);
    ({ closing, next } = await openLists(deps));
  } else if (Date.parse(closing.closesAt) > now.getTime() && !input.force) {
    throw new HttpsError("failed-precondition", `List ${closing.listNumber} closes at ${closing.closesAt}`);
  }
  if (!next) throw new HttpsError("failed-precondition", `List ${closing.listNumber + 1} is missing; run closeList`);

  const assemblyAt = now.toISOString();
  const terms = await loadBlockTerms(deps.live);
  await mutate(deps.db, "AssembleList", {
    closingListId: closing.id,
    closesAt: closing.closesAt,
    assemblyAt,
    nextListId: next.id,
    gateHours: deps.cfg.gateHours,
    freeLimit: deps.cfg.freeLimit,
    softLandingDays: deps.cfg.softLandingDays,
    blockWords: terms.words,
    blockSubstrings: terms.substrings,
    contactPattern: CONTACT_PATTERN,
    social,
  });

  const settled = await query<{ prayerList: { settledAt: string | null } | null }>(deps.db, "GetList", { id: closing.id });
  const settledAt = settled.prayerList?.settledAt;
  if (!settledAt || Date.parse(settledAt) !== Date.parse(assemblyAt)) {
    throw new HttpsError("already-exists", `List ${next.listNumber} was already assembled`);
  }
  await mutate(deps.db, "RecountList", { listId: next.id, approvedOnly: false });

  const summary = await query<{ prayerList: { soulCount: number; intentionCount: number; prayerCount: number } | null }>(
    deps.db, "GetListSummary", { id: next.id },
  );
  await deps.live.setCurrentList({
    listId: next.id,
    listNumber: next.listNumber,
    prayerCount: summary.prayerList?.prayerCount ?? 0,
    closesAt: null,
  });
  const held = await getHeldEntries(deps, next.id);
  return {
    listId: next.id,
    listNumber: next.listNumber,
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

/** schema-brief §9.12: "List 52 is up · 4,345 people, including you." */
export function listLiveCopy(listNumber: number, people: number): string {
  return `List ${listNumber} is up · ${people.toLocaleString("en-US")} people, including you.`;
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
  const res = await query<{ prayerList: (ListRow & { soulCount: number }) | null }>(deps.db, "GetList", { id: input.listId });
  if (!res.prayerList) throw new HttpsError("not-found", "List not found");
  await mutate(deps.db, "PublishListVideo", { listId: input.listId, videoPath: input.videoPath, posts });
  // Users opt in by subscribing to this topic alongside User.listLiveOptIn.
  const body = listLiveCopy(res.prayerList.listNumber, res.prayerList.soulCount);
  await deps.notifier.sendToTopic("list-live", { body }, {
    listId: input.listId,
    listNumber: String(res.prayerList.listNumber),
  });
  return { listId: input.listId, posts: posts.length, body };
}
