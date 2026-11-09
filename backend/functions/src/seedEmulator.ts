// Seed data for the LOCAL EMULATORS only (scripts/seed-emulator.ts runs it
// after assertEmulatorTarget). Rich, believable test data modelled on the
// iOS app's MockSeed (apps/ios/PlusPrayer/Data/Mock/MockSeed.swift), so the
// app on the real repositories looks like it does on the mock:
//
//   Lists 1–70, one per day ending today (Mountain date). Older lists are
//   published, sealed in their weekday's wax and settled with plausible
//   counts; today's list (70) is current, open (no closesAt), sealed; RTDB
//   /lists/current matches it.
//
//   For each test user (the uid the app signed in with):
//   - Me (the self name kept from the name step, else "Eric Olson") with a
//     chosen intention;
//   - Dad, carried, prayed for near-daily, two intentions, one chosen;
//   - Mom, carried, her intention answered 10 days ago;
//   - Aunt Bea, private (never carried: no list entries), prayer days with gaps;
//   - Daniel Kim, Our parish, Ukraine (added 2 days ago) carried; Lena Park
//     added today, not carried;
//   - ~2 months of prayers (morning / evening, some days two, one auto-saved,
//     several holding many people, some with journal entries), a few days
//     off and a few without the list;
//   - entries on every list after a day you prayed with the list before it;
//   - the streak, computed with the server's own rule (applyListDay).
//   Q32: the pool counts people (5 carried of 10), each person has at most
//   one chosen open intention.
//
//   RTDB: /config (missing keys, as seed-config does), the blocklist (if
//   empty), /stats/live, /lists/current; /presence is cleared.
//
// The whole SQL Connect database is wiped first: a seed is a known state.
// Restoring that state later is the snapshot's job (backend/CLAUDE.md,
// "Test on your phone with the emulators").

import { CLIENT_CONFIG_DEFAULTS } from "./config";
import { addDays, daysBetween, localDateIn, weekday } from "./dates";
import { Deps } from "./deps";
import { normId, selfSubjectId, stableUuid } from "./ids";
import { seedBlocklist } from "./moderation";
import { applyListDay, StreakState } from "./streak";

export const SEED_LIST_COUNT = 70;
export const SEED_TIME_ZONE = "America/Denver";
export const SEED_DEFAULT_NAME = "Eric Olson";
export const SEED_LIVE_STATS = { prayingNow: 213, prayedLastHour: 640, prayedToday: 4113 };
/** The pool the seeded users hold (a base subscription: basePremiumPool). */
export const SEED_INCLUDE_LIMIT = 10;

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

// ----------------------------------------------------------------- time --

function tzOffsetMs(timeZone: string, at: Date): number {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
    }).formatToParts(at).map((p) => [p.type, p.value]),
  );
  const asUtc = Date.UTC(+parts.year, +parts.month - 1, +parts.day, +parts.hour, +parts.minute, +parts.second);
  return asUtc - Math.floor(at.getTime() / 1000) * 1000;
}

/** The instant of a wall-clock time on a calendar date in `timeZone`. */
export function zonedInstant(date: string, hour: number, minute: number, timeZone: string): Date {
  const [y, m, d] = date.split("-").map(Number);
  const wall = Date.UTC(y, m - 1, d, hour, minute);
  let t = wall;
  for (let i = 0; i < 3; i++) t = wall - tzOffsetMs(timeZone, new Date(t));
  return new Date(t);
}

// ----------------------------------------------------------------- plan --

export interface SeedList {
  id: string;
  listNumber: number;
  listDate: string;
  status: "published";
  currentFrom: string;
  closesAt: string | null;
  settledAt: string | null;
  publishedAt: string;
  videoPublishedAt: string;
  sealVariant: number;
  soulCount: number;
  intentionCount: number;
  prayerCount: number;
  prayerSeconds: number;
}

