// Streak + grace rules (streaks-reminders.md). Pure — no emulator needed —
// plus one end-to-end case through onPrayerLogged.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { processPrayer } from "../src/prayers";
import { applyListDay, StreakState, streakFromDays } from "../src/streak";
import { addList, createUser, DAY, logPrayer, makeDeps, resetDb, sql } from "./helpers";

const rules = { graceCap: 2, graceIntervalDays: 7, graceOffersEnabled: true };
const fresh: StreakState = { currentStreak: 0, bestStreak: 0, lastListLocalDate: null, graceDays: 0, graceOfferPending: false };

function run(days: string[], start: StreakState = fresh, r = rules): StreakState {
  return days.reduce((s, d) => applyListDay(s, d, r), start);
}

describe("streak: local days prayed with the list", () => {
  it("starts at 1 and counts consecutive days", () => {
    const s = run(["2026-10-01", "2026-10-02", "2026-10-03"]);
    assert.equal(s.currentStreak, 3);
    assert.equal(s.bestStreak, 3);
    assert.equal(s.lastListLocalDate, "2026-10-03");
  });

  it("a second list prayer the same day changes nothing", () => {
    const s = run(["2026-10-01", "2026-10-01"]);
    assert.equal(s.currentStreak, 1);
  });

  it("an older day synced late does not move the streak", () => {
    const s = run(["2026-10-01", "2026-10-02", "2026-09-30"]);
    assert.deepEqual(s, run(["2026-10-01", "2026-10-02"]));
  });

  it("a missed day restarts the streak when no grace is banked; best stays", () => {
    const s = run(["2026-10-01", "2026-10-02", "2026-10-04"]);
    assert.equal(s.currentStreak, 1);
    assert.equal(s.bestStreak, 2);
  });
});

describe("grace days: lazy use at the next list prayer", () => {
  it("bridges missed days ≤ bank; a bridged day keeps the streak but doesn't add", () => {
    const s = run(["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-05"], { ...fresh, graceDays: 1 });
    assert.equal(s.currentStreak, 4); // 3 real days + the 5th; the 4th was bridged
    assert.equal(s.graceDays, 0);
  });

  it("two missed days use two grace days", () => {
    const s = run(["2026-10-01", "2026-10-04"], { ...fresh, graceDays: 2 });
    assert.equal(s.currentStreak, 2);
    assert.equal(s.graceDays, 0);
  });

  it("misses beyond the bank break the streak and leave the bank unchanged", () => {
    const s = run(["2026-10-01", "2026-10-02", "2026-10-06"], { ...fresh, graceDays: 2 });
    assert.equal(s.currentStreak, 1);
    assert.equal(s.graceDays, 2);
  });
});

describe("grace offers: every 7 real list days", () => {
  const week = Array.from({ length: 7 }, (_, i) => `2026-10-${String(i + 1).padStart(2, "0")}`);

  it("offers on day 7, not before", () => {
    assert.equal(run(week.slice(0, 6)).graceOfferPending, false);
    assert.equal(run(week).graceOfferPending, true);
  });

  it("does not offer when the bank is full", () => {
    assert.equal(run(week, { ...fresh, graceDays: 2 }).graceOfferPending, false);
  });

  it("does not offer after 'Don't offer again'", () => {
    assert.equal(run(week, fresh, { ...rules, graceOffersEnabled: false }).graceOfferPending, false);
  });

  it("an unanswered offer stays pending; offers don't stack", () => {
    const fourteen = Array.from({ length: 14 }, (_, i) => `2026-10-${String(i + 1).padStart(2, "0")}`);
    const s = run(fourteen);
    assert.equal(s.graceOfferPending, true);
    assert.equal(s.graceDays, 0);
  });

  it("bridged days don't count toward the next offer", () => {
    // 6 real days, 1 bridged, 1 real → 7 real days: offer on that day.
    const days = ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04", "2026-10-05", "2026-10-06", "2026-10-08"];
    const s = run(days, { ...fresh, graceDays: 1 });
    assert.equal(s.currentStreak, 7);
    assert.equal(s.graceDays, 0);
    assert.equal(s.graceOfferPending, true);
  });
});

describe("streakFromDays (account merge)", () => {
  it("counts the run ending at the latest day", () => {
    assert.equal(streakFromDays([]), 0);
    assert.equal(streakFromDays(["2026-10-01", "2026-10-03", "2026-10-04", "2026-10-05"]), 3);
  });
});

describe("streak end-to-end via onPrayerLogged", () => {
  beforeEach(resetDb);

  it("only prayers with the list extend the stored streak", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - 3 * DAY, status: "published" });
    await createUser("s1");

    const d1 = await logPrayer("s1", { listId, localDate: "2026-10-01" });
    const personal = await logPrayer("s1", { listId: null, localDate: "2026-10-02" });
    const d3 = await logPrayer("s1", { listId, localDate: "2026-10-03" });
    for (const id of [d1, personal, d3]) await processPrayer(deps, id);

    const [u] = await sql<{ current_streak: number; best_streak: number; last: string }>(
      `SELECT current_streak, best_streak, to_char(last_list_local_date, 'YYYY-MM-DD') AS last FROM "user" WHERE id = $1`,
      ["s1"],
    );
    // The personal day doesn't bridge: 10-02 had no list prayer → restart.
    assert.equal(u.current_streak, 1);
    assert.equal(u.best_streak, 1);
    assert.equal(u.last, "2026-10-03");
  });
});
