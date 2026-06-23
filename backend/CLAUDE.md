# backend/ — Server-Side Context

Inherits all brand-wide truths from the root CLAUDE.md. This file covers the
backend: SQL Connect schema/operations, Cloud Functions, and security rules.

---

## What Lives Here

```
backend/
  firebase.json        ← Firebase project config; deploys run from this folder
  .firebaserc
  dataconnect/
    schema/            ← schema.gql (the data model)
    connector/         ← queries & mutations (the operation/API surface)
  functions/           ← Cloud Functions
  database.rules.json  ← RTDB security rules (presence, live counts)
  storage.rules        ← Cloud Storage security rules (rules only — no media)
```

Run deploys from inside `backend/`: `firebase deploy --only dataconnect`
(or `:functions`, etc.). The Firebase CLI locates the project by `firebase.json`
in this folder.

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

## Cloud Functions (anticipated)

- **assembleNextList** — manual-trigger (see below) join-and-write that builds
  the next list from users who prayed for the current one. Writes PrayerListEntry
  rows with frozen publicName, applying moderation filtering on social-sourced
  names. SETTLE-ON-CLOSE: before opening the new list, freeze the closing list's
  final live prayerCount (from RTDB) into its PrayerList.prayerCount, so the
  world-count historical sum reads finalized values (see Counts model below).
- **mirrorPrayerCount** — on prayer commit, bump the current list's prayerCount
  and mirror to RTDB.
- **presence mirror/reconcile** — maintain the RTDB presence counter; periodic
  reconciliation backstop.
- **billing entitlement** — on subscription change (later), set planTier /
  includeLimit on the user. Never client-writable.
- **streak update** — on a community prayer commit, update currentStreak /
  bestStreak / lastPrayedListNumber.

### Daily transition timing (UPDATED)
The daily list transition runs **manually, kicked off by Eric, around 8am his
time** — NOT on a schedule. Life happens; the manual trigger preserves
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
  well-defined once the OPEN listContextNumber decision is made (personal-only
  prayers aren't on the list axis without it). Denormalize per-subject streak
  only if it becomes a hot read.

### OPEN decision: Prayer.listContextNumber
Personal-only prayers (communityList = null) aren't placed on the list-number
axis. If tier-1 personal counts/streaks should read as "list cycles I prayed for
X" rather than raw event counts, add a `listContextNumber: Int` (always set) to
Prayer. UNRESOLVED — clean additive change whenever decided. Tier-3 does NOT
need it.
