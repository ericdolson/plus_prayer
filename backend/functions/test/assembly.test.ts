// Assembly + the carried pool (monetization.md, subjects.md, list-lifecycle.md).

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import { mutate } from "../src/db";
import { assembleNextList, closeList, getListForPrint, listLiveCopy, moderateEntry, publishList, publishListVideo } from "../src/lists";
import { addSubject, restoreSubject, setCarriedItems } from "../src/subjects";
import { processPrayer } from "../src/prayers";
import { resetClientConfigCache } from "../src/clientConfig";
import {
  addList, addSubjectRow, adminDb, clientDb, createUser, DAY, exec, impersonate, logPrayer, makeDeps, resetDb, sql, TestDeps,
} from "./helpers";

interface EntryRow {
  public_name: string;
  kind: string;
  source: string;
  moderation_status: string;
  reason_category: string | null;
  parent_name: string | null;
}

async function entries(listId: string, ownerId?: string): Promise<EntryRow[]> {
  return sql<EntryRow>(
    `SELECT e.public_name, e.kind::text AS kind, e.source::text AS source,
       e.moderation_status::text AS moderation_status, e.reason_category::text AS reason_category,
       p.public_name AS parent_name
     FROM prayer_list_entry e LEFT JOIN prayer_list_entry p ON p.id = e.parent_entry_id
     WHERE e.list_id = $1::uuid AND ($2::text IS NULL OR e.owner_id = $2)
     ORDER BY e.public_name`,
    [listId, ownerId ?? null],
  );
}
const names = (rows: EntryRow[]) => rows.map((r) => r.public_name);

/** A current list everyone prayed for, then close + assemble. */
async function setupAndAssemble(deps: TestDeps, users: string[], social?: unknown) {
  const listId = await addList(1, { currentFrom: Date.now() - DAY });
  for (const uid of users) await logPrayer(uid, { listId });
  await closeList(deps, 0);
  deps.clock.now = new Date(Date.now() + 1000);
  return assembleNextList(deps, { social });
}