export interface SeedSubject {
  key: string;
  id: string;
  kind: "SOUL" | "INTENTION";
  parentId: string | null;
  publicName: string;
  personalLabel: string | null;
  isSelf: boolean;
  isCarried: boolean;
  sortOrder: number;
  avatarTone: number | null;
  resolution: "ANSWERED" | null;
  resolvedAt: string | null;
  createdAt: string;
}

export interface SeedPrayer {
  id: string;
  startedAt: string;
  prayedAt: string;
  durationSeconds: number;
  localDate: string;
  timezone: string;
  communityListId: string | null;
  listContextNumber: number;
  endedBy: "AMEN" | "AUTO";
  note: string | null;
  countedAt: string;
  subjectIds: string[];
}

export interface SeedEntry {
  id: string;
  listId: string;
  subjectId: string;
  parentEntryId: string | null;
  kind: "SOUL" | "INTENTION";
  publicName: string;
}

export interface SeedUserPlan {
  uid: string;
  displayName: string;
  user: {
    timezone: string;
    planTier: string;
    includeLimit: number;
    trialStartedAt: string;
    entitlementExpiresAt: string;
    streak: StreakState;
  };
  subjects: SeedSubject[];
  prayers: SeedPrayer[];
  entries: SeedEntry[];
}

/** Lists 1..70, the last one today (Mountain date, `listTimeZone`). */
export function planLists(now: Date, listTimeZone = SEED_TIME_ZONE): SeedList[] {
  const today = localDateIn(listTimeZone, now);
  const lists: SeedList[] = [];
  for (let n = 1; n <= SEED_LIST_COUNT; n++) {
    const back = SEED_LIST_COUNT - n;
    const listDate = addDays(today, -back);
    // The morning routine's cutoff (~6 am MT); today's never later than an
    // hour ago, so it's current whenever the seed runs.
    let currentFrom = zonedInstant(listDate, 6, (n * 7) % 20, listTimeZone);
    if (back === 0 && currentFrom.getTime() > now.getTime() - HOUR) currentFrom = new Date(now.getTime() - HOUR);
    const soulCount = 2600 + n * 25 + ((n * 37) % 90);
    lists.push({
      id: normId(stableUuid("seed-list", n)),
      listNumber: n,
      listDate,
      status: "published",
      currentFrom: currentFrom.toISOString(),
      closesAt: null,
      settledAt: null,
      publishedAt: new Date(Math.min(currentFrom.getTime() + 2 * HOUR, now.getTime())).toISOString(),
      videoPublishedAt: new Date(Math.min(currentFrom.getTime() + 2 * HOUR, now.getTime())).toISOString(),
      sealVariant: weekday(listDate),
      soulCount,
      intentionCount: Math.round(soulCount * 0.28),
      prayerCount: 0,
      prayerSeconds: 0,
    });
  }
  // Each list closes when the next becomes current and settles at assembly.
  for (let i = 0; i < lists.length - 1; i++) {
    const closesAt = lists[i + 1].currentFrom;
    lists[i].closesAt = closesAt;
    lists[i].settledAt = new Date(Date.parse(closesAt) + 20 * MINUTE).toISOString();
    lists[i].prayerCount = Math.round(lists[i].soulCount * 0.88) + ((lists[i].listNumber * 53) % 140);
  }
  // Today's count so far.
  const current = lists[lists.length - 1];
  const sinceOpen = Math.max(0, now.getTime() - Date.parse(current.currentFrom));
  current.prayerCount = Math.max(120, Math.round(current.soulCount * 0.88 * Math.min(1, sinceOpen / (16 * HOUR))));
  for (const l of lists) l.prayerSeconds = l.prayerCount * 540;
  return lists;
}

/** Illustrative journal entries (user content, as in MockHistory). */
const JOURNAL = [
  "Dad sounded stronger on the phone tonight.",
  "A quiet morning. Thought of Mom most of the time.",
  "Hard to focus today. Stayed anyway.",
  "Daniel starts treatment next week.",
  "Prayed on the walk to work.",
];
const ANSWERED_ENTRY = "Ruth's baby is here. Both well.";

