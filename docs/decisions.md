# +Prayer — Decision Log

Canonical running log. Each decision carries a timestamp. Conflict resolution:
prefer the more recent timestamp; surface ambiguous conflicts rather than
resolving silently.

This file captures decisions. Verbose working-session summaries for agent
ingestion live in `../seeds/`.

---

## Backend / Database

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
