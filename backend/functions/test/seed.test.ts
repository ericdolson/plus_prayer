// seed-emulator: the guard (refuses anything but the local emulators), and
// what the seed writes (counts, the Q32 invariants, the current list, the
// History the app reads), against the SQL Connect emulator.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { beforeEach, describe, it } from "node:test";
import { assertEmulatorTarget, EmulatorGuardError } from "../src/emulatorGuard";
import { chosenIntentions, carriedNames, PoolSubject } from "../src/pool";
import { planLists, planUser, SEED_INCLUDE_LIMIT, SEED_LIST_COUNT, seedEmulator, zonedInstant } from "../src/seedEmulator";
import { localDateIn, weekday } from "../src/dates";
import { normId, selfSubjectId } from "../src/ids";
import { clientDb, createUser, impersonate, makeDeps, resetDb, sql } from "./helpers";

const EMULATED = {
  DATA_CONNECT_EMULATOR_HOST: "127.0.0.1:9399",
  FIREBASE_DATABASE_EMULATOR_HOST: "127.0.0.1:9000",
  FIREBASE_AUTH_EMULATOR_HOST: "localhost:9099",
  GCLOUD_PROJECT: "demo-plusprayer",
};

describe("emulator guard", () => {
  it("accepts only local emulators on a demo- project", () => {
    const t = assertEmulatorTarget(EMULATED);
    assert.equal(t.projectId, "demo-plusprayer");
    assert.equal(t.databaseURL, "http://127.0.0.1:9000?ns=demo-plusprayer-default-rtdb");
  });

  const refused: [string, NodeJS.ProcessEnv][] = [
    ["nothing set (production defaults)", {}],
    ["the production project", { ...EMULATED, GCLOUD_PROJECT: "plusprayer" }],
    ["no project", { ...EMULATED, GCLOUD_PROJECT: "" }],
    ["SQL Connect not emulated", { ...EMULATED, DATA_CONNECT_EMULATOR_HOST: undefined }],
    ["RTDB not emulated", { ...EMULATED, FIREBASE_DATABASE_EMULATOR_HOST: undefined }],
    ["Auth not emulated", { ...EMULATED, FIREBASE_AUTH_EMULATOR_HOST: undefined }],
    ["a remote emulator host", { ...EMULATED, DATA_CONNECT_EMULATOR_HOST: "dataconnect.googleapis.com:443" }],
    ["a URL instead of host:port", { ...EMULATED, FIREBASE_DATABASE_EMULATOR_HOST: "https://plusprayer-default-rtdb.firebaseio.com" }],
    ["a production database URL", { ...EMULATED, FIREBASE_DATABASE_URL: "https://plusprayer-default-rtdb.firebaseio.com" }],
    ["a service account", { ...EMULATED, GOOGLE_APPLICATION_CREDENTIALS: "/tmp/service-account.json" }],
  ];
  for (const [what, env] of refused) {
    it(`refuses ${what}`, () => {
      assert.throws(() => assertEmulatorTarget(env), EmulatorGuardError);
    });
  }

  it("the seed script exits 2 before connecting when pointed at production", () => {
    const env = { PATH: process.env.PATH, HOME: process.env.HOME, GCLOUD_PROJECT: "plusprayer" };
    const res = spawnSync(process.execPath, ["--import", "tsx", join(__dirname, "../scripts/seed-emulator.ts"), "--uid", "x"], {
      env, encoding: "utf8", cwd: join(__dirname, ".."),
    });
    assert.equal(res.status, 2, res.stderr);
    assert.match(res.stderr, /Refusing to run/);
    assert.doesNotMatch(res.stderr, /seed-emulator · project/, "never got as far as connecting");
  });

  it("the emulator sweeper refuses too", () => {
    const env = { PATH: process.env.PATH, HOME: process.env.HOME, ...EMULATED, GCLOUD_PROJECT: "plusprayer" };
    const res = spawnSync(process.execPath, ["--import", "tsx", join(__dirname, "../scripts/emulator-sweeper.ts")], {
      env, encoding: "utf8", cwd: join(__dirname, ".."),
    });
    assert.equal(res.status, 2, res.stderr);
    assert.match(res.stderr, /demo- project/);
  });
});

