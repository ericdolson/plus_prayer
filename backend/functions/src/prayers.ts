// onPrayerLogged (OPERATIONS.md §D): the side effects of one committed
// prayer, applied EXACTLY ONCE (Prayer.countedAt claim inside the same
// statement as every increment — admin/prayers.gql ApplyPrayer).
//
//   always        DailyStats (UTC day of the prayer's end); peoplePraying via
//                 User.lastStatsDate
//   list prayer   the list's prayerCount / prayerSeconds — only while that
//                 list isn't settled and the prayer started before its
//                 closesAt (a settled list's numbers are final); streak +
//                 grace, or a streak repair when an older day syncs late
//   first prayer  starts the 14-day reverse trial (basePremiumPool)
//
// Aggregates are increment-on-write and never recounted from rows.

import { HttpsError } from "firebase-functions/v2/https";
import { getClientConfig } from "./clientConfig";
import { addDays, DAY_MS, utcDate } from "./dates";
import { mutate, query } from "./db";
import { Deps } from "./deps";
import { hasActiveEntitlement } from "./pool";
import { applyListDay, repairStreak, StreakState } from "./streak";

interface PrayerContext {
  prayer: {
    id: string;
    startedAt: string;
    prayedAt: string;
    durationSeconds: number;
    localDate: string;
    countedAt: string | null;
    communityList: { id: string; listNumber: number; closesAt: string | null; settledAt: string | null } | null;
    user: {
      id: string;
      includeLimit: number;
      trialStartedAt: string | null;
      entitlementExpiresAt: string | null;
      currentStreak: number;
      bestStreak: number;
      lastListLocalDate: string | null;
      lastStatsDate: string | null;
      graceDays: number;
      graceOfferPending: boolean;
      graceOffersEnabled: boolean;
    };
  } | null;
}

/** How far back a late-sync repair looks for list days. */
const REPAIR_LOOKBACK_DAYS = 366;

export type ProcessResult = "applied" | "already" | "missing";

export async function processPrayer(deps: Deps, prayerId: string): Promise<ProcessResult> {
  const rules = await getClientConfig(deps.live);
  for (let attempt = 0; attempt < 6; attempt++) {
    const ctx = await query<PrayerContext>(deps.db, "GetPrayerContext", { id: prayerId });
    const p = ctx.prayer;
    if (!p) return "missing";
    if (p.countedAt) return "already";
    const u = p.user;
    const now = deps.now();

    // A list's counters move until assembly settles it, and only for prayers
    // that started before its cutoff (later ones count toward the next list).
    const list = p.communityList;
    const listId = list && !list.settledAt && (!list.closesAt || Date.parse(p.startedAt) < Date.parse(list.closesAt))
      ? list.id
      : null;

    const statsDate = utcDate(new Date(p.prayedAt));
    const countPerson = u.lastStatsDate === null || u.lastStatsDate < statsDate;

    const was: StreakState = {
      currentStreak: u.currentStreak,
      bestStreak: u.bestStreak,
      lastListLocalDate: u.lastListLocalDate,
      graceDays: u.graceDays,
      graceOfferPending: u.graceOfferPending,
    };
    let next = was;
    if (list && was.lastListLocalDate !== null && p.localDate < was.lastListLocalDate) {
      // An older list day synced late: recompute the run from the list days
      // (this prayer included) with the grace currently held.
      const res = await query<{ days: { d: string }[] }>(deps.db, "GetUserListDays", {
        uid: u.id,
        from: addDays(was.lastListLocalDate, -REPAIR_LOOKBACK_DAYS),
        to: was.lastListLocalDate,
      });
      next = repairStreak(was, res.days.map((r) => r.d));
    } else if (list) {
      next = applyListDay(was, p.localDate, {
        graceCap: rules.graceCap,
        graceIntervalDays: rules.graceIntervalDays,
        graceOffersEnabled: u.graceOffersEnabled,
      });
    }

    // Reverse trial at the first prayer — unless an entitlement (e.g. bought
    // before praying) is already active.
    let trialStartedAt = u.trialStartedAt;
    let entitlementExpiresAt = u.entitlementExpiresAt;
    let includeLimit = u.includeLimit;
    if (trialStartedAt === null && !hasActiveEntitlement(u, now)) {
      trialStartedAt = now.toISOString();
      entitlementExpiresAt = new Date(now.getTime() + deps.cfg.trialDays * DAY_MS).toISOString();
      includeLimit = deps.cfg.basePremiumPool;
    }

    const res = await mutate<{ _execute: number }>(deps.db, "ApplyPrayer", {
      prayerId,
      listId,
      durationSeconds: p.durationSeconds,
      statsDate,
      peopleIncrement: countPerson ? 1 : 0,
      uid: u.id,
      ...next,
      lastStatsDate: countPerson ? statsDate : u.lastStatsDate,
      trialStartedAt,
      entitlementExpiresAt,
      includeLimit,
      wasCurrentStreak: was.currentStreak,
      wasBestStreak: was.bestStreak,
      wasLastListLocalDate: was.lastListLocalDate,
      wasGraceDays: was.graceDays,
      wasGraceOfferPending: was.graceOfferPending,
      wasLastStatsDate: u.lastStatsDate,
      wasTrialStartedAt: u.trialStartedAt,
      wasEntitlementExpiresAt: u.entitlementExpiresAt,
      wasIncludeLimit: u.includeLimit,
    });
    // 0 rows: counted meanwhile, or the user row moved — re-read and decide.
    if (res._execute !== 1) continue;

    if (list && listId) {
      const counts = await query<{ prayerList: { prayerCount: number } | null }>(deps.db, "GetListCount", { id: listId });
      if (counts.prayerList) {
        await deps.live.raiseCurrentListCount({ listId, listNumber: list.listNumber }, counts.prayerList.prayerCount);
      }
    }
    return "applied";
  }
  throw new Error(`processPrayer(${prayerId}): user state kept changing`);
}

/** Backstop for missed triggers: re-run the reaction for uncounted prayers. */
export async function sweepUncountedPrayers(deps: Deps, olderThanMs = 120_000): Promise<number> {
  const before = new Date(deps.now().getTime() - olderThanMs).toISOString();
  const res = await query<{ prayers: { id: string }[] }>(deps.db, "GetUncountedPrayers", { before });
  let applied = 0;
  for (const { id } of res.prayers) {
    if ((await processPrayer(deps, id)) === "applied") applied++;
  }
  return applied;
}

/** "Keep it" / "No thanks" / "Don't offer again" on a pending grace offer. */
export async function answerGraceOffer(
  deps: Deps,
  uid: string,
  answer: "accept" | "decline" | "never",
): Promise<{ graceDays: number }> {
  const rules = await getClientConfig(deps.live);
  const res = await query<{ user: { graceDays: number; graceOfferPending: boolean; graceOffersEnabled: boolean } | null }>(
    deps.db, "GetGraceState", { uid },
  );
  if (!res.user) throw new HttpsError("not-found", "Account not found");
  if (!res.user.graceOfferPending) throw new HttpsError("failed-precondition", "No grace day is being offered");
  const graceDays = answer === "accept" ? Math.min(res.user.graceDays + 1, rules.graceCap) : res.user.graceDays;
  const updated = await mutate<{ _execute: number }>(deps.db, "AnswerGraceOffer", {
    uid,
    graceDays,
    graceOffersEnabled: answer === "never" ? false : res.user.graceOffersEnabled,
  });
  if (updated._execute !== 1) throw new HttpsError("failed-precondition", "No grace day is being offered");
  return { graceDays };
}
