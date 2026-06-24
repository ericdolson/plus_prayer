# +Prayer — Decision Log

Canonical running log. Each decision carries a timestamp. Conflict resolution:
prefer the more recent timestamp; surface ambiguous conflicts rather than
resolving silently.

This file captures decisions. Verbose working-session summaries for agent
ingestion live in `../seeds/`.

## Operations & List Lifecycle

### Decision: Gap dissolved via Option C — current flips at cutoff
**Timestamp:** 2026-06-24
The earlier "prayers close at 6am, list becomes current at 8am" created a 2-hour
gap where praying for the current list would put you on the list AFTER next —
violating the "pray for the current list, be on the next" promise. Resolved by
flipping "current" at the cutoff itself: pray before cutoff → on N+1; pray after
→ you're praying for N+1 (now current) → on N+2. No gap, promise literally true.
A list can be CURRENT before its video is published; the app shows a "the list is
being filmed, available shortly" placeholder until videoPublishedAt is set
(on-brand anticipation, not an apology). Added videoPublishedAt to PrayerList.
This SIMPLIFIED the schema — no prayersClosedAt gap-state needed.

### Decision: logPrayer is an optimistic client write, not a gated function
**Timestamp:** 2026-06-24
Offline capability matters most exactly when it's most likely to fail — someone
praying at a sentimental place without signal. So logPrayer writes Prayer +
PrayerSubjectLink rows directly (offline-capable), UI-validated. The community-
list rule is UI-enforced now; server-side reconciliation is DEFERRED. ACCEPTED
INTERIM GAP: a determined actor hitting the mutation directly could bypass the
rule (e.g. farm stats without a community prayer). Low stakes for a prayer app at
launch; reconciliation added later when bad actors are real, with no migration
(schema already supports the check). Logged here so it's a decision on record,
not an oversight.

### Decision: Subject lifecycle is a single status enum (ACTIVE/ARCHIVED/PURGED)
**Timestamp:** 2026-06-24
Replaces the proposed soft-delete + isRecoverable two-flag model (which allowed
contradictory combinations). One axis, three honest states: ACTIVE (main list,
list-eligible), ARCHIVED (recoverable hide — e.g. removed in grief, may want
back), PURGED ("gone gone": hidden everywhere incl. archive, not user-restorable,
but the ROW PERSISTS for history/count integrity). Lets a user truly clean up a
troll/joke subject without it lurking forever, while derived counts never break.
PURGED = UI-permanent, NOT data-erased — a real GDPR-style erase is a separate
future feature. Self-subject forced ACTIVE, cannot be archived/purged.

### Decision: listContextNumber added; tier-1 supports BOTH semantics
**Timestamp:** 2026-06-24
Prayer.listContextNumber (always set = current list number at prayer time)
resolves the earlier open question. Tier-1 personal count now supports both raw
("times I prayed for X" = link count) AND cycle ("list cycles I prayed for X" =
distinct listContextNumber). The cycle view is also the per-subject streak basis.
Works for personal-only prayers (communityList = null) because listContextNumber
is independent of communityList.

### Decision: signUp is an auth-trigger function, not a client mutation
**Timestamp:** 2026-06-24
onAuthUserCreated creates the User + self-PrayerSubject atomically, server-side,
so it can't be skipped (a client-called signUp could be authenticated-but-never-
called, leaving a user with no self-soul, breaking the core promise). Must detect
anonymous→permanent LINKING and not create a second User row.

### Decision: Prayer side-effects are reactions, not inside logPrayer
**Timestamp:** 2026-06-24
Count bump + RTDB mirror + streak update happen as onPrayerLogged reaction, not
in the logPrayer write — keeps the write pure and offline-friendly. Wiring (true
DB trigger vs. sequential function call) confirmed against current Data Connect
capabilities at implementation; designed as separable units.

### Cut for MVP: setSubjectActive / pause-a-subject
**Timestamp:** 2026-06-24
Pausing a subject from lists without archiving is deferred to avoid complexity
creep. The status enum can gain a paused-equivalent later if user control demands
it. updatePrayer is NOTE-ONLY; prayers are never hard-deleted.

### Operation spec
**Timestamp:** 2026-06-24
Full screen→operation map at
backend/dataconnect/connector/OPERATIONS.md — the spec the .gql connectors and
Cloud Functions are built from.

---



### Decision: SQL Connect (managed Postgres) over Firestore for the primary store
**Timestamp:** 2026-06-23
The app's data is substantially relational (subjects, prayers, lists, future
groups/follows). SQL Connect chosen for: per-operation pricing (1 operation per
query regardless of rows, vs. Firestore per-document reads), native Postgres
full-text search (eliminates the Algolia sync the Firestore design required),
and per-operation `@auth` (vs. a single global rules file that must anticipate
every client-composed query). Tradeoff accepted: reintroduces a provisioned
Cloud SQL instance to size (storage auto-grows; compute is a manual dial; read
pools can autoscale on Enterprise Plus). Net: cheaper for the relational/batch
heart of the app; instance floor means Firestore can be cheaper at very small
scale.