describe("seed plan", () => {
  it("lists 1–70 end today, one per day, sealed by weekday, each closing as the next opens", () => {
    const now = new Date("2026-11-08T22:00:00Z"); // 3 pm in Denver
    const lists = planLists(now);
    assert.equal(lists.length, SEED_LIST_COUNT);
    assert.equal(lists.at(-1)!.listDate, localDateIn("America/Denver", now));
    assert.equal(lists[0].listDate, "2026-08-31");
    for (let i = 0; i < lists.length; i++) {
      assert.equal(lists[i].listNumber, i + 1);
      assert.equal(lists[i].sealVariant, weekday(lists[i].listDate));
      if (i < lists.length - 1) {
        assert.equal(lists[i].closesAt, lists[i + 1].currentFrom);
        assert.ok(lists[i].settledAt && lists[i].prayerCount > 1000);
      }
    }
    assert.equal(lists.at(-1)!.closesAt, null, "today's list is open");
    assert.ok(Date.parse(lists.at(-1)!.currentFrom) < now.getTime());
  });

  it("today's list is current even just after midnight", () => {
    const now = zonedInstant("2026-11-08", 0, 20, "America/Denver");
    const last = planLists(now).at(-1)!;
    assert.equal(last.listDate, "2026-11-08");
    assert.ok(Date.parse(last.currentFrom) <= now.getTime());
  });

  it("nothing is in the future and nobody is held before they were added", () => {
    const now = zonedInstant("2026-11-08", 0, 20, "America/Denver");
    const plan = planUser("u", planLists(now), now);
    const created = new Map(plan.subjects.map((s) => [s.id, Date.parse(s.createdAt)]));
    for (const p of plan.prayers) {
      assert.ok(Date.parse(p.prayedAt) <= now.getTime(), `${p.localDate} ends before now`);
      for (const id of p.subjectIds) assert.ok(created.get(id)! < Date.parse(p.startedAt), "held after it was added");
    }
  });
});

