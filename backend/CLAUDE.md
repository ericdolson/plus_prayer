# backend/ — Server-Side Context

Inherits all brand-wide truths from the root CLAUDE.md. Product behavior lives
in docs/product/ (read the README there first); this file is build rules only. This file covers the
backend: SQL Connect schema/operations, Cloud Functions, and security rules.

---

## What Lives Here

```
backend/
  firebase.json        ← Firebase project config; deploys run from this folder
  .firebaserc
  dataconnect/
    schema/            ← schema.gql (the data model)
    connector/         ← client operations (the app's API surface; OPERATIONS.md)
    admin/             ← admin-only operations (Admin SDK: functions + admin CLI)
  functions/           ← Cloud Functions
    scripts/admin.ts   ← admin CLI (Eric's skills; same modules as the admin callables)
  database.rules.json  ← RTDB security rules (presence, live counts)
  storage.rules        ← Cloud Storage security rules (rules only — no media)
```

Run deploys from inside `backend/`: `firebase deploy --only dataconnect`
(or `:functions`, etc.). The Firebase CLI locates the project by `firebase.json`
in this folder. Deploy functions with `npx -y firebase-tools@latest deploy
--only functions`: the standalone `firebase` binary's bundled npm crashes in
the predeploy build. Schema migrations: check `firebase dataconnect:sql:diff`
before a schema deploy.

---

## Database: SQL Connect (managed Postgres)

Two billing surfaces: a serverless per-operation layer ($0.90/M operations,
250k/month free on Blaze) and the underlying Cloud SQL instance (hourly,
always-on). One operation = one query execution regardless of rows returned —
this is the core cost advantage over Firestore's per-document reads.

### Architectural rules
- **Queries are defined server-side**, not composed on the client. The client
  invokes named operations via the generated typed SDK. This is the security
  model: a client can only run operations you defined. Authorization is declared
  per-operation with `@auth`, not in a global rules file.
- **All global/aggregated state is written server-side**, never by clients:
  counters, list assembly, plan/entitlement fields, streaks.
- **The daily list is assembled with a server-side join-and-write** (set-based
  INSERT … SELECT), so the qualifying intentions never leave the database. The
  large dataset is never shipped to a client. Downloading the *assembled* list
  for printing is a separate, trivial read of one finished table.

### Region
`us-central1` (Iowa) — among the cheapest, fully-featured, geographically
central for a nationwide US launch audience. Do not optimize region for a
hypothetical global audience; global comes later via read replicas + CDN.

---

## Live State: Realtime Database (NOT SQL Connect)

The two high-fan-out live numbers live in RTDB, mirrored from server-side:
- **"Praying now" presence** — anyone currently in prayer (not tied to the
  global list). Uses RTDB `onDisconnect()` for crash-proof cleanup; no sweeper
  job needed as the primary mechanism. A low-frequency reconciliation job is the
  backstop, not the hot path.
- **Live prayer count for the current list** — the denormalized `prayerCount`
  on the current PrayerList row is mirrored to an RTDB node that clients
  subscribe to.

RTDB is bandwidth-billed, which is the right model for volatile high-churn data
and the reason these are deliberately NOT on SQL Connect (whose subscription
fan-out billing is the newest, least-proven surface).

---

## Cloud Functions (deployed; wiring in `functions/src/index.ts`)

All in `us-central1`. Logic lives in modules taking `Deps`, so tests run them
against the emulator and the admin CLI runs the same code locally.

- **Accounts** — `onAuthUserCreated` (v1 auth trigger: User row), and user
  callables `syncAccount`, `setSelfName`, `deleteAccount`, `mergeAccounts`.
- **Subjects** — user callables `addSubject`, `updateSubject`,
  `setCarriedItems` (free-text caps and server-owned state live here, not in
  the client connector).
