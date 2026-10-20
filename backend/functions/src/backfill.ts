// Backfill lists 1..N from the publishing pipeline's JSON (publishing/
// lists.json + participants.json) so list numbering in the database is
// continuous with what was printed (decisions.md, 2026-10-17).
//
// Each list goes in as published, with the counts that were printed; every
// list but the last is settled (closesAt = settledAt = the next list's
// currentFrom), and the last becomes the current list. Its 🙏 commenters go
// in as SOCIAL ExternalPerson rows with APPROVED entries. The base set's
// names aren't in the database yet, so a backfilled list's soulCount is the
// printed total, not a count of its entries.

import { randomUUID } from "node:crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { weekday } from "./dates";
import { mutate, query } from "./db";
import { Deps } from "./deps";
import { normId } from "./ids";
import { cleanText, truncateGraphemes } from "./text";

export interface BackfillPerson {
  platform: string;
  externalId: string;
  displayName: string;
  firstSeen: string | null;
}

export interface BackfillPost {
  platform: string;
  url: string;
  externalId: string | null;
}

export interface BackfillListPlan {
  listNumber: number;
  listDate: string;
  currentFrom: string;
  closesAt: string | null;
  settledAt: string | null;
  sealVariant: number;
  soulCount: number;
  intentionCount: number;
  videoPath: string | null;
  people: BackfillPerson[];
  posts: BackfillPost[];
}

type Json = Record<string, any>;

const DATE = /^\d{4}-\d{2}-\d{2}$/;

function bad(message: string): never {
  throw new HttpsError("invalid-argument", message);
}

/** The storage path inside a Firebase download URL (…/o/<path>?alt=media…). */
function storagePath(url: unknown): string | null {
  if (typeof url !== "string") return null;
  const m = /\/o\/([^?]+)/.exec(url);
  return m ? decodeURIComponent(m[1]) : null;
}

/**
 * A 🙏 commenter. Names Eric added by hand have no platform id, so they're
 * keyed by name ("name:<lowercased name>"); the same name on two lists is
 * one person.
 */
function person(raw: Json, where: string, nameCap: number): BackfillPerson {
  const platform = typeof raw?.platform === "string" ? raw.platform.trim().toLowerCase() : "";
  const displayName = typeof raw?.handle === "string" ? truncateGraphemes(cleanText(raw.handle), nameCap).trim() : "";
  if (!platform || !displayName) bad(`${where}: needs platform and handle`);
  const id = raw.id == null ? "" : String(raw.id).trim();
  return {
    platform,
    externalId: id || `name:${displayName.toLowerCase()}`,
    displayName,
    firstSeen: typeof raw.at === "string" ? raw.at : null,
  };
}

/** Post links that were actually recorded (a URL); failed or unconfirmed posts are left out. */
function posts(platforms: unknown): BackfillPost[] {
  if (!platforms || typeof platforms !== "object") return [];
  return Object.entries(platforms as Json)
    .filter(([, p]) => typeof p?.platform_post_url === "string" && p.platform_post_url)
    .map(([platform, p]) => ({
      platform: platform.trim().toLowerCase(),
      url: p.platform_post_url,
      externalId: typeof p.post_id === "string" ? p.post_id : null,
    }));
}

