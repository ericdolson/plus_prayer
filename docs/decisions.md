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

### Decision: A missing-children database is the default base set for daily lists
**Timestamp:** 2026-09-13
Lists are seeded from a missing children's database as a standing base set of
souls to be prayed for, independent of social participation. Consequence for
tooling and reporting: `soul_count` in `publishing/lists.json` is NOT a function
of `pending[N]` in `publishing/participants.json`. The base set can raise the
count on a day when the 🙏 harvest returns zero new participants — List 47
shipped at 4,562 souls against List 46's 4,560 with a 0-participant harvest, which
is what prompted writing this down. A `soul_count` that outruns the harvest is
normal and is NOT evidence of a harvest bug or a dropped participant; only the
reverse (harvested participants missing from the count) warrants investigation.
Caption rule is unchanged and is the thing most likely to be got wrong: the source
note ("filled entirely with the names of missing children from the NamUs database.
May they be found.") belongs only to lists filled ENTIRELY from that source, as
List 1 was. Routine base-set additions carry NO source note — Lists 45, 46 and 47
all shipped without one. See publishing/captions/list-caption-template.md.

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

### Decision: 🙏 on any past post counts; old posts get a closed-state comment
**Timestamp:** 2026-07-03
When a new list goes live, the previous list's pinned comment is updated to point
to the new current list: "List [N-1] is retired — but a 🙏 here still counts. Find
the newest list on our channel/Page/profile." (Wording history: "List [N] is
sealed" was dropped 2026-07-04 — "sealed" collides with the ritual description and
"closed" would contradict a 🙏 still counting. Briefly "a newer list is up now",
then settled 2026-07-05 on "retired": the list is set aside and kept, not destroyed
— dignified, and it reads naturally before "but a 🙏 here still counts". Kept for
the close-out status only, never the ritual description.) The
aggregation pipeline scans ALL past posts nightly, not just the most recent — a
🙏 on any post carries the commenter onto the next list. Rationale: the algorithm
surfaces old posts to new viewers; rejecting late participation would break the
promise and frustrate people who had no way to know the post was old. TikTok posts
are left unchanged (no mechanic to close; caption already redirects to
YouTube/Instagram).

### Decision: Brand voice evolves from "spare/direct" to "spare + subtle human warmth"
**Timestamp:** 2026-07-03 (SUPERSEDES the earlier "no we / no instructed feeling" absolutes)
The original voice banned any collective "we" and any instructed feeling. In
practice that read as cold, and the opposite over-correction (fully warm drafts)
read as fake. Resolved to a middle: mostly facts and restraint, but a quiet
inclusive "we" ("Here, we hold each other") and at most ONE restrained emotional
line per piece ("May they be found") are now allowed. Still banned: hype,
urgency, spiritual-tourism phrases, performed/saccharine warmth, and piling on
sentiment. Locked video-description shape (from List 2 on): (1) define +Prayer and
state the mechanic generally, ending the paragraph on the "the world plus prayer"
pun; (2) the list line + optional source note; (3) ritual + CTA, with the CTA the
final piece. TikTok keeps a 🙏 in the CTA but anchored to YouTube/Instagram
("head to YouTube or Instagram to leave a 🙏"), never implying a 🙏 left on
TikTok counts (comment aggregation is blocked there). Template saved at
publishing/captions/list-caption-template.md; brand-voice section in root
CLAUDE.md updated to match.

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