/** Days (back from today) with no prayer at all, and with a prayer but not with the list. */
const DAYS_OFF = new Set([50, 41, 33, 24, 16, 11]);
const WITHOUT_LIST = new Set([45, 29, 0]);
const BEA_DAYS = new Set([44, 37, 30, 22, 9, 3]);
const PRAYER_DAYS = 60; // b = 59 … 0
const ANSWERED_AGO = 10;
const AUTO_SAVED_DAY = 9;

interface SubjectSpec {
  key: string;
  kind: "SOUL" | "INTENTION";
  parent?: string;
  name: string;
  alias?: string;
  carried: boolean;
  order: number;
  tone?: number;
  createdAgo: number;
  answeredAgo?: number;
  /** Held on the day `b` days back (before its parent's rule is applied). */
  held: (b: number) => boolean;
}

function subjectSpecs(selfName: string): SubjectSpec[] {
  return [
    { key: "self", kind: "SOUL", name: selfName, alias: "Me", carried: true, order: 0, tone: 7, createdAgo: 62, held: (b) => b % 3 === 0 },
    { key: "self-1", kind: "INTENTION", parent: "self", name: "Patience with the new job", carried: true, order: 1, createdAgo: 35, held: (b) => b % 6 === 0 },
    { key: "dad", kind: "SOUL", name: "Gary Olson", alias: "Dad", carried: true, order: 1, tone: 0, createdAgo: 60, held: (b) => b % 7 !== 3 },
    { key: "dad-1", kind: "INTENTION", parent: "dad", name: "Healing after his surgery", carried: true, order: 1, createdAgo: 58, held: (b) => b % 7 !== 3 && b % 2 === 0 },
    { key: "dad-2", kind: "INTENTION", parent: "dad", name: "Rest for his heart", carried: false, order: 2, createdAgo: 25, held: (b) => b % 5 === 0 },
    { key: "mom", kind: "SOUL", name: "Margaret Olson", alias: "Mom", carried: true, order: 2, tone: 8, createdAgo: 55, held: (b) => b % 2 === 1 || b === ANSWERED_AGO },
    { key: "mom-1", kind: "INTENTION", parent: "mom", name: "A safe delivery for Ruth", carried: true, order: 1, createdAgo: 54, answeredAgo: ANSWERED_AGO, held: (b) => (b % 2 === 1 || b === ANSWERED_AGO) && b >= ANSWERED_AGO },
    { key: "daniel", kind: "SOUL", name: "Daniel Kim", carried: true, order: 3, tone: 10, createdAgo: 40, held: (b) => b % 4 === 1 },
    { key: "parish", kind: "SOUL", name: "Our parish", carried: true, order: 4, tone: 13, createdAgo: 20, held: (b) => b % 6 === 2 },
    { key: "ukraine", kind: "SOUL", name: "Ukraine", carried: true, order: 5, tone: 14, createdAgo: 2, held: (b) => b <= 1 },
    { key: "bea", kind: "SOUL", name: "Beatrice Moreno", alias: "Aunt Bea", carried: false, order: 6, tone: 6, createdAgo: 45, held: (b) => BEA_DAYS.has(b) },
    // Added today: nothing yet but today.
    { key: "lena", kind: "SOUL", name: "Lena Park", carried: false, order: 7, tone: 3, createdAgo: 0, held: () => false },
  ];
}

