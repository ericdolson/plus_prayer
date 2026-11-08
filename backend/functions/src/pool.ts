// The carried pool (docs/product/monetization.md, subjects.md; Q32,
// 2026-11-08). Mirrors the rules assembleNextList applies in SQL
// (admin/lists.gql AssembleList), so a save the server accepts is exactly
// what the next list will print.
//
// - A place = one carried PERSON (a name) beyond the self name. Intentions
//   never cost a place.
// - An intention's `isCarried` means "chosen to print with its person"; each
//   person (Me included) may have at most `intentionsPerPerson` chosen
//   (RTDB /config, default 1). It prints only when its person is carried.

import { ServerConfig } from "./config";

export interface PoolSubject {
  id: string;
  kind: "SOUL" | "INTENTION";
  isSelf: boolean;
  isCarried: boolean;
  status: "ACTIVE" | "ARCHIVED" | "PURGED";
  resolvedAt: string | null;
  parent: { id: string } | null;
  sortOrder: number;
  /** Present from GetPoolState (restore needs them); drafts leave them out. */
  resolution?: "ANSWERED" | "RELEASED" | null;
  archivedByCascade?: boolean;
}

export interface Entitlement {
  includeLimit: number;
  entitlementExpiresAt: string | null;
}

export function hasActiveEntitlement(e: Entitlement, now: Date): boolean {
  return e.entitlementExpiresAt !== null && Date.parse(e.entitlementExpiresAt) > now.getTime();
}

const isOpen = (s: PoolSubject) => s.status === "ACTIVE" && !s.resolvedAt;

/** Carried names beyond the self name (ACTIVE, flagged): what the pool counts. */
export function carriedNames(subjects: PoolSubject[]): PoolSubject[] {
  return subjects.filter((s) => s.kind === "SOUL" && !s.isSelf && s.isCarried && isOpen(s));
}

/**
 * A person's chosen intentions: open (ACTIVE, unresolved) intentions flagged
 * isCarried under that name, in the person's order. Answered ones don't
 * count (answering the chosen one frees the choice).
 */
export function chosenIntentions(subjects: PoolSubject[], personId: string): PoolSubject[] {
  return subjects
    .filter((s) => s.kind === "INTENTION" && s.parent?.id === personId && s.isCarried && isOpen(s))
    .sort((a, b) => a.sortOrder - b.sortOrder);
}

export interface PoolCheck {
  ok: boolean;
  /** Carried names beyond the self name. */
  carried: number;
  /** The limit the save is measured against (free → freeLimit). */
  limit: number;
  free: boolean;
}

/** Do the carried names fit the user's EFFECTIVE entitlement right now? */
export function checkPool(subjects: PoolSubject[], e: Entitlement, now: Date, cfg: ServerConfig): PoolCheck {
  const carried = carriedNames(subjects).length;
  const free = !hasActiveEntitlement(e, now);
  const limit = free ? cfg.freeLimit : e.includeLimit;
  return { ok: carried <= limit, carried, limit, free };
}

/** Does `proposed` turn on a name that `current` has off? (Only that is pool-checked.) */
export function addsName(current: PoolSubject[], proposed: PoolSubject[]): boolean {
  const before = new Map(current.map((s) => [s.id, s.isCarried]));
  return proposed.some((s) => s.kind === "SOUL" && !s.isSelf && s.isCarried && before.get(s.id) !== true);
}

/**
 * People whose chosen intentions grew from `current` to `proposed` and are now
 * over the cap. A person whose choices didn't grow is never reported, so a
 * save that only reduces is always accepted (even with old data over the cap).
 */
export function overCap(current: PoolSubject[], proposed: PoolSubject[], cap: number): string[] {
  const people = proposed.filter((s) => s.kind === "SOUL" && s.status === "ACTIVE");
  return people
    .filter((p) => {
      const before = new Set(chosenIntentions(current, p.id).map((s) => s.id));
      const after = chosenIntentions(proposed, p.id);
      return after.some((s) => !before.has(s.id)) && after.length > cap;
    })
    .map((p) => p.id);
}
