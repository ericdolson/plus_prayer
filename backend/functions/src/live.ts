// RTDB implementation of `Live` (schema-brief §3):
//   /presence/{uid}/{deviceId}  owner-write drafts (private)
//   /stats/live                 server-write, public-read
//   /lists/current              server-write, public-read
//   /config                     server-write, public-read

import { getDatabase } from "firebase-admin/database";
import { ClientConfig } from "./config";
import { CurrentListLive, Live, LiveStats, PresenceTree } from "./deps";
import { normId } from "./ids";

export function rtdbLive(): Live {
  const db = () => getDatabase();
  return {
    async setCurrentList(value: CurrentListLive) {
      await db().ref("lists/current").set({ ...value, listId: normId(value.listId) });
    },
    // Transactions run first against the local cache (often null) and are
    // retried with the server value, so a null `cur` must never abort.
    async setCurrentListClosesAt(list) {
      const id = normId(list.listId);
      await db().ref("lists/current").transaction((cur: CurrentListLive | null) => {
        if (cur && cur.listId === id) return { ...cur, closesAt: list.closesAt };
        return { ...list, listId: id }; // missing or stale: re-sync the whole node
      });
    },
    async raiseCurrentListCount(listId, count) {
      const id = normId(listId);
      await db().ref("lists/current").transaction((cur: CurrentListLive | null) => {
        if (!cur || cur.listId !== id) return cur;
        return { ...cur, prayerCount: Math.max(cur.prayerCount ?? 0, count) };
      });
    },
    async readPresence() {
      return ((await db().ref("presence").get()).val() ?? {}) as PresenceTree;
    },
    async removeDraft(uid, deviceId) {
      await db().ref(`presence/${uid}/${deviceId}`).remove();
    },
    async removeUser(uid) {
      await db().ref(`presence/${uid}`).remove();
    },
    async movePresence(fromUid, toUid) {
      const from = db().ref(`presence/${fromUid}`);
      const drafts = (await from.get()).val();
      if (drafts) await db().ref(`presence/${toUid}`).update(drafts);
      await from.remove();
    },
    async setStatsLive(stats: LiveStats) {
      await db().ref("stats/live").set(stats);
    },
    async claimStatsPublish(now, intervalMs) {
      const res = await db().ref("stats/publishedAt").transaction((last: number | null) => {
        if (last !== null && now - last < intervalMs) return undefined; // abort
        return now;
      });
      return res.committed;
    },
    async readClientConfig() {
      return ((await db().ref("config").get()).val() ?? null) as Partial<ClientConfig> | null;
    },
    async writeClientConfigDefaults(defaults) {
      const ref = db().ref("config");
      const existing = ((await ref.get()).val() ?? {}) as Record<string, unknown>;
      const missing = Object.fromEntries(Object.entries(defaults).filter(([k]) => existing[k] === undefined));
      if (Object.keys(missing).length) await ref.update(missing);
      return Object.keys(missing);
    },
  };
}
