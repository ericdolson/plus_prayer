# SEED: Backend architecture & MVP schema session

Verbose, agent-readable summary of the 2026-06-23 working session that produced
the backend choice, the MVP SQL Connect schema, the freemium model, and the
monorepo structure. Optimized for agent ingestion, not human skimming. Pair this
with the schema at `backend/dataconnect/schema/schema.gql` and the decision log
at `docs/decisions.md`.

## Backend decision arc
Evaluated Firestore vs Supabase vs AWS AppSync, then re-evaluated in 2026 light:
Firestore Enterprise (NoSQL + new search/joins) vs Firebase SQL Connect (managed
Postgres + realtime, formerly Data Connect) vs Supabase. Landed on SQL Connect
for relational fit, native full-text search (kills the Algolia sync the older
Firestore design needed), and per-operation pricing + per-operation `@auth`. Key
billing insight: one operation = one query execution regardless of rows; a query
returning 15 (or thousands of) rows is 1 operation, vs Firestore's per-document
reads. Caveat captured: SQL Connect has TWO bills — the serverless operation
layer AND an always-on Cloud SQL instance (storage auto-grows; compute is a
manual size dial; read pools autoscale on Enterprise Plus). So SQL Connect wins
at relational/read scale; Firestore can be cheaper at tiny scale due to the
instance floor. High-fan-out realtime (presence, live counts) deliberately kept
on RTDB because SQL Connect subscription fan-out billing is the newest/least
documented surface.

## Why SQL Connect's model fit especially well
Queries are defined server-side and invoked by name via a generated typed SDK —
the client cannot run undefined queries. This replaces Firestore's global rules
file (which Eric found painful at scale) with per-operation auth declared next to
each operation. The daily-list problem that plagued the Firestore design (get all
who prayed → fan out to their intentions = N+1 reads or write amplification)
collapses to a single server-side set-based join-and-write that never ships the
rows to a client. Downloading the assembled list to print is a separate trivial
read of one finished table; optionally render a print-ready PDF server-side into
Cloud Storage.

## MVP schema shape (see schema.gql for the authoritative, commented version)
Tables: User, PrayerSubject (unified souls+intentions via `kind`), PrayerList,
PrayerListPost, PrayerListEntry (the assembled, frozen, moderated list),
Prayer (immutable completed history), PrayerSubjectLink (prayer↔subject M2M).
Deferred via clean seams: usernames (nullable @unique later), groups/following
(nullable groupId/visibility + new tables later), intention→soul relation
(nullable self-ref later).

## Freemium model — the load-bearing product decision (Model A)
"Self is the dividend, not a slot." A participant is ALWAYS carried on the list
for free (the reward for praying), pinned top, exempt from includeLimit. Paid
tiers ($20–30/yr target) add slots to carry OTHERS. Chosen over the alternative
("the top-of-list item is the one free slot") because A never forces a user to
choose between themselves and a loved one — the alternative's conversion pressure
comes from a wound, which is the grimmer monetization. A is simultaneously more
profitable and more ethical. Unlimited PRIVATE prayer is always free; only
printed-list slots are gated. The fold UX is reorder-not-toggle (gentler;
non-coercive upsell). Guardrail: keep upgrade prompts humane — never on a fresh
crisis subject.

## Social phase reframed to SOULS-ONLY
Earlier plan let followers comment "🙏 <intention>" for a free printed intention.
Reversed: social is souls-only (🙏 = carry me). Reasons: consistency with Model A
(intentions are the app's paid value), better mechanics (one emoji = lowest
friction; written intentions tank participation), lower moderation risk (no
free-text injection), and intentions need structured UI anyway. "Add intentions
and the people you love" becomes the app's opening value prop → app feels like a
gain over social, not a downgrade.

## Moderation: list is curated, not a live feed
PrayerList.status (draft→published) + PrayerListEntry.source (app|social) and
moderationStatus (approved|held|excluded)+heldReason. Social names get strict
profanity/blocklist filtering at assembly; app users' own subjects are higher
trust. Human review checkpoint fits the manual ~8am transition. Held entries are
recoverable. Curation, stated honestly, builds trust.

## Streaks, names, location
Streaks = consecutive list numbers (no timezone math; missed list breaks streak,
grace addable later). Subjects carry publicName (printed) + personalLabel
(owner-only "Dad"). Prayer carries optional consent-gated lat/long for the user's
own "where I prayed" map now, fuzzable for a global view later (capture now —
unbackfillable).

## Auth
Google + Apple + Anonymous (no email/password). Anonymous→permanent MUST link
(Firebase account linking) so souls/history survive — critical because the anon
user is themselves a soul. Signup creates User + self-subject in one transaction.

## Timing change (supersedes prior memory)
Daily transition is MANUAL, ~8am Eric's time, NOT scheduled (was 9:30pm /
implied schedule). Manual preserves flexibility.

## Structure
Monorepo. backend/ groups all server-side deploy artifacts under one
firebase.json (deploys run from backend/); app keeps its own Firebase client
config. Media never in git (Cloud Storage + manifest). Path-scoped CI. Layered
CLAUDE.md (root brand voice + per-workstream).

## Open / next
- Design the connector operations (queries+mutations) with correct @auth — NOT
  yet done. See backend/dataconnect/connector/README.md for the list.
- Reconcile app-store tagline ("Every faith") to web ("Everyone").
- Later: subscription/billing tables; grace mechanic; groups; usernames;
  global location view; print-PDF rendering.
- Suggested exercise once operations exist: cost model at launch / 10k DAU /
  100k DAU counting BOTH operations and instance tier (turns "magnitudes cheaper"
  into real numbers and finds the Firestore crossover point).
