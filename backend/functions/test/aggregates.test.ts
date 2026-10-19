// Increment-only aggregates (stats-history.md): PrayerList.prayerCount /
// prayerSeconds and DailyStats are incremented exactly once per prayer, only
// while a list is current (and before its cutoff), and never reduced by
// account deletion.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { deleteAccount } from "../src/accounts";
import { utcDate } from "../src/dates";
import { processPrayer, sweepUncountedPrayers } from "../src/prayers";
import { addList, createUser, DAY, HOUR, logPrayer, makeDeps, resetDb, sql } from "./helpers";

async function listCounts(id: string) {
  const [row] = await sql<{ prayer_count: number; prayer_seconds: number }>(
    "SELECT prayer_count, prayer_seconds FROM prayer_list WHERE id = $1::uuid", [id],
  );
  return row;
}

async function daily(date: string) {
  const [row] = await sql<{ prayers: number; prayer_seconds: number; people_praying: number }>(
    "SELECT prayers, prayer_seconds, people_praying FROM daily_stats WHERE date = $1::date", [date],
  );
  return row ?? { prayers: 0, prayer_seconds: 0, people_praying: 0 };
}

describe("increment-only aggregates", () => {
  beforeEach(resetDb);

  it("a prayer is counted exactly once, however often the reaction runs", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await deps.live.setCurrentList({ listId, listNumber: 1, prayerCount: 0, closesAt: null });
    await createUser("a1");
    const id = await logPrayer("a1", { listId, durationSeconds: 90 });

    assert.equal(await processPrayer(deps, id), "applied");
    assert.equal(await processPrayer(deps, id), "already");
    assert.equal(await sweepUncountedPrayers(deps, 0), 0);

    assert.deepEqual(await listCounts(listId), { prayer_count: 1, prayer_seconds: 90 });
    const today = utcDate(new Date());
    assert.deepEqual(await daily(today), { prayers: 1, prayer_seconds: 90, people_praying: 1 });
    assert.equal(deps.live.currentList?.prayerCount, 1, "mirrored to /lists/current");
  });

  it("concurrent reactions for the same prayer still count it once", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("a2");
    const id = await logPrayer("a2", { listId, durationSeconds: 30 });
    const results = await Promise.all([processPrayer(deps, id), processPrayer(deps, id), processPrayer(deps, id)]);
    assert.equal(results.filter((r) => r === "applied").length, 1);
    assert.deepEqual(await listCounts(listId), { prayer_count: 1, prayer_seconds: 30 });
  });

  it("peoplePraying counts each person once per UTC day; personal prayers count in DailyStats only", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("b1");
    await createUser("b2");
    for (const id of [
      await logPrayer("b1", { listId, durationSeconds: 10 }),
      await logPrayer("b1", { listId: null, durationSeconds: 20 }),
      await logPrayer("b2", { listId: null, durationSeconds: 30 }),
    ]) {
      await processPrayer(deps, id);
    }
    assert.deepEqual(await daily(utcDate(new Date())), { prayers: 3, prayer_seconds: 60, people_praying: 2 });
    assert.deepEqual(await listCounts(listId), { prayer_count: 1, prayer_seconds: 10 });
  });

  it("a settled list's numbers are final: late prayers for it don't move them", async () => {
    const deps = makeDeps();
    const closed = await addList(1, { currentFrom: Date.now() - 2 * DAY, closesAt: Date.now() - DAY, settled: true });
    await addList(2, { currentFrom: Date.now() - DAY });
    await createUser("c1");
    // Offline device still thought List 1 was current; syncs after the flip.
    const id = await logPrayer("c1", { listId: closed, startedAt: Date.now() - DAY - HOUR });
    assert.equal(await processPrayer(deps, id), "applied");
    assert.deepEqual(await listCounts(closed), { prayer_count: 0, prayer_seconds: 0 });
    assert.equal((await daily(utcDate(new Date(Date.now() - DAY - HOUR + 60_000)))).prayers, 1);
  });

  it("prayers started after the current list's closesAt don't count toward it", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - DAY, closesAt: Date.now() - 2 * 60_000 });
    await createUser("d1");
    const before = await logPrayer("d1", { listId, startedAt: Date.now() - 10 * 60_000, durationSeconds: 60 });
    const after = await logPrayer("d1", { listId, startedAt: Date.now() - 60_000, durationSeconds: 30 });
    await processPrayer(deps, before);
    await processPrayer(deps, after);
    assert.deepEqual(await listCounts(listId), { prayer_count: 1, prayer_seconds: 60 });
  });

  it("deleting an account removes its data but never reduces the aggregates", async () => {
    const deps = makeDeps();
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("e1");
    await createUser("e2");
    for (const id of [await logPrayer("e1", { listId, durationSeconds: 40 }), await logPrayer("e2", { listId, durationSeconds: 50 })]) {
      await processPrayer(deps, id);
    }
    const listBefore = await listCounts(listId);
    const dailyBefore = await daily(utcDate(new Date()));

    await deleteAccount(deps, "e1");

    assert.deepEqual(await listCounts(listId), listBefore);
    assert.deepEqual(await daily(utcDate(new Date())), dailyBefore);
    assert.equal((await sql("SELECT id FROM prayer WHERE user_id = $1", ["e1"])).length, 0);
    assert.equal((await sql(`SELECT id FROM "user" WHERE id = $1`, ["e1"])).length, 0);
    assert.deepEqual(deps.deletedAuthUsers, ["e1"]);
  });

  it("the first prayer starts the 14-day trial with the base premium pool", async () => {
    const deps = makeDeps();
    await createUser("f1");
    const id = await logPrayer("f1", { listId: null });
    await processPrayer(deps, id);
    const [u] = await sql<{ include_limit: number; days: number }>(
      `SELECT include_limit, round(extract(epoch FROM entitlement_expires_at - trial_started_at) / 86400)::int AS days
       FROM "user" WHERE id = $1`, ["f1"],
    );
    assert.deepEqual(u, { include_limit: 10, days: 14 });
  });
});