describe("assembly: each user's portion", () => {
  beforeEach(resetDb);

  it("premium (Q32): the pool counts people; each prints with its first chosen intention", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("p", { name: "Pat", includeLimit: 2, expiresInMs: 30 * DAY });
    await addSubjectRow("p", { parentId: selfId, name: "Me: steady work", sortOrder: 1 });
    await addSubjectRow("p", { parentId: selfId, name: "Me: patience", sortOrder: 2 }); // over the cap (old data)
    const a = await addSubjectRow("p", { name: "Ann", sortOrder: 1 });
    await addSubjectRow("p", { parentId: a, name: "Ann: rest", sortOrder: 2 }); // over the cap: second by sortOrder
    await addSubjectRow("p", { parentId: a, name: "Ann: healing", sortOrder: 1 });
    await addSubjectRow("p", { parentId: a, name: "Ann: job", sortOrder: 3, carried: false }); // not chosen
    await addSubjectRow("p", { name: "Bo", sortOrder: 2 }); // 2nd person: intentions cost nothing, so Bo fits
    await addSubjectRow("p", { name: "Dee", sortOrder: 4 }); // 3rd person — over the limit
    const c = await addSubjectRow("p", { name: "Cy (not carried)", sortOrder: 3, carried: false });
    await addSubjectRow("p", { parentId: c, name: "Cy: job", sortOrder: 1 }); // chosen, but Cy isn't carried

    const res = await setupAndAssemble(deps, ["p"]);
    const rows = await entries(res.listId, "p");
    assert.deepEqual(names(rows), ["Ann", "Ann: healing", "Bo", "Me: steady work", "Pat"]);
    assert.equal(rows.find((r) => r.public_name === "Ann: healing")?.parent_name, "Ann");
    assert.equal(rows.find((r) => r.public_name === "Me: steady work")?.parent_name, "Pat");
    assert.equal(res.soulCount, 3);
    assert.equal(res.intentionCount, 2, "no \"and N more\": only chosen intentions print");
  });

  it("the cap comes from /config intentionsPerPerson", async () => {
    const deps = makeDeps();
    deps.live.config = { intentionsPerPerson: 2 };
    const { selfId } = await createUser("p2", { name: "Pia" });
    await addSubjectRow("p2", { parentId: selfId, name: "Me: one", sortOrder: 1 });
    await addSubjectRow("p2", { parentId: selfId, name: "Me: two", sortOrder: 2 });
    await addSubjectRow("p2", { parentId: selfId, name: "Me: three", sortOrder: 3 });
    const res = await setupAndAssemble(deps, ["p2"]);
    assert.deepEqual(names(await entries(res.listId, "p2")), ["Me: one", "Me: two", "Pia"]);
  });

  it("resolved and archived items are never carried and don't use the pool", async () => {
    const deps = makeDeps();
    await createUser("q", { name: "Quinn", includeLimit: 2, expiresInMs: 30 * DAY });
    const dee = await addSubjectRow("q", { name: "Dee", sortOrder: 1 });
    const answered = await addSubjectRow("q", { parentId: dee, name: "Dee: answered", sortOrder: 1 });
    const archived = await addSubjectRow("q", { name: "Archived one", sortOrder: 2 });
    await addSubjectRow("q", { name: "Eli", sortOrder: 3 });
    await clientDb.executeMutation("MarkIntentionAnswered", { id: answered }, impersonate("q"));
    await clientDb.executeMutation("ArchiveSubject", { id: archived }, impersonate("q"));

    const res = await setupAndAssemble(deps, ["q"]);
    assert.deepEqual(names(await entries(res.listId, "q")), ["Dee", "Eli", "Quinn"]);
  });

  it("free (0 people): you, with your intention", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("f", { name: "Fay", trialEnded: true });
    await addSubjectRow("f", { parentId: selfId, name: "Fay: courage", sortOrder: 1 });
    await addSubjectRow("f", { parentId: selfId, name: "Fay: rest", sortOrder: 2 }); // over the cap (old data)
    const res = await setupAndAssemble(deps, ["f"]);
    assert.deepEqual(names(await entries(res.listId, "f")), ["Fay", "Fay: courage"]);
  });

  it("free after the trial and over the free limit (a carried name): you, with your intention", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("g", { name: "Gus", trialEnded: true });
    await addSubjectRow("g", { name: "Mom" });
    await addSubjectRow("g", { parentId: selfId, name: "Gus: work" });
    const res = await setupAndAssemble(deps, ["g"]);
    assert.deepEqual(names(await entries(res.listId, "g")), ["Gus", "Gus: work"]);
  });

  it("soft landing: ≤7 days after an entitlement ends the full portion stays; after that, you with your intention", async () => {
    const deps = makeDeps();
    await createUser("s", { name: "Sol", includeLimit: 10, expiresInMs: -2 * DAY });
    await addSubjectRow("s", { name: "Tia", sortOrder: 1 });
    await addSubjectRow("s", { name: "Uma", sortOrder: 2 });
    const { selfId: tedSelf } = await createUser("t", { name: "Ted", includeLimit: 10, expiresInMs: -8 * DAY });
    const val = await addSubjectRow("t", { name: "Val", sortOrder: 1 });
    await addSubjectRow("t", { parentId: val, name: "Val: rest", sortOrder: 1 });
    await addSubjectRow("t", { parentId: tedSelf, name: "Ted: patience", sortOrder: 1 });
    const res = await setupAndAssemble(deps, ["s", "t"]);
    assert.deepEqual(names(await entries(res.listId, "s")), ["Sol", "Tia", "Uma"]);
    assert.deepEqual(names(await entries(res.listId, "t")), ["Ted", "Ted: patience"],
      "past the soft landing: still over the free pool, so no other names — but your intention is free (Q32)");
  });

  it("an intention under an archived name is not carried", async () => {
    const deps = makeDeps();
    await createUser("h", { name: "Hal", includeLimit: 5, expiresInMs: 30 * DAY });
    const n = await addSubjectRow("h", { name: "Ivy" });
    await addSubjectRow("h", { parentId: n, name: "Ivy: peace" });
    await clientDb.executeMutation("ArchiveSubject", { id: n }, impersonate("h"));
    const res = await setupAndAssemble(deps, ["h"]);
    assert.deepEqual(names(await entries(res.listId, "h")), ["Hal"]);
  });
});