### Decision: Region us-central1 (Iowa)
**Timestamp:** 2026-06-23
Among the cheapest, fully-featured, geographically central for a nationwide US
launch. Do NOT optimize region for a hypothetical global audience — global comes
later via read replicas + CDN, and (for EU) data-residency may matter more than
latency. us-west3 (SLC) tempting for personal dev latency but smaller + pricier.

### Decision: High-fan-out live state stays on Realtime Database, not SQL Connect
**Timestamp:** 2026-06-23 (consistent with earlier presence design)
"Praying now" presence and the live list prayer-count are mirrored to RTDB.
RTDB is bandwidth-billed (right for volatile high-churn data) and its
`onDisconnect()` gives crash-proof presence cleanup. SQL Connect subscription
fan-out billing is the newest/least-proven surface — kept off the hot path.

### Decision: Daily list assembled via server-side join-and-write
**Timestamp:** 2026-06-23
The next list is built with a set-based INSERT … SELECT inside Postgres; the
qualifying intentions never ship to a client. This resolves the Firestore
fan-out pain (N+1 reads or write amplification). Downloading the assembled list
for printing is a separate trivial read of one finished table (optionally
rendered to a print-ready PDF server-side and dropped in Cloud Storage).

### Decision: Daily transition is MANUAL, ~8am, not scheduled
**Timestamp:** 2026-06-23 (SUPERSEDES earlier 9:30pm / scheduled assumption)
Eric kicks off the transition manually around 8am his time. Not on a cron yet —
life happens; manual preserves flexibility. The moderation review checkpoint
fits naturally into this manual step.

---

## Data Model / Schema (MVP)