/** One test user's rows, deterministic for (uid, now). */
export function planUser(uid: string, lists: SeedList[], now: Date, selfName = SEED_DEFAULT_NAME,
                         timezone = SEED_TIME_ZONE): SeedUserPlan {
  const today = localDateIn(timezone, now);
  const listOn = new Map(lists.map((l) => [l.listDate, l]));
  const specs = subjectSpecs(selfName);
  const idOf = (key: string) => (key === "self" ? normId(selfSubjectId(uid)) : normId(stableUuid("seed-subject", uid, key)));
  const createdAt = (s: SubjectSpec) =>
    s.createdAgo === 0
      ? new Date(Math.max(zonedInstant(today, 0, 1, timezone).getTime(), now.getTime() - 5 * MINUTE))
      : zonedInstant(addDays(today, -s.createdAgo), 6, 30, timezone);

  const subjects: SeedSubject[] = specs.map((s) => ({
    key: s.key,
    id: idOf(s.key),
    kind: s.kind,
    parentId: s.parent ? idOf(s.parent) : null,
    publicName: s.name,
    personalLabel: s.alias ?? null,
    isSelf: s.key === "self",
    isCarried: s.carried,
    sortOrder: s.order,
    avatarTone: s.tone ?? null,
    resolution: s.answeredAgo === undefined ? null : "ANSWERED",
    resolvedAt: s.answeredAgo === undefined ? null : zonedInstant(addDays(today, -s.answeredAgo), 20, 15, timezone).toISOString(),
    createdAt: createdAt(s).toISOString(),
  }));
  const byKey = new Map(specs.map((s) => [s.key, s]));

  // Prayers, oldest first.
  const prayers: SeedPrayer[] = [];
  for (let b = PRAYER_DAYS - 1; b >= 0; b--) {
    if (DAYS_OFF.has(b)) continue;
    const date = addDays(today, -b);
    const list = listOn.get(date)!;
    const exists = (s: SubjectSpec) => s.createdAgo > b;
    let held = specs.filter((s) => exists(s) && s.held(b) && (!s.parent || exists(byKey.get(s.parent)!)));
    // An intention held brings its name, as the server links it.
    const parents = held.filter((s) => s.parent).map((s) => byKey.get(s.parent!)!);
    held = [...new Set([...held, ...parents])];
    if (held.length === 0) held = [byKey.get("self")!];

    // Some days a morning and an evening prayer, split by person.
    const people = held.filter((s) => s.kind === "SOUL").sort((a, c) => a.order - c.order);
    const split = b % 5 === 2 && people.length >= 2;
    const parts = split
      ? [people.slice(0, Math.ceil(people.length / 2)), people.slice(Math.ceil(people.length / 2))]
      : [people];
    parts.forEach((part, idx) => {
      const keys = new Set(part.map((p) => p.key));
      const ids = held.filter((s) => keys.has(s.parent ?? s.key)).map((s) => idOf(s.key));
      const morning = split ? idx === 0 : b % 2 === 0;
      const autoSaved = b === AUTO_SAVED_DAY && idx === 0;
      const durationSeconds = autoSaved ? 38 * 60 : (4 + ((b * 13 + idx * 5) % 20)) * 60;
      let start = morning
        ? zonedInstant(date, 7, (b * 7) % 40, timezone)
        : zonedInstant(date, 21, (b * 11) % 45, timezone);
      if (b === 0) {
        // Today's prayer was earlier today, never in the future.
        const dayStart = zonedInstant(date, 0, 0, timezone).getTime();
        const latest = now.getTime() - durationSeconds * 1000 - MINUTE;
        start = new Date(Math.max(dayStart, Math.min(start.getTime(), latest)));
      }
      const end = new Date(start.getTime() + durationSeconds * 1000);
      const last = idx === parts.length - 1;
      const note = b === ANSWERED_AGO && last ? ANSWERED_ENTRY
        : (b * 3 + idx) % 4 === 1 ? JOURNAL[(b + idx) % JOURNAL.length] : null;
      prayers.push({
        id: normId(stableUuid("seed-prayer", uid, b, idx)),
        startedAt: start.toISOString(),
        prayedAt: end.toISOString(),
        durationSeconds,
        localDate: date,
        timezone,
        communityListId: WITHOUT_LIST.has(b) ? null : list.id,
        listContextNumber: list.listNumber,
        endedBy: autoSaved ? "AUTO" : "AMEN",
        note,
        // Already counted: the emulator sweeper never re-applies them.
        countedAt: end.toISOString(),
        subjectIds: ids,
      });
    });
  }

  // Entries: list N prints you and what you carried if you prayed with N-1.
  const listDays = [...new Set(prayers.filter((p) => p.communityListId).map((p) => p.localDate))].sort();
  const prayedWith = new Set(listDays);
  const entries: SeedEntry[] = [];
  for (let i = 1; i < lists.length; i++) {
    const list = lists[i];
    if (!prayedWith.has(lists[i - 1].listDate)) continue;
    const b = daysBetween(list.listDate, today);
    const printedName = new Map<string, string>();
    for (const s of specs) {
      if (s.kind !== "SOUL" || !s.carried || !(s.createdAgo > b)) continue;
      const entryId = normId(stableUuid("seed-entry", uid, list.listNumber, s.key));
      printedName.set(s.key, entryId);
      entries.push({ id: entryId, listId: list.id, subjectId: idOf(s.key), parentEntryId: null, kind: "SOUL", publicName: s.name });
    }
    for (const s of specs) {
      if (s.kind !== "INTENTION" || !s.carried || !(s.createdAgo > b) || !printedName.has(s.parent!)) continue;
      if (s.answeredAgo !== undefined && !(b > s.answeredAgo)) continue; // printed until it was answered
      entries.push({
        id: normId(stableUuid("seed-entry", uid, list.listNumber, s.key)),
        listId: list.id,
        subjectId: idOf(s.key),
        parentEntryId: printedName.get(s.parent!)!,
        kind: "INTENTION",
        publicName: s.name,
      });
    }
  }

  // The streak, with the server's rule, over the list days.
  let streak: StreakState = { currentStreak: 0, bestStreak: 0, lastListLocalDate: null, graceDays: 1, graceOfferPending: false };
  for (const day of listDays) {
    streak = applyListDay(streak, day, { graceCap: 2, graceIntervalDays: 7, graceOffersEnabled: false });
  }
  const firstPrayer = prayers[0];

  return {
    uid,
    displayName: selfName,
    user: {
      timezone,
      // Trial at the first prayer, then the base subscription.
      planTier: "plan_a",
      includeLimit: SEED_INCLUDE_LIMIT,
      trialStartedAt: firstPrayer.startedAt,
      entitlementExpiresAt: new Date(now.getTime() + 25 * DAY).toISOString(),
      streak,
    },
    subjects,
    prayers,
    entries,
  };
}

