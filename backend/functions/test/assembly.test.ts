// Assembly + the carried pool (monetization.md, subjects.md, list-lifecycle.md).

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import { mutate } from "../src/db";
import { assembleNextList, closeList, listLiveCopy, moderateEntry, publishList, publishListVideo } from "../src/lists";
import { addSubject, setCarriedItems } from "../src/subjects";
import {
  addList, addSubjectRow, adminDb, clientDb, createUser, DAY, impersonate, logPrayer, makeDeps, resetDb, sql, TestDeps,
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

  it("premium: self, then self's intentions, then each name with its intentions, up to the limit", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("p", { name: "Pat", includeLimit: 3, expiresInMs: 30 * DAY });
    await addSubjectRow("p", { parentId: selfId, name: "Me: steady work", sortOrder: 1 });
    const a = await addSubjectRow("p", { name: "Ann", sortOrder: 1 });
    await addSubjectRow("p", { parentId: a, name: "Ann: healing", sortOrder: 1 });
    await addSubjectRow("p", { parentId: a, name: "Ann: rest", sortOrder: 2 }); // 4th — over the limit
    await addSubjectRow("p", { name: "Bo", sortOrder: 2 }); // over the limit
    const c = await addSubjectRow("p", { name: "Cy (not carried)", sortOrder: 3, carried: false });
    await addSubjectRow("p", { parentId: c, name: "Cy: job", sortOrder: 1 }); // name not carried → not effective

    const res = await setupAndAssemble(deps, ["p"]);
    const rows = await entries(res.listId, "p");
    assert.deepEqual(names(rows), ["Ann", "Ann: healing", "Me: steady work", "Pat"]);
    assert.equal(rows.find((r) => r.public_name === "Ann: healing")?.parent_name, "Ann");
    assert.equal(rows.find((r) => r.public_name === "Me: steady work")?.parent_name, "Pat");
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

  it("free: the self name plus one intention under Me", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("f", { name: "Fay" });
    await addSubjectRow("f", { parentId: selfId, name: "Fay: courage" });
    const res = await setupAndAssemble(deps, ["f"]);
    assert.deepEqual(names(await entries(res.listId, "f")), ["Fay", "Fay: courage"]);
  });

  it("free and over the free limit (a carried name), never premium: self name only", async () => {
    const deps = makeDeps();
    await createUser("g", { name: "Gus" });
    await addSubjectRow("g", { name: "Mom" });
    const res = await setupAndAssemble(deps, ["g"]);
    assert.deepEqual(names(await entries(res.listId, "g")), ["Gus"]);
  });

  it("soft landing: ≤7 days after an entitlement ends the full portion stays; after that, self only", async () => {
    const deps = makeDeps();
    await createUser("s", { name: "Sol", includeLimit: 10, expiresInMs: -2 * DAY });
    await addSubjectRow("s", { name: "Tia", sortOrder: 1 });
    await addSubjectRow("s", { name: "Uma", sortOrder: 2 });
    await createUser("t", { name: "Ted", includeLimit: 10, expiresInMs: -8 * DAY });
    await addSubjectRow("t", { name: "Val", sortOrder: 1 });
    const res = await setupAndAssemble(deps, ["s", "t"]);
    assert.deepEqual(names(await entries(res.listId, "s")), ["Sol", "Tia", "Uma"]);
    assert.deepEqual(names(await entries(res.listId, "t")), ["Ted"]);
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

  it("adds the 🙏 harvest and the active base set; holds contact info; counts non-excluded", async () => {
    const deps = makeDeps();
    deps.live.blocklist = ["darn"]; // the editable RTDB list overrides the bundled seed
    await createUser("u", { name: "Una" });
    await createUser("v", { name: "Call me 555-123-4567" });
    await mutate(adminDb, "UpsertBaseSetPerson", { externalId: "MP1", displayName: "Missing Child One", activeFrom: null, activeUntil: null });
    await mutate(adminDb, "UpsertBaseSetPerson", {
      externalId: "MP2", displayName: "Found Child", activeFrom: null, activeUntil: new Date(Date.now() - DAY).toISOString(),
    });
    const res = await setupAndAssemble(deps, ["u", "v"], [
      { platform: "YouTube", externalId: "yt1", displayName: "Jane Doe" },
      { platform: "youtube", externalId: "yt1", displayName: "Jane Doe" }, // duplicate → once
      { platform: "instagram", externalId: "ig1", displayName: "darn it" },
      { platform: "threads", externalId: "th1", displayName: "see www.example.com" },
    ]);

    const rows = await entries(res.listId);
    const by = Object.fromEntries(rows.map((r) => [r.public_name, r]));
    assert.deepEqual(names(rows), ["Call me 555-123-4567", "Jane Doe", "Missing Child One", "Una", "darn it", "see www.example.com"]);
    assert.equal(by["Jane Doe"].source, "SOCIAL");
    assert.equal(by["Jane Doe"].moderation_status, "APPROVED");
    assert.equal(by["Missing Child One"].source, "BASE_SET");
    assert.deepEqual([by["darn it"].moderation_status, by["darn it"].reason_category], ["HELD", "LANGUAGE"]);
    assert.deepEqual([by["see www.example.com"].reason_category, by["Call me 555-123-4567"].reason_category], ["CONTACT_OR_LINK", "CONTACT_OR_LINK"]);
    assert.equal(res.held, 3);
    assert.equal(res.soulCount, 6, "draft counts include held, exclude nothing yet");

    // Review: exclude one, approve the rest, publish → printed counts only.
    const held = await sql<{ id: string; public_name: string }>(
      "SELECT id, public_name FROM prayer_list_entry WHERE list_id = $1::uuid AND moderation_status = 'HELD'", [res.listId],
    );
    for (const h of held) {
      await moderateEntry(deps, h.public_name === "darn it"
        ? { entryId: h.id, status: "EXCLUDED", reasonCategory: "LANGUAGE" }
        : { entryId: h.id, status: "APPROVED" });
    }
    const pub = await publishList(deps, res.listId);
    assert.equal(pub.sealVariant, new Date(`${(await sql<{ d: string }>("SELECT to_char(list_date, 'YYYY-MM-DD') AS d FROM prayer_list WHERE id = $1::uuid", [res.listId]))[0].d}T12:00:00Z`).getUTCDay());
    const [counts] = await sql<{ soul_count: number }>("SELECT soul_count FROM prayer_list WHERE id = $1::uuid", [res.listId]);
    assert.equal(counts.soul_count, 5);
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
    await createUser("x", { includeLimit: 1, expiresInMs: 30 * DAY });
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

  it("free: only an intention under Me fits; an intention counts only if its name is carried", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("z");
    const mom = await addSubjectRow("z", { name: "Mom", carried: false });
    const momIntention = await addSubjectRow("z", { parentId: mom, name: "Mom: surgery", carried: false });
    const mine = await addSubjectRow("z", { parentId: selfId, name: "Me: patience", carried: false });
    await assert.rejects(setCarriedItems(deps, "z", [mom]), /Over the carried limit/);
    // Mom's intention flagged but Mom isn't carried → not effective → fits.
    assert.deepEqual(await setCarriedItems(deps, "z", [mine, momIntention]), { carried: 1, limit: 1 });
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
    const deps = makeDeps();
    const res = await setupAndAssemble(deps, [], [
      { platform: "youtube", externalId: "n1", displayName: "Dick Smith" },
      { platform: "youtube", externalId: "n2", displayName: "Regina Mona" },
      { platform: "youtube", externalId: "n3", displayName: "Anita Concha" },
    ]);
    assert.deepEqual((await entries(res.listId)).map((r) => r.moderation_status), ["APPROVED", "APPROVED", "APPROVED"]);
  });

  it("uses the bundled LDNOOBW seed when no editable list is set", async () => {
    const deps = makeDeps(); // deps.live.blocklist is null → bundled seed
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