### Decision: Default publish lead time cut from ~5 min to ~2 min
**Timestamp:** 2026-07-31 (SUPERSEDES the ~5-minute default set when the Threads 409 was found)
Measured `post.published` log timestamps against `scheduled_for` for Lists 21–29.
Two findings drove the change. (1) **YouTube ignores `scheduled_for`** — it publishes
~1–2 min after the create call regardless of the target (List 28: created ~15:47 for
a 15:55 target, live at 15:47:42), so the lead time is exactly how early YouTube
lands ahead of the other four (FB ≈ +1, TikTok ≈ +1, IG ≈ +2, Threads ≈ +3–5 min
after target). A 5-min lead strung the five posts across ~10 minutes and staggered
the pinning work; ~2 min lands them within about a minute of each other. (2) The
**Threads 409 is strictly an artifact of the immediate-publish path**, not a
too-soon-schedule problem — any future-dated instant routes through the scheduler,
which polls sub-minute (Facebook fires +0.8–1.4 min every list). So the lead exists
only as slack for the five create calls, not for the queue. Guard rails, since 2 min
leaves ~75s of slack: compute the target right before the first create (not at the
start of the run), and push it out a minute if it drifts within ~60s of now — a past
`scheduled_for` falls back to immediate publishing and reintroduces the 409.

### Decision: A brand 🙏🏻 follows the mechanic comment on each new list
**Timestamp:** 2026-10-09
Eric holds a prayer while each list is published. `finalize-comments` now posts a
bare `🙏🏻` (no text) as a second comment right after the mechanic comment on
YouTube, Facebook, and Instagram — so the first prayer under the instruction is
ours, and people can see that we pray here too. It is logged as `prayer_id` in
`lists.json`, is never pinned, and is NOT deleted at close-out (only the mechanic
is). It posts from the brand account, so the harvest's brand filter excludes it.
Threads and TikTok get none: the API can't comment on either.

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

---

## Process & Product (2026-10)

### Decision: Current-state product spec lives in docs/product/
**Timestamp:** 2026-10-17
Product, UX, and architecture decisions are consolidated into `docs/product/`,
one current-state file per feature, indexed by `docs/product/README.md`. This log
stays the append-only WHY. Not split by `app/` vs `backend/` because nearly every
feature (auth, streaks, presence) crosses both — split copies would drift.
Subfolder CLAUDE.md files hold build rules only and link to the specs.
Unresolved items are tracked in `docs/product/open-questions.md`.

### Decision: Streaks count calendar days in the user's local timezone
**Timestamp:** 2026-10-17 (SUPERSEDES 2026-06-23 "Streaks = consecutive list numbers")
Duolingo-style day streaks with a "last call" reminder. The list rollover is
manual and follows no user's timezone, so a list-number streak has no clean
deadline to remind against. Details (what counts toward the day, `localDate`
on Prayer, grace/freeze) are PROPOSED/OPEN in docs/product/streaks-reminders.md.
Schema change pending confirmation of those details.

### Decision: A prayer holds the list and/or subjects, or neither
**Timestamp:** 2026-10-17 (SUPERSEDES 2026-06-24 UI rule "community prayer before personal prayers")
Main screen is the user's personal prayer list with today's list pinned as the
top row. Starting a prayer, the user chooses what it holds: the current list,
any of their souls/intentions, both, or nothing (a general prayer). Only prayers
that include the current list earn a place on the next list. Tapping into a
row's detail lets the user start a prayer with that item already included.
Removes the ordering rule and its interim gap; schema already supports it
(communityList nullable, zero-or-more PrayerSubjectLinks).

### Decision: In-prayer UX happens in place (Option B)
**Timestamp:** 2026-10-17
Chosen over a separate quiet screen. Same view, so search/filters persist; halo
+ removed nav mark the mode; rows' `>` becomes a check meaning "holding this one
now", with a subtle sparkle so the act carries weight. Pray FAB gains a ~5s
decaying ring, then becomes Amen; ✕ anytime. The list is NOT pre-checked —
instead, ending a prayer that didn't include the current list opens a quiet,
standalone invitation to hold today's list. Rows: title + one secondary line;
the pinned list row's secondary line shows who will be carried on the next list.
Details marked PROPOSED in docs/product/prayer-flow.md.

### Decision: Intentions are printed as text on the physical list
**Timestamp:** 2026-10-17
Intentions appear on the printed list alongside souls' names, not as a count.
Names and intentions are character-capped; font size shrinks to accommodate
large lists. Raises intention-text moderation at assembly (open).

