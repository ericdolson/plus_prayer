// Accounts (auth-onboarding.md): User creation, linking refresh, deletion,
// merging an anonymous account into an existing one, and entitlements.

import { HttpsError } from "firebase-functions/v2/https";
import { getClientConfig } from "./clientConfig";
import { mutate, query } from "./db";
import { Deps } from "./deps";
import { hasActiveEntitlement } from "./pool";
import { streakFromDays } from "./streak";

export function providerName(signInProvider: string | undefined, providerIds: string[] = []): string {
  const id = signInProvider ?? providerIds[0];
  if (!id || id === "anonymous") return "anonymous";
  if (id === "google.com") return "google";
  if (id === "apple.com") return "apple";
  return id;
}

/** onAuthUserCreated / syncAccount: the User row only (displayName null). */
export async function ensureUser(deps: Deps, uid: string, authProvider: string) {
  await mutate(deps.db, "EnsureUser", { uid, authProvider, isAnonymous: authProvider === "anonymous" });
}

/** Immediate after one confirmation; the store subscription is cancelled by the user. */
export async function deleteAccount(deps: Deps, uid: string) {
  await mutate(deps.db, "DeleteAccountData", { uid });
  await deps.live.removeUser(uid);
  await deps.auth.deleteUser(uid);
  return { deleted: true };
}

export async function setEntitlement(
  deps: Deps,
  input: { uid?: unknown; planTier?: unknown; includeLimit?: unknown; entitlementExpiresAt?: unknown },
) {
  if (typeof input.uid !== "string" || typeof input.planTier !== "string" || !Number.isInteger(input.includeLimit)) {
    throw new HttpsError("invalid-argument", "uid, planTier, includeLimit are required");
  }
  const expires = input.entitlementExpiresAt;
  if (expires !== null && expires !== undefined && (typeof expires !== "string" || Number.isNaN(Date.parse(expires)))) {
    throw new HttpsError("invalid-argument", "entitlementExpiresAt must be an ISO timestamp or null");
  }
  await mutate(deps.db, "SetEntitlement", {
    uid: input.uid,
    planTier: input.planTier,
    includeLimit: input.includeLimit,
    entitlementExpiresAt: expires ?? null,
  });
  return { uid: input.uid };
}

interface MergeUser {
  id: string;
  displayName: string | null;
  planTier: string;
  includeLimit: number;
  trialStartedAt: string | null;
  entitlementExpiresAt: string | null;
  currentStreak: number;
  bestStreak: number;
  lastListLocalDate: string | null;
  lastStatsDate: string | null;
  graceDays: number;
  graceOfferPending: boolean;
  self: { id: string }[];
}

const maxDate = (a: string | null, b: string | null) => (a === null ? b : b === null ? a : a > b ? a : b);
const minTime = (a: string | null, b: string | null) =>
  a === null ? b : b === null ? a : Date.parse(a) <= Date.parse(b) ? a : b;

/**
 * [Merge both] after a credential-in-use conflict: the signed-in existing
 * user passes the anonymous account's ID token. One transaction in
 * admin/accounts.gql MergeAccounts; then the anon auth user and RTDB nodes.
 */
export async function mergeAccounts(deps: Deps, targetUid: string, anonIdToken: unknown) {
  if (typeof anonIdToken !== "string") throw new HttpsError("invalid-argument", "anonIdToken is required");
  let anon: { uid: string; signInProvider: string | undefined };
  try {
    anon = await deps.auth.verifyIdToken(anonIdToken);
  } catch {
    throw new HttpsError("permission-denied", "That sign-in has expired; try again");
  }
  if (anon.signInProvider !== "anonymous") throw new HttpsError("failed-precondition", "Only an anonymous account can be merged");
  if (anon.uid === targetUid) throw new HttpsError("invalid-argument", "That is already this account");

  const state = await query<{ anon: MergeUser | null; target: MergeUser | null; listDays: { d: string }[] }>(
    deps.db, "GetMergeState", { anonUid: anon.uid, targetUid },
  );
  if (!state.target) throw new HttpsError("failed-precondition", "Account is not ready yet");
  if (!state.anon) {
    await deps.auth.deleteUser(anon.uid);
    return { merged: false };
  }
  const a = state.anon;
  const t = state.target;
  const rules = await getClientConfig(deps.live);
  const now = deps.now();

  const lastListLocalDate = maxDate(a.lastListLocalDate, t.lastListLocalDate);
  const recomputed = streakFromDays(state.listDays.map((r) => r.d));
  const storedOnLastDay = [a, t]
    .filter((u) => u.lastListLocalDate !== null && u.lastListLocalDate === lastListLocalDate)
    .reduce((m, u) => Math.max(m, u.currentStreak), 0);
  const currentStreak = Math.max(recomputed, storedOnLastDay);

  // Keep the active entitlement (the later-ending one if both are active).
  const active = [t, a]
    .filter((u) => hasActiveEntitlement(u, now))
    .sort((x, y) => Date.parse(y.entitlementExpiresAt!) - Date.parse(x.entitlementExpiresAt!))[0];
  const ent = active ?? t;

  await mutate(deps.db, "MergeAccounts", {
    anonUid: a.id,
    targetUid: t.id,
    anonSelf: a.self[0]?.id ?? null,
    targetSelf: t.self[0]?.id ?? null,
    displayName: t.displayName ?? a.displayName,
    planTier: ent.planTier,
    includeLimit: ent.includeLimit,
    trialStartedAt: minTime(a.trialStartedAt, t.trialStartedAt),
    entitlementExpiresAt: ent.entitlementExpiresAt,
    currentStreak,
    bestStreak: Math.max(a.bestStreak, t.bestStreak, currentStreak),
    lastListLocalDate,
    lastStatsDate: maxDate(a.lastStatsDate, t.lastStatsDate),
    graceDays: Math.min(rules.graceCap, Math.max(a.graceDays, t.graceDays)),
    graceOfferPending: a.graceOfferPending || t.graceOfferPending,
  });
  await deps.live.movePresence(a.id, t.id);
  await deps.auth.deleteUser(a.id);
  return { merged: true };
}