describe("assembly: names from outside the app, flags, counts", () => {
  beforeEach(resetDb);

  it("adds the 🙏 harvest and the active base set; excludes contact info; held items still print", async () => {
    const deps = makeDeps({ wordBlocklistEnabled: true });
    deps.live.blocklist = ["darn"]; // the editable RTDB list overrides the bundled seed
    await createUser("u", { name: "Una" });
    await mutate(adminDb, "UpsertBaseSetPerson", { externalId: "MP1", displayName: "Missing Child One", activeFrom: null, activeUntil: null });
    await mutate(adminDb, "UpsertBaseSetPerson", {
      externalId: "MP2", displayName: "Found Child", activeFrom: null, activeUntil: new Date(Date.now() - DAY).toISOString(),
    });
    const res = await setupAndAssemble(deps, ["u"], [
      { platform: "YouTube", externalId: "yt1", displayName: "Jane Doe" },
      { platform: "youtube", externalId: "yt1", displayName: "Jane Doe" }, // duplicate → once
      { platform: "instagram", externalId: "ig1", displayName: "darn it" },
      { platform: "threads", externalId: "th1", displayName: "see www.example.com" },
      { platform: "facebook", externalId: "fb1", displayName: "Call me 555-123-4567" },
      { platform: "facebook", externalId: "fb2", displayName: "Ruth (John 3:16)" },
    ]);

    const rows = await entries(res.listId);
    const by = Object.fromEntries(rows.map((r) => [r.public_name, r]));
    assert.deepEqual(names(rows), [
      "Call me 555-123-4567", "Jane Doe", "Missing Child One", "Ruth (John 3:16)", "Una", "darn it", "see www.example.com",
    ]);
    assert.equal(by["Jane Doe"].source, "SOCIAL");
    assert.equal(by["Jane Doe"].moderation_status, "APPROVED");
    assert.equal(by["Missing Child One"].source, "BASE_SET");
    assert.equal(by["Ruth (John 3:16)"].moderation_status, "APPROVED", "a verse reference isn't contact info");
    for (const n of ["see www.example.com", "Call me 555-123-4567"]) {
      assert.deepEqual([by[n].moderation_status, by[n].reason_category], ["EXCLUDED", "CONTACT_OR_LINK"], n);
    }
    assert.deepEqual([by["darn it"].moderation_status, by["darn it"].reason_category], ["HELD", "LANGUAGE"]);
    assert.equal(res.held, 1);
    assert.equal(res.soulCount, 5, "everything not EXCLUDED counts — HELD prints");

    // Eric doesn't touch the held one: it still prints after publish.
    const pub = await publishList(deps, res.listId);
    assert.equal(pub.sealVariant, new Date(`${(await sql<{ d: string }>("SELECT to_char(list_date, 'YYYY-MM-DD') AS d FROM prayer_list WHERE id = $1::uuid", [res.listId]))[0].d}T12:00:00Z`).getUTCDay());
    const printed = (await getListForPrint(deps, res.listId)) as { prayerListEntries: { publicName: string }[] };
    assert.ok(printed.prayerListEntries.some((e) => e.publicName === "darn it"), "HELD prints unless excluded");
    assert.ok(!printed.prayerListEntries.some((e) => e.publicName === "see www.example.com"));
    const [counts] = await sql<{ soul_count: number }>("SELECT soul_count FROM prayer_list WHERE id = $1::uuid", [res.listId]);
    assert.equal(counts.soul_count, 5);

    // He excludes it after all → it stops printing and leaves the count.
    const [darn] = await sql<{ id: string }>("SELECT id FROM prayer_list_entry WHERE public_name = 'darn it'");
    await moderateEntry(deps, { entryId: darn.id, status: "EXCLUDED", reasonCategory: "LANGUAGE" });
    const [after] = await sql<{ soul_count: number }>("SELECT soul_count FROM prayer_list WHERE id = $1::uuid", [res.listId]);
    assert.equal(after.soul_count, 4);
  });

  it("two assemblies at once: one settles N and fills N+1, the other writes nothing", async () => {
    const deps = makeDeps();
    await createUser("w");
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await logPrayer("w", { listId });
    await closeList(deps, 0);
    const later = (ms: number) => ({ ...deps, now: () => new Date(Date.now() + ms) });
    const results = await Promise.allSettled([assembleNextList(later(1000), {}), assembleNextList(later(1001), {})]);
    assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
    const failed = results.find((r) => r.status === "rejected") as PromiseRejectedResult;
    assert.match(String(failed.reason), /already assembled/);
    assert.equal((await sql("SELECT id FROM prayer_list_entry")).length, 1, "no duplicate entries");
  });
});

