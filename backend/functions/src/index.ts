// +Prayer Cloud Functions — wiring only. Logic lives in the modules imported
// below, each taking `Deps` so tests can run it against the emulator. The
// admin callables here are also available to Eric's skills as a CLI
// (scripts/admin.ts) that runs the same modules with a service account.
// Region us-central1 (same as SQL Connect — required for its triggers).

import { initializeApp } from "firebase-admin/app";
import * as functionsV1 from "firebase-functions/v1";
import { onMutationExecuted } from "firebase-functions/dataconnect";
import { onValueWritten } from "firebase-functions/v2/database";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import { defineBoolean, defineInt, defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";

import * as accounts from "./accounts";
import { DEFAULT_SERVER_CONFIG } from "./config";
import { Deps } from "./deps";
import * as lists from "./lists";
import * as prayers from "./prayers";
import * as presence from "./presence";
import { LOCATION, productionDeps, SERVICE_ID } from "./runtime";
import * as subjects from "./subjects";

initializeApp();
setGlobalOptions({ region: LOCATION });

const gateHours = defineInt("GATE_HOURS", { default: DEFAULT_SERVER_CONFIG.gateHours });
const basePremiumPool = defineInt("BASE_PREMIUM_POOL", { default: DEFAULT_SERVER_CONFIG.basePremiumPool });
const subjectCap = defineInt("SUBJECT_CAP", { default: DEFAULT_SERVER_CONFIG.subjectCap });
const listTimeZone = defineString("LIST_TIME_ZONE", { default: DEFAULT_SERVER_CONFIG.listTimeZone });
// Off for the beta; set true at Stage 2 to turn the LANGUAGE flag back on.
const wordBlocklist = defineBoolean("MODERATION_WORD_BLOCKLIST", { default: DEFAULT_SERVER_CONFIG.wordBlocklistEnabled });

let deps: Deps | null = null;
function getDeps(): Deps {
  deps ??= productionDeps({
    ...DEFAULT_SERVER_CONFIG,
    gateHours: gateHours.value(),
    basePremiumPool: basePremiumPool.value(),
    subjectCap: subjectCap.value(),
    listTimeZone: listTimeZone.value(),
    wordBlocklistEnabled: wordBlocklist.value(),
  });
  return deps;
}

function requireUid(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign in first");
  return req.auth.uid;
}

function requireAdmin(req: CallableRequest): void {
  if (req.auth?.token?.admin !== true) throw new HttpsError("permission-denied", "Admin only");
}

/** A user callable that also makes sure the User row exists. */
function userCall<T>(fn: (d: Deps, uid: string, data: any) => Promise<T>) {
  return onCall(async (req) => {
    const uid = requireUid(req);
    const d = getDeps();
    await accounts.ensureUser(d, uid, accounts.providerName(req.auth?.token?.firebase?.sign_in_provider));
    return fn(d, uid, req.data ?? {});
  });
}

function adminCall<T>(fn: (d: Deps, data: any) => Promise<T>) {
  return onCall(async (req) => {
    requireAdmin(req);
    return fn(getDeps(), req.data ?? {});
  });
}

// ---------------------------------------------------------------- accounts --

/** The User row only; the self subject comes from setSelfName. Linking keeps the uid, so no second User. */
export const onAuthUserCreated = functionsV1.region(LOCATION).auth.user().onCreate(async (user) => {
  const provider = accounts.providerName(undefined, user.providerData.map((p) => p.providerId));
  await accounts.ensureUser(getDeps(), user.uid, provider);
});

/** Call after sign-in / linking: refreshes authProvider + isAnonymous. */
export const syncAccount = userCall(async () => ({ ok: true }));
export const setSelfName = userCall((d, uid, data) => subjects.setSelfName(d, uid, data.name));
export const deleteAccount = userCall((d, uid) => accounts.deleteAccount(d, uid));
export const mergeAccounts = userCall((d, uid, data) => accounts.mergeAccounts(d, uid, data.anonIdToken));

// ---------------------------------------------------------------- subjects --

export const addSubject = userCall((d, uid, data) => subjects.addSubject(d, uid, data));
export const updateSubject = userCall((d, uid, data) => subjects.updateSubject(d, uid, data));
export const setCarriedItems = userCall((d, uid, data) => subjects.setCarriedItems(d, uid, data.carriedIds));

// ----------------------------------------------------------------- prayers --

export const onPrayerLogged = onMutationExecuted(
  { service: SERVICE_ID, connector: "plusprayer", operation: "LogPrayer" },
  async (event) => {
    const payload = event.data.payload as { variables?: { id?: string }; errors?: unknown[] };
    if (payload.errors?.length || !payload.variables?.id) return; // retried duplicate or failed write
    await prayers.processPrayer(getDeps(), payload.variables.id);
  },
);

/** Backstop for missed onPrayerLogged events. */
export const sweepUncountedPrayers = onSchedule("every 10 minutes", async () => {
  await prayers.sweepUncountedPrayers(getDeps());
});

export const answerGraceOffer = userCall((d, uid, data) => {
  if (!["accept", "decline", "never"].includes(data.answer)) {
    throw new HttpsError("invalid-argument", "answer must be accept, decline, or never");
  }
  return prayers.answerGraceOffer(d, uid, data.answer);
});

export const autoSavePrayerDrafts = onSchedule("every 15 minutes", async () => {
  await presence.autoSavePrayerDrafts(getDeps());
});

// ---------------------------------------------------------------- presence --

export const presencePublisher = onValueWritten({ ref: "/presence/{uid}/{deviceId}" }, async () => {
  await presence.publishLiveStats(getDeps(), { throttle: true });
});

export const presenceReconcile = onSchedule("every 1 minutes", async () => {
  await presence.publishLiveStats(getDeps(), { throttle: false });
});

// ------------------------------------------------------------ admin (Eric) --

export const closeList = adminCall((d, data) => lists.closeList(d, data.minutes));
export const assembleNextList = adminCall((d, data) => lists.assembleNextList(d, data));
export const getHeldEntries = adminCall((d, data) => lists.getHeldEntries(d, data.listId));
export const getReviewDiff = adminCall((d, data) => lists.getReviewDiff(d, data.listId));
export const moderateEntry = adminCall((d, data) => lists.moderateEntry(d, data));
export const moderateEntries = adminCall((d, data) => lists.moderateEntries(d, data));
export const getListForPrint = adminCall((d, data) => lists.getListForPrint(d, data.listId));
export const publishList = adminCall((d, data) => lists.publishList(d, data.listId));
export const publishListVideo = adminCall((d, data) => lists.publishListVideo(d, data));
export const setEntitlement = adminCall((d, data) => accounts.setEntitlement(d, data));