### Decision: Free tier, reverse trial, and intentions nested under names
**Timestamp:** 2026-10-17 (SUPERSEDES "non-premium intentions are never on the global list")
- Free app prints you + one intention of your own. Social prints only you
  (comment text ignored by design so carrying others is the app's value).
- New users get a ~14-day reverse trial of premium: no card, no auto-renew,
  heads-up before it ends, then settle to free with a gentle invitation.
  Judged generous enough that the end-of-trial change won't feel like a wound,
  provided it is communicated early. Trial history stays visible forever.
- Intentions always live under a name (person, group, or cause — user's choice
  of naming). One level. Add-intention defaults to "For: Me".
- Selection: intention implies its name; name doesn't imply intentions;
  partial state on names.
- Names print together with their intentions; the app previews "your portion"
  exactly as printed. Single copy, never shared — privacy/terms statement needed.
- Character caps: 40 (name), 80 (intention). App user's social 🙏 carries only them.

### Decision: Premium = pool of carried names/intentions; trial-end and over-limit flows
**Timestamp:** 2026-10-17
Paid capacity is a pool counted per name or intention (not "lines" — printing
word-wraps). Managed on a "your portion" screen with an illustrative preview.
Over-selecting is allowed (e.g. 17/15 + upgrade mark); saving invites upgrade.
Reverse trial = 14 days, heads-up ~day 10; at the end, invite to subscribe
first, then trim-to-free selection, with a second invitation if still over.

### Decision: No silent carry choices; auto-carry while room remains
**Timestamp:** 2026-10-17
Over-limit save + declined upgrade → save blocked, user trims. New items are
auto-carried while the pool has room; once full, new items are private-only and
visibly marked as not on the list.

### Decision: Answered vs Release; answered intentions are not list-eligible
**Timestamp:** 2026-10-17
Resolving an intention: Answered (leaves the global list, stays on the user's
main view for gratitude prayers until archived) or Release (no gratitude
implied, auto-archived). An anonymous answered count may appear on the list and
in captions once numbers are meaningful.

### Decision: Onboarding is anonymous-first with a personal "What's your name?"
**Timestamp:** 2026-10-17
Flow: splash → plain mechanic line → "What's your name?" (becomes the
self-subject "Me", with helper text that their name will be carried by the
world) → optional "who else do you hold?" → main screen → after first Amen:
carried confirmation, reminder choice, notification permission. Trial starts at
first prayer. Sign-in prompts after first prayer, ~3-day streak, before trial
end. Account deletion is immediate; past entries lose name/owner, counts stay.
Names are never legible in recordings.

### Decision: Pay before sign-in; self-name edit limit; aliases
**Timestamp:** 2026-10-17
Purchasing never requires sign-in; a sign-in prompt follows purchase. Self-name
edits are free until first printed, then once per 7 days. One name field for the
user. Every name has an optional owner-only alias (self = "Me"); the real name is
printed and is what future group members see.

### Decision: ExternalPerson for non-app names; backfill and pre-launch cutover
**Timestamp:** 2026-10-17
Social 🙏 commenters and the NamUs base set are `ExternalPerson` rows; list
entries reference a subject or an external person (exactly one). List history
is backfilled from publishing JSON so numbering is continuous, and the
harvest/publish pipeline moves to the DB before launch. Resolved NamUs cases
leave the base set quietly.

### Decision: Presence via a throttled public counter
**Timestamp:** 2026-10-18
One "praying now" number for any prayer, count only. Live count shown at ≥10,
otherwise a time-window count; never show 0. Raw `/presence/{uid}` is private;
a server process aggregates and republishes one small public RTDB node about
every 5s (plus the last-hour prayer count) so presence churn doesn't fan out to
every client.

### Decision: Streak rules
**Timestamp:** 2026-10-18
Any prayer ≥5s counts for the user's local day (`Prayer.localDate`). One grace
day is earned per 7 consecutive days, max one held, auto-used on a miss, never
sold. A strict-streak setting disables grace, with a one-time explainer.
Last call ~8pm local if not prayed. Quiet milestones at 7/30/100/365.

### Decision: Grace days are offered, accepted, and banked (up to 3)
**Timestamp:** 2026-10-18 (SUPERSEDES earlier same-day "one grace day + strict setting")
Every 7 actually-prayed days the user is offered a grace day; accepted ones bank
up to 3. No strict setting — declining offers "Don't offer again". Bridged days
don't earn grace; each missed day consumes one; streak breaks when the bank runs
out. Never sold. Stays close to Duolingo's proven pattern.

### Decision: Grace bank cap starts at 2
**Timestamp:** 2026-10-18 (refines "banked up to 3")
Start at 2, close to Duolingo's market-tested cap; raising to 3 later is
generous, lowering would feel like a takeaway. Cap and interval live in Remote
Config. Full bank still gets a quiet 7-day acknowledgement.

### Decision: MVP notifications and self-hosted video
**Timestamp:** 2026-10-18
Only server push at MVP is an opt-in "Today's list is live". Reminders, last call
(only if not prayed at all that day), and the trial notice are local. List video
is self-hosted on Firebase Storage to start and plays full-bleed on the list
detail page; optimize hosting later if egress grows.

### Decision: Wax seal as the list row avatar; sealVariant stored
**Timestamp:** 2026-10-18
The pinned list row uses the day's wax-stamp vector (unsealed until published).
`PrayerList.sealVariant` is stored and set at publish from the current
weekday→color mapping, so changing the rotation later costs nothing.

### Decision: Morning admin flow and moderation
**Timestamp:** 2026-10-18
Assemble → review flagged → print → publish, via admin-only Cloud Functions
called by existing Claude skills (no console at MVP). Auto-flags: profanity,
PII/links, frequent self-name changes (not all-caps, not new accounts). Users
see "Held for review" / "Not printed". The skill keeps generating the print PDF,
now from DB data; server-side PDF later so others can help.

### Decision: Faith positioning — open brand, familiar ritual words
**Timestamp:** 2026-10-18
Brand and store stay faith-agnostic ("One list. Everyone. Every day." everywhere,
retiring the "Every faith" store variant). In-app ritual language keeps familiar,
widely used Christian-rooted words (Amen, grace day). No explicit Christian lean.

### Decision: Printed-list privacy and account age
**Timestamp:** 2026-10-18
Retired lists are kept forever, sealed, in a locked filing cabinet at the office.
Helpers may handle lists later under a confidentiality agreement. Accounts are
13+; child accounts possibly later. Policy leads with a plain-language summary,
drafted via a generator and reviewed by a lawyer before launch.

### Milestone: Staged roadmap drafted
**Timestamp:** 2026-10-18
docs/product/roadmap.md now holds Stages 0–4 with a tagged checklist built from
the 2026-10-17/18 product meetings.

### Decision: Notes yes, location later, manual order, keep list videos
**Timestamp:** 2026-10-18 (location SUPERSEDES 2026-06-23 "capture from day one")
Optional private prayer note after Amen at MVP. Location capture deferred past
MVP (accepting no early data). Main list order is manual drag (names and
intentions within a name); filters handle "unprayed". Past list videos are kept.

### Decision: Last call at 8pm; guided prayer post-MVP
**Timestamp:** 2026-10-18
Last call ~8pm local (less intrusive than the seed's 9pm). Guided prayer ("Help
me pray") is a post-MVP premium feature; schema seams (`Prayer.mode`,
`User.prayerVoice`) added now.

### Decision: List gate = since last flip OR within ~30 hours
**Timestamp:** 2026-10-18 (supersedes seed 2026-10-11 "48h rolling window" proposal)
Carried if the user prayed with the list since the last flip, or within ~30h of
assembly. Covers manual flip variance and near-flip pray-ers without letting
every-other-day prayer keep someone on every list. Streaks stay independent of
being carried.

### Decision: Bead-strand history; streak in the header
**Timestamp:** 2026-10-18 (SUPERSEDES seed 2026-10-11 v3 line timeline and outcome recording)
Detail-page history is a strand of beads — one per list the item was on, in that
list's wax color — with neutral "Off the list · N days" gaps and counts-only
personal prayers, plus note/answered hints on period rows. Built entirely from
existing tables; no per-assembly outcome records. The streak badge sits beside
the header avatar; "carried on N lists" lives on Today's list page.

### Decision: In-progress prayer drafts live in RTDB; prayer time shown plainly
**Timestamp:** 2026-10-18
Drafts (per device) live in the RTDB presence node with a heartbeat; the Prayer
row is written once at Amen, or by a 6h auto-save job with an estimated duration
(last foreground + ≤30 min, 4h cap, `endedBy = AUTO`, shown with "~"). Back
within ~30 min resumes quietly; later asks. Prayer time appears per prayer and
in the History header, never on detail pages, never ranked.

### Decision: The streak counts days with the world
**Timestamp:** 2026-10-18 (SUPERSEDES same-day "any prayer ≥5s counts for the day")
The single streak counts local days on which the user prayed with the list. The
community is +Prayer's offering; streaking any prayer would make it like every
other app. This restores "keep your streak = stay carried" and aligns the habit
with what premium sells. Personal-only days are acknowledged with hollow marks
and a "Days in prayer this month" count — not a second streak. Last call fires
only if the user hasn't prayed with the list today (two wordings).

### Decision: Badge states, avatar clusters, notification privacy
**Timestamp:** 2026-10-18
Streak badge is always visible (muted when not yet today; no number at zero) so
the sheet is always reachable. A shared avatar-cluster component names who's on
the list wherever "the list" appears. Notifications may show names/aliases by
default but never intention text (except moment reminders' own words); a
"Show names in notifications" setting (default on) allows blank reminders.

### Decision: Language, future groups shape, list scope, analytics
**Timestamp:** 2026-10-18 (groups part SUPERSEDES 2026-06-23 "nullable groupId on subjects")
UI follows device language with override; `User.locale` stored; caps count
visible characters; print fonts cover all scripts. Future groups use a share
table (one item → many groups or PUBLIC), families/churches/denominations are
group types, prayers may link to others' shared items with op-level permission.
`PrayerList.scope` (GLOBAL default) added as a cheap seam. Analytics events and
a minimum-app-version flag ship from day one. "In memory" state noted for later.

### Decision: Personal practice is free at any size
**Timestamp:** 2026-10-18 (reconfirms 2026-06-23 "unlimited personal prayer always free")
No private limit on names or intentions. Growth matters most; private names are
the pipeline for paid carrying, and a private cap would read as charging to
remember people. Only a ~500-name abuse safety cap exists. Large personal lists
(e.g. pastors) point to the future group/organization product.

### Decision: Answers to the first backend schema review
**Timestamp:** 2026-10-18
Streak fields stored on User (`lastListLocalDate`), prayers dated by local start,
grace consumed lazily, display computes effective streak. Free = 1; pool = all
carried beyond self; `basePremiumPool = 10` shared by trial and base tier;
expired entitlement computed as free with a ≤7-day trial-end soft landing.
`PrayerList.closesAt` (set ~5 min ahead by Eric, in-app banner, no push) makes the
cutoff exact: prayers started before it count. Aggregates (`prayerCount`,
`prayerSeconds`, `DailyStats`) are incremented on write so deletions never reduce
them; account deletion removes entries. `setSelfName` creates the self subject;
onboarding resumes by state; `mergeAccounts` offered on link conflicts with a
duplicates warning. Effective carry = intention && parent; cascades on archive.
Moderation fields become enums with four user-facing reason categories.

### Decision: Client config in RTDB /config, not Firebase Remote Config
**Timestamp:** 2026-10-18 (SUPERSEDES earlier same-day references to Remote Config)
Firebase Remote Config moved to usage-based pricing on 2026-09-01 (free plan
capped at 100k fetches/day; beyond that metered). Tunable client values (grace
cap/interval, presence threshold, min app version) live in a public-read,
server-write RTDB `/config` node with app-compiled defaults — already in the
stack, offline-cached, live. Enforcement stays server-side. Revisit Remote Config
only for A/B tests or audience targeting.

### Decision: Answers to the backend implementation review
**Timestamp:** 2026-10-18
Approved backend choices (RTDB /config, server-function writes for pool/caps,
`Prayer.countedAt`, no auth.uid default). Setting `closesAt` creates the N+1 list
row so post-cutoff prayers count toward N+1. Late-synced offline prayers repair
the stored streak. Grace offers count within the current streak. Restoring a
Released intention reopens it. Social names truncated to 40 graphemes; blocklist
seeded from an open multilingual list. Moderation exclusions enforced in
server operations. "List is live" push: "List 52 is up · 4,345 people,
including you."

### Decision: Gate counts only prayers started before the cutoff
**Timestamp:** 2026-10-18 (refines the "since last flip OR within ~30h" gate)
The 30h window is bounded to before `closesAt`, so a prayer after the cutoff
counts only for N+1 and can't earn two lists. "List is live" push drops
"including you" because it is a broadcast. Name-like words removed from the
blocklist seed.

### Decision: Beta moderation — block contact info at input, invisible pending, exception-based review
**Timestamp:** 2026-10-18 (refines the 2026-10-18 auto-flag and "Held for review" decisions)
Phone numbers, emails, and links can't be saved in names/aliases/intentions at
all (app + server). Pending review is never shown to users; anything Eric doesn't
exclude prints. The morning skill takes an AI first pass over the new/changed
diff. Exclusions are shown gently after assembly with an edit path. The word
blocklist is switched off until public launch. AI moderation processing is
disclosed in the privacy policy.

### Decision: Aliases are not moderated
**Timestamp:** 2026-10-18
Aliases are owner-only, never printed or shared, so they skip the contact-info
input block, the blocklist, and the morning AI first pass. Only printed text
(names, intentions, the self name) is moderated.

### Known gap logged: safety handling for self-harm and threats
**Timestamp:** 2026-10-18
Self-harm language is never blocked; a gentle on-device resource card (988 /
international directory) is planned for Stage 2. Threats toward others are not
printed and are prohibited; credible imminent threats and child-safety content
follow an internal policy (law enforcement / NCMEC). Beta covers terms, privacy
disclosure, internal policy, and AI first-pass flags; resource card and lawyer
review close the gap before public launch. Tracked in docs/product/safety.md and
open-questions Q28.

### Decision: Home visual design and color system
**Timestamp:** 2026-10-23 (SUPERSEDES: unprayed dot, one-line row status text,
carried mark on rows, chevron→checkbox, pinned list row, floating presence line,
header search icon)
Design review of the first Home build. Direction: minimal, modern, expensive.
The "darker/antique" principle is scoped to the physical ritual and on-camera
objects; the app UI is clean and modern in light and dark themes. Color by
meaning: brand blue = action (dark-mode glyph on #5AA9FB for contrast), gold =
held (rings, intention end-dots, halo, Answered, carried avatars after praying),
everything else neutral. Rows mark presence not absence: held-today gold ring
until local midnight; no unprayed dot or "last prayed" text; no chevrons; no
carried badges. Intentions in smaller system sans on a neutral thread from the
avatar, left-aligned with names, tappable to their own page. The list row
becomes a flat tonal community card (scale, presence, carry status; cluster
lights gold after praying; checkable in prayer). System font for body (SF Pro
on iOS), serif for names/list numbers/big lines; 20pt margins, no dividers;
translucent bars; one thin-line icon set; one signature motion (Amen → seal),
springs only on checks; pull-down search. Full spec: docs/product/design-direction.md.

### Decision: Dark-mode action blue and a darker dark ground
**Timestamp:** 2026-10-24 (REVISES the 2026-10-23 "Home visual design and
color system" tokens)
In dark mode the action blue goes back to the brand electric blue `#0580F9`
with a white glyph (the pray button as it was before the review), replacing
`#5AA9FB` with a near-black glyph. White on `#0580F9` is 3.8:1: enough for the
glyph and large text, so labels on blue stay large/bold. The dark ground moves
about halfway to black (`#1D2124` → `#0E1012`), closer to iOS and Gmail dark,
but not pure black (OLED smear; the frosted bars and gold glow need something
to read against). Surfaces keep clear steps above it (card `#1A1D21`, raised
`#23272D`), and sheets/dialogs lift slightly (`#16191D`). Light mode unchanged.
Spec: docs/product/design-direction.md §1.

### Decision: Community card — day-scoped gold border, two-line status, solid rings
**Timestamp:** 2026-10-24 (refines 2026-10-23 card decision; replaces gold rims on cluster avatars)
Praying with the list today (local day) gives the card a thin gold border,
cleared at local midnight — one clock with the streak and row rings, so a
prayer for the same list yesterday never looks like today's. Cluster avatars
stay plain. Avatar row = yours on today's list; a separate status line speaks
about tomorrow, computed from the gate ("They'll be on List 53" / "Your next
prayer carries them onto List 54" / "Pray to carry them onto List 53"); only
differences are named. No extra "held yesterday" icon. Name rings are always
solid — no dashed partial state (intention dots show detail). Non-breaking
space in "List N".

### Decision: Bright avatar palette
**Timestamp:** 2026-10-27 (SUPERSEDES muted/antique avatar tones)
Avatars use bright, saturated mid-tones with white initials for a modern,
premium feel and at-a-glance recognition; the sacred palette lives on the wax
seals and the future prayer experience. Excluded: gold/amber/yellow (collides
with held), blues near the action blue, true red. 12–16 tones, ≥3:1 white
initials, mapping frozen after launch. Spec: design-direction.md §1b.
_Same day:_ 16 tones final (three tuned, plus fuchsia, sienna, forest), ordered
so hash neighbors differ; initials white at 80% so letters lightly take the
tone, with olive darkened to `#5F9133` to keep 3:1.

### Decision: No static glow on held rings, dots, or the card border
**Timestamp:** 2026-10-27 (revises the 2026-10-23 "glow in dark mode" detail)
With the bright avatar palette, the static gold glow muddied edges and read as
cheap. Held rings, intention dots, and the community card border are crisp gold
in both themes. Glow is kept only for the prayer-mode screen halo and a brief
(~300–400 ms) bloom when something is checked, which settles into the crisp ring.
_Same day:_ the community card's held mark is the name ring itself (2 pt gold,
2 pt gap, same fade and bloom) drawn around the card, replacing the 1.5 pt
border at 70–80%, so checking the card feels like checking a name.

### Decision: Home polish round — spacing, floating bar, search, avatar grouping, checkedAt
**Timestamp:** 2026-10-27 (revises 2026-10-23 footer and pull-down search)
Tight spacing within a name's group and generous between groups; intentions one
step smaller; header avatar ~32 pt. Bottom bar becomes a floating translucent
pill (History · Search · Add) with a separate same-height pray button on the
right; in prayer the pill becomes time · with N · ✕ and the button becomes Amen.
Search opens from the pill, docked above the keyboard (above the prayer bar while
praying), replacing pull-down search. Pull-down encouragement deferred. Card
cluster: grouped overlapping avatars first; >5 people uses 4 avatars + a gray
"+N" disc and count-free text; the count appears exactly once. Seal art deferred
to its own task. `PrayerSubjectLink.checkedAt` added as a data seam; no per-item
prayer time in the UI.

### Decision: Answers to the app agent's Home polish workarounds
**Timestamp:** 2026-10-27
Intention rows use a ~40 pt pitch (tap target) instead of 2–4 pt gaps —
small type carries the tightness. History is an icon with accessibility labels.
Prayer bar "with 229" (screen readers: "praying with 229 others"). Light-mode
"+N" disc uses `hairline` fill. One shared cluster component everywhere incl. the
invitation (larger avatars allowed there). While typing, the docked search row
carries a compact pray/Amen button so Pray is always reachable. Cluster avatars
at 24 pt show a single initial (≥11 pt) or color only. App sends `checkedAt` per
checked item once the regenerated SDK includes it.

### Note: Prayer groups UI direction (future)
**Timestamp:** 2026-10-28
A group appears on Home as a top-level row (group picture + name) with members'
shared items threaded beneath, each showing the sharer's small avatar. Prayers
log to the member's item. Any item may be shared (not only under "Me"), with an
optional group-facing label chosen at share time (future `Share.displayLabel`)
and a confirmation of what the group will see. Value: tier-2 counts, "Mom prayed
for…" pushes, shared Answered moments. Sharing never changes printing. Not built;
see docs/product/groups-design-note.md.

### Decision: Sans avatar initials, blue pray button, dark-mode neutrals
**Timestamp:** 2026-10-28
Avatar initials use the body sans (medium/semibold, ~40% of diameter) so they
don't compete with serif names. The pray button stays action blue (dark/gold
reads disabled and misuses gold). Dark mode keeps a faint, single-hue cool tint
on surfaces but neutralizes the ink toward ~#E8EAED; confirm on device with a
temporary 3-way toggle (current / pure gray / tinted + neutral ink). Card status
text runs full-width rather than wrapping beside the cluster.

### Decision: Dark mode uses neutral ink on tinted surfaces
**Timestamp:** 2026-10-28
Chosen on device from the 3-way comparison (current blue ink / pure gray /
tinted surfaces + neutral ink): tinted surfaces + neutral ink. Dark `ink`
#E8EAED, `inkMuted` #9A9EA4, `inkFaint` #6C7076, all on the surfaces' hue; the
temporary toggle is removed. See design-direction.md §1c.

### Decision: Inline filters, cancel in the header during prayer, intention legibility
**Timestamp:** 2026-10-28
Filter icon expands chips inline in the header (scrolling, with ✕); an active
filter stays visible as a neutral chip with ✕. In prayer, cancel moves to the
header top-left (confirmation over ~30 s) and the pill keeps search; the
praying-hands header icon is removed. Intentions get ~7:1 contrast / regular
weight; "Answered" is never larger than its intention.

### Decision: Scroll edges instead of a frosted header; controls on glass
**Timestamp:** 2026-10-28 (revises the frosted header bar)
Following iOS 26, Home's header has no slab or divider: the list blurs and dims
into the top of the screen on one smooth curve with no visible start or end,
sharp again by the header's bottom. A separate, independently tuned edge does
the same under the floating bar. The blur stays slight so text beneath stays
readable. The streak badge, filter, pill and search field float on their own
rounded glass; the pray button stays solid blue. Where blur isn't supported,
the edges are the dim alone. Values tuned on device. See design-direction.md §4.

### Decision: Filter menu + single active chip; "Cancel" as text in prayer
**Timestamp:** 2026-10-28 (REPLACES the same-day inline chip row)
The filter icon opens a small anchored pull-down menu (All / Unprayed today /
Carried, checkmark). An active filter shows as one chip replacing the icon, with
the × inside it (× clears; label reopens the menu). Prayer-mode cancel is a text
"Cancel" button top-left (confirm over ~30 s), so it can't be confused with the
chip's ×.

### Decision: Filter menu labels, counts, and linger-then-fold
**Timestamp:** 2026-10-28
"Unprayed today" becomes "Still to hold" (menu and chip). "Carried" stays plain,
without a list number. No menu icons. The menu shows muted counts on all three
options, with a gold check when Still to hold reaches zero (progressive
disclosure for people who like a to-do feel; never on the main screen). Empty
state: "Everyone's been held today." Under the filter, held rows linger with
their ring ~1–1.5 s after Amen before folding away. Custom menu keeps menu
accessibility semantics.

### Decision: Community card follows filters; Carried teaching helper
**Timestamp:** 2026-10-28
The card shows under All and Carried, under Still to hold only until the list
is held today (then lingers and folds), and hides during search. When Carried
shows only the user's own items, a quiet helper explains carrying and links to
Your portion — explanatory, never an upgrade prompt.