// ------------------------------------------------------------------ write --

/** One native statement over a JSON array (`$1::jsonb`); returns rows affected. */
async function execJson(deps: Deps, statement: string, rows: unknown): Promise<number> {
  const res = await deps.db.executeGraphql<{ n: number }, { rows: unknown }>(
    `mutation Seed($rows: Any) { n: _execute(sql: ${JSON.stringify(statement)}, params: [{ _expr: "vars.rows" }]) }`,
    { variables: { rows } },
  );
  return res.data.n;
}

async function selectRows<T>(deps: Deps, statement: string): Promise<T[]> {
  const res = await deps.db.executeGraphql<{ rows: T[] }, Record<string, never>>(`query Q { rows: _select(sql: ${JSON.stringify(statement)}) }`);
  return res.data.rows;
}

const TABLES = [
  "prayer_subject_link", "prayer_list_entry", "prayer", "reminder_preference",
  "prayer_subject", "prayer_list_post", "prayer_list", "external_person", "daily_stats", '"user"',
];

/** Deletes every row (children first). */
export async function wipeDatabase(deps: Deps): Promise<void> {
  const fields = TABLES.map((t, i) => `t${i}: _execute(sql: ${JSON.stringify(`DELETE FROM ${t}`)})`).join("\n");
  await deps.db.executeGraphql(`mutation Wipe { ${fields} }`);
}

export interface SeedSummary {
  lists: number;
  currentList: { listNumber: number; listDate: string; prayerCount: number };
  users: {
    uid: string;
    name: string;
    subjects: number;
    prayers: number;
    entries: number;
    currentStreak: number;
    bestStreak: number;
  }[];
}

