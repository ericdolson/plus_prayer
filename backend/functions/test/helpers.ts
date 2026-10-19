// Test harness: the REAL connector operations on the SQL Connect emulator,
// an in-memory RTDB, and no FCM / Auth. Run via `npm test` (starts the
// emulator) or `npm run test:run` against an already-running one.

import { randomUUID } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { DataConnect, getDataConnect } from "firebase-admin/data-connect";
import { resetClientConfigCache } from "../src/clientConfig";
import { ClientConfig, CLIENT_CONFIG_DEFAULTS, DEFAULT_SERVER_CONFIG, ServerConfig } from "../src/config";
import { mutate, query } from "../src/db";
import { CurrentListLive, Deps, Live, LiveStats, PresenceTree } from "../src/deps";
import { normId, selfSubjectId } from "../src/ids";

process.env.DATA_CONNECT_EMULATOR_HOST ??= "127.0.0.1:9399";
const appNamed = (name: string) =>
  getApps().find((a) => a.name === name) ?? initializeApp({ projectId: "demo-plusprayer" }, name);

// firebase-admin caches DataConnect instances per app by location + service
// only (the connector is ignored), so each connector needs its own app.
const service = { serviceId: "plusprayer-service", location: "us-central1" };
export const adminDb: DataConnect = getDataConnect({ ...service, connector: "admin" }, appNamed("[DEFAULT]"));
export const clientDb: DataConnect = getDataConnect({ ...service, connector: "plusprayer" }, appNamed("client"));

export const HOUR = 3_600_000;
export const DAY = 24 * HOUR;

/** Wipe every table (ad-hoc admin GraphQL; not a deployed operation). */
export async function resetDb(): Promise<void> {
  const tables = [
    "prayer_subject_link", "prayer_list_entry", "prayer", "reminder_preference",
    "prayer_subject", "prayer_list_post", "prayer_list", "external_person", "daily_stats", '"user"',
  ];
  const fields = tables.map((t, i) => `t${i}: _execute(sql: ${JSON.stringify(`DELETE FROM ${t}`)})`).join("\n");
  // No @transaction: native SQL fields must not be mixed under one (see
  // connector/mutations.gql); fields run in order, children first.
  await adminDb.executeGraphql(`mutation Reset { ${fields} }`);
  resetClientConfigCache();
}

export class FakeLive implements Live {
  currentList: CurrentListLive | null = null;
  stats: LiveStats | null = null;
  presence: PresenceTree = {};
  config: Partial<ClientConfig> | null = null;
  lastPublish: number | null = null;
  async setCurrentList(v: CurrentListLive) { this.currentList = { ...v, listId: normId(v.listId) }; }
  async setCurrentListClosesAt(list: CurrentListLive & { closesAt: number }) {
    const id = normId(list.listId);
    this.currentList = this.currentList?.listId === id
      ? { ...this.currentList, closesAt: list.closesAt }
      : { ...list, listId: id };
  }
  async raiseCurrentListCount(listId: string, count: number) {
    if (this.currentList?.listId === normId(listId)) {
      this.currentList.prayerCount = Math.max(this.currentList.prayerCount, count);
    }
  }
  async readPresence() { return structuredClone(this.presence); }
  async removeDraft(uid: string, deviceId: string) { delete this.presence[uid]?.[deviceId]; }
  async removeUser(uid: string) { delete this.presence[uid]; }
  async movePresence(from: string, to: string) {
    this.presence[to] = { ...(this.presence[to] ?? {}), ...(this.presence[from] ?? {}) };
    delete this.presence[from];
  }
  async setStatsLive(s: LiveStats) { this.stats = s; }
  async claimStatsPublish(now: number, intervalMs: number) {
    if (this.lastPublish !== null && now - this.lastPublish < intervalMs) return false;
    this.lastPublish = now;
    return true;
  }
  async readClientConfig() { return this.config; }
  async writeClientConfigDefaults(d: ClientConfig) { this.config = { ...d, ...this.config }; return []; }
}

export interface TestDeps extends Deps {
  live: FakeLive;
  sent: { topic: string; title: string; body: string }[];
  deletedAuthUsers: string[];
  clock: { now: Date };
}

export function makeDeps(cfg: Partial<ServerConfig> = {}): TestDeps {
  const clock = { now: new Date() };
  const sent: TestDeps["sent"] = [];
  const deletedAuthUsers: string[] = [];
  return {
    db: adminDb,
    live: new FakeLive(),
    notifier: { async sendToTopic(topic, title, body) { sent.push({ topic, title, body }); } },
    auth: {
      async deleteUser(uid) { deletedAuthUsers.push(uid); },
      async verifyIdToken(token) {
        const [uid, provider] = token.split(":");
        return { uid, signInProvider: provider };
      },
    },
    cfg: { ...DEFAULT_SERVER_CONFIG, ...cfg },
    now: () => clock.now,
    sent,
    deletedAuthUsers,
    clock,
  };
}

