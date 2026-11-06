// Subject writes that need server rules (grapheme caps, the pool, the ~500
// abuse cap, the self-name rate limit). Everything else is a connector
// mutation (connector/mutations.gql).

import { HttpsError } from "firebase-functions/v2/https";
import { DAY_MS } from "./dates";
import { hasCheck, mutate, query } from "./db";
import { Deps } from "./deps";
import { selfSubjectId } from "./ids";
import { checkPool, Entitlement, PoolSubject } from "./pool";
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
 * Appended to the bottom of its level. `carry` (default true) asks for it to
 * be carried; false saves it for private prayer only. `carryParent` (an
 * intention under an uncarried name) carries the name too, which also brings
 * back its intentions still flagged. One pool check covers the whole result:
 * if it doesn't fit, nothing is carried — the item is saved for private
 * prayer and the name is left as it was.
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

  // carryParent only acts with carry, on a name that isn't already carried
  // (the self is always carried); otherwise it's a no-op.
  const liftParent = carry && carryParent && !!parent && !parent.isSelf && !parent.isCarried;
  let isCarried = false;
  if (carry) {
    const draft: PoolSubject = {
      id: "new",
      kind,
      isSelf: false,
      isCarried: true,
      status: "ACTIVE",
      resolvedAt: null,
      parent: parentId ? { id: parentId } : null,
      sortOrder,
    };
    const proposed = liftParent ? subjects.map((s) => (s.id === parentId ? { ...s, isCarried: true } : s)) : subjects;
    isCarried = checkPool([...proposed, draft], user, deps.now(), deps.cfg).ok;
  }

  let id: string;
  if (isCarried && liftParent) {
    try {
      const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubjectCarryingParent", {
        uid, parentId, publicName, personalLabel, note, sortOrder,
      });
      id = res.prayerSubject_insert.id;
    } catch (err) {
      // The name was archived from another device since the read.
      if (hasCheck(err, "That name was not found")) throw new HttpsError("invalid-argument", "That name was not found");
      throw err;
    }
  } else {
    const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubject", {
      uid, kind, parentId, publicName, personalLabel, note, isCarried, sortOrder,
    });
    id = res.prayerSubject_insert.id;
  }

  const parentCarried = parent ? parent.isSelf || parent.isCarried || (isCarried && liftParent) : null;
  const effectivelyCarried = isCarried && parentCarried !== false;
  return { id, isCarried, parentCarried, effectivelyCarried, sortOrder };
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
 * Save "your portion": exactly `carriedIds` are carried. Blocked — never
 * trimmed — when the effective carry exceeds the effective entitlement; the
 * error details drive the meter / paywall ("17 / 15").
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
  if (!check.ok) {
    throw new HttpsError("failed-precondition", "Over the carried limit", {
      reason: "OVER_LIMIT",
      carried: check.carried,
      limit: check.limit,
      free: check.free,
    });
  }
  const carriedIds = proposed.filter((s) => !s.isSelf && s.isCarried && s.status === "ACTIVE" && !s.resolvedAt).map((s) => s.id);
  await mutate(deps.db, "SetCarried", { uid, carriedIds });
  return { carried: check.carried, limit: check.limit };
}
