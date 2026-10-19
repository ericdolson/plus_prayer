// Presence (presence-live.md) and prayer drafts (prayer-flow.md).
//
// /presence/{uid}/{deviceId} exists while a prayer is in progress on that
// device. It counts as praying while foregrounded (heartbeat ~1/min) and for
// ~30 min after backgrounding. Clients never read raw presence: a publisher
// writes ONE public node, /stats/live, at most every ~5 s (event-driven) plus
// a 1-min reconcile.

import { localDateIn, MINUTE_MS, HOUR_MS, utcDate } from "./dates";
import { mutate, query } from "./db";
import { Deps, PresenceDraft, PresenceTree } from "./deps";
import { draftPrayerId } from "./ids";
import { processPrayer } from "./prayers";

export function isPraying(d: PresenceDraft, now: number, deps: Deps): boolean {
  if (typeof d?.lastActiveAt !== "number") return false;
  const idle = now - d.lastActiveAt;
  return d.inForeground
    ? idle < deps.cfg.foregroundStaleMinutes * MINUTE_MS
    : idle < deps.cfg.backgroundPresenceMinutes * MINUTE_MS;
}

/** People, not devices. */
export function countPrayingNow(tree: PresenceTree, now: number, deps: Deps): number {
  let people = 0;
  for (const devices of Object.values(tree ?? {})) {
    if (Object.values(devices ?? {}).some((d) => isPraying(d, now, deps))) people++;
  }
  return people;
}

export async function publishLiveStats(deps: Deps, opts: { throttle: boolean }): Promise<boolean> {
  const now = deps.now();
  if (opts.throttle && !(await deps.live.claimStatsPublish(now.getTime(), deps.cfg.statsPublishIntervalMs))) {
    return false;
  }
  const tree = await deps.live.readPresence();
  const stats = await query<{ lastHour: { people: number } | null; today: { prayers: number; peoplePraying: number } | null }>(
    deps.db, "GetLiveStats", { since: new Date(now.getTime() - HOUR_MS).toISOString(), today: utcDate(now) },
  );
  await deps.live.setStatsLive({
    prayingNow: countPrayingNow(tree, now.getTime(), deps),
    prayedLastHour: stats.lastHour?.people ?? 0,
    prayedToday: stats.today?.peoplePraying ?? 0,
    updatedAt: now.getTime(),
  });
  return true;
}

function itemIds(d: PresenceDraft): string[] {
  const raw = d.itemIds;
  const ids = Array.isArray(raw) ? raw : raw ? Object.values(raw) : [];
  return ids.filter((x): x is string => typeof x === "string" && /^[0-9a-f-]{32,36}$/i.test(x));
}

/**
 * Drafts idle > 6h become prayers with endedBy AUTO. Estimated end = last
 * foreground moment + up to 30 min, capped at 4h from start. Local date and
 * list are taken from the START. Under the minimum duration: discarded.
 */
export async function autoSavePrayerDrafts(deps: Deps): Promise<{ saved: number; discarded: number }> {
  const now = deps.now().getTime();
  const tree = await deps.live.readPresence();
  let saved = 0;
  let discarded = 0;
  for (const [uid, devices] of Object.entries(tree ?? {})) {
    for (const [deviceId, d] of Object.entries(devices ?? {})) {
      if (typeof d?.startedAt !== "number" || typeof d?.lastActiveAt !== "number") continue;
      if (now - d.lastActiveAt < deps.cfg.autoSaveHours * HOUR_MS) continue;

      const end = Math.min(d.lastActiveAt + deps.cfg.draftGraceMinutes * MINUTE_MS, d.startedAt + deps.cfg.durationCapHours * HOUR_MS);
      const durationSeconds = Math.floor((end - d.startedAt) / 1000);
      if (durationSeconds < deps.cfg.minPrayerSeconds) {
        await deps.live.removeDraft(uid, deviceId);
        discarded++;
        continue;
      }

      const started = new Date(d.startedAt);
      const user = await query<{ user: { timezone: string | null } | null }>(deps.db, "GetUserTimezone", { uid });
      if (!user.user) {
        await deps.live.removeDraft(uid, deviceId);
        discarded++;
        continue;
      }
      const timezone = d.timezone ?? user.user.timezone ?? "UTC";
      const list = (await query<{ prayerLists: { id: string; listNumber: number }[] }>(
        deps.db, "GetListAt", { at: started.toISOString() },
      )).prayerLists[0];
      const id = d.prayerId && /^[0-9a-f-]{32,36}$/i.test(d.prayerId) ? d.prayerId : draftPrayerId(uid, deviceId, d.startedAt);

      await mutate(deps.db, "InsertAutoSavedPrayer", {
        id,
        uid,
        startedAt: started.toISOString(),
        prayedAt: new Date(end).toISOString(),
        durationSeconds,
        localDate: d.localDate ?? localDateIn(timezone, started),
        timezone,
        communityListId: d.listIncluded && list ? list.id : null,
        listContextNumber: list?.listNumber ?? 0,
        subjectIds: itemIds(d),
      });
      await processPrayer(deps, id);
      await deps.live.removeDraft(uid, deviceId);
      saved++;
    }
  }
  return { saved, discarded };
}
