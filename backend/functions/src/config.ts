// Tunables (schema-brief §5). Server params live here; client-visible values
// live in RTDB /config (defaults: ../config/client-config.json) and are
// read by the server too, so the app and the enforcement never disagree.

import clientDefaults from "../config/client-config.json";

export interface ServerConfig {
  /** List gate: a list prayer that ENDED within this many hours qualifies. */
  gateHours: number;
  /** Free tier: one intention under "Me". */
  freeLimit: number;
  /** Trial and base subscription both grant this pool (monetization.md). */
  basePremiumPool: number;
  trialDays: number;
  /** Soft landing after any entitlement end (trial or lapsed subscription). */
  softLandingDays: number;
  subjectCap: number;
  nameCap: number;
  intentionCap: number;
  selfNameChangeDays: number;
  minPrayerSeconds: number;
  /** Auto-save: drafts idle this long are finalized as endedBy AUTO. */
  autoSaveHours: number;
  /** Auto-save estimate: last foreground moment + up to this. */
  draftGraceMinutes: number;
  durationCapHours: number;
  /** A foreground device without a heartbeat for this long is gone. */
  foregroundStaleMinutes: number;
  /** A backgrounded device still counts as praying this long. */
  backgroundPresenceMinutes: number;
  statsPublishIntervalMs: number;
  closeListMinutes: number;
  /** The list's calendar day (listDate) is taken in this zone. */
  listTimeZone: string;
  /** Profanity / blocklist words (whole-word, case-insensitive). */
  blocklist: string[];
}

export const DEFAULT_SERVER_CONFIG: ServerConfig = {
  gateHours: 30,
  freeLimit: 1,
  basePremiumPool: 10,
  trialDays: 14,
  softLandingDays: 7,
  subjectCap: 500,
  nameCap: 40,
  intentionCap: 80,
  selfNameChangeDays: 7,
  minPrayerSeconds: 5,
  autoSaveHours: 6,
  draftGraceMinutes: 30,
  durationCapHours: 4,
  foregroundStaleMinutes: 3,
  backgroundPresenceMinutes: 30,
  statsPublishIntervalMs: 5000,
  closeListMinutes: 5,
  listTimeZone: "America/Denver",
  blocklist: [],
};

export interface ClientConfig {
  graceCap: number;
  graceIntervalDays: number;
  presenceDisplayThreshold: number;
  minAppVersion: string;
  minPrayerSeconds: number;
  draftResumeMinutes: number;
  autoSaveHours: number;
  durationCapHours: number;
}

export const CLIENT_CONFIG_DEFAULTS: ClientConfig = (() => {
  const { ["//"]: _comment, ...values } = clientDefaults as ClientConfig & { "//"?: string };
  return values;
})();

/** Overlay whatever /config holds on the compiled defaults. */
export function resolveClientConfig(stored: Partial<ClientConfig> | null | undefined): ClientConfig {
  const out = { ...CLIENT_CONFIG_DEFAULTS };
  for (const key of Object.keys(out) as (keyof ClientConfig)[]) {
    const v = stored?.[key];
    if (v !== undefined && v !== null && typeof v === typeof out[key]) {
      (out as Record<string, unknown>)[key] = v;
    }
  }
  return out;
}