describe("the pool on the server (addSubject / setCarriedItems)", () => {
  beforeEach(resetDb);

  it("auto-carries while there is room, then saves for private prayer", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("x", { includeLimit: 1, expiresInMs: 30 * DAY });
    // Intentions cost no place (Q32).
    await addSubject(deps, "x", { kind: "INTENTION", parentId: selfId, publicName: "Me: rest" });
    const first = await addSubject(deps, "x", { kind: "SOUL", publicName: "Abe" });
    const second = await addSubject(deps, "x", { kind: "SOUL", publicName: "Bea" });
    assert.equal(first.isCarried, true);
    assert.equal(second.isCarried, false);
    assert.equal(second.sortOrder, first.sortOrder + 1, "new items go to the bottom");
  });

  it("blocks an over-limit save with the meter numbers — never trims silently", async () => {
    const deps = makeDeps();
    await createUser("y", { includeLimit: 1, expiresInMs: 30 * DAY });
    const a = await addSubjectRow("y", { name: "Cal", carried: false });
    const b = await addSubjectRow("y", { name: "Dot", carried: false });
    await assert.rejects(setCarriedItems(deps, "y", [a, b]), (err: HttpsError) => {
      assert.equal(err.code, "failed-precondition");
      assert.deepEqual(err.details, { reason: "OVER_LIMIT", carried: 2, limit: 1, free: false });
      return true;
    });
    assert.deepEqual(await setCarriedItems(deps, "y", [b]), { carried: 1, limit: 1 });
    const carried = await sql<{ public_name: string }>("SELECT public_name FROM prayer_subject WHERE owner_id = $1 AND is_carried AND NOT is_self", ["y"]);
    assert.deepEqual(carried.map((r) => r.public_name), ["Dot"]);
  });

  it("over the pool (a lapsed trial): uncarrying is always accepted; adding is still blocked", async () => {
    const deps = makeDeps();
    await createUser("lapsed", { includeLimit: 10, expiresInMs: -DAY }); // trial ended: free pool
    const a = await addSubjectRow("lapsed", { name: "Ann", carried: true });
    const b = await addSubjectRow("lapsed", { name: "Ben", carried: true });
    await addSubjectRow("lapsed", { name: "Cy", carried: true });
    const bNote = await addSubjectRow("lapsed", { parentId: b, name: "Ben: work", carried: true });
    const d = await addSubjectRow("lapsed", { name: "Dee", carried: false });
    const carriedNames = async () =>
      (await sql<{ public_name: string }>(
        "SELECT public_name FROM prayer_subject WHERE owner_id = $1 AND is_carried AND NOT is_self ORDER BY public_name", ["lapsed"],
      )).map((r) => r.public_name);

    // Turning Cy off still leaves them over the free pool (0 people) — accepted.
    assert.deepEqual(await setCarriedItems(deps, "lapsed", [a, b, bNote]), { carried: 2, limit: 0 });
    assert.deepEqual(await carriedNames(), ["Ann", "Ben", "Ben: work"]);
    // An intention alone, too.
    assert.deepEqual(await setCarriedItems(deps, "lapsed", [a, b]), { carried: 2, limit: 0 });

    // Adding a person while over is blocked, and so is a swap of people (one off, one on).
    await assert.rejects(setCarriedItems(deps, "lapsed", [a, b, d]), (err: HttpsError) => {
      assert.deepEqual(err.details, { reason: "OVER_LIMIT", carried: 3, limit: 0, free: true });
      return true;
    });
    await assert.rejects(setCarriedItems(deps, "lapsed", [a, d]), /Over the carried limit/);
    assert.deepEqual(await carriedNames(), ["Ann", "Ben"], "a rejected save writes nothing");

    // Down to nothing is fine; the same set again is a no-op that's accepted.
    assert.deepEqual(await setCarriedItems(deps, "lapsed", []), { carried: 0, limit: 0 });
    assert.deepEqual(await setCarriedItems(deps, "lapsed", []), { carried: 0, limit: 0 });
  });

  it("under the pool, an addition is still pool-checked", async () => {
    const deps = makeDeps();
    await createUser("room", { includeLimit: 2, expiresInMs: 30 * DAY });
    const a = await addSubjectRow("room", { name: "Ann", carried: true });
    const b = await addSubjectRow("room", { name: "Ben", carried: false });
    const c = await addSubjectRow("room", { name: "Cy", carried: false });
    assert.deepEqual(await setCarriedItems(deps, "room", [a, b]), { carried: 2, limit: 2 });
    await assert.rejects(setCarriedItems(deps, "room", [a, b, c]), (err: HttpsError) => {
      assert.deepEqual(err.details, { reason: "OVER_LIMIT", carried: 3, limit: 2, free: false });
      return true;
    });
  });

  it("free = 0 people: no name fits; choosing intentions costs nothing (Me's, or under an uncarried name)", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("z", { trialEnded: true });
    const mom = await addSubjectRow("z", { name: "Mom", carried: false });
    const momIntention = await addSubjectRow("z", { parentId: mom, name: "Mom: surgery", carried: false });
    const mine = await addSubjectRow("z", { parentId: selfId, name: "Me: patience", carried: false });
    await assert.rejects(setCarriedItems(deps, "z", [mom]), (err: HttpsError) => {
      assert.deepEqual(err.details, { reason: "OVER_LIMIT", carried: 1, limit: 0, free: true });
      return true;
    });
    assert.deepEqual(await setCarriedItems(deps, "z", [mine, momIntention]), { carried: 0, limit: 0 });
  });

  it("Q32: the pool counts names only — a person with their intention uses one place", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("pp", { includeLimit: 1, expiresInMs: 30 * DAY });
    const dad = await addSubjectRow("pp", { name: "Dad", carried: false });
    const knee = await addSubjectRow("pp", { parentId: dad, name: "Dad: knee", carried: false });
    const mine = await addSubjectRow("pp", { parentId: selfId, name: "Me: rest", carried: false });
    const mom = await addSubjectRow("pp", { name: "Mom", carried: false });
    const momNote = await addSubjectRow("pp", { parentId: mom, name: "Mom: sleep", carried: false });
    assert.deepEqual(await setCarriedItems(deps, "pp", [dad, knee, mine, momNote]), { carried: 1, limit: 1 });
    await assert.rejects(setCarriedItems(deps, "pp", [dad, knee, mine, mom, momNote]), /Over the carried limit/);
  });

  it("Q32: the per-person cap is enforced, Me included; a reduction over the cap is still accepted", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("cp", { includeLimit: 5, expiresInMs: 30 * DAY });
    const dad = await addSubjectRow("cp", { name: "Dad" });
    const knee = await addSubjectRow("cp", { parentId: dad, name: "Dad: knee", sortOrder: 1 });
    const sleep = await addSubjectRow("cp", { parentId: dad, name: "Dad: sleep", sortOrder: 2, carried: false });
    const m1 = await addSubjectRow("cp", { parentId: selfId, name: "Me: one", sortOrder: 1 });
    const m2 = await addSubjectRow("cp", { parentId: selfId, name: "Me: two", sortOrder: 2, carried: false });
    await assert.rejects(setCarriedItems(deps, "cp", [dad, knee, sleep, m1]), (err: HttpsError) => {
      assert.equal(err.code, "failed-precondition");
      assert.deepEqual(err.details, { reason: "OVER_CAP", cap: 1, personIds: [dad] });
      return true;
    });
    await assert.rejects(setCarriedItems(deps, "cp", [dad, knee, m1, m2]), (err: HttpsError) => {
      assert.deepEqual((err.details as { personIds: string[] }).personIds, [selfId]);
      return true;
    });
    // A swap (one off, one on) is fine.
    assert.deepEqual(await setCarriedItems(deps, "cp", [dad, sleep, m2]), { carried: 1, limit: 5 });

    // Old data over the cap: removing something else is still accepted.
    await exec("UPDATE prayer_subject SET is_carried = true WHERE owner_id = 'cp'");
    assert.deepEqual(await setCarriedItems(deps, "cp", [dad, knee, sleep, m1]), { carried: 1, limit: 5 }, "Me trimmed, Dad unchanged");
    deps.live.config = { intentionsPerPerson: 2 };
    resetClientConfigCache();
    assert.deepEqual(await setCarriedItems(deps, "cp", [dad, knee, sleep, m1, m2]), { carried: 1, limit: 5 }, "cap from /config");
  });

  it("Q32: choosing a different intention at the cap is allowed even over the pool (a swap is never pool-checked)", async () => {
    const deps = makeDeps();
    await createUser("sw", { includeLimit: 10, expiresInMs: -DAY }); // lapsed: free pool, 0 people
    const ann = await addSubjectRow("sw", { name: "Ann" });
    const ben = await addSubjectRow("sw", { name: "Ben" });
    const x = await addSubjectRow("sw", { parentId: ann, name: "Ann: x", sortOrder: 1 });
    const y = await addSubjectRow("sw", { parentId: ann, name: "Ann: y", sortOrder: 2, carried: false });
    assert.deepEqual(await setCarriedItems(deps, "sw", [ann, ben, y]), { carried: 2, limit: 0 });
    const chosen = await sql<{ id: string }>("SELECT id FROM prayer_subject WHERE owner_id = 'sw' AND kind = 'INTENTION' AND is_carried");
    assert.deepEqual(chosen.map((r) => r.id), [y]);
    assert.ok(x);
  });

  it("the ~500 cap counts what's on Home; archiving makes room; a quiet hard cap counts every row not purged", async () => {
    const deps = makeDeps({ subjectCap: 3, subjectHardCap: 5 });
    await createUser("k"); // Me: 1 on Home
    const archive = (id: string) => clientDb.executeMutation("ArchiveSubject", { id }, impersonate("k"));
    const add = (name: string) => addSubject(deps, "k", { kind: "SOUL", publicName: name });

    await add("A");
    const b = await add("B"); // 3 on Home
    await assert.rejects(add("C"), (err: HttpsError) => {
      assert.equal(err.code, "resource-exhausted");
      assert.match(err.message, /Archive some to add more/);
      return true;
    });
    await archive(b.id); // 2 on Home, 3 rows
    const c = await add("C"); // 3 on Home, 4 rows
    await archive(c.id); // 2 on Home, 4 rows
    const d = await add("D"); // 3 on Home, 5 rows
    await archive(d.id); // 2 on Home, 5 rows: the hard cap
    await assert.rejects(add("E"), (err: HttpsError) => {
      assert.equal(err.code, "failed-precondition");
      assert.doesNotMatch(err.message, /500/, "generic, not the cap people see");
      return true;
    });
  });

  it("caps names at 40 and intentions at 80 visible characters (grapheme clusters)", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("cap");
    const family = "👨‍👩‍👧‍👦"; // one grapheme, 11 code units
    await addSubject(deps, "cap", { kind: "SOUL", publicName: family.repeat(40) });
    await assert.rejects(addSubject(deps, "cap", { kind: "SOUL", publicName: "x".repeat(41) }), /40 characters/);
    await addSubject(deps, "cap", { kind: "INTENTION", parentId: selfId, publicName: "y".repeat(80) });
    await assert.rejects(addSubject(deps, "cap", { kind: "INTENTION", parentId: selfId, publicName: "y".repeat(81) }), /80 characters/);
  });
});