- **Prayers** — `onPrayerLogged` (SQL Connect trigger on LogPrayer: list
  count + RTDB mirror, streak + grace, DailyStats); `sweepUncountedPrayers`
  (every 10 min, backstop for missed events); `answerGraceOffer`.
- **Presence** — `presencePublisher` (RTDB write trigger, throttled) and
  `presenceReconcile` (every minute) publish one public `/stats/live` node;
  `autoSavePrayerDrafts` (every 15 min) saves drafts past `autoSaveHours`.
- **Admin callables** (require the `admin` custom claim) — `closeList`,
  `assembleNextList`, `getReviewDiff`, `moderateEntry`, `moderateEntries`,
  `getHeldEntries`, `getListForPrint`, `publishList`, `publishListVideo`,
  `setEntitlement` (billing later; never client-writable). Eric's skills run
  these through the admin CLI instead (gcloud login, no claim needed).

`assembleNextList` settles list N — its prayerCount is final from then on, so
the world-count historical sum reads settled values (see Counts model below)
— and drafts N+1's entries in one statement: app carried items, the 🙏
harvest (SOCIAL), and the base set (BASE_SET), with moderation flags.

Data scripts (admin CLI): `seed-config` (RTDB `/config` + blocklist) and
`backfill` (lists 1..N from `publishing/*.json`). The NamUs base-set import
is not written yet.

### Daily transition timing (UPDATED 2026-06-24, Option C)
The daily list transition runs **manually, kicked off by Eric, at the ~6am MT
cutoff** — NOT on a schedule. The new list becomes current at that moment; its
video follows ~8am (publishListVideo sets videoPublishedAt). Life happens; the manual trigger preserves
flexibility. (This supersedes any earlier 9:30pm/scheduled-cron assumption.)
Because a human kicks off the transition, the moderation review checkpoint fits
naturally into that same step.

---

## Sensitive Data Posture

Intentions are sensitive personal data (health, relationships, grief). Auth
levels on every operation that touches subjects/intentions must reflect this.
The list is confidential — printed only at Eric's work, not shared publicly in
full. Public exposure of a subject is opt-in per-subject and gated.

---

## Counts & Streaks Model (DERIVE on read; store only when hot)

Full detail in `dataconnect/schema/schema.gql` header. Summary:

- **Derive, don't store** any stat until a read is a measured bottleneck. A
  computed value is always correct; a stored one can drift.
- **Three per-subject "prayed for" counts**, all derived in one operation:
  - Tier 1 "I prayed for Mom N times" — count of the user's PrayerSubjectLink
    rows for that subject. (OPEN: raw count vs. list-cycle count — see below.)
  - Tier 2 "my group prayed for Mom" — later, with groups.
  - Tier 3 "the world prayed for Mom N times" — SUM(PrayerList.prayerCount) over
    every list the subject appeared on (PrayerListEntry). Core mechanic: praying
    for a list credits everyone on it. Derivable today, no schema change.
  - NEVER sum tier-3 across subjects into a headline — it multiply-counts.
    "Prayers the world offered" is a separate number (PrayerList.prayerCount).
- **Live world-count = static + live, stitched on the client:** sqlc returns the
  sum over the subject's CLOSED lists (current EXCLUDED) plus a boolean "on the
  current list"; if true, the client adds the live current-list count from its
  existing RTDB subscription. sqlc never subscribes. Settle-on-close keeps the
  two halves from overlapping/double-counting.
- **User participation streak is STORED** on User (frequently read; bestStreak
  costly to re-derive). **Per-subject streaks are DERIVED** and only fully
  defined via listContextNumber (decided). User streak basis changed to local
  calendar days on 2026-10-17 — see docs/product/streaks-reminders.md. Denormalize per-subject streak
  only if it becomes a hot read.

### DECIDED (2026-06-24): Prayer.listContextNumber
Always set to the current list number at prayer time. Supports tier-1 cycle
counts. NOTE: user streaks moved to local calendar days on 2026-10-17 — see
docs/product/streaks-reminders.md.