export const iso = (ms: number) => new Date(ms).toISOString();
export const ago = (ms: number) => Date.now() - ms;

// --------------------------------------------------------------- fixtures --

export function impersonate(uid: string, provider = "anonymous") {
  return { impersonate: { authClaims: { sub: uid, firebase: { sign_in_provider: provider } } as never } };
}

/** User (+ self subject unless self: false, + optional entitlement). */
export async function createUser(
  uid: string,
  opts: { self?: boolean; name?: string; includeLimit?: number; expiresInMs?: number | null; planTier?: string } = {},
): Promise<{ uid: string; selfId: string | null }> {
  await mutate(adminDb, "EnsureUser", { uid, authProvider: "anonymous", isAnonymous: true });
  let selfId: string | null = null;
  if (opts.self !== false) {
    await mutate(adminDb, "CreateSelf", { uid, selfId: selfSubjectId(uid), name: opts.name ?? `Person ${uid}` });
    const s = await query<{ user: { self: { id: string }[] } }>(adminDb, "GetSelfState", { uid });
    selfId = s.user.self[0].id;
  }
  if (opts.includeLimit !== undefined || opts.expiresInMs !== undefined) {
    await mutate(adminDb, "SetEntitlement", {
      uid,
      planTier: opts.planTier ?? "plan_a",
      includeLimit: opts.includeLimit ?? 1,
      entitlementExpiresAt: opts.expiresInMs == null ? null : iso(Date.now() + opts.expiresInMs),
    });
  }
  return { uid, selfId };
}

export async function addSubjectRow(
  uid: string,
  s: { kind?: "SOUL" | "INTENTION"; parentId?: string | null; name: string; carried?: boolean; sortOrder?: number },
): Promise<string> {
  const res = await mutate<{ prayerSubject_insert: { id: string } }>(adminDb, "InsertSubject", {
    uid,
    kind: s.kind ?? (s.parentId ? "INTENTION" : "SOUL"),
    parentId: s.parentId ?? null,
    publicName: s.name,
    personalLabel: null,
    note: null,
    isCarried: s.carried ?? true,
    sortOrder: s.sortOrder ?? 1,
  });
  return res.prayerSubject_insert.id;
}

export async function addList(
  listNumber: number,
  opts: { currentFrom?: number | null; closesAt?: number | null; status?: string; listDate?: string } = {},
): Promise<string> {
  const id = normId(randomUUID());
  await mutate(adminDb, "InsertList", {
    id,
    listNumber,
    listDate: opts.listDate ?? "2026-10-18",
    status: opts.status ?? "published",
    currentFrom: opts.currentFrom == null ? null : iso(opts.currentFrom),
    closesAt: opts.closesAt == null ? null : iso(opts.closesAt),
    publishedAt: null,
    sealVariant: null,
  });
  return id;
}

/** The real client LogPrayer, as that user. Returns the prayer id. */
export async function logPrayer(
  uid: string,
  p: {
    listId?: string | null;
    startedAt?: number;
    durationSeconds?: number;
    localDate?: string;
    subjectIds?: string[];
    listContextNumber?: number;
    id?: string;
  } = {},
): Promise<string> {
  const id = p.id ?? randomUUID();
  const durationSeconds = p.durationSeconds ?? 60;
  const startedAt = p.startedAt ?? Date.now() - durationSeconds * 1000;
  await clientDb.executeMutation("LogPrayer", {
    id,
    startedAt: iso(startedAt),
    prayedAt: iso(startedAt + durationSeconds * 1000),
    durationSeconds,
    localDate: p.localDate ?? new Date(startedAt).toISOString().slice(0, 10),
    timezone: "UTC",
    communityListId: p.listId ?? null,
    listContextNumber: p.listContextNumber ?? 1,
    note: null,
    subjectIds: p.subjectIds ?? [],
  }, impersonate(uid));
  return id;
}

/** Ad-hoc read for assertions. */
export async function sql<T = Record<string, unknown>>(statement: string, params: unknown[] = []): Promise<T[]> {
  const decls = params.map((_, i) => `$p${i}: Any`).join(", ");
  const binds = params.map((_, i) => `{ _expr: "vars.p${i}" }`).join(", ");
  const variables = Object.fromEntries(params.map((v, i) => [`p${i}`, v]));
  const res = await adminDb.executeGraphql<{ rows: T[] }, Record<string, unknown>>(
    `query Q${decls ? `(${decls})` : ""} { rows: _select(sql: ${JSON.stringify(statement)}, params: [${binds}]) }`,
    { variables },
  );
  // Raw Postgres returns dashed UUIDs; SQL Connect GraphQL returns 32 hex.
  const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return res.data.rows.map((row) => Object.fromEntries(
    Object.entries(row as Record<string, unknown>).map(([k, v]) => [k, typeof v === "string" && uuid.test(v) ? normId(v) : v]),
  ) as T);
}

export { CLIENT_CONFIG_DEFAULTS };
