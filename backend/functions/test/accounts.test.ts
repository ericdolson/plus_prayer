// Self name + account merge.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import { ensureUser, mergeAccounts } from "../src/accounts";
import { assembleNextList, closeList, publishList } from "../src/lists";
import { processPrayer } from "../src/prayers";
import { setSelfName } from "../src/subjects";
import { addList, addSubjectRow, createUser, DAY, logPrayer, makeDeps, resetDb, sql } from "./helpers";

describe("setSelfName", () => {
  beforeEach(resetDb);

  it("creates exactly one self subject, even when called concurrently", async () => {
    const deps = makeDeps();
    await ensureUser(deps, "n1", "anonymous");
    await Promise.all([setSelfName(deps, "n1", "Ada"), setSelfName(deps, "n1", "Ada")]);
    const selves = await sql<{ public_name: string; personal_label: string; is_carried: boolean }>(
      "SELECT public_name, personal_label, is_carried FROM prayer_subject WHERE owner_id = $1 AND is_self", ["n1"],
    );
    assert.deepEqual(selves, [{ public_name: "Ada", personal_label: "Me", is_carried: true }]);
    const [u] = await sql<{ display_name: string }>(`SELECT display_name FROM "user" WHERE id = $1`, ["n1"]);
    assert.equal(u.display_name, "Ada");
  });

  it("is free to change until first printed, then once per 7 days", async () => {
    const deps = makeDeps();
    await createUser("n2", { name: "Bea" });
    await setSelfName(deps, "n2", "Beatrice");
    await setSelfName(deps, "n2", "Bee"); // still not printed → free

    // Print it: carried on a published list.
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await logPrayer("n2", { listId });
    await closeList(deps, 0);
    deps.clock.now = new Date(Date.now() + 1000);
    const next = await assembleNextList(deps, {});
    await publishList(deps, next.listId);

    await assert.rejects(setSelfName(deps, "n2", "B."), (err: HttpsError) => {
      assert.equal(err.code, "resource-exhausted");
      assert.ok((err.details as { nextChangeAvailableAt: string }).nextChangeAvailableAt);
      return true;
    });
    deps.clock.now = new Date(Date.now() + 8 * DAY);
    const ok = await setSelfName(deps, "n2", "B.");
    assert.ok(ok.nextChangeAvailableAt);
  });
});

describe("mergeAccounts", () => {
  beforeEach(resetDb);

  it("folds the anonymous account into the existing one", async () => {
    const deps = makeDeps();
    const target = await createUser("t", { name: "Tom" });
    const anon = await createUser("a", { name: "Tom" });
    const tName = await addSubjectRow("t", { name: "Kim", sortOrder: 1 });
    const aName = await addSubjectRow("a", { name: "Lou", sortOrder: 1 });
    const aMine = await addSubjectRow("a", { parentId: anon.selfId, name: "Me: calm", sortOrder: 1 });

    // Both selves printed on the same list; the anon also has an intention there.
    const list1 = await addList(1, { currentFrom: Date.now() - 2 * DAY });
    const p1 = await logPrayer("t", { listId: list1, localDate: "2026-10-01" });
    const p2 = await logPrayer("a", { listId: list1, localDate: "2026-10-02", subjectIds: [aMine] });
    await processPrayer(deps, p1);
    await processPrayer(deps, p2);
    await closeList(deps, 0);
    deps.clock.now = new Date(Date.now() + 1000);
    const list2 = await assembleNextList(deps, {});

    await mergeAccounts(deps, "t", "a:anonymous");

    const subjects = await sql<{ id: string; public_name: string; owner_id: string; parent_id: string | null; sort_order: number }>(
      "SELECT id, public_name, owner_id, parent_id, sort_order FROM prayer_subject ORDER BY public_name",
    );
    assert.ok(subjects.every((s) => s.owner_id === "t"));
    assert.equal(subjects.filter((s) => s.id === anon.selfId).length, 0, "anon self removed");
    const lou = subjects.find((s) => s.id === aName)!;
    assert.equal(lou.sort_order, 2, "appended after the target's names");
    assert.equal(subjects.find((s) => s.id === aMine)!.parent_id, target.selfId, "re-parented to the target self");
    assert.ok(subjects.find((s) => s.id === tName));

    const entries = await sql<{ subject_id: string; owner_id: string; parent_entry_id: string | null }>(
      "SELECT subject_id, owner_id, parent_entry_id FROM prayer_list_entry WHERE list_id = $1::uuid", [list2.listId],
    );
    const selfEntries = entries.filter((e) => e.subject_id === target.selfId);
    assert.equal(selfEntries.length, 1, "one self entry where both selves were on the list");
    assert.ok(entries.every((e) => e.owner_id === "t"));
    const calm = entries.find((e) => e.subject_id === aMine);
    assert.ok(calm, "the anon's intention stays on the list");
    const [selfEntry] = await sql<{ id: string }>(
      "SELECT id FROM prayer_list_entry WHERE list_id = $1::uuid AND subject_id = $2::uuid", [list2.listId, target.selfId],
    );
    assert.equal(calm!.parent_entry_id, selfEntry.id, "grouped under the surviving self entry");

    const prayers = await sql<{ user_id: string }>("SELECT user_id FROM prayer");
    assert.deepEqual(prayers.map((p) => p.user_id), ["t", "t"]);
    const links = await sql<{ subject_id: string }>("SELECT subject_id FROM prayer_subject_link WHERE prayer_id = $1::uuid", [p2]);
    assert.deepEqual(new Set(links.map((l) => l.subject_id)), new Set([aMine, target.selfId]));

    const [u] = await sql<{ current_streak: number; best_streak: number }>(
      `SELECT current_streak, best_streak FROM "user" WHERE id = 't'`,
    );
    assert.deepEqual(u, { current_streak: 2, best_streak: 2 }, "streak recomputed from merged list days");
    assert.equal((await sql(`SELECT id FROM "user" WHERE id = 'a'`)).length, 0);
    assert.deepEqual(deps.deletedAuthUsers, ["a"]);
  });

  it("only an anonymous account can be merged", async () => {
    const deps = makeDeps();
    await createUser("t");
    await createUser("g");
    await assert.rejects(mergeAccounts(deps, "t", "g:google.com"), /Only an anonymous account/);
  });
});