describe("pre-trial pool (2026-11-09): never prayed, never entitled → basePremiumPool", () => {
  beforeEach(resetDb);
  const carriedNames = async (uid: string) =>
    (await sql<{ public_name: string }>(
      "SELECT public_name FROM prayer_subject WHERE owner_id = $1 AND kind = 'SOUL' AND is_carried AND NOT is_self ORDER BY sort_order",
      [uid],
    )).map((r) => r.public_name);

  it("addSubject before the first prayer carries the name (onboarding's adds)", async () => {
    const deps = makeDeps();
    await createUser("new");
    const julie = await addSubject(deps, "new", { kind: "SOUL", publicName: "Julie Olson", personalLabel: "Mom" });
    assert.deepEqual([julie.isCarried, julie.effectivelyCarried], [true, true]);
    const rest = await addSubject(deps, "new", { kind: "INTENTION", parentId: julie.id, publicName: "Healing after surgery" });
    assert.deepEqual([rest.isCarried, rest.parentCarried, rest.effectivelyCarried], [true, true, true],
      "the first intention becomes their chosen one");
  });

  it("a never-prayed user carries up to 10 people, not 11", async () => {
    const deps = makeDeps();
    await createUser("ten");
    const added = [];
    for (let i = 1; i <= 11; i++) added.push(await addSubject(deps, "ten", { kind: "SOUL", publicName: `P${i}` }));
    assert.deepEqual(added.map((a) => a.isCarried), [...Array(10).fill(true), false]);
    await assert.rejects(setCarriedItems(deps, "ten", added.map((a) => a.id)), (err: HttpsError) => {
      assert.deepEqual(err.details, { reason: "OVER_LIMIT", carried: 11, limit: 10, free: false });
      return true;
    });
    assert.deepEqual(await setCarriedItems(deps, "ten", added.slice(0, 10).map((a) => a.id)), { carried: 10, limit: 10 });
  });

  it("the pre-trial pool comes from /config basePremiumPool; restoreSubject sees it", async () => {
    const deps = makeDeps();
    deps.live.config = { basePremiumPool: 2 };
    await createUser("cfg");
    const a = await addSubject(deps, "cfg", { kind: "SOUL", publicName: "Ann" });
    const b = await addSubject(deps, "cfg", { kind: "SOUL", publicName: "Ben" });
    await clientDb.executeMutation("ArchiveSubject", { id: b.id }, impersonate("cfg"));
    const c = await addSubject(deps, "cfg", { kind: "SOUL", publicName: "Cy" });
    assert.deepEqual([a.isCarried, b.isCarried, c.isCarried], [true, true, true]);
    const restored = await restoreSubject(deps, "cfg", b.id);
    assert.deepEqual([restored.isCarried, restored.uncarried], [false, true], "over the pre-trial pool: back uncarried");
  });

  it("the first prayer starts the 14-day trial; the names stay carried", async () => {
    const deps = makeDeps();
    await createUser("first");
    for (const n of ["Ann", "Ben", "Cy"]) await addSubject(deps, "first", { kind: "SOUL", publicName: n });
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await processPrayer(deps, await logPrayer("first", { listId }));
    const [u] = await sql<{ include_limit: number; started: boolean; days: number }>(
      `SELECT include_limit, trial_started_at IS NOT NULL AS started,
         round(extract(epoch FROM entitlement_expires_at - trial_started_at) / 86400)::int AS days
       FROM "user" WHERE id = 'first'`,
    );
    assert.deepEqual(u, { include_limit: 10, started: true, days: 14 });
    assert.deepEqual(await carriedNames("first"), ["Ann", "Ben", "Cy"]);
    const d = await addSubject(deps, "first", { kind: "SOUL", publicName: "Dee" });
    assert.equal(d.isCarried, true, "now measured against the trial's includeLimit");
  });

  it("not pre-trial: a trial that ended, or an entitlement that lapsed before any prayer, is free", async () => {
    const deps = makeDeps();
    await createUser("ended", { trialEnded: true });
    assert.equal((await addSubject(deps, "ended", { kind: "SOUL", publicName: "Ann" })).isCarried, false);
    await createUser("lapsedFirst", { includeLimit: 10, expiresInMs: -30 * DAY });
    assert.equal((await addSubject(deps, "lapsedFirst", { kind: "SOUL", publicName: "Ann" })).isCarried, false);
  });

  it("assembly: a first prayer whose trial start hasn't run yet still prints the pre-trial pool", async () => {
    const deps = makeDeps();
    deps.live.config = { basePremiumPool: 2 };
    await createUser("race", { name: "Rae" });
    for (const n of ["Ann", "Ben", "Cy"]) await addSubjectRow("race", { name: n });
    const res = await setupAndAssemble(deps, ["race"]); // the prayer isn't processed
    assert.deepEqual(names(await entries(res.listId, "race")), ["Ann", "Ben", "Rae"]);
  });

  it("after the trial: over the free pool, the soft landing still prints the full portion for 7 days", async () => {
    const deps = makeDeps();
    await createUser("soft", { name: "Sol" });
    for (const n of ["Tia", "Uma"]) await addSubject(deps, "soft", { kind: "SOUL", publicName: n });
    const first = await addList(1, { currentFrom: Date.now() - 20 * DAY, closesAt: Date.now() - 19 * DAY, settled: true });
    await processPrayer(deps, await logPrayer("soft", { listId: first, startedAt: Date.now() - 19.5 * DAY }));
    await exec(`UPDATE "user" SET entitlement_expires_at = now() - interval '2 days' WHERE id = 'soft'`);
    assert.equal((await addSubject(deps, "soft", { kind: "SOUL", publicName: "Vic" })).isCarried, false, "free now: no new places");
    const listId = await addList(2, { currentFrom: Date.now() - DAY });
    await logPrayer("soft", { listId });
    await closeList(deps, 0);
    deps.clock.now = new Date(Date.now() + 1000);
    const res = await assembleNextList(deps, {});
    assert.deepEqual(names(await entries(res.listId, "soft")), ["Sol", "Tia", "Uma"]);
  });
});

