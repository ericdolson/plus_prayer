// The list gate (list-lifecycle.md, schema-brief §6): at assembly a user is
// carried if they have a prayer that included the list and either
//   (a) its communityList is the closing list and it started before closesAt, or
//   (b) it ended within the last 30h.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { assembleNextList, closeList } from "../src/lists";
import { addList, createUser, DAY, HOUR, logPrayer, makeDeps, resetDb, sql } from "./helpers";

async function carriedOwners(listId: string): Promise<string[]> {
  const rows = await sql<{ owner_id: string }>(
    "SELECT owner_id FROM prayer_list_entry WHERE list_id = $1::uuid AND owner_id IS NOT NULL ORDER BY owner_id",
    [listId],
  );
  return rows.map((r) => r.owner_id);
}

describe("list gate", () => {
  beforeEach(resetDb);

  it("carries (a) prayers for the closing list started before closesAt and (b) list prayers ended within 30h", async () => {
    const deps = makeDeps();
    const older = await addList(1, { currentFrom: Date.now() - 4 * DAY, closesAt: Date.now() - 3 * DAY });
    const closing = await addList(2, { currentFrom: Date.now() - 3 * DAY });
    for (const uid of ["a", "b", "c", "d", "e", "f"]) await createUser(uid);

    // a: prayed for List 2 long ago (> 30h) — still before its cutoff → (a)
    await logPrayer("a", { listId: closing, startedAt: Date.now() - 2 * DAY });
    // b: prayed with the list 10h ago → both (a) and (b)
    await logPrayer("b", { listId: closing, startedAt: Date.now() - 10 * HOUR });
    // c: personal prayer only (no list) → not carried
    await logPrayer("c", { listId: null, startedAt: Date.now() - HOUR });
    // d: a list prayer for List 1 that ended 31h ago → neither rule
    await logPrayer("d", { listId: older, startedAt: Date.now() - 31 * HOUR - 120_000 });
    // e: a stale client logged List 1 two hours ago → (b), the list was included
    await logPrayer("e", { listId: older, startedAt: Date.now() - 2 * HOUR });

    const closed = await closeList(deps, 0); // cutoff = now
    deps.clock.now = new Date(Date.parse(closed.closesAt) + 1000);
    // f: started after the cutoff, before assembly → not (a); (b) carries it
    await logPrayer("f", { listId: closing, startedAt: Date.parse(closed.closesAt) + 200, durationSeconds: 5 });

    const res = await assembleNextList(deps, {});
    assert.equal(res.listNumber, 3);
    assert.deepEqual(await carriedOwners(res.listId), ["a", "b", "e", "f"]);
  });

  it("praying every other day is not enough (a two-day-old list prayer for an older list)", async () => {
    const deps = makeDeps();
    const older = await addList(1, { currentFrom: Date.now() - 3 * DAY, closesAt: Date.now() - DAY });
    await addList(2, { currentFrom: Date.now() - DAY });
    await createUser("g");
    await logPrayer("g", { listId: older, startedAt: Date.now() - 2 * DAY + HOUR });
    await closeList(deps, 0);
    deps.clock.now = new Date(Date.now() + 1000);
    const res = await assembleNextList(deps, {});
    assert.deepEqual(await carriedOwners(res.listId), []);
  });

  it("refuses to assemble before the cutoff, and opens N+1 current from N's closesAt", async () => {
    const deps = makeDeps();
    await addList(1, { currentFrom: Date.now() - DAY });
    await assert.rejects(assembleNextList(deps, {}), /closeList/);

    const closed = await closeList(deps, 5);
    await assert.rejects(assembleNextList(deps, {}), /closes at/);
    assert.equal(deps.live.currentList?.closesAt, Date.parse(closed.closesAt), "closesAt mirrored for the banner");

    deps.clock.now = new Date(Date.parse(closed.closesAt) + 1000);
    const res = await assembleNextList(deps, {});
    const [row] = await sql<{ current_from: string; status: string }>(
      "SELECT to_char(current_from AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS') AS current_from, status FROM prayer_list WHERE id = $1::uuid",
      [res.listId],
    );
    assert.equal(row.current_from, closed.closesAt.slice(0, 19));
    assert.equal(row.status, "draft");
    assert.deepEqual(deps.live.currentList, { listId: res.listId, listNumber: 2, prayerCount: 0, closesAt: null });
    await assert.rejects(assembleNextList(deps, {}), /closeList/, "List 2 is now current and not closed");
  });
});
