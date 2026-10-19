// Subject writes that need server rules (grapheme caps, the pool, the ~500
// abuse cap, the self-name rate limit). Everything else is a connector
// mutation (connector/mutations.gql).

import { HttpsError } from "firebase-functions/v2/https";
import { DAY_MS } from "./dates";
import { hasCheck, mutate, query } from "./db";
import { Deps } from "./deps";
import { selfSubjectId } from "./ids";
import { checkPool, Entitlement, PoolSubject } from "./pool";
import { optionalText, requireName } from "./text";

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
  const name = requireName(rawName, deps.cfg.nameCap);
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

/**
 * "Add name" (40) or "Add intention" (80, under a name; default "Me").
 * Appended to the bottom of its level; carried automatically while the pool
 * has room, otherwise saved for private prayer and marked not on the list.
 */
export async function addSubject(
  deps: Deps,
  uid: string,
  input: { kind?: unknown; parentId?: unknown; publicName?: unknown; personalLabel?: unknown; note?: unknown },
) {
  const kind = input.kind === "INTENTION" ? "INTENTION" : input.kind === "SOUL" ? "SOUL" : null;
  if (!kind) throw new HttpsError("invalid-argument", "kind must be SOUL or INTENTION");
  const publicName = requireName(input.publicName, kind === "SOUL" ? deps.cfg.nameCap : deps.cfg.intentionCap, "publicName");
  const personalLabel = optionalText(input.personalLabel, ALIAS_CAP, "personalLabel") ?? null;
  const note = optionalText(input.note, NOTE_CAP, "note") ?? null;

  const { user, subjects } = await poolState(deps, uid);
  if (subjects.length >= deps.cfg.subjectCap) {
    throw new HttpsError("resource-exhausted", "This list is very full. Contact us if you need more room.");
  }

  let parentId: string | null = null;
  if (kind === "INTENTION") {
    if (typeof input.parentId !== "string") throw new HttpsError("invalid-argument", "An intention needs its name");
    const parent = subjects.find((s) => s.id === input.parentId);
    if (!parent || parent.kind !== "SOUL" || parent.status !== "ACTIVE") {
      throw new HttpsError("invalid-argument", "That name was not found");
    }
    parentId = parent.id;
  } else if (input.parentId != null) {
    throw new HttpsError("invalid-argument", "A name has no parent");
  }

  const level = subjects.filter((s) => !s.isSelf && (s.parent?.id ?? null) === parentId);
  const sortOrder = level.reduce((max, s) => Math.max(max, s.sortOrder), 0) + 1;

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
  const isCarried = checkPool([...subjects, draft], user, deps.now(), deps.cfg).ok;

  const res = await mutate<{ prayerSubject_insert: { id: string } }>(deps.db, "InsertSubject", {
    uid, kind, parentId, publicName, personalLabel, note, isCarried, sortOrder,
  });
  return { id: res.prayerSubject_insert.id, isCarried, sortOrder };
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
    vars.publicName = requireName(input.publicName, subject.kind === "SOUL" ? deps.cfg.nameCap : deps.cfg.intentionCap, "publicName");
  }
  const personalLabel = optionalText(input.personalLabel, ALIAS_CAP, "personalLabel");
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
