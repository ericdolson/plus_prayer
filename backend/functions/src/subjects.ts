// Subject writes that need server rules (grapheme caps, the pool, the ~500
// abuse cap, the self-name rate limit). Everything else is a connector
// mutation (connector/mutations.gql).

import { HttpsError } from "firebase-functions/v2/https";
import { DAY_MS } from "./dates";
import { hasCheck, mutate, query } from "./db";
import { Deps } from "./deps";
import { selfSubjectId } from "./ids";
import { getClientConfig } from "./clientConfig";
import { addsName, checkPool, chosenIntentions, Entitlement, overCap, PoolSubject } from "./pool";
import { optionalText, requireName, requireNoContact } from "./text";

const ALIAS_CAP = 40;
const NOTE_CAP = 1000;

interface SelfState {
  user: {
    id: string;
    displayName: string | null;
    selfNameChangedAt: string | null;
    self: { id: string; publicName: string }[];
  } | null;
  printed: { _count: number }[];
}

/**
 * Creates the self subject on first call ("What's your name?"); later calls
 * are self-name edits — free until the self name is first printed (an
 * APPROVED entry on a PUBLISHED list), then once per 7 days.
 */
export async function setSelfName(deps: Deps, uid: string, rawName: unknown) {
  const name = requireNoContact(requireName(rawName, deps.cfg.nameCap), "name");
  const state = await query<SelfState>(deps.db, "GetSelfState", { uid });
  if (!state.user) throw new HttpsError("failed-precondition", "Account is not ready yet");
  const self = state.user.self[0];

  if (!self) {
    const res = await mutate<{ _execute: number }>(deps.db, "CreateSelf", { uid, selfId: selfSubjectId(uid), name });
    if (res._execute !== 1) throw new HttpsError("failed-precondition", "Account is not ready yet");
    return { created: true, name, nextChangeAvailableAt: null };
  }
  if (self.publicName === name) {
    return { created: false, name, nextChangeAvailableAt: nextChange(deps, state) };
  }

  const next = nextChange(deps, state);
  if (next && Date.parse(next) > deps.now().getTime()) {
    throw new HttpsError("resource-exhausted", "Your name can be changed again soon", { nextChangeAvailableAt: next });
  }
  const renamed = await mutate<{ _execute: number }>(deps.db, "RenameSelf", { uid, name });
  if (renamed._execute !== 1) throw new HttpsError("failed-precondition", "Your name could not be changed");
  const printed = (state.printed[0]?._count ?? 0) > 0;
  return {
    created: false,
    name,
    nextChangeAvailableAt: printed
      ? new Date(deps.now().getTime() + deps.cfg.selfNameChangeDays * DAY_MS).toISOString()
      : null,
  };
}

function nextChange(deps: Deps, state: SelfState): string | null {
  const printed = (state.printed[0]?._count ?? 0) > 0;
  const changed = state.user?.selfNameChangedAt;
  if (!printed || !changed) return null;
  return new Date(Date.parse(changed) + deps.cfg.selfNameChangeDays * DAY_MS).toISOString();
}

interface PoolState {
  user: ({ id: string; planTier: string } & Entitlement) | null;
  subjects: PoolSubject[];
}

async function poolState(deps: Deps, uid: string) {
  const state = await query<PoolState>(deps.db, "GetPoolState", { uid });
  if (!state.user) throw new HttpsError("failed-precondition", "Account is not ready yet");
  return { user: state.user, subjects: state.subjects };
}

function optionalBool(value: unknown, fallback: boolean, field: string): boolean {
  if (value === undefined || value === null) return fallback;
  if (typeof value !== "boolean") throw new HttpsError("invalid-argument", `${field} must be true or false`);
  return value;
}