describe("addSubject carry inputs (carry / carryParent)", () => {
  beforeEach(resetDb);
  const flags = (uid: string) =>
    sql<{ public_name: string; is_carried: boolean }>(
      "SELECT public_name, is_carried FROM prayer_subject WHERE owner_id = $1 AND NOT is_self ORDER BY public_name", [uid],
    );

  it("carry: false saves for private prayer even with room", async () => {
    const deps = makeDeps();
    await createUser("c1", { includeLimit: 5, expiresInMs: 30 * DAY });
    const kept = await addSubject(deps, "c1", { kind: "SOUL", publicName: "Bo" });
    assert.deepEqual([kept.isCarried, kept.parentCarried, kept.effectivelyCarried], [true, null, true]);
    const res = await addSubject(deps, "c1", { kind: "SOUL", publicName: "Abe", carry: false });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [false, null, false], "a name has no parent");
    assert.deepEqual(await flags("c1"), [{ public_name: "Abe", is_carried: false }, { public_name: "Bo", is_carried: true }]);
  });

  it("an intention under Me reports its name as carried", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("c2");
    const res = await addSubject(deps, "c2", { kind: "INTENTION", parentId: selfId, publicName: "Me: rest" });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [true, true, true]);
  });

  it("carryParent carries the name too (one place); carry: true at the cap swaps the new intention in", async () => {
    const deps = makeDeps();
    await createUser("c3", { includeLimit: 1, expiresInMs: 30 * DAY });
    const dad = await addSubjectRow("c3", { name: "Dad", carried: false });
    const knee = await addSubjectRow("c3", { parentId: dad, name: "Dad: knee", carried: true });
    const res = await addSubject(deps, "c3", {
      kind: "INTENTION", parentId: dad, publicName: "Dad: sleep", carry: true, carryParent: true,
    });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [true, true, true]);
    assert.deepEqual(res.unchosenIds, [knee]);
    assert.deepEqual(await flags("c3"), [
      { public_name: "Dad", is_carried: true },
      { public_name: "Dad: knee", is_carried: false },
      { public_name: "Dad: sleep", is_carried: true },
    ]);
  });

  it("all or nothing: if the name doesn't fit, nothing changes (no swap) and the item is saved unchosen", async () => {
    const deps = makeDeps();
    await createUser("c4", { includeLimit: 1, expiresInMs: 30 * DAY });
    await addSubjectRow("c4", { name: "Ann" }); // the one place
    const dad = await addSubjectRow("c4", { name: "Dad", carried: false });
    await addSubjectRow("c4", { parentId: dad, name: "Dad: knee", carried: true });
    const res = await addSubject(deps, "c4", {
      kind: "INTENTION", parentId: dad, publicName: "Dad: sleep", carry: true, carryParent: true,
    });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [false, false, false]);
    assert.deepEqual(res.unchosenIds, []);
    assert.deepEqual(await flags("c4"), [
      { public_name: "Ann", is_carried: true },
      { public_name: "Dad", is_carried: false },
      { public_name: "Dad: knee", is_carried: true },
      { public_name: "Dad: sleep", is_carried: false },
    ]);
  });

  it("Q32: a new intention is auto-chosen under the cap; at the cap it's saved unchosen unless carry: true swaps it in", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("c8"); // free: intentions cost nothing
    const first = await addSubject(deps, "c8", { kind: "INTENTION", parentId: selfId, publicName: "Me: one" });
    assert.deepEqual([first.isCarried, first.effectivelyCarried, first.unchosenIds], [true, true, []]);
    const second = await addSubject(deps, "c8", { kind: "INTENTION", parentId: selfId, publicName: "Me: two" });
    assert.deepEqual([second.isCarried, second.effectivelyCarried, second.unchosenIds], [false, false, []]);
    const third = await addSubject(deps, "c8", { kind: "INTENTION", parentId: selfId, publicName: "Me: three", carry: true });
    assert.deepEqual([third.isCarried, third.effectivelyCarried, third.unchosenIds], [true, true, [first.id]]);
    assert.deepEqual(await flags("c8"), [
      { public_name: "Me: one", is_carried: false },
      { public_name: "Me: three", is_carried: true },
      { public_name: "Me: two", is_carried: false },
    ]);
    // Another person's choices are untouched by a swap.
    const mom = await addSubjectRow("c8", { name: "Mom", carried: false });
    const momOne = await addSubject(deps, "c8", { kind: "INTENTION", parentId: mom, publicName: "Mom: rest", carry: true });
    assert.deepEqual([momOne.isCarried, momOne.parentCarried, momOne.unchosenIds], [true, false, []]);
    assert.equal((await flags("c8")).find((r) => r.public_name === "Me: three")?.is_carried, true);
  });

  it("free = 0: a new name is saved for private prayer", async () => {
    const deps = makeDeps();
    await createUser("c9", { trialEnded: true });
    const res = await addSubject(deps, "c9", { kind: "SOUL", publicName: "Mom" });
    assert.deepEqual([res.isCarried, res.effectivelyCarried], [false, false]);
  });

  it("without carryParent, an intention under an uncarried name keeps its flag but its name stays off", async () => {
    const deps = makeDeps();
    await createUser("c5", { includeLimit: 5, expiresInMs: 30 * DAY });
    const dad = await addSubjectRow("c5", { name: "Dad", carried: false });
    const res = await addSubject(deps, "c5", { kind: "INTENTION", parentId: dad, publicName: "Dad: sleep" });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [true, false, false], "flagged, not printed");
  });

  it("free tier: carryParent can't carry another person's name", async () => {
    const deps = makeDeps();
    await createUser("c6", { trialEnded: true });
    const mom = await addSubjectRow("c6", { name: "Mom", carried: false });
    const res = await addSubject(deps, "c6", { kind: "INTENTION", parentId: mom, publicName: "Mom: surgery", carryParent: true });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [false, false, false]);
  });

  it("carryParent is a no-op with carry: false; non-booleans are rejected", async () => {
    const deps = makeDeps();
    await createUser("c7", { includeLimit: 5, expiresInMs: 30 * DAY });
    const dad = await addSubjectRow("c7", { name: "Dad", carried: false });
    const res = await addSubject(deps, "c7", { kind: "INTENTION", parentId: dad, publicName: "Dad: sleep", carry: false, carryParent: true });
    assert.deepEqual([res.isCarried, res.parentCarried, res.effectivelyCarried], [false, false, false]);
    await assert.rejects(addSubject(deps, "c7", { kind: "SOUL", publicName: "Eve", carry: "yes" }), (err: HttpsError) => {
      assert.equal(err.code, "invalid-argument");
      return true;
    });
  });
});

