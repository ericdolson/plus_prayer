// Deterministic UUIDs (v4 layout, sha256-derived) for rows that must be
// created at most once without a database uniqueness constraint to lean on.

import { createHash } from "node:crypto";

export function stableUuid(...parts: (string | number)[]): string {
  const h = createHash("sha256").update(parts.join("/")).digest("hex");
  const variant = ((parseInt(h[16], 16) & 3) | 8).toString(16);
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-${variant}${h.slice(17, 20)}-${h.slice(20, 32)}`;
}

/** The self subject's id: one per user, so concurrent setSelfName calls converge. */
export const selfSubjectId = (uid: string) => stableUuid("self", uid);

/** A draft auto-saved without a client prayer id: stable across job re-runs. */
export const draftPrayerId = (uid: string, deviceId: string, startedAt: number) =>
  stableUuid("draft", uid, deviceId, startedAt);

/** SQL Connect returns UUIDs as 32 hex digits; use that form everywhere ids
 *  leave the database (RTDB /lists/current, comparisons). */
export const normId = (id: string) => id.replace(/-/g, "").toLowerCase();
