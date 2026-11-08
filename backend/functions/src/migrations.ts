// One-time data migrations, run through the admin CLI (never on deploy).
//
// Q32 (2026-11-08, docs/product/schema-brief.md "Pool counts people"): the
// pool counts people and each person prints with up to `intentionsPerPerson`
// chosen intentions. Beta data from the item model can hold more chosen per
// person; the first by sortOrder stay chosen. Free users who never had an
// entitlement move from the old free default (includeLimit 1) to 0.
// Idempotent: a second run changes nothing.

import { getClientConfig } from "./clientConfig";
import { mutate, query } from "./db";
import { Deps } from "./deps";

export interface Q32Overflow {
  /** Owners with at least one person over the cap. */
  owners: number;
  /** People (names, Me included) over the cap. */
  people: number;
  /** Chosen intentions the migration unchooses. */
  intentions: number;
  /** Free users still on the old default includeLimit 1. */
  freeDefaults: number;
}

export async function q32Overflow(deps: Deps, cap: number): Promise<Q32Overflow> {
  const res = await query<{
    overflow: { owners: number; people: number; intentions: number }[];
    freeDefaults: { users: number }[];
  }>(deps.db, "GetIntentionCapOverflow", { cap });
  const o = res.overflow[0] ?? { owners: 0, people: 0, intentions: 0 };
  return { owners: o.owners, people: o.people, intentions: o.intentions, freeDefaults: res.freeDefaults[0]?.users ?? 0 };
}

/** Dry run reports what would change; otherwise applies it and reports both. */
export async function migrateQ32(deps: Deps, opts: { dryRun?: boolean } = {}) {
  const { intentionsPerPerson: cap } = await getClientConfig(deps.live);
  const before = await q32Overflow(deps, cap);
  if (opts.dryRun) return { dryRun: true, intentionsPerPerson: cap, wouldChange: before };
  const unchosen = await mutate<{ _execute: number }>(deps.db, "EnforceIntentionCap", { cap, uid: null });
  const freeLimits = await mutate<{ _execute: number }>(deps.db, "MigrateFreeIncludeLimit", {});
  return {
    dryRun: false,
    intentionsPerPerson: cap,
    before,
    unchosenIntentions: unchosen._execute,
    freeIncludeLimitsReset: freeLimits._execute,
    after: await q32Overflow(deps, cap),
  };
}