/**
 * "Add name" (40) or "Add intention" (80, under a name; default "Me").
 * Appended to the bottom of its level. The pool counts people (Q32,
 * 2026-11-08):
 * - A name is carried while the pool has room (`carry`, default true; false
 *   saves it for private prayer only).
 * - An intention is chosen to print with its person when that person has
 *   fewer than `intentionsPerPerson` chosen (/config). At the cap it's saved
 *   unchosen — unless `carry: true` is passed explicitly, which swaps it in:
 *   the person's last chosen intention(s) by sortOrder are unchosen in the
 *   same write (`unchosenIds`). Choosing costs no place.
 * - `carryParent` (an intention under an uncarried name) carries the name
 *   too, pool-checked. All or nothing: if the name doesn't fit, neither the
 *   name nor the intention changes (no swap), and the item is saved
 *   unchosen for private prayer.
 *
 * Returns the stored flags — `isCarried` (the item's) and, for an intention,
 * `parentCarried` (its name is the self or carried) — and
 * `effectivelyCarried` (it prints: own flag && parent's), which the app uses
 * for "Saved, but not carried". A rare simultaneous add from two devices can
 * overshoot the pool (read-then-write; accepted 2026-11-06, schema-brief).
 */
export async function addSubject(
  deps: Deps,
  uid: string,
  input: {
    kind?: unknown; parentId?: unknown; publicName?: unknown; personalLabel?: unknown; note?: unknown;
    carry?: unknown; carryParent?: unknown;
  },
) {
  const kind = input.kind === "INTENTION" ? "INTENTION" : input.kind === "SOUL" ? "SOUL" : null;
  if (!kind) throw new HttpsError("invalid-argument", "kind must be SOUL or INTENTION");
  const publicName = requireNoContact(
    requireName(input.publicName, kind === "SOUL" ? deps.cfg.nameCap : deps.cfg.intentionCap, "publicName"),
    "publicName",
  );
  // Aliases are owner-only and never printed, so they aren't moderated.
  const personalLabel = optionalText(input.personalLabel, ALIAS_CAP, "personalLabel") ?? null;
  const note = optionalText(input.note, NOTE_CAP, "note") ?? null;
  const carry = optionalBool(input.carry, true, "carry");
  const carryAsked = input.carry === true; // explicit: swap in at the cap
  const carryParent = optionalBool(input.carryParent, false, "carryParent");

  const { user, subjects } = await poolState(deps, uid);
  // The cap people see counts what's on Home (ACTIVE, Answered included), so
  // archiving makes room. A quiet hard cap on every row not purged stops
  // archive-and-add abuse.
  if (subjects.filter((s) => s.status === "ACTIVE").length >= deps.cfg.subjectCap) {
    throw new HttpsError("resource-exhausted", "You've reached 500 names and intentions. Archive some to add more.");
  }
  if (subjects.length >= deps.cfg.subjectHardCap) {
    // Quiet: no dedicated copy; the app shows its generic "Couldn't add this
    // right now. Try again in a little while."
    throw new HttpsError("failed-precondition", "Couldn't add this right now.");
  }

  let parent: PoolSubject | null = null;
  if (kind === "INTENTION") {
    if (typeof input.parentId !== "string") throw new HttpsError("invalid-argument", "An intention needs its name");
    parent = subjects.find((s) => s.id === input.parentId) ?? null;
    if (!parent || parent.kind !== "SOUL" || parent.status !== "ACTIVE") {
      throw new HttpsError("invalid-argument", "That name was not found");
    }
  } else if (input.parentId != null) {
    throw new HttpsError("invalid-argument", "A name has no parent");
  }
  const parentId = parent?.id ?? null;

  const level = subjects.filter((s) => !s.isSelf && (s.parent?.id ?? null) === parentId);
  const sortOrder = level.reduce((max, s) => Math.max(max, s.sortOrder), 0) + 1;

  let id: string;
  if (!parent) {
    const draft: PoolSubject = {
      id: "new", kind: "SOUL", isSelf: false, isCarried: true, status: "ACTIVE", resolvedAt: null, parent: null, sortOrder,
    };
    const isCarried = carry && checkPool([...subjects, draft], user, deps.now(), deps.cfg).ok;
    const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubject", {
      uid, kind, parentId: null, publicName, personalLabel, note, isCarried, sortOrder,
    });
    id = res.prayerSubject_insert.id;
    return { id, isCarried, parentCarried: null, effectivelyCarried: isCarried, sortOrder, unchosenIds: [] as string[] };
  }

  const { intentionsPerPerson: cap } = await getClientConfig(deps.live);
  const chosen = chosenIntentions(subjects, parent.id);
  // carryParent only acts with carry, on a name that isn't already carried
  // (the self is always carried); otherwise it's a no-op.
  const liftParent = carry && carryParent && !parent.isSelf && !parent.isCarried;
  const parentFits = !liftParent ||
    checkPool(subjects.map((s) => (s.id === parent!.id ? { ...s, isCarried: true } : s)), user, deps.now(), deps.cfg).ok;

  let isCarried = false;
  let unchosenIds: string[] = [];
  if (carry && parentFits && cap > 0) {
    if (chosen.length < cap) {
      isCarried = true;
    } else if (carryAsked) {
      isCarried = true;
      unchosenIds = chosen.slice(cap - 1).map((s) => s.id);
    }
  }
  const lifted = isCarried && liftParent;

  try {
    if (lifted) {
      const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubjectCarryingParent", {
        uid, parentId, publicName, personalLabel, note, sortOrder, unchooseIds: unchosenIds,
      });
      id = res.prayerSubject_insert.id;
    } else if (isCarried) {
      const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertChosenIntention", {
        uid, parentId, publicName, personalLabel, note, sortOrder, unchooseIds: unchosenIds,
      });
      id = res.prayerSubject_insert.id;
    } else {
      const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubject", {
        uid, kind, parentId, publicName, personalLabel, note, isCarried: false, sortOrder,
      });
      id = res.prayerSubject_insert.id;
    }
  } catch (err) {
    // The name was archived from another device since the read.
    if (hasCheck(err, "That name was not found")) throw new HttpsError("invalid-argument", "That name was not found");
    throw err;
  }

  const parentCarried = parent.isSelf || parent.isCarried || lifted;
  return { id, isCarried, parentCarried, effectivelyCarried: isCarried && parentCarried, sortOrder, unchosenIds };
}

