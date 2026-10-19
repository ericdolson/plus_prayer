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
import { hasContactInfo } from "./contact";
import { BlockTerms, loadBlockTerms } from "./moderation";
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
  /** Contact info or a link in the name → entered as EXCLUDED · CONTACT_OR_LINK. */
  excluded: boolean;
}

/**
 * Validate, de-duplicate, and cap display names at 40 graphemes (truncated).
 * Names with contact info or links can't be blocked at input like the app's,
 * so they are excluded at ingest.
 */
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
    out.push({ platform, externalId, displayName, excluded: hasContactInfo(displayName) });
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
  // The word blocklist is off for the beta (schema-brief §11); the code stays.
  const terms: BlockTerms = deps.cfg.wordBlocklistEnabled ? await loadBlockTerms(deps.live) : { words: [], substrings: [] };
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
    social,
  });

  const settled = await query<{ prayerList: { settledAt: string | null } | null }>(deps.db, "GetList", { id: closing.id });
  const settledAt = settled.prayerList?.settledAt;
  if (!settledAt || Date.parse(settledAt) !== Date.parse(assemblyAt)) {
    throw new HttpsError("already-exists", `List ${next.listNumber} was already assembled`);
  }
  await mutate(deps.db, "RecountList", { listId: next.id });

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
    review: await getReviewDiff(deps, next.id),
  };
}

export interface ReviewItem {
  entryId: string;
  kind: "SOUL" | "INTENTION";
  source: "APP" | "SOCIAL";
  publicName: string;
  previousName: string | null;
  change: "NEW" | "CHANGED";
  isSelf: boolean;
  parentName: string | null;
  moderationStatus: "APPROVED" | "HELD";
  reasonCategory: string | null;
}

/**
 * Names and intentions new or changed since the last list they were on
 * (self-name changes included) — the morning skill's AI first pass and
 * Eric's review. Everything not excluded prints.
 */
export async function getReviewDiff(deps: Deps, listId: string): Promise<ReviewItem[]> {
  const res = await query<{ entries: ReviewItem[] }>(deps.db, "GetReviewDiff", { listId });
  return res.entries;
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
  await mutate(deps.db, "RecountList", { listId: list.id });
  return { entryId: input.entryId, status };
}

export interface AutoReviewDecision {
  entryId: string;
  /** approve → prints as-is · exclude → not printed (category shown to the user) · unsure → flagged for Eric */
  decision: "approve" | "exclude" | "unsure";
  reasonCategory?: (typeof REASONS)[number];
  /** Why — required for exclude and unsure; stored as heldReason ("auto-review: …"). */
  note?: string;
}

const ENTRY_ID = /^[0-9a-f]{32}$|^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_DECISIONS = 5000;

/**
 * The morning skill's first pass over the review diff, applied in one call:
 * it decides what's obvious and marks the rest `unsure`, which leaves only
 * those for Eric (returned as `forEric`). Review stays exception-based —
 * anything not excluded prints, including what Eric never gets to.
 */
export async function moderateEntries(deps: Deps, input: { listId?: unknown; decisions?: unknown }) {
  if (typeof input.listId !== "string" || !Array.isArray(input.decisions)) {
    throw new HttpsError("invalid-argument", "listId and decisions are required");
  }
  if (input.decisions.length > MAX_DECISIONS) throw new HttpsError("invalid-argument", `at most ${MAX_DECISIONS} decisions per call`);
  const seen = new Set<string>();
  const rows = (input.decisions as AutoReviewDecision[]).map((d, i) => {
    const where = `decisions[${i}]`;
    if (typeof d?.entryId !== "string" || !ENTRY_ID.test(d.entryId)) throw new HttpsError("invalid-argument", `${where}: bad entryId`);
    const id = normId(d.entryId);
    if (seen.has(id)) throw new HttpsError("invalid-argument", `${where}: duplicate entryId`);
    seen.add(id);
    const note = typeof d.note === "string" ? d.note.trim().slice(0, 500) : "";
    const category = d.reasonCategory == null ? null : REASONS.find((r) => r === d.reasonCategory);
    if (category === undefined) throw new HttpsError("invalid-argument", `${where}: unknown reasonCategory`);
    switch (d.decision) {
      case "approve":
        return { entryId: id, status: "APPROVED", category: null, note: note ? `auto-review: ${note}` : null };
      case "exclude":
        if (!category) throw new HttpsError("invalid-argument", `${where}: an exclusion needs a reasonCategory (users see it)`);
        if (!note) throw new HttpsError("invalid-argument", `${where}: say why it's excluded`);
        return { entryId: id, status: "EXCLUDED", category, note: `auto-review: ${note}` };
      case "unsure":
        if (!note) throw new HttpsError("invalid-argument", `${where}: say what's unclear, for Eric`);
        return { entryId: id, status: "HELD", category, note: `auto-review: ${note}` };
      default:
        throw new HttpsError("invalid-argument", `${where}: decision must be approve, exclude, or unsure`);
    }
  });
  const res = await mutate<{ _execute: number }>(deps.db, "ModerateEntries", { listId: input.listId, decisions: rows });
  await mutate(deps.db, "RecountList", { listId: input.listId });
  return {
    updated: res._execute,
    approved: rows.filter((r) => r.status === "APPROVED").length,
    excluded: rows.filter((r) => r.status === "EXCLUDED").length,
    unsure: rows.filter((r) => r.status === "HELD").length,
    forEric: await getHeldEntries(deps, input.listId),
  };
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
  await mutate(deps.db, "RecountList", { listId });
  return { listId, listNumber: res.prayerList.listNumber, sealVariant };
}

/** schema-brief §10: "List 52 is up · 4,345 people." (one broadcast to all opted-in users) */
export function listLiveCopy(listNumber: number, people: number): string {
  return `List ${listNumber} is up · ${people.toLocaleString("en-US")} people.`;
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
