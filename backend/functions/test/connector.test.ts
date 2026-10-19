// Client connector operations under their real @auth, as the user (impersonated).

import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { beforeEach, describe, it } from "node:test";
import { addList, addSubjectRow, clientDb, createUser, DAY, exec, impersonate, logPrayer, resetDb, sql } from "./helpers";

const status = async (id: string) =>
  (await sql<{ status: string; cascade: boolean }>(
    "SELECT status::text AS status, archived_by_cascade AS cascade FROM prayer_subject WHERE id = $1::uuid", [id],
  ))[0];

describe("logPrayer", () => {
  beforeEach(resetDb);

  it("links only the caller's subjects, adds the parent name, and a retry is a no-op", async () => {
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await createUser("me");
    await createUser("other");
    const mom = await addSubjectRow("me", { name: "Mom" });
    const surgery = await addSubjectRow("me", { parentId: mom, name: "Mom: surgery" });
    const theirs = await addSubjectRow("other", { name: "Not mine" });

    const id = randomUUID();
    await logPrayer("me", { id, listId, subjectIds: [surgery, theirs] });
    await logPrayer("me", { id, listId, subjectIds: [], durationSeconds: 999 }); // retried send

    const links = await sql<{ subject_id: string }>("SELECT subject_id FROM prayer_subject_link WHERE prayer_id = $1::uuid", [id]);
    assert.deepEqual(new Set(links.map((l) => l.subject_id)), new Set([surgery, mom]));
    const [p] = await sql<{ duration_seconds: number; ended_by: string }>(
      "SELECT duration_seconds, ended_by::text AS ended_by FROM prayer WHERE id = $1::uuid", [id],
    );
    assert.deepEqual(p, { duration_seconds: 60, ended_by: "AMEN" }, "the retry did not overwrite history");
  });

  it("rejects prayers under 5 seconds and unauthenticated callers", async () => {
    await createUser("me");
    await assert.rejects(logPrayer("me", { durationSeconds: 4 }), /between 5 seconds and 4 hours/);
    await assert.rejects(
      clientDb.executeQuery("GetMyHeader", undefined as never, { impersonate: { unauthenticated: true } }),
      /signed-in user/,
    );
  });

  it("a prayer for a list id that doesn't exist is stored without the list", async () => {
    await createUser("me");
    const id = await logPrayer("me", { listId: randomUUID().replace(/-/g, "") });
    const [p] = await sql<{ community_list_id: string | null }>("SELECT community_list_id FROM prayer WHERE id = $1::uuid", [id]);
    assert.equal(p.community_list_id, null);
  });
});

describe("subject lifecycle", () => {
  beforeEach(resetDb);

  it("archiving a name cascades; restoring it brings back only cascaded intentions", async () => {
    await createUser("me");
    const name = await addSubjectRow("me", { name: "Dad" });
    const open = await addSubjectRow("me", { parentId: name, name: "Dad: rest" });
    const released = await addSubjectRow("me", { parentId: name, name: "Dad: job" });
    const ownArchive = await addSubjectRow("me", { parentId: name, name: "Dad: move" });
    const as = impersonate("me");
    await clientDb.executeMutation("ReleaseIntention", { id: released }, as);
    await clientDb.executeMutation("ArchiveSubject", { id: ownArchive }, as);

    await clientDb.executeMutation("ArchiveSubject", { id: name }, as);
    assert.deepEqual(await status(open), { status: "ARCHIVED", cascade: true });
    await assert.rejects(clientDb.executeMutation("RestoreSubject", { id: open }, as), /Restore its name first/);

    await clientDb.executeMutation("RestoreSubject", { id: name }, as);
    assert.deepEqual(await status(name), { status: "ACTIVE", cascade: false });
    assert.deepEqual(await status(open), { status: "ACTIVE", cascade: false });
    assert.equal((await status(released)).status, "ARCHIVED");
    assert.equal((await status(ownArchive)).status, "ARCHIVED");
  });

  it("purge cascades; the self subject can't be archived or purged; others' items are untouchable", async () => {
    const { selfId } = await createUser("me");
    await createUser("other");
    const name = await addSubjectRow("me", { name: "Gran" });
    const child = await addSubjectRow("me", { parentId: name, name: "Gran: peace" });
    const as = impersonate("me");
    await assert.rejects(clientDb.executeMutation("ArchiveSubject", { id: selfId }, as), /Item not found/);
    await assert.rejects(clientDb.executeMutation("PurgeSubject", { id: name }, impersonate("other")), /Item not found/);
    await clientDb.executeMutation("PurgeSubject", { id: name }, as);
    assert.equal((await status(child)).status, "PURGED");
    const archived = await clientDb.executeQuery<{ prayerSubjects: unknown[] }, Record<string, never>>("GetMyArchivedSubjects", {}, as);
    assert.equal(archived.data.prayerSubjects.length, 0, "PURGED never appears");
  });

  it("reorders one level; the self row stays pinned", async () => {
    const { selfId } = await createUser("me");
    const a = await addSubjectRow("me", { name: "A", sortOrder: 1 });
    const b = await addSubjectRow("me", { name: "B", sortOrder: 2 });
    await clientDb.executeMutation("ReorderSubjects", { orderedIds: [b, a, selfId!] }, impersonate("me"));
    const rows = await sql<{ public_name: string; sort_order: number }>(
      "SELECT public_name, sort_order FROM prayer_subject WHERE owner_id = $1 ORDER BY is_self DESC, sort_order", ["me"],
    );
    assert.deepEqual(rows.map((r) => [r.public_name, r.sort_order]), [["Person me", 0], ["B", 1], ["A", 2]]);
  });
});