/** Text edits on a non-self item (the self name goes through setSelfName). */
export async function updateSubject(
  deps: Deps,
  uid: string,
  input: { id?: unknown; publicName?: unknown; personalLabel?: unknown; note?: unknown },
) {
  if (typeof input.id !== "string") throw new HttpsError("invalid-argument", "id is required");
  const { subjects } = await poolState(deps, uid);
  const subject = subjects.find((s) => s.id === input.id && !s.isSelf);
  if (!subject) throw new HttpsError("not-found", "Item not found");
  const vars: Record<string, unknown> = { uid, id: subject.id };
  if (input.publicName !== undefined) {
    vars.publicName = requireNoContact(
      requireName(input.publicName, subject.kind === "SOUL" ? deps.cfg.nameCap : deps.cfg.intentionCap, "publicName"),
      "publicName",
    );
  }
  const personalLabel = optionalText(input.personalLabel, ALIAS_CAP, "personalLabel"); // never printed: not moderated
  if (personalLabel !== undefined) vars.personalLabel = personalLabel;
  const note = optionalText(input.note, NOTE_CAP, "note");
  if (note !== undefined) vars.note = note;
  try {
    await mutate(deps.db, "UpdateSubjectText", vars);
  } catch (err) {
    if (hasCheck(err, "NOT_FOUND")) throw new HttpsError("not-found", "Item not found");
    throw err;
  }
  return { id: subject.id };
}

/**
 * Save "your portion": exactly `carriedIds` are carried (names) or chosen
 * (intentions). Q32 (2026-11-08):
 * - **Pool:** only names going from off to on are pool-checked. Blocked —
 *   never trimmed — when the carried names would then exceed the effective
 *   entitlement (`OVER_LIMIT`; details drive the meter).
 * - **Cap:** a person (Me included) whose chosen intentions grow must end
 *   with at most `intentionsPerPerson` (`OVER_CAP`). Choosing a different
 *   intention (one off, one on) is a swap: cap-checked, never pool-checked.
 * - A save that only reduces carrying is always accepted, even over the
 *   pool or the cap (a lapsed trial trims this way; schema-brief
 *   2026-11-07).
 */
