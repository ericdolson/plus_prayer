// Tunables (schema-brief §5). Server params live here; client-visible values
// live in RTDB /config (defaults: ../config/client-config.json) and are
// read by the server too, so the app and the enforcement never disagree.

import clientDefaults from "../config/client-config.json";

export interface ServerConfig {
  /** List gate (b): a list prayer that ENDED in this many hours before closesAt qualifies. */
  gateHours: number;
  /** Free tier: carried people beyond the self name (Q32, 2026-11-08: 0 — you, with your intention). */
  freeLimit: number;
  trialDays: number;
  /** Soft landing after any entitlement end (trial or lapsed subscription). */
  softLandingDays: number;
  /** ~500 names and intentions on Home (ACTIVE, Answered included): "You've reached 500…". */
  subjectCap: number;
  /** Quiet hard cap on all rows not purged (archived included), against archive-and-add abuse. Param SUBJECT_HARD_CAP; no dedicated copy. */
  subjectHardCap: number;
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
  /** LANGUAGE auto-flag from the word blocklist. Off for the beta (Stage 2). */
  wordBlocklistEnabled: boolean;
}

export const DEFAULT_SERVER_CONFIG: ServerConfig = {
  gateHours: 30,
  freeLimit: 0,
  trialDays: 14,
  softLandingDays: 7,
  subjectCap: 500,
  subjectHardCap: 5000,
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
  wordBlocklistEnabled: false,
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
  /** The reverse trial and the base subscription both grant this pool
   *  (monetization.md). One source: the server's grant reads it from /config,
   *  and the add sheet shows it ("Membership carries up to {premiumPool}…"). */
  basePremiumPool: number;
  /** Q32 (2026-11-08): how many intentions each carried person (Me included)
   *  prints with — the most an owner may choose per person. The server
   *  enforces it on every carry write and at assembly; the app shows it. */
  intentionsPerPerson: number;
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