describe("§9 follow-ups on the client connector", () => {
  beforeEach(resetDb);

  it("restoring a Released intention reopens it; an Answered one stays Answered", async () => {
    await createUser("me");
    const name = await addSubjectRow("me", { name: "Ma" });
    const released = await addSubjectRow("me", { parentId: name, name: "Ma: move" });
    const answered = await addSubjectRow("me", { parentId: name, name: "Ma: test results" });
    const as = impersonate("me");
    await clientDb.executeMutation("ReleaseIntention", { id: released }, as);
    await clientDb.executeMutation("MarkIntentionAnswered", { id: answered }, as);
    await clientDb.executeMutation("ArchiveSubject", { id: answered }, as);

    await clientDb.executeMutation("RestoreSubject", { id: released }, as);
    await clientDb.executeMutation("RestoreSubject", { id: answered }, as);
    const rows = await sql<{ id: string; status: string; resolution: string | null; resolved: boolean }>(
      "SELECT id, status::text AS status, resolution::text AS resolution, resolved_at IS NOT NULL AS resolved FROM prayer_subject WHERE id IN ($1::uuid, $2::uuid)",
      [released, answered],
    );
    const by = Object.fromEntries(rows.map((r) => [r.id, r]));
    assert.deepEqual(by[released], { id: released, status: "ACTIVE", resolution: null, resolved: false });
    assert.deepEqual(by[answered], { id: answered, status: "ACTIVE", resolution: "ANSWERED", resolved: true });
  });

  it("range-checks avatarTone (0–15, or null for the default)", async () => {
    await createUser("me");
    const id = await addSubjectRow("me", { name: "Jo" });
    const as = impersonate("me");
    await clientDb.executeMutation("SetSubjectAvatarTone", { id, avatarTone: 15 }, as);
    await clientDb.executeMutation("SetSubjectAvatarTone", { id, avatarTone: null }, as);
    await assert.rejects(clientDb.executeMutation("SetSubjectAvatarTone", { id, avatarTone: 16 }, as), /0 to 15/);
    await assert.rejects(clientDb.executeMutation("SetSubjectAvatarTone", { id, avatarTone: -1 }, as), /0 to 15/);
  });

  it("the detail page's entries (beads, world count) are APPROVED only, server-side", async () => {
    await createUser("me");
    const name = await addSubjectRow("me", { name: "Al" });
    const l1 = await addList(1, { currentFrom: Date.now() - 2 * DAY });
    const l2 = await addList(2, { currentFrom: Date.now() - DAY });
    await exec(
      `INSERT INTO prayer_list_entry (list_id, subject_id, owner_id, kind, public_name, source, moderation_status)
       VALUES ($1::uuid, $3::uuid, 'me', 'SOUL', 'Al', 'APP', 'APPROVED'),
              ($2::uuid, $3::uuid, 'me', 'SOUL', 'Al', 'APP', 'EXCLUDED')`,
      [l1, l2, name],
    );
    const res = await clientDb.executeQuery<{ prayerSubjects: { entries: { list: { listNumber: number } }[] }[] }, { id: string }>(
      "GetSubjectDetail", { id: name }, impersonate("me"),
    );
    assert.deepEqual(res.data.prayerSubjects[0].entries.map((e) => e.list.listNumber), [1]);
  });
});