describe("seedEmulator (SQL Connect emulator)", () => {
  beforeEach(resetDb);

  async function seed(uids = ["phone"], now = new Date()) {
    const deps = makeDeps();
    deps.clock.now = now;
    const summary = await seedEmulator(deps, { uids });
    return { deps, summary };
  }

  it("writes the lists, the current list's RTDB mirror, /config and /stats/live", async () => {
    const { deps, summary } = await seed();
    const lists = await sql<{ n: number; published: number; settled: number; open: number }>(
      `SELECT count(*)::int AS n, count(*) FILTER (WHERE status = 'published')::int AS published,
              count(settled_at)::int AS settled, count(*) FILTER (WHERE closes_at IS NULL)::int AS open
       FROM prayer_list`,
    );
    assert.deepEqual(lists[0], { n: 70, published: 70, settled: 69, open: 1 });
    const meta = (await clientDb.executeQuery<{ prayerLists: { id: string; listNumber: number; prayerCount: number }[] }, object>(
      "GetCurrentListMeta", {}, impersonate("phone"),
    )).data.prayerLists[0];
    assert.equal(meta.listNumber, 70, "today's list is the current one");
    assert.deepEqual(deps.live.currentList, { listId: meta.id, listNumber: 70, prayerCount: meta.prayerCount, closesAt: null });
    assert.equal(deps.live.stats?.prayingNow, 213);
    assert.equal(deps.live.config?.intentionsPerPerson, 1);
    assert.equal(summary.currentList.listNumber, 70);
  });

  it("gives the user Home, History and a streak through the client connector", async () => {
    const { summary } = await seed();
    const as = impersonate("phone");
    const run = <T>(op: string, vars?: object) => clientDb.executeQuery<T, object>(op, vars as object, as).then((r) => r.data);

    type Subj = { id: string; kind: string; parentId: string | null; publicName: string; personalLabel: string | null;
      isSelf: boolean; isCarried: boolean; resolvedAt: string | null; createdAt: string; lastPrayed: unknown[] };
    const { prayerSubjects: subjects } = await run<{ prayerSubjects: Subj[] }>("GetMySubjects");
    const label = (s: Subj) => s.personalLabel ?? s.publicName;
    assert.deepEqual(subjects.filter((s) => s.kind === "SOUL").map(label),
      ["Me", "Dad", "Mom", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea", "Lena Park"]);
    const me = subjects.find((s) => s.isSelf)!;
    assert.equal(me.id, normId(selfSubjectId("phone")), "the self id setSelfName would derive");
    assert.equal(me.publicName, "Eric Olson");

    // Q32: the pool counts people; at most one chosen open intention each.
    const pool: PoolSubject[] = subjects.map((s) => ({
      id: s.id, kind: s.kind as "SOUL" | "INTENTION", isSelf: s.isSelf, isCarried: s.isCarried, status: "ACTIVE",
      resolvedAt: s.resolvedAt, parent: s.parentId ? { id: s.parentId } : null, sortOrder: 0,
    }));
    assert.equal(carriedNames(pool).length, 5);
    assert.ok(carriedNames(pool).length <= SEED_INCLUDE_LIMIT);
    for (const person of pool.filter((s) => s.kind === "SOUL")) {
      assert.ok(chosenIntentions(pool, person.id).length <= 1, `${person.id} has at most one chosen`);
    }
    const dad = subjects.find((s) => label(s) === "Dad")!;
    const dadIntentions = subjects.filter((s) => s.parentId === dad.id);
    assert.equal(dadIntentions.length, 2);
    assert.equal(dadIntentions.filter((s) => s.isCarried).length, 1);
    const momAnswered = subjects.find((s) => s.publicName === "A safe delivery for Ruth")!;
    const answeredDaysAgo = (Date.now() - Date.parse(momAnswered.resolvedAt!)) / 86_400_000;
    assert.ok(answeredDaysAgo > 9 && answeredDaysAgo < 11, "answered about 10 days ago");
    const lena = subjects.find((s) => s.publicName === "Lena Park")!;
    assert.equal(localDateIn("America/Denver", new Date(lena.createdAt)), localDateIn("America/Denver", new Date()));
    assert.equal(lena.lastPrayed.length, 0);

    // History: prayers + every list entry.
    type Prayer = { id: string; endedBy: string; note: string | null; communityList: { listNumber: number } | null; held: { id: string }[] };
    const { prayers } = await run<{ prayers: Prayer[] }>("GetMyPrayerHistory", { limit: 500 });
    assert.equal(prayers.length, summary.users[0].prayers);
    assert.ok(prayers.length >= 55, "about two months of prayers");
    assert.equal(prayers.filter((p) => p.endedBy === "AUTO").length, 1, "one auto-saved");
    assert.ok(prayers.filter((p) => p.held.length >= 3).length >= 10, "several hold many people");
    assert.ok(prayers.filter((p) => p.note).length >= 8, "some journal entries");
    assert.ok(prayers.some((p) => p.communityList === null), "some without the list");

    type Entry = { subject: { id: string }; list: { listNumber: number } };
    const { prayerListEntries: entries } = await run<{ prayerListEntries: Entry[] }>("GetMyListEntries");
    assert.equal(entries.length, summary.users[0].entries);
    const onList = (id: string) => new Set(entries.filter((e) => e.subject.id === id).map((e) => e.list.listNumber));
    const bea = subjects.find((s) => label(s) === "Aunt Bea")!;
    assert.equal(onList(bea.id).size, 0, "a private person is on no list");
    assert.ok(subjects.find((s) => label(s) === "Aunt Bea")!.lastPrayed.length === 1, "but has prayer days");
    assert.ok(onList(dad.id).size >= 45, "Dad carried near-daily");
    assert.ok(onList(dad.id).has(70), "on today's list");
    assert.ok(!onList(momAnswered.id).has(70), "an answered intention stops printing");
    // Every entry follows a day you prayed with the list before it.
    const listDays = new Set(prayers.filter((p) => p.communityList).map((p) => p.communityList!.listNumber));
    for (const n of onList(me.id)) assert.ok(listDays.has(n - 1), `on List ${n} after praying with ${n - 1}`);

    // The header and streak.
    type Header = { user: { displayName: string; currentStreak: number; bestStreak: number; lastListLocalDate: string; includeLimit: number } };
    const { user } = await run<Header>("GetMyHeader");
    assert.equal(user.displayName, "Eric Olson");
    assert.ok(user.currentStreak >= 6);
    assert.ok(user.bestStreak >= user.currentStreak);
    const yesterday = localDateIn("America/Denver", new Date(Date.now() - 86_400_000));
    assert.equal(user.lastListLocalDate, yesterday, "the streak counted yesterday; today not yet with the list");
    const currentId = (await run<{ prayerLists: { id: string }[] }>("GetCurrentListMeta")).prayerLists[0].id;
    const status = await run<{ myEntries: unknown[]; myPrayersWithList: { _count: number }[] }>(
      "GetMyListStatus", { listId: currentId },
    );
    assert.ok(status.myEntries.length >= 7, "you and what you carried print on today's list");
    assert.equal(status.myPrayersWithList[0]._count, 0, "not prayed with today's list yet");

    // Seeded prayers are already counted, so the sweeper never re-applies them.
    const uncounted = await sql<{ n: number }>("SELECT count(*)::int AS n FROM prayer WHERE counted_at IS NULL");
    assert.equal(uncounted[0].n, 0);
  });

  it("keeps the name the app set, seeds several users, and wipes what was there", async () => {
    await createUser("phone", { name: "Ann Lee" });
    await createUser("stranger");
    const { summary } = await seed(["phone", "sim"]);
    assert.deepEqual(summary.users.map((u) => [u.uid, u.name]), [["phone", "Ann Lee"], ["sim", "Eric Olson"]]);
    const users = await sql<{ id: string }>(`SELECT id FROM "user" ORDER BY id`);
    assert.deepEqual(users.map((u) => u.id), ["phone", "sim"]);
    const again = await seed(["phone"]);
    assert.equal(again.summary.users[0].name, "Ann Lee", "re-seeding is repeatable");
    const counts = await sql<{ n: number }>("SELECT count(*)::int AS n FROM prayer_list");
    assert.equal(counts[0].n, 70);
  });
});