/**
 * Wipes the emulator's SQL Connect data and writes the seed for `uids`
 * (each gets the same personal data). Keeps each user's self name if the app
 * already set one (the name step), unless `name` is given. Only call it
 * after assertEmulatorTarget().
 */
export async function seedEmulator(deps: Deps, opts: { uids: string[]; now?: Date; name?: string }): Promise<SeedSummary> {
  if (opts.uids.length === 0) throw new Error("No users to seed");
  const now = opts.now ?? deps.now();
  const names = new Map(
    (await selectRows<{ owner_id: string; public_name: string }>(
      deps, "SELECT owner_id, public_name FROM prayer_subject WHERE is_self",
    )).map((r) => [r.owner_id, r.public_name]),
  );
  const lists = planLists(now, deps.cfg.listTimeZone);
  const plans = opts.uids.map((uid) => planUser(uid, lists, now, opts.name ?? names.get(uid) ?? SEED_DEFAULT_NAME));

  await wipeDatabase(deps);
  await execJson(deps, `
    INSERT INTO prayer_list
      (id, scope, list_number, list_date, status, current_from, closes_at, settled_at, published_at,
       video_published_at, seal_variant, soul_count, intention_count, prayer_count, prayer_seconds, created_at)
    SELECT x.id, 'GLOBAL', x."listNumber", x."listDate", x.status, x."currentFrom", x."closesAt", x."settledAt",
      x."publishedAt", x."videoPublishedAt", x."sealVariant", x."soulCount", x."intentionCount", x."prayerCount",
      x."prayerSeconds", x."currentFrom"
    FROM jsonb_to_recordset($1::jsonb) AS x(id uuid, "listNumber" int, "listDate" date, status text,
      "currentFrom" timestamptz, "closesAt" timestamptz, "settledAt" timestamptz, "publishedAt" timestamptz,
      "videoPublishedAt" timestamptz, "sealVariant" int, "soulCount" int, "intentionCount" int,
      "prayerCount" int, "prayerSeconds" int)`, lists);

  for (const plan of plans) {
    const u = plan.user;
    await execJson(deps, `
      INSERT INTO "user"
        (id, display_name, auth_provider, is_anonymous, locale, timezone, plan_tier, include_limit,
         trial_started_at, entitlement_expires_at, current_streak, best_streak, last_list_local_date,
         grace_days, grace_offer_pending, grace_offers_enabled, last_stats_date, created_at)
      SELECT x.id, x."displayName", 'anonymous', true, 'en', x.timezone, x."planTier", x."includeLimit",
        x."trialStartedAt", x."entitlementExpiresAt", x."currentStreak", x."bestStreak", x."lastListLocalDate",
        x."graceDays", false, true, NULL, x."createdAt"
      FROM jsonb_to_recordset($1::jsonb) AS x(id text, "displayName" text, timezone text, "planTier" text,
        "includeLimit" int, "trialStartedAt" timestamptz, "entitlementExpiresAt" timestamptz,
        "currentStreak" int, "bestStreak" int, "lastListLocalDate" date, "graceDays" int, "createdAt" timestamptz)`,
    [{
      id: plan.uid, displayName: plan.displayName, timezone: u.timezone, planTier: u.planTier,
      includeLimit: u.includeLimit, trialStartedAt: u.trialStartedAt, entitlementExpiresAt: u.entitlementExpiresAt,
      currentStreak: u.streak.currentStreak, bestStreak: u.streak.bestStreak,
      lastListLocalDate: u.streak.lastListLocalDate, graceDays: u.streak.graceDays,
      createdAt: plan.subjects[0].createdAt,
    }]);
    // Names before intentions (parent_id references a row).
    const ordered = [...plan.subjects].sort((a, b) => (a.kind === b.kind ? 0 : a.kind === "SOUL" ? -1 : 1));
    await execJson(deps, `
      INSERT INTO prayer_subject
        (id, owner_id, kind, parent_id, public_name, personal_label, is_self, is_carried, status, sort_order,
         avatar_tone, resolution, resolved_at, created_at)
      SELECT x.id, x."ownerId", x.kind::subject_kind, x."parentId", x."publicName", x."personalLabel", x."isSelf",
        x."isCarried", 'ACTIVE', x."sortOrder", x."avatarTone", x.resolution::subject_resolution, x."resolvedAt",
        x."createdAt"
      FROM jsonb_to_recordset($1::jsonb) AS x(id uuid, "ownerId" text, kind text, "parentId" uuid,
        "publicName" text, "personalLabel" text, "isSelf" boolean, "isCarried" boolean, "sortOrder" int,
        "avatarTone" int, resolution text, "resolvedAt" timestamptz, "createdAt" timestamptz)`,
    ordered.map((s) => ({ ...s, ownerId: plan.uid })));
    await execJson(deps, `
      INSERT INTO prayer
        (id, user_id, started_at, prayed_at, duration_seconds, local_date, timezone, community_list_id,
         list_context_number, ended_by, mode, note, counted_at)
      SELECT x.id, x."userId", x."startedAt", x."prayedAt", x."durationSeconds", x."localDate", x.timezone,
        x."communityListId", x."listContextNumber", x."endedBy"::prayer_ended_by, 'MANUAL', x.note, x."countedAt"
      FROM jsonb_to_recordset($1::jsonb) AS x(id uuid, "userId" text, "startedAt" timestamptz,
        "prayedAt" timestamptz, "durationSeconds" int, "localDate" date, timezone text, "communityListId" uuid,
        "listContextNumber" int, "endedBy" text, note text, "countedAt" timestamptz)`,
    plan.prayers.map((p) => ({ ...p, userId: plan.uid })));
    await execJson(deps, `
      INSERT INTO prayer_subject_link (prayer_id, subject_id)
      SELECT x."prayerId", x."subjectId" FROM jsonb_to_recordset($1::jsonb) AS x("prayerId" uuid, "subjectId" uuid)`,
    plan.prayers.flatMap((p) => p.subjectIds.map((subjectId) => ({ prayerId: p.id, subjectId }))));
    // Names before intentions (parent_entry_id references a row).
    const entries = [...plan.entries].sort((a, b) => (a.kind === b.kind ? 0 : a.kind === "SOUL" ? -1 : 1));
    await execJson(deps, `
      INSERT INTO prayer_list_entry
        (id, list_id, subject_id, owner_id, parent_entry_id, kind, public_name, source, moderation_status)
      SELECT x.id, x."listId", x."subjectId", x."ownerId", x."parentEntryId", x.kind::subject_kind, x."publicName",
        'APP', 'APPROVED'
      FROM jsonb_to_recordset($1::jsonb) AS x(id uuid, "listId" uuid, "subjectId" uuid, "ownerId" text,
        "parentEntryId" uuid, kind text, "publicName" text)`,
    entries.map((e) => ({ ...e, ownerId: plan.uid })));
  }

  // RTDB, as seed-config does, plus the live nodes.
  const current = lists[lists.length - 1];
  await deps.live.writeClientConfigDefaults(CLIENT_CONFIG_DEFAULTS);
  await deps.live.writeBlocklistIfMissing(seedBlocklist());
  await deps.live.setStatsLive({ ...SEED_LIVE_STATS, updatedAt: now.getTime() });
  await deps.live.setCurrentList({ listId: current.id, listNumber: current.listNumber, prayerCount: current.prayerCount, closesAt: null });
  for (const uid of opts.uids) await deps.live.removeUser(uid);

  return {
    lists: lists.length,
    currentList: { listNumber: current.listNumber, listDate: current.listDate, prayerCount: current.prayerCount },
    users: plans.map((p) => ({
      uid: p.uid,
      name: p.displayName,
      subjects: p.subjects.length,
      prayers: p.prayers.length,
      entries: p.entries.length,
      currentStreak: p.user.streak.currentStreak,
      bestStreak: p.user.streak.bestStreak,
    })),
  };
}