### Decision: Unified PrayerSubject table (souls + intentions) with a `kind` enum
**Timestamp:** 2026-06-23
They share almost all fields and always travel together; splitting doubles
joins. Only kind-specific field is `answeredAt` (intentions can be marked
answered — the gratitude payoff; null for souls). Entanglement ("an intention
about a soul") deferred as a future nullable self-reference.

### Decision: publicName + personalLabel on subjects
**Timestamp:** 2026-06-23
Two names, two audiences: publicName is printed/shown ("Gary Olson");
personalLabel is owner-only and intimate ("Dad"), optional. List assembly
snapshots publicName.

### Decision: Self is the dividend, not a slot (Model A)
**Timestamp:** 2026-06-23
The user is ALWAYS carried on the list for free as the reward for participating,
pinned to the top of their entry, and NOT counted against includeLimit. Paid
tiers add slots for carrying OTHERS. Rationale: A is both more profitable AND
more ethical — it never makes a user choose between themselves and a loved one
(which the alternative, "top-of-list is the free one," would). The thing sold is
generosity toward others, not one's own inclusion. Pricing target $20–30/yr
reads as membership, not paywall. Unlimited PERSONAL (private) prayer always
free; only the printed-list slots are gated. Guardrail: keep upgrade prompts
humane — never fire on a freshly-added subject tied to someone in crisis.

### Decision: includeLimit default 0 = "additional subjects beyond self"
**Timestamp:** 2026-06-23
Stored as a concrete number on User (not derived from planTier) so one-off
grants are possible. Server-written only, on billing events.

### Decision: Ordered subjects with top-N "fold", not explicit toggles
**Timestamp:** 2026-06-23
sortOrder on PrayerSubject; the top `includeLimit` active non-self subjects are
carried. Reordering reframes the limit as prioritization, not exclusion —
gentler in an emotional context and a non-coercive upgrade prompt. Self is
pinned top and exempt from ordering.

### Decision: Streaks = consecutive list numbers, not calendar days
**Timestamp:** 2026-06-23
Avoids all per-user timezone math. Tradeoff accepted: a fully-missed list breaks
the streak with no make-up. A grace/freeze mechanic can be added later with no
schema change (lastPrayedListNumber already stored).

### Decision: Frozen publicName snapshot in PrayerListEntry
**Timestamp:** 2026-06-23
A printed list does not change if the user later edits the subject.

### Decision: Capture optional consent-gated location on Prayer
**Timestamp:** 2026-06-23
Primarily for the user's own "where I prayed" history/map now; coarse/fuzzed
global view possible later. Store precise, fuzz on output. Impossible to
backfill — capture from day one.

### Decision: Counts & streaks are DERIVED on read, not stored (with two exceptions)
**Timestamp:** 2026-06-23
Principle: don't store derived data until a read is a measured bottleneck; a
computed value is always correct, a stored one can drift. Three per-subject
"prayed for" counts, all derived in one operation: Tier 1 "I prayed for Mom"
(count of the user's PrayerSubjectLink rows for the subject), Tier 2 "my group
prayed for Mom" (later, with groups), Tier 3 "the world prayed for Mom" =
SUM(PrayerList.prayerCount) over the lists the subject appeared on
(PrayerListEntry). Tier 3 works because the core mechanic credits everyone on a
list with that list's prayers; it needs no cross-user identity (it's the
subject's own entries). Per-subject streaks also derived. EXCEPTIONS that stay
STORED: the USER participation streak on User (read on nearly every app open;
bestStreak costly to re-derive over all history) and the denormalized list
counts. Caution captured: never sum tier-3 across subjects into a headline
number — every subject on a list is credited that list's full count, so summing
multiply-counts. "Prayers the world offered" is a separate figure
(PrayerList.prayerCount itself).

### Decision: World-count derivation = sum of prayerCount over the subject's lists
**Timestamp:** 2026-06-23
"The world prayed for Mom N times" = SUM(PrayerList.prayerCount) for every list
where Mom has a PrayerListEntry. Example: Mom on lists 1–4 at 1,000 each = 4,000.
Honest and computable from existing tables; no identity resolution. Separately
surfaced from "how many prayers the world offered" to avoid implying inflated
multiples — handled by how each stat is worded in the UI.

### Decision: Live world-count stitched client-side (static sqlc + live RTDB)
**Timestamp:** 2026-06-23
sqlc query returns the sum over the subject's CLOSED lists (current EXCLUDED)
plus a boolean "is the subject on the current list". If true, the client adds the
live current-list count from its existing RTDB subscription. sqlc never
subscribes — reuses the RTDB live number already powering the list display. Rule
preventing double-count: sqlc owns everything up to but not including the current
list; RTDB owns the current list.

### Decision: Settle-on-close — freeze a list's final count at transition
**Timestamp:** 2026-06-23
When a list stops being current (the manual ~8am transition opens the next one),
the transition job freezes that list's final live prayerCount (from RTDB) into
PrayerList.prayerCount as its permanent settled value. This makes the world-count
historical sum read finalized numbers and lets the client safely add the live
value for only the current list. Added to assembleNextList's responsibilities.

### OPEN: Prayer.listContextNumber (tier-1 personal semantics undecided)
**Timestamp:** 2026-06-23
Personal-only prayers (communityList = null) aren't on the list-number axis. If
tier-1 personal counts/streaks should read as "list cycles I prayed for X" rather
than raw event counts, add a `listContextNumber: Int` (always set) to Prayer.
UNRESOLVED — left undecided rather than silently chosen. Clean additive change
whenever settled. Tier-3 world-count does NOT need it.

### Decision: Signup creates User + self-PrayerSubject in one transaction
**Timestamp:** 2026-06-23
The "you are the first soul" mechanic is true from the first second. Anonymous→
permanent upgrades must LINK accounts (Firebase linking) so souls/history carry
over.

### Decision: Defer usernames, groups, following
**Timestamp:** 2026-06-23
All are clean additive changes. displayName (non-unique) ships now; unique
username added when discovery/social ships. Core schema shaped to accept groups
(nullable groupId/visibility on subjects) without migration pain.

---

## Moderation / Trust

### Decision: The list is curated, not a live feed
**Timestamp:** 2026-06-23
Names are reviewed before being printed/sealed. PrayerList has a status
(draft→published); PrayerListEntry has source ("app"|"social") and
moderationStatus ("approved"|"held"|"excluded") + heldReason. Social-sourced
names (lower trust) get strict profanity/blocklist filtering at assembly; app
users' own subjects are higher trust. Held entries are recoverable, not deleted.
Stated honestly, curation builds trust.

---

## Social / Publishing

### Decision: Social phase is SOULS-ONLY (no free-text intentions)
**Timestamp:** 2026-06-23 (SUPERSEDES earlier "🙏 <intention>" social mechanic)
Dropping the free social intention: (1) keeps social consistent with Model A —
self carried free, others are the app's paid value; (2) better social mechanics —
one emoji is lowest-friction, asking for a written intention sharply cuts
participation; (3) lower moderation risk — removes the free-text injection
vector; (4) intentions want the app's structured UI anyway (freeform comments
can't reliably classify soul vs intention). "Add intentions and the people you
love" becomes the app's opening value proposition, making the app feel like a
gain over social, not a downgrade.

---

## Project Structure

### Decision: Monorepo, with media in Cloud Storage (not git)
**Timestamp:** 2026-06-23 (refines the earlier 2026-04-23 monorepo decision)
One repo for code, text, config, and brand/agent context, with layered
CLAUDE.md files (root = brand-wide; subfolders = workstream). Video/raw media
NEVER in git — Cloud Storage, referenced by manifest. Path-scoped CI so mixed
cadences (slow app store review / continuous functions / daily social) deploy
independently.

### Decision: backend/ folder groups all server-side deploy artifacts
**Timestamp:** 2026-06-23
dataconnect/, functions/, and future rules (database.rules.json, storage.rules)
live under backend/, governed by one firebase.json (deploys run from backend/).
Named "backend" not "firebase" because Firebase usage also spans the app. The
app keeps its own Firebase CLIENT config (firebase_options.dart, etc.) at its
required paths. FCM is not its own folder (it's functions code + app code);
storage in-repo is only storage.rules.
