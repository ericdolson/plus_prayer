// Production Deps, shared by the deployed functions (index.ts) and the admin
// CLI the skills run (scripts/admin.ts), so both act through the exact same
// code paths. Call initializeApp() before productionDeps().

import { getAuth } from "firebase-admin/auth";
import { getDataConnect } from "firebase-admin/data-connect";
import { getMessaging } from "firebase-admin/messaging";
import { DEFAULT_SERVER_CONFIG, ServerConfig } from "./config";
import { Deps } from "./deps";
import { rtdbLive } from "./live";

export const SERVICE_ID = "plusprayer-service";
export const LOCATION = "us-central1";

export function productionDeps(cfg: ServerConfig): Deps {
  return {
    db: getDataConnect({ serviceId: SERVICE_ID, location: LOCATION, connector: "admin" }),
    live: rtdbLive(),
    notifier: {
      async sendToTopic(topic, notification, data) {
        await getMessaging().send({ topic, notification, data });
      },
    },
    auth: {
      async deleteUser(uid) {
        try {
          await getAuth().deleteUser(uid);
        } catch (err) {
          if ((err as { code?: string }).code !== "auth/user-not-found") throw err;
        }
      },
      async verifyIdToken(token) {
        const decoded = await getAuth().verifyIdToken(token, true);
        return { uid: decoded.uid, signInProvider: decoded.firebase?.sign_in_provider };
      },
    },
    cfg,
    now: () => new Date(),
  };
}

/**
 * Server config from environment variables named like the deployed params
 * (GATE_HOURS, BASE_PREMIUM_POOL, SUBJECT_CAP, LIST_TIME_ZONE,
 * MODERATION_WORD_BLOCKLIST), falling back to the defaults.
 */
export function serverConfigFromEnv(env: NodeJS.ProcessEnv = process.env): ServerConfig {
  const int = (name: string, fallback: number) => {
    const v = env[name];
    if (v === undefined || v === "") return fallback;
    const n = Number(v);
    if (!Number.isInteger(n)) throw new Error(`${name} must be an integer (got "${v}")`);
    return n;
  };
  const bool = (name: string, fallback: boolean) => {
    const v = env[name]?.toLowerCase();
    return v === undefined || v === "" ? fallback : v === "true" || v === "1";
  };
  return {
    ...DEFAULT_SERVER_CONFIG,
    gateHours: int("GATE_HOURS", DEFAULT_SERVER_CONFIG.gateHours),
    basePremiumPool: int("BASE_PREMIUM_POOL", DEFAULT_SERVER_CONFIG.basePremiumPool),
    subjectCap: int("SUBJECT_CAP", DEFAULT_SERVER_CONFIG.subjectCap),
    listTimeZone: env.LIST_TIME_ZONE || DEFAULT_SERVER_CONFIG.listTimeZone,
    wordBlocklistEnabled: bool("MODERATION_WORD_BLOCKLIST", DEFAULT_SERVER_CONFIG.wordBlocklistEnabled),
  };
}