describe("every client query executes", () => {
  beforeEach(resetDb);

  it("runs all 14 reads for a user with subjects, prayers, and list entries", async () => {
    const { selfId } = await createUser("me");
    const name = await addSubjectRow("me", { name: "Bea" });
    const intention = await addSubjectRow("me", { parentId: name, name: "Bea: rest" });
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    const prayerId = await logPrayer("me", { listId, subjectIds: [intention], localDate: "2026-10-10" });
    await exec(
      `INSERT INTO prayer_list_entry (list_id, subject_id, owner_id, kind, public_name, source, moderation_status)
       VALUES ($1::uuid, $2::uuid, 'me', 'SOUL', 'Bea', 'APP', 'APPROVED')`,
      [listId, name],
    );
    await clientDb.executeMutation("CreateReminder", { slot: "MORNING", localTime: "07:30" }, impersonate("me"));
    const as = impersonate("me");
    const run = (op: string, vars: object = {}) => clientDb.executeQuery<Record<string, unknown>, object>(op, vars, as);

    const ops: [string, object][] = [
      ["GetCurrentListMeta", {}], ["GetPastLists", {}], ["GetMyHeader", {}], ["GetMySubjects", {}],
      ["SearchMySubjects", { query: "Bea" }], ["GetMyListStatus", { listId }], ["GetMyPortion", { listId }],
      ["GetSubjectDetail", { id: name }], ["GetMyPrayerHistory", {}], ["GetMyPrayerTime", { weekStart: "2026-10-05" }],
      ["GetPrayer", { id: prayerId }], ["GetMyMonth", { from: "2026-10-01", to: "2026-10-31" }],
      ["GetMyArchivedSubjects", {}], ["GetMyReminders", {}],
    ];
    for (const [op, vars] of ops) await run(op, vars);

    const subjects = (await run("GetMySubjects")).data.prayerSubjects as { id: string; lastPrayed: { prayer: { localDate: string } }[] }[];
    assert.equal(subjects.find((x) => x.id === name)?.lastPrayed[0]?.prayer.localDate, "2026-10-10", "parent name linked");
    assert.equal(subjects.find((x) => x.id === selfId)?.lastPrayed.length, 0);
    const detail = (await run("GetSubjectDetail", { id: name })).data.prayerSubjects as { prayers: { prayer: { id: string } }[] }[];
    assert.deepEqual(detail[0].prayers.map((p) => p.prayer.id), [prayerId]);
  });
});

describe("review is invisible to users (schema-brief §11)", () => {
  beforeEach(resetDb);

  it("HELD looks like any printed entry; only EXCLUDED surfaces, with its category", async () => {
    const { selfId } = await createUser("me");
    const held = await addSubjectRow("me", { name: "Flagged one" });
    const excluded = await addSubjectRow("me", { name: "Not printed one" });
    const listId = await addList(1, { currentFrom: Date.now() - DAY });
    await exec(
      `INSERT INTO prayer_list_entry (list_id, subject_id, owner_id, kind, public_name, source, moderation_status, reason_category)
       VALUES ($1::uuid, $2::uuid, 'me', 'SOUL', 'Me', 'APP', 'APPROVED', NULL),
              ($1::uuid, $3::uuid, 'me', 'SOUL', 'Flagged one', 'APP', 'HELD', 'NAME_CHANGES'),
              ($1::uuid, $4::uuid, 'me', 'SOUL', 'Not printed one', 'APP', 'EXCLUDED', 'OTHER')`,
      [listId, selfId, held, excluded],
    );
    const as = impersonate("me");
    type Status = {
      myEntries: Record<string, unknown>[];
      notPrinted: { subject: { id: string }; reasonCategory: string }[];
    };
    const status = (await clientDb.executeQuery<Status, { listId: string }>("GetMyListStatus", { listId }, as)).data;
    assert.deepEqual(status.myEntries.map((e) => e.publicName).sort(), ["Flagged one", "Me"]);
    assert.ok(status.myEntries.every((e) => !("moderationStatus" in e) && !("reasonCategory" in e)));
    assert.deepEqual(status.notPrinted.map((e) => [e.subject.id, e.reasonCategory]), [[excluded, "OTHER"]]);

    const portion = (await clientDb.executeQuery<{ notPrinted: { subject: { id: string } }[] }, { listId: string }>(
      "GetMyPortion", { listId }, as,
    )).data;
    assert.deepEqual(portion.notPrinted.map((e) => e.subject.id), [excluded]);

    const detail = (await clientDb.executeQuery<{ prayerSubjects: { entries: unknown[] }[] }, { id: string }>(
      "GetSubjectDetail", { id: held }, as,
    )).data;
    assert.equal(detail.prayerSubjects[0].entries.length, 1, "a HELD entry printed, so it's a bead");
  });
});
