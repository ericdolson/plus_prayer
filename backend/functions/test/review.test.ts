// The morning review diff (schema-brief §11): names and intentions that are
// new or changed since the last list they were on, incl. self-name changes.

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { mutate } from "../src/db";
import { assembleNextList, closeList, getListForPrint, getReviewDiff, moderateEntries } from "../src/lists";
import { addList, addSubjectRow, adminDb, createUser, DAY, logPrayer, makeDeps, resetDb, sql, TestDeps } from "./helpers";

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

describe("the morning skill's first pass (moderateEntries)", () => {
  beforeEach(resetDb);

  it("applies obvious calls, and leaves Eric only what it couldn't decide", async () => {
    const deps = makeDeps();
    await createUser("una", { name: "Una" });
    const list1 = await addList(1, { currentFrom: Date.now() - DAY });
    const res = await nextList(deps, ["una"], [
      { platform: "youtube", externalId: "a", displayName: "Grace Okafor" },
      { platform: "youtube", externalId: "b", displayName: "buy followers here" },
      { platform: "youtube", externalId: "c", displayName: "Xx_Shadow_xX" },
    ], list1, Date.now());
    const id = (name: string) => res.review.find((r) => r.publicName === name)!.entryId;

    const out = await moderateEntries(deps, {
      listId: res.listId,
      decisions: [
        { entryId: id("Una"), decision: "approve" },
        { entryId: id("Grace Okafor"), decision: "approve", note: "a person's name" },
        { entryId: id("buy followers here"), decision: "exclude", reasonCategory: "OTHER", note: "spam, not a name" },
        { entryId: id("Xx_Shadow_xX"), decision: "unsure", note: "a handle — could be how they go by" },
      ],
    });
    assert.deepEqual([out.updated, out.approved, out.excluded, out.unsure], [4, 2, 1, 1]);
    assert.deepEqual(
      (out.forEric as { publicName: string; heldReason: string }[]).map((e) => [e.publicName, e.heldReason]),
      [["Xx_Shadow_xX", "auto-review: a handle — could be how they go by"]],
      "only what it couldn't call reaches Eric, with its reason",
    );

    // Exception-based: the unsure one still prints if Eric does nothing; the excluded one doesn't.
    const printed = (await getListForPrint(deps, res.listId)) as { prayerListEntries: { publicName: string }[] };
    assert.deepEqual(printed.prayerListEntries.map((e) => e.publicName).sort(), ["Grace Okafor", "Una", "Xx_Shadow_xX"]);
    const [counts] = await sql<{ soul_count: number }>("SELECT soul_count FROM prayer_list WHERE id = $1::uuid", [res.listId]);
    assert.equal(counts.soul_count, 3);
  });

  it("validates decisions and only touches entries on the given list", async () => {
    const deps = makeDeps();
    await createUser("vic", { name: "Vic" });
    const list1 = await addList(1, { currentFrom: Date.now() - DAY });
    const res = await nextList(deps, ["vic"], [], list1, Date.now());
    const entryId = res.review[0].entryId;
    await assert.rejects(moderateEntries(deps, { listId: res.listId, decisions: [{ entryId, decision: "exclude", note: "x" }] }), /needs a reasonCategory/);
    await assert.rejects(moderateEntries(deps, { listId: res.listId, decisions: [{ entryId, decision: "unsure" }] }), /what's unclear/);
    await assert.rejects(moderateEntries(deps, { listId: res.listId, decisions: [{ entryId, decision: "approve" }, { entryId, decision: "approve" }] }), /duplicate/);
    const other = await moderateEntries(deps, { listId: list1, decisions: [{ entryId, decision: "exclude", reasonCategory: "OTHER", note: "wrong list" }] });
    assert.equal(other.updated, 0, "an entry on another list is never touched");
  });
});