/** lists.json + participants.json → one row set per list, oldest first. */
export function planBackfill(listsJson: unknown, participantsJson: unknown, nameCap: number): BackfillListPlan[] {
  const lists = (listsJson as Json)?.lists;
  if (!lists || typeof lists !== "object") bad("lists.json: no \"lists\" object");
  const pending: Json = (participantsJson as Json)?.pending ?? {};

  const numbers = Object.keys(lists).map(Number).sort((a, b) => a - b);
  if (!numbers.length) bad("lists.json: no lists");
  numbers.forEach((n, i) => {
    if (!Number.isInteger(n) || n < 1) bad(`lists.json: bad list number "${n}"`);
    if (i > 0 && n !== numbers[i - 1] + 1) bad(`lists.json: list ${numbers[i - 1] + 1} is missing`);
  });

  const plans = numbers.map((n): BackfillListPlan => {
    const l: Json = lists[String(n)];
    const where = `list ${n}`;
    if (typeof l?.date !== "string" || !DATE.test(l.date)) bad(`${where}: bad date`);
    const pub: Json = l.published ?? {};
    const currentFrom = pub.published_at ?? pub.scheduled_for ?? pub.intended_for;
    if (typeof currentFrom !== "string" || Number.isNaN(Date.parse(currentFrom))) bad(`${where}: no publish time`);
    if (!Number.isInteger(l.soul_count) || !Number.isInteger(l.intention_count ?? 0)) bad(`${where}: bad counts`);
    const people = (Array.isArray(pending[String(n)]) ? pending[String(n)] : [])
      .map((p: Json, i: number) => person(p, `participants ${n}[${i}]`, nameCap));
    return {
      listNumber: n,
      listDate: l.date,
      currentFrom: new Date(currentFrom).toISOString(),
      closesAt: null,
      settledAt: null,
      sealVariant: weekday(l.date),
      soulCount: l.soul_count,
      intentionCount: l.intention_count ?? 0,
      videoPath: storagePath(l.video_url),
      people,
      posts: posts(pub.platforms),
    };
  });

  for (let i = 0; i < plans.length - 1; i++) {
    const next = plans[i + 1].currentFrom;
    if (Date.parse(next) <= Date.parse(plans[i].currentFrom)) {
      bad(`list ${plans[i + 1].listNumber} was published before list ${plans[i].listNumber}`);
    }
    plans[i].closesAt = next;
    plans[i].settledAt = next;
  }
  return plans;
}

interface ExistingList {
  id: string;
  listNumber: number;
  settledAt: string | null;
}

async function existingLists(deps: Deps): Promise<Map<number, ExistingList>> {
  const res = await query<{ prayerLists: ExistingList[] }>(deps.db, "GetListNumbers");
  return new Map(res.prayerLists.map((l) => [l.listNumber, l]));
}

/**
 * Insert the planned lists that aren't in the database yet (all, or just
 * `only`), oldest first; lists already there only get their post links
 * refreshed. When the last list goes in it becomes the current list, so this
 * refuses if the database already has a current list or a later one.
 */
export async function backfillLists(
  deps: Deps,
  plans: BackfillListPlan[],
  opts: { only?: number; dryRun?: boolean } = {},
) {
  const selected = opts.only === undefined ? plans : plans.filter((p) => p.listNumber === opts.only);
  if (!selected.length) bad(`list ${opts.only} isn't in lists.json`);
  const last = plans[plans.length - 1];
  const before = await existingLists(deps);
  const toInsert = selected.filter((p) => !before.has(p.listNumber));

  if (toInsert.includes(last)) {
    const open = [...before.values()].find((l) => !l.settledAt);
    const later = [...before.keys()].find((n) => n > last.listNumber);
    if (open || later !== undefined) {
      throw new HttpsError(
        "failed-precondition",
        `List ${open?.listNumber ?? later} is already in the database; backfill only fills in history before it`,
      );
    }
  }

  const summary = {
    insert: toInsert.map((p) => p.listNumber),
    alreadyPresent: selected.filter((p) => before.has(p.listNumber)).map((p) => p.listNumber),
    people: toInsert.reduce((n, p) => n + p.people.length, 0),
    posts: selected.reduce((n, p) => n + p.posts.length, 0),
    current: toInsert.includes(last) ? last.listNumber : null,
  };
  if (opts.dryRun) return { dryRun: true, ...summary, lists: toInsert };

  for (const p of selected) {
    await mutate(deps.db, "BackfillList", {
      id: normId(randomUUID()),
      listNumber: p.listNumber,
      listDate: p.listDate,
      currentFrom: p.currentFrom,
      closesAt: p.closesAt,
      settledAt: p.settledAt,
      sealVariant: p.sealVariant,
      soulCount: p.soulCount,
      intentionCount: p.intentionCount,
      videoPath: p.videoPath,
      people: p.people,
      posts: p.posts,
    });
  }

  const after = await existingLists(deps);
  const inserted = toInsert.filter((p) => after.has(p.listNumber)).map((p) => p.listNumber);
  const current = summary.current === null ? undefined : after.get(summary.current);
  if (current && inserted.includes(current.listNumber)) {
    await deps.live.setCurrentList({ listId: current.id, listNumber: current.listNumber, prayerCount: 0, closesAt: null });
  }
  return { ...summary, inserted, currentListId: current?.id ?? null };
}
