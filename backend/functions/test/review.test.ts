// The morning review diff (schema-brief §11): names and intentions that are
// new or changed since the last list they were on, incl. self-name changes.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { mutate } from "../src/db";
import { assembleNextList, closeList, getReviewDiff } from "../src/lists";
import { addList, addSubjectRow, adminDb, createUser, DAY, logPrayer, makeDeps, resetDb, TestDeps } from "./helpers";

/** Everyone prays for the current list, then close + assemble. */
async function nextList(deps: TestDeps, uids: string[], social: unknown[], listId: string, at: number) {
  for (const uid of uids) await logPrayer(uid, { listId, startedAt: at - 120_000 });
  deps.clock.now = new Date(at);
  const closed = await closeList(deps, 0);
  deps.clock.now = new Date(Date.parse(closed.closesAt) + 1000);
  const res = await assembleNextList(deps, { social });
  return { ...res, closesAt: Date.parse(closed.closesAt) };
}

describe("review diff", () => {
  beforeEach(resetDb);

  it("lists new and changed names and intentions only — not repeats or the base set", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("ann", { name: "Ann", includeLimit: 10, expiresInMs: 30 * DAY });
    await addSubjectRow("ann", { parentId: selfId, name: "Ann: steady work" });
    await mutate(adminDb, "UpsertBaseSetPerson", { externalId: "MP1", displayName: "Missing Child One", activeFrom: null, activeUntil: null });
    const list1 = await addList(1, { currentFrom: Date.now() - DAY });

    const first = await nextList(deps, ["ann"], [{ platform: "youtube", externalId: "j1", displayName: "Jane" }], list1, Date.now());
    // Everything on the first assembled list is new (no earlier list), except the base set.
    assert.deepEqual(
      first.review.map((r) => [r.publicName, r.change]).sort(),
      [["Ann", "NEW"], ["Ann: steady work", "NEW"], ["Jane", "NEW"]],
    );

    // Overnight: Ann renames herself and adds an intention; a new 🙏 arrives.
    await mutate(adminDb, "RenameSelf", { uid: "ann", name: "Ann Lee" });
    await addSubjectRow("ann", { parentId: selfId, name: "Ann: Mom's surgery", sortOrder: 2 });
    const second = await nextList(
      deps, ["ann"],
      [{ platform: "youtube", externalId: "j1", displayName: "Jane" }, { platform: "youtube", externalId: "b1", displayName: "Bob" }],
      first.listId, first.closesAt + 60_000,
    );

    const byName = Object.fromEntries(second.review.map((r) => [r.publicName, r]));
    assert.deepEqual(Object.keys(byName).sort(), ["Ann Lee", "Ann: Mom's surgery", "Bob"]);
    assert.deepEqual(
      [byName["Ann Lee"].change, byName["Ann Lee"].previousName, byName["Ann Lee"].isSelf],
      ["CHANGED", "Ann", true],
    );
    assert.deepEqual(
      [byName["Ann: Mom's surgery"].change, byName["Ann: Mom's surgery"].kind, byName["Ann: Mom's surgery"].parentName],
      ["NEW", "INTENTION", "Ann Lee"],
    );
    assert.equal(byName["Bob"].source, "SOCIAL");
    assert.deepEqual(await getReviewDiff(deps, second.listId), second.review, "the admin callable returns the same diff");
  });

  it("a name that skipped a day isn't 'new' when it returns unchanged", async () => {
    const deps = makeDeps();
    await createUser("sam", { name: "Sam" });
    await createUser("kay", { name: "Kay" });
    const list1 = await addList(1, { currentFrom: Date.now() - DAY });
    const first = await nextList(deps, ["sam", "kay"], [], list1, Date.now());
    const second = await nextList(deps, ["kay"], [], first.listId, first.closesAt + 60_000); // Sam skips
    const third = await nextList(deps, ["sam", "kay"], [], second.listId, second.closesAt + 60_000);
    assert.deepEqual(third.review, []);
  });
});
