// The carried pool (docs/product/monetization.md, subjects.md). Mirrors the
// rules assembleNextList applies in SQL (admin/lists.gql AssembleList), so a
// save the server accepts is exactly what the next list will print.

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
}

export interface Entitlement {
  includeLimit: number;
  entitlementExpiresAt: string | null;
}

export function hasActiveEntitlement(e: Entitlement, now: Date): boolean {
  return e.entitlementExpiresAt !== null && Date.parse(e.entitlementExpiresAt) > now.getTime();
}

/**
 * Effectively carried items beyond the self name: ACTIVE, unresolved, flagged
 * isCarried, and — for an intention — under an ACTIVE name that is itself
 * carried (or is the self).
 */
export function effectiveCarried(subjects: PoolSubject[]): PoolSubject[] {
  const byId = new Map(subjects.map((s) => [s.id, s]));
  return subjects.filter((s) => {
    if (s.isSelf || !s.isCarried || s.status !== "ACTIVE" || s.resolvedAt) return false;
    if (s.kind === "SOUL") return true;
    const parent = s.parent ? byId.get(s.parent.id) : undefined;
    return !!parent && parent.status === "ACTIVE" && (parent.isSelf || parent.isCarried);
  });
}

/** The free portion: at most `freeLimit` items, all intentions under "Me". */
export function fitsFree(carried: PoolSubject[], subjects: PoolSubject[], cfg: ServerConfig): boolean {
  const selfId = subjects.find((s) => s.isSelf)?.id;
  return (
    carried.length <= cfg.freeLimit &&
    carried.every((s) => s.kind === "INTENTION" && !!selfId && s.parent?.id === selfId)
  );
}

export interface PoolCheck {
  ok: boolean;
  carried: number;
  /** The limit the save is measured against (free → freeLimit). */
  limit: number;
  free: boolean;
}

/** Does this carried set fit the user's EFFECTIVE entitlement right now? */
export function checkPool(subjects: PoolSubject[], e: Entitlement, now: Date, cfg: ServerConfig): PoolCheck {
  const carried = effectiveCarried(subjects);
  if (hasActiveEntitlement(e, now)) {
    return { ok: carried.length <= e.includeLimit, carried: carried.length, limit: e.includeLimit, free: false };
  }
  return { ok: fitsFree(carried, subjects, cfg), carried: carried.length, limit: cfg.freeLimit, free: true };
}
