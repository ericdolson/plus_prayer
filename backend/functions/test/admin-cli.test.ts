// The admin CLI the skills run (scripts/admin.ts → src/adminCli.ts): the whole
// morning flow through its commands, error output, config, and the real entry
// script as a subprocess.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { beforeEach, describe, it } from "node:test";
import { errorJson, runAdminCommand } from "../src/adminCli";
import { DEFAULT_SERVER_CONFIG } from "../src/config";
import { serverConfigFromEnv } from "../src/runtime";
import { addList, createUser, DAY, logPrayer, makeDeps, resetDb, sql, TestDeps } from "./helpers";

const files = (map: Record<string, unknown>) => ({
  async readJson(path: string) {
    if (!(path in map)) throw new Error(`no such file: ${path}`);
    return map[path];
  },
});

const run = (deps: TestDeps, args: string, io = files({})) => runAdminCommand(deps, args.split(" ").filter(Boolean), io);

describe("admin CLI: the morning flow", () => {
  beforeEach(resetDb);

  it("status → close-list → assemble → review → moderate → held → exclude → publish → print → video", async () => {
    const deps = makeDeps();
    await createUser("ana", { name: "Ana" });
    const list1 = await addList(1, { currentFrom: Date.now() - DAY });
    await logPrayer("ana", { listId: list1 });

    const before = (await run(deps, "status")) as { current: { listNumber: number } };
    assert.equal(before.current.listNumber, 1);

    const closed = (await run(deps, "close-list --minutes 0")) as { nextListNumber: number };
    assert.equal(closed.nextListNumber, 2);
    deps.clock.now = new Date(Date.now() + 1000);

    const io = files({
      "harvest.json": [
        { platform: "youtube", externalId: "y1", displayName: "Grace" },
        { platform: "youtube", externalId: "y2", displayName: "buy likes cheap" },
        { platform: "youtube", externalId: "y3", displayName: "Xx_Moon_xX" },
      ],
    });
    const assembled = (await run(deps, "assemble --social harvest.json", io)) as {
      listNumber: number;
      review: { entryId: string; publicName: string }[];
    };
    assert.equal(assembled.listNumber, 2);
    const id = (name: string) => assembled.review.find((r) => r.publicName === name)!.entryId;

    const review = (await run(deps, "review")) as unknown[];
    assert.deepEqual(review, assembled.review, "--list defaults to the current list");

    const decisions = [
      { entryId: id("Ana"), decision: "approve" },
      { entryId: id("Grace"), decision: "approve" },
      { entryId: id("buy likes cheap"), decision: "exclude", reasonCategory: "OTHER", note: "spam" },
      { entryId: id("Xx_Moon_xX"), decision: "unsure", note: "a handle" },
    ];
    const moderated = (await run(deps, "moderate --decisions -", files({ "-": decisions }))) as { unsure: number; forEric: unknown[] };
    assert.equal(moderated.unsure, 1);

    const held = (await run(deps, "held")) as { id: string; publicName: string }[];
    assert.deepEqual(held.map((h) => h.publicName), ["Xx_Moon_xX"]);
    await run(deps, `exclude --entry ${held[0].id} --category OTHER --note not-a-name`);
    assert.deepEqual(await run(deps, "held"), []);

    const published = (await run(deps, "publish")) as { listNumber: number };
    assert.equal(published.listNumber, 2);
    const printed = (await run(deps, "print")) as { prayerListEntries: { publicName: string }[] };
    assert.deepEqual(printed.prayerListEntries.map((e) => e.publicName).sort(), ["Ana", "Grace"]);

    const video = (await run(deps, "publish-video --video videos/2.mp4 --posts posts.json", files({
      "posts.json": [{ platform: "youtube", url: "https://youtu.be/x", externalId: "x" }],
    }))) as { body: string; posts: number };
    assert.deepEqual([video.body, video.posts], ["List 2 is up · 2 people.", 1]);
  });

  it("set-entitlement and seed-config", async () => {
    const deps = makeDeps();
    await createUser("pat");
    await run(deps, "set-entitlement --uid pat --tier plan_a --limit 10 --expires 2030-01-01T00:00:00Z");
    const [u] = await sql<{ plan_tier: string; include_limit: number }>(`SELECT plan_tier, include_limit FROM "user" WHERE id = 'pat'`);
    assert.deepEqual(u, { plan_tier: "plan_a", include_limit: 10 });

    const seeded = (await run(deps, "seed-config")) as { addedConfigKeys: string[]; blocklistSeeded: boolean; blocklistTerms: number };
    assert.equal(seeded.blocklistSeeded, true);
    assert.ok(seeded.blocklistTerms > 2000);
    assert.equal(deps.live.config?.graceCap, 2);
    const again = (await run(deps, "seed-config")) as { blocklistSeeded: boolean };
    assert.equal(again.blocklistSeeded, false, "never overwrites an edited list");
  });

  it("errors come back as JSON a skill can read", async () => {
    const deps = makeDeps();
    const shape = async (args: string) => {
      try {
        await run(deps, args);
        assert.fail("expected an error");
      } catch (err) {
        return errorJson(err).error;
      }
    };
    assert.equal((await shape("frobnicate")).code, "invalid-argument");
    assert.match((await shape("moderate")).message, /--decisions is required/);
    assert.equal((await shape("status --bogus")).code, "invalid-argument");
    const precondition = await shape("close-list");
    assert.deepEqual([precondition.code, precondition.message], ["failed-precondition", "There is no current list yet (backfill lists first)"]);
  });
});

describe("admin CLI: config and the entry script", () => {
  it("reads the deployed param names from the environment", () => {
    assert.deepEqual(serverConfigFromEnv({}), DEFAULT_SERVER_CONFIG);
    const cfg = serverConfigFromEnv({ GATE_HOURS: "24", MODERATION_WORD_BLOCKLIST: "true", LIST_TIME_ZONE: "America/Chicago" });
    assert.deepEqual([cfg.gateHours, cfg.wordBlocklistEnabled, cfg.listTimeZone], [24, true, "America/Chicago"]);
    assert.throws(() => serverConfigFromEnv({ GATE_HOURS: "thirty" }), /GATE_HOURS must be an integer/);
  });

  const script = resolve(__dirname, "..", "scripts", "admin.ts");
  const exec = (env: NodeJS.ProcessEnv, ...args: string[]) =>
    spawnSync(process.execPath, ["--import", "tsx", script, ...args], { env: { PATH: process.env.PATH, ...env }, encoding: "utf8" });

  it("runs against the emulator and prints JSON", async () => {
    await resetDb();
    const res = exec({ DATA_CONNECT_EMULATOR_HOST: process.env.DATA_CONNECT_EMULATOR_HOST ?? "127.0.0.1:9399", GCLOUD_PROJECT: "demo-plusprayer" }, "status");
    assert.equal(res.status, 0, res.stderr);
    assert.match(res.stderr, /project demo-plusprayer · EMULATOR/);
    assert.deepEqual(JSON.parse(res.stdout), { current: null, openLists: [] });
  });

  it("refuses to run without credentials", () => {
    const res = exec({ CLOUDSDK_CONFIG: "/nonexistent" }, "status"); // never the developer's real gcloud login
    assert.equal(res.status, 2);
    assert.match(res.stderr, /GOOGLE_APPLICATION_CREDENTIALS/);
  });
});