export async function setCarriedItems(deps: Deps, uid: string, rawIds: unknown) {
  if (!Array.isArray(rawIds) || rawIds.some((id) => typeof id !== "string")) {
    throw new HttpsError("invalid-argument", "carriedIds must be a list of ids");
  }
  const { user, subjects } = await poolState(deps, uid);
  const wanted = new Set(rawIds as string[]);
  const proposed = subjects.map((s) =>
    s.isSelf || s.status !== "ACTIVE" || s.resolvedAt ? s : { ...s, isCarried: wanted.has(s.id) },
  );
  const check = checkPool(proposed, user, deps.now(), deps.cfg);
  if (!check.ok && addsName(subjects, proposed)) {
    throw new HttpsError("failed-precondition", "Over the carried limit", {
      reason: "OVER_LIMIT",
      carried: check.carried,
      limit: check.limit,
      free: check.free,
    });
  }
  const { intentionsPerPerson: cap } = await getClientConfig(deps.live);
  const over = overCap(subjects, proposed, cap);
  if (over.length > 0) {
    throw new HttpsError("failed-precondition", "Over the intentions per person", {
      reason: "OVER_CAP",
      cap,
      personIds: over,
    });
  }
  const carriedIds = proposed.filter((s) => !s.isSelf && s.isCarried && s.status === "ACTIVE" && !s.resolvedAt).map((s) => s.id);
  await mutate(deps.db, "SetCarried", { uid, carriedIds });
  return { carried: check.carried, limit: check.limit };
}

/**
 * Restore an archived item (subjects.md, schema-brief §7). Never blocked for
 * the pool or the cap, never over them (2026-11-07; Q32 2026-11-08):
 * - A carried name that would go over the owner's pool comes back
 *   uncarried; its cascade-archived intentions keep their choices.
 * - A chosen intention whose person already has `intentionsPerPerson`
 *   chosen comes back unchosen. One that comes back resolved (Answered)
 *   isn't counted and keeps its flag.
 *
 * Returns `isCarried` (the item's stored flag after) and `uncarried` (true
 * when the pool or the cap turned it off), so the app can say so.
 */
export async function restoreSubject(deps: Deps, uid: string, rawId: unknown) {
  if (typeof rawId !== "string") throw new HttpsError("invalid-argument", "id is required");
  const { user, subjects } = await poolState(deps, uid);
  const item = subjects.find((s) => s.id === rawId && s.status === "ARCHIVED");
  if (!item) throw new HttpsError("not-found", "Archived item not found");
  const parent = item.parent ? subjects.find((s) => s.id === item.parent!.id) : undefined;
  if (item.parent && parent?.status !== "ACTIVE") {
    throw new HttpsError("failed-precondition", "Restore its name first");
  }

  const restore = (s: PoolSubject, isCarried: boolean): PoolSubject => {
    if (s.id === item.id) {
      const reopened = s.resolution === "RELEASED";
      return {
        ...s, status: "ACTIVE", isCarried, archivedByCascade: false,
        ...(reopened ? { resolution: null, resolvedAt: null } : {}),
      };
    }
    if (item.kind === "SOUL" && s.parent?.id === item.id && s.status === "ARCHIVED" && s.archivedByCascade) {
      return { ...s, status: "ACTIVE", archivedByCascade: false };
    }
    return s;
  };

  let isCarried = item.isCarried;
  if (isCarried) {
    const after = subjects.map((s) => restore(s, true));
    if (item.kind === "SOUL") {
      if (!checkPool(after, user, deps.now(), deps.cfg).ok) isCarried = false;
    } else {
      const { intentionsPerPerson: cap } = await getClientConfig(deps.live);
      const chosenAfter = chosenIntentions(after, item.parent!.id);
      const counted = chosenAfter.some((s) => s.id === item.id); // open after the restore
      if (counted && chosenAfter.length > cap) isCarried = false;
    }
  }

  try {
    await mutate(deps.db, "RestoreSubjectFor", { uid, id: item.id, isCarried });
  } catch (err) {
    // Restored, purged, or its name archived from another device since the read.
    if (hasCheck(err, "Restore its name first")) throw new HttpsError("failed-precondition", "Restore its name first");
    if (hasCheck(err, "Archived item not found")) throw new HttpsError("not-found", "Archived item not found");
    throw err;
  }
  return { id: item.id, isCarried, uncarried: item.isCarried && !isCarried };
}
