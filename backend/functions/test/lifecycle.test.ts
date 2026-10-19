// The cutoff (schema-brief §9.2): setting list N's closesAt creates list N+1
// right away (draft, currentFrom = closesAt). Prayers started before the
// cutoff count toward N until assembly settles it; later ones count toward
// N+1, which assembly then fills.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { assembleNextList, closeList } from "../src/lists";
import { processPrayer } from "../src/prayers";
import { addList, clientDb, createUser, DAY, impersonate, logPrayer, makeDeps, resetDb, sql } from "./helpers";

interface ListRow { id: string; list_number: number; status: string; current_from: string; closes_at: string | null; settled: boolean }

async function lists(): Promise<ListRow[]> {
  return sql<ListRow>(
    `SELECT id, list_number, status, to_char(current_from AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS') AS current_from,
       to_char(closes_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS') AS closes_at, settled_at IS NOT NULL AS settled
     FROM prayer_list ORDER BY list_number`,
  );
}

async function counts(id: string) {
  const [r] = await sql<{ prayer_count: number; prayer_seconds: number }>(
    "SELECT prayer_count, prayer_seconds FROM prayer_list WHERE id = $1::uuid", [id],
  );
  return r;
}

async function currentListNumber(uid: string): Promise<number> {
  const res = await clientDb.executeQuery<{ prayerLists: { listNumber: number }[] }, Record<string, never>>(
    "GetCurrentListMeta", {}, impersonate(uid),
  );
  return res.data.prayerLists[0].listNumber;
}

describe("N+1 is created at closesAt", () => {
  beforeEach(resetDb);

  it("creates N+1 as a draft current from the cutoff; re-closing before the cutoff moves both", async () => {
    const deps = makeDeps();
    await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("v");

    const first = await closeList(deps, 5);
    let [n, next] = await lists();
    assert.equal(next.list_number, 2);
    assert.equal(next.status, "draft");
    assert.equal(next.current_from, first.closesAt.slice(0, 23));
    assert.equal(n.closes_at, first.closesAt.slice(0, 23));
    assert.equal(first.nextListId, next.id);
    assert.equal(await currentListNumber("v"), 1, "N+1 isn't current before the cutoff");

    const again = await closeList(deps, 10);
    const rows = await lists();
    assert.equal(rows.length, 2, "no second N+1");
    [n, next] = rows;
    assert.equal(n.closes_at, again.closesAt.slice(0, 23));
    assert.equal(next.current_from, again.closesAt.slice(0, 23));
    assert.equal(again.nextListId, first.nextListId);
  });

  it("after the cutoff: N+1 is current and counts later prayers; N keeps earlier ones until assembly settles it", async () => {
    const deps = makeDeps();
    const n = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("early");
    await createUser("late");

    // Started before the cutoff, committed after it (still before assembly).
    const earlyStart = Date.now() - 2 * 60_000;
    const closed = await closeList(deps, 0);
    const next = closed.nextListId!;
    assert.equal(await currentListNumber("late"), 2, "N+1 is current from the cutoff");
    const early = await logPrayer("early", { listId: n, startedAt: earlyStart, durationSeconds: 60 });
    const late = await logPrayer("late", { listId: next, startedAt: Date.parse(closed.closesAt) + 1000, durationSeconds: 30 });

    await processPrayer(deps, early);
    await processPrayer(deps, late);
    assert.deepEqual(await counts(n), { prayer_count: 1, prayer_seconds: 60 });
    assert.deepEqual(await counts(next), { prayer_count: 1, prayer_seconds: 30 });
    assert.equal(deps.live.currentList?.listNumber, 2, "the live mirror moved to N+1 with its first prayer");

    deps.clock.now = new Date(Date.now() + 1000);
    const res = await assembleNextList(deps, {});
    assert.equal(res.listId, next, "assembly fills the N+1 created at the cutoff");
    assert.equal((await lists()).length, 2);
    const owners = await sql<{ owner_id: string }>(
      "SELECT owner_id FROM prayer_list_entry WHERE list_id = $1::uuid ORDER BY owner_id", [next],
    );
    assert.deepEqual(owners.map((o) => o.owner_id), ["early"], "late prayed for N+1, so it earns N+2, not N+1");
    assert.deepEqual(deps.live.currentList, { listId: next, listNumber: 2, prayerCount: 1, closesAt: null });

    // N is settled now: a late offline prayer for it changes nothing.
    const [settled] = (await lists()).filter((l) => l.list_number === 1);
    assert.equal(settled.settled, true);
    const offline = await logPrayer("early", { listId: n, startedAt: earlyStart + 1000, durationSeconds: 45 });
    assert.equal(await processPrayer(deps, offline), "applied");
    assert.deepEqual(await counts(n), { prayer_count: 1, prayer_seconds: 60 });
  });

  it("refuses to re-close a list whose cutoff has passed", async () => {
    const deps = makeDeps();
    await addList(1, { currentFrom: Date.now() - DAY });
    await closeList(deps, 0);
    deps.clock.now = new Date(Date.now() + 1000);
    await assert.rejects(closeList(deps, 5), /run assembleNextList/);
  });
});

describe("one prayer earns exactly one list (schema-brief §10)", () => {
  beforeEach(resetDb);

  it("a prayer after N's cutoff is carried on N+2 only — never on N+1 too", async () => {
    const deps = makeDeps();
    const n = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("one");

    const closedN = await closeList(deps, 0);
    const next = closedN.nextListId!;
    const cutoff = Date.parse(closedN.closesAt);
    // The only prayer: for N+1, right after N's cutoff (well within 30h of it).
    const id = await logPrayer("one", { listId: next, startedAt: cutoff + 1000, durationSeconds: 20 });
    await processPrayer(deps, id);

    deps.clock.now = new Date(cutoff + 2000);
    await assembleNextList(deps, {}); // fills N+1
    deps.clock.now = new Date(cutoff + 60_000);
    const closedNext = await closeList(deps, 0); // N+1's cutoff, after the prayer started
    deps.clock.now = new Date(Date.parse(closedNext.closesAt) + 1000);
    const n2 = await assembleNextList(deps, {}); // fills N+2

    const carried = await sql<{ list_number: number }>(
      `SELECT l.list_number FROM prayer_list_entry e JOIN prayer_list l ON l.id = e.list_id
       WHERE e.owner_id = $1 ORDER BY l.list_number`, ["one"],
    );
    assert.deepEqual(carried.map((c) => c.list_number), [3], "carried once, on N+2");
    assert.equal(n2.listNumber, 3);
    assert.deepEqual(await counts(next), { prayer_count: 1, prayer_seconds: 20 }, "and it counted toward N+1");
    assert.deepEqual(await counts(n), { prayer_count: 0, prayer_seconds: 0 });
  });
});