describe("§9 follow-ups: harvest names, the seeded blocklist, the live push", () => {
  beforeEach(resetDb);

  it("truncates social display names to 40 graphemes on ingest", async () => {
    const deps = makeDeps();
    const family = "👨‍👩‍👧‍👦";
    const res = await setupAndAssemble(deps, [], [
      { platform: "youtube", externalId: "long1", displayName: "A".repeat(39) + family + "BCD" },
    ]);
    const [row] = await entries(res.listId);
    assert.equal(row.public_name, "A".repeat(39) + family, "40 visible characters, emoji intact");
    const [person] = await sql<{ display_name: string }>("SELECT display_name FROM external_person");
    assert.equal(person.display_name, row.public_name);
  });

  it("the bundled seed leaves out words that are also given names", async () => {
    const deps = makeDeps({ wordBlocklistEnabled: true });
    const res = await setupAndAssemble(deps, [], [
      { platform: "youtube", externalId: "n1", displayName: "Dick Smith" },
      { platform: "youtube", externalId: "n2", displayName: "Regina Mona" },
      { platform: "youtube", externalId: "n3", displayName: "Anita Concha" },
    ]);
    assert.deepEqual((await entries(res.listId)).map((r) => r.moderation_status), ["APPROVED", "APPROVED", "APPROVED"]);
  });

  it("the word blocklist is off by default for the beta", async () => {
    const deps = makeDeps();
    const res = await setupAndAssemble(deps, [], [{ platform: "youtube", externalId: "o1", displayName: "You BASTARD!" }]);
    assert.deepEqual((await entries(res.listId)).map((r) => r.moderation_status), ["APPROVED"]);
  });

  it("uses the bundled LDNOOBW seed when no editable list is set", async () => {
    const deps = makeDeps({ wordBlocklistEnabled: true }); // deps.live.blocklist is null → bundled seed
    const res = await setupAndAssemble(deps, [], [
      { platform: "youtube", externalId: "w1", displayName: "You BASTARD!" }, // English, whole word, any case
      { platform: "youtube", externalId: "w2", displayName: "Sebastardo Ruiz" }, // not a whole word
      { platform: "youtube", externalId: "z1", displayName: "王下贱明" }, // zh 2-char term inside a name
      { platform: "youtube", externalId: "z2", displayName: "王性明" }, // zh single char: whole token only
    ]);
    const by = Object.fromEntries((await entries(res.listId)).map((r) => [r.public_name, r]));
    assert.deepEqual([by["You BASTARD!"].moderation_status, by["You BASTARD!"].reason_category], ["HELD", "LANGUAGE"]);
    assert.equal(by["Sebastardo Ruiz"].moderation_status, "APPROVED");
    assert.equal(by["王下贱明"].reason_category, "LANGUAGE");
    assert.equal(by["王性明"].moderation_status, "APPROVED");
  });

  it("the list-live push says how many people the list holds", async () => {
    const deps = makeDeps();
    await createUser("pp", { name: "Pia" });
    const res = await setupAndAssemble(deps, ["pp"], [
      { platform: "youtube", externalId: "s1", displayName: "Sam" },
      { platform: "youtube", externalId: "s2", displayName: "Sue" },
    ]);
    await publishList(deps, res.listId);
    await publishListVideo(deps, { listId: res.listId, videoPath: "videos/2.mp4", posts: [] });
    assert.deepEqual(deps.sent, [{ topic: "list-live", body: "List 2 is up · 3 people." }]);
    assert.equal(listLiveCopy(52, 4345), "List 52 is up · 4,345 people.");
  });
});
