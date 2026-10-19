// User streak + grace days (docs/product/streaks-reminders.md).
//
// A streak counts LOCAL days prayed WITH THE LIST. State is stored on User and
// advanced here only by a list prayer. Grace is consumed lazily: when the next
// list day arrives, the missed days in between use banked grace days if there
// are enough; otherwise the streak restarts (the bank is left as it was).
// A bridged day keeps the streak alive but doesn't add to it, so the stored
// streak counts real list days — which is also what earns grace offers.

import { daysBetween } from "./dates";

export interface StreakState {
  currentStreak: number;
  bestStreak: number;
  lastListLocalDate: string | null;
  graceDays: number;
  graceOfferPending: boolean;
}

export interface GraceRules {
  graceCap: number;
  graceIntervalDays: number;
  graceOffersEnabled: boolean;
}

/** Apply one list prayer on local date `day`. Pure. */
export function applyListDay(state: StreakState, day: string, rules: GraceRules): StreakState {
  const last = state.lastListLocalDate;
  // Same day again, or an older day synced late: the stored streak is
  // already past it.
  if (last !== null && daysBetween(last, day) <= 0) return { ...state };

  let { currentStreak, graceDays, graceOfferPending } = state;
  if (last === null) {
    currentStreak = 1;
  } else {
    const missed = daysBetween(last, day) - 1;
    if (missed === 0) {
      currentStreak += 1;
    } else if (missed <= graceDays) {
      graceDays -= missed;
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }
  }

  // Every N real list days: offer a grace day (never stacking), unless the
  // bank is full or the user said "Don't offer again". A full bank is
  // acknowledged by the app from the same numbers; nothing is stored.
  if (
    rules.graceOffersEnabled &&
    rules.graceIntervalDays > 0 &&
    currentStreak % rules.graceIntervalDays === 0 &&
    graceDays < rules.graceCap
  ) {
    graceOfferPending = true;
  }

  return {
    currentStreak,
    bestStreak: Math.max(state.bestStreak, currentStreak),
    lastListLocalDate: day,
    graceDays,
    graceOfferPending,
  };
}

/**
 * Streak recomputed from merged list days (mergeAccounts): the run of
 * consecutive days ending at the latest one. Grace history isn't recoverable,
 * so a stored streak that already ends on that same day is kept if longer.
 */
export function streakFromDays(sortedDays: string[]): number {
  if (sortedDays.length === 0) return 0;
  let run = 1;
  for (let i = sortedDays.length - 1; i > 0; i--) {
    if (daysBetween(sortedDays[i - 1], sortedDays[i]) === 1) run += 1;
    else break;
  }
  return run;
}
