// Everything the handlers touch outside their own logic, behind one object so
// tests can run the real SQL Connect operations (emulator) with an in-memory
// RTDB and no FCM.

import { DataConnect } from "firebase-admin/data-connect";
import { ClientConfig, ServerConfig } from "./config";

/** A prayer draft at /presence/{uid}/{deviceId} (schema-brief §3). */
export interface PresenceDraft {
  startedAt: number;
  lastActiveAt: number;
  inForeground: boolean;
  listIncluded?: boolean;
  itemIds?: string[] | Record<string, string>;
  /** Optional: the client's prayer id, so auto-save and a late Amen collide. */
  prayerId?: string;
  /** Optional: device local date / IANA zone at the start. */
  localDate?: string;
  timezone?: string;
}

export type PresenceTree = Record<string, Record<string, PresenceDraft>>;

export interface LiveStats {
  prayingNow: number;
  prayedLastHour: number;
  prayedToday: number;
  updatedAt: number;
}

export interface CurrentListLive {
  listId: string;
  listNumber: number;
  prayerCount: number;
  closesAt: number | null;
}

/** RTDB surface used by the backend. */
export interface Live {
  setCurrentList(value: CurrentListLive): Promise<void>;
  /** Set closesAt on /lists/current (re-syncing the node if it's missing or stale). */
  setCurrentListClosesAt(list: CurrentListLive & { closesAt: number }): Promise<void>;
  /**
   * Mirror a counted list's prayerCount: raise it if this is the list shown
   * (never lowers it); move the node forward to a newer list (N+1 after the
   * cutoff); ignore an older one.
   */
  raiseCurrentListCount(list: { listId: string; listNumber: number }, count: number): Promise<void>;
  readPresence(): Promise<PresenceTree>;
  removeDraft(uid: string, deviceId: string): Promise<void>;
  removeUser(uid: string): Promise<void>;
  movePresence(fromUid: string, toUid: string): Promise<void>;
  setStatsLive(stats: LiveStats): Promise<void>;
  /** True if this caller may publish now (≥ intervalMs since the last). */
  claimStatsPublish(now: number, intervalMs: number): Promise<boolean>;
  readClientConfig(): Promise<Partial<ClientConfig> | null>;
  /** RTDB /moderation/blocklist (server-only), or null if not set. */
  readBlocklist(): Promise<string[] | null>;
  /** Seed /moderation/blocklist if empty; true when written. */
  writeBlocklistIfMissing(terms: string[]): Promise<boolean>;
  writeClientConfigDefaults(defaults: ClientConfig): Promise<string[]>;
}

export interface Notifier {
  sendToTopic(topic: string, notification: { title?: string; body: string }, data?: Record<string, string>): Promise<void>;
}

export interface AuthAdmin {
  deleteUser(uid: string): Promise<void>;
  /** Verifies an ID token; returns uid + sign-in provider. */
  verifyIdToken(token: string): Promise<{ uid: string; signInProvider: string | undefined }>;
}

export interface Deps {
  /** SQL Connect, admin connector (NO_ACCESS operations). */
  db: DataConnect;
  live: Live;
  notifier: Notifier;
  auth: AuthAdmin;
  cfg: ServerConfig;
  now(): Date;
}
