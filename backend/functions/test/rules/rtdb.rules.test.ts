// RTDB security rules (database.rules.json) against the Database emulator,
// plus the server's RTDB writes (live.ts). Needs a JDK 21+ for the emulator:
//   npm run test:rules
// Uses unsigned emulator ID tokens for end users.

import assert from "node:assert/strict";
import { after, describe, it } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { CLIENT_CONFIG_DEFAULTS } from "../../src/config";
import { rtdbLive } from "../../src/live";

const HOST = process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? "127.0.0.1:9000";
const NS = "demo-plusprayer-default-rtdb";
process.env.FIREBASE_DATABASE_EMULATOR_HOST = HOST;
const app = initializeApp({ projectId: "demo-plusprayer", databaseURL: `http://${HOST}?ns=${NS}` });
after(() => deleteApp(app)); // the RTDB connection would keep the process alive

const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");
function token(uid: string): string {
  const now = Math.floor(Date.now() / 1000);
  return `${b64({ alg: "none", typ: "JWT" })}.${b64({
    sub: uid, user_id: uid, aud: "demo-plusprayer", iss: "https://securetoken.google.com/demo-plusprayer",
    iat: now, exp: now + 3600, auth_time: now, firebase: { sign_in_provider: "anonymous", identities: {} },
  })}.`;
}

async function status(method: string, path: string, uid: string | null, body?: unknown): Promise<number> {
  const auth = uid ? `&auth=${token(uid)}` : "";
  const res = await fetch(`http://${HOST}${path}.json?ns=${NS}${auth}`, {
    method, body: body === undefined ? undefined : JSON.stringify(body),
  });
  return res.status;
}

const t = Date.now();
const draft = {
  startedAt: t, lastActiveAt: t, inForeground: true, listIncluded: true,
  itemIds: ["a1b2c3d4e5f60718293a4b5c6d7e8f90"], prayerId: "a1b2c3d4-e5f6-4071-8293-a4b5c6d7e8f9",
  localDate: "2026-10-18", timezone: "America/Denver",
};

describe("RTDB rules: presence drafts", () => {
  it("the owner can write, update (onDisconnect), read, and delete their own draft", async () => {
    assert.equal(await status("PUT", "/presence/u1/dev1", "u1", draft), 200);
    assert.equal(await status("PATCH", "/presence/u1/dev1", "u1", { inForeground: false, lastActiveAt: t }), 200);
    assert.equal(await status("GET", "/presence/u1", "u1"), 200);
    assert.equal(await status("DELETE", "/presence/u1/dev1", "u1"), 200);
  });

  it("nobody else can read or write it, and raw /presence is never readable", async () => {
    assert.equal(await status("PUT", "/presence/u1/dev1", "u2", draft), 401);
    assert.equal(await status("GET", "/presence/u1", "u2"), 401);
    assert.equal(await status("GET", "/presence", "u1"), 401);
  });

  it("rejects malformed drafts", async () => {
    assert.equal(await status("PUT", "/presence/u1/x", "u1", { ...draft, note: "free text" }), 401);
    assert.equal(await status("PUT", "/presence/u1/x", "u1", { startedAt: t, inForeground: true }), 401);
    assert.equal(await status("PUT", "/presence/u1/x", "u1", { ...draft, startedAt: t + 3_600_000 }), 401);
    assert.equal(await status("PUT", "/presence/u1/x", "u1", { ...draft, localDate: "18/10/2026" }), 401);
  });
});

describe("RTDB rules: public, server-written nodes", () => {
  it("are readable without auth and never client-writable", async () => {
    for (const path of ["/stats/live", "/lists/current", "/config"]) {
      assert.equal(await status("GET", path, null), 200, path);
      assert.equal(await status("PUT", path, "u1", { x: 1 }), 401, path);
    }
    assert.equal(await status("GET", "/stats/publishedAt", "u1"), 401);
  });
});

describe("live.ts against RTDB", () => {
  const live = rtdbLive();

  it("mirrors the current list, only ever raises its count, and moves forward to N+1", async () => {
    const read = async () => (await fetch(`http://${HOST}/lists/current.json?ns=${NS}`)).json();
    await live.setCurrentList({ listId: "abc-def", listNumber: 7, prayerCount: 0, closesAt: null });
    await live.raiseCurrentListCount({ listId: "abcdef", listNumber: 7 }, 5);
    await live.raiseCurrentListCount({ listId: "abcdef", listNumber: 7 }, 3);
    await live.raiseCurrentListCount({ listId: "older", listNumber: 6 }, 99);
    await live.setCurrentListClosesAt({ listId: "abcdef", listNumber: 7, prayerCount: 0, closesAt: 123 });
    assert.deepEqual(await read(), { listId: "abcdef", listNumber: 7, prayerCount: 5, closesAt: 123 });
    await live.raiseCurrentListCount({ listId: "next", listNumber: 8 }, 1);
    assert.deepEqual(await read(), { listId: "next", listNumber: 8, prayerCount: 1 });
  });

  it("throttles /stats/live publishing", async () => {
    const now = Date.now() + 10_000_000;
    assert.equal(await live.claimStatsPublish(now, 5000), true);
    assert.equal(await live.claimStatsPublish(now + 1000, 5000), false);
    assert.equal(await live.claimStatsPublish(now + 6000, 5000), true);
  });

  it("seeds /config defaults without overwriting tuned values", async () => {
    await fetch(`http://${HOST}/config.json?ns=${NS}&access_token=owner`, { method: "PUT", body: JSON.stringify({ graceCap: 3 }) });
    const added = await live.writeClientConfigDefaults(CLIENT_CONFIG_DEFAULTS);
    assert.ok(!added.includes("graceCap"));
    const cfg = await live.readClientConfig();
    assert.equal(cfg?.graceCap, 3);
    assert.equal(cfg?.presenceDisplayThreshold, 10);
  });
});
