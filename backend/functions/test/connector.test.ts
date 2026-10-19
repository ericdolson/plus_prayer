// Client connector operations under their real @auth, as the user (impersonated).

import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { beforeEach, describe, it } from "node:test";
import { addList, addSubjectRow, clientDb, createUser, DAY, impersonate, logPrayer, resetDb, sql } from "./helpers";

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
