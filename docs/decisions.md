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

### Decision: Search empty state with add shortcut
**Timestamp:** 2026-10-28
No results shows 'No one named "{query}" yet.' with [Add "{query}"], opening the
add sheet prefilled as a name. Archived matches appear with Restore. In prayer
mode, only the line shows.

### Decision: Search empty state copy handles partial queries
**Timestamp:** 2026-10-28 (revises same-day copy)
'Nothing matches "{query}".' with [+ Add someone], opening the add sheet with the
query prefilled and the cursor at the end; shown after a ~500–700 ms typing pause.

### Decision: Search empty state accounts for an active filter
**Timestamp:** 2026-10-28
If a filtered search finds nothing but All has matches: 'Nothing in "{filter}"
matches "{q}". N matches in All.' with [Show all] (clears filter, keeps query).
If nothing matches anywhere: the normal empty state plus a quiet "Clear filter".

### Decision: One search empty state; filter extra in a glass card
**Timestamp:** 2026-10-29 (supersedes the two 2026-10-28 filter/copy entries above)
Every no-results case uses the same layout: one line 'No matches for "{q}"'
(query truncated with "…", never wraps) + a blue [ + Add ] (prefilled add sheet,
name by default). When a filter hides matches, a one-line glass card below adds
'N match(es) in All   Show →' (Show clears the filter, keeps the query). When
nothing matches anywhere, no card and no "Clear filter" link.
Why: the two screens felt like different experiences; the filtered copy wrapped;
"Clear filter" was a dead end when All has no matches; "+ Add someone" read as
people-only though the sheet also adds intentions.
Rejected: showing the hidden rows inside the card (uncommon; Gmail/Slack/Mail
show a count + scope link instead; crowds a calm screen); "Show all" as the
primary pill in the filtered case (inconsistent primary); "+ Add '{q}'" (reads
oddly for partial queries, rejected 2026-10-28); "+ Add name or intention" (too long).

### Decision: Glass only for floating controls; match hint on cardSurface
**Timestamp:** 2026-10-29 (revises the same-day search empty state entry)
Glass is reserved for controls floating over content (streak badge, filter,
pill, docked search field); in-content containers (community card, search match
hint) are flat `cardSurface` with a softer, non-capsule radius. The "N match in
All · Show →" hint moves from glass to `cardSurface`, radius ~16 pt, and the
whole container is the tap target (one action, one accessibility button).
Why: on glass the hint read as a second search field; the community card was
already the right model. Whole-container tap: single action, larger target.

### Decision: Carried mark on rows; streak badge becomes the wax stamp
**Timestamp:** 2026-11-01 (revises 2026-10-23 "no carried badges" / "small mark
if carried" removal)
A tiny neutral glyph trails every carried name and intention on Home (same set
as the Carried filter; intention = intention ∧ name). It means "carried", not
"on List 52" or "staged for List 53": the gate is per user, so per-row timing
would repeat the community card's line on every row, and the only per-item
differences (edits since the flip) are already named on the card. "Me" is
marked too. Private items have no mark (absence is never marked). For now the
glyph is the logo glyph the streak badge used; a bloom without the "+" is a
later design to-do (open-questions D1). The streak badge switches now to the
day's wax stamp (`WaxSeal`), so the two don't read as the same thing.
Why: without a mark, a long list where only some items are carried was
unreadable except through the Carried filter (e.g. "Rest for his heart" under
a carried Dad).
Rejected: a leading mark (collides with the gold held dot, breaks alignment);
two states for current vs next list (unreadable at font size; competes with
gold = held); marks only when a list is mixed (the meaning would flicker as
items are added); marking private items instead (absence marking); gold or
blue mark (gold = held, blue = action).

### Decision: Carried mark is a quiet background mark, below 3:1
**Timestamp:** 2026-11-01 (revises the same-day carried mark entry's
`carriedMark` = `inkFaint`, ≥3:1)
`carriedMark` gets its own value halfway between `thread` and `inkFaint`:
dark `#53585E` (2.7:1 on ground), light `#A6B4C6` (1.8:1). The mark is a
secondary cue, like the thread: noticed when you look, not scanned for. The
Carried filter is the reliable way to see what's carried; screen readers hear
", carried".
Why: at `inkFaint` the filled glyph read too loud beside the names.
Rejected: tying it to `thread` (1.8:1 dark, 1.4:1 light: nearly invisible in
light at 9 pt, and retuning the thread would silently move the mark); keeping
≥3:1 and quieting it by size or shape instead (may revisit with the D1 bloom).

### Decision: One symbol, two materials — ink bloom = carried, wax bloom = sealed
**Timestamp:** 2026-11-01 (refines the same-day carried mark entry)
The bloom is the only brand mark on Home. Flat neutral ("ink") on rows means
carried — this will be printed. Pressed into the day's wax, it is the seal on
the community card and the streak badge — an event (the list was sealed; you
sealed your day). The 7 wax-stamp vectors become the bloom in wax, replacing
the circled-"+" placeholder (design to-do D2).
Why: the placeholder stamp (circled "+") and the row bloom read as two
competing marks for "+Prayer". Matches the ritual: names are printed in ink,
the whole sheet gets one seal.
Rejected: wax on rows for items on a sealed list — on paper names aren't
individually sealed; the row mark is a standing choice, not a dated record
(that record is the bead strand, already in wax colors).

### Decision: Streak badge is a neutral pewter seal; the number carries the state
**Timestamp:** 2026-11-01 (revises the same-day "streak badge becomes the wax stamp")
The badge uses the stamp shape unwaxed, in pewter (`inkMuted` + relief), never
gold or a wax color. Prayed today → number in `ink`; alive, not yet today →
number in `inkMuted`, seal dimmer; zero → dim seal, no number.
Why: in the build, the badge repeated the card's gold seal right above it —
duplicative and loud, with the card's gold border already saying "prayed
today". And the clocks don't match: the badge clears at local midnight but the
wax changes at the flip, so a colored badge would either show a retired list's
wax after the flip or claim a new list not yet prayed. Wax color belongs to
lists (card, Today's list, beads), never to the user.
Rejected: today's-weekday wax (mismatches the list's wax across time zones);
the wax of the last list prayed (stale after the flip); switching to the new
list's wax at the flip (claims a list not yet prayed); gold (gold = held, and
the card border already holds that signal).

### Decision: Community card redesign — stamp in the corner, two blocks, three-ish lines
**Timestamp:** 2026-11-02 (supersedes the 2026-10-27 cluster layout and the
"only differences are named" card lines)
The card answers two questions: is the list alive (world) and are my people
going onto the next list (you). World block beside a large day's seal (~104 pt,
cropped ~75% into the top-left corner): "List 52" with a live "● N praying"
marker on the right of the title row (hidden in prayer mode — the pill shows
"with N"), then "N people · N prayers" in words (numbers `ink` tabular, labels
`inkMuted`; changed digits crossfade). You block full width: carried people's
avatars filling the width (+N only on measured overflow), then one status line.
The closing notice replaces the status line.
Why: seven lines of text made the card busy. The differences lines are now
redundant with the carried mark on rows; "are on List 52" repeated what the
avatars show and isn't actionable. The prayer count stays because every prayer
for the list holds everyone on it — your people's number. The cropped stamp
gives the app's most valuable surface a distinctive anchor and stages the
Amen stamp moment.
Rejected: icons for the counts (person / praying hands, even neutral) — reads
as engagement metrics, and the hands should stay a verb; an intention count on
the card (Today's list has it); presence on its own line or outside the card;
a fixed 4-avatar cap.

### Decision: Community card — answers to the app agent's build questions
**Timestamp:** 2026-11-02 (refines the same-day card redesign)
- Avatar row always shown (you're always carried); only-you copy: "Pray to be
  on List 53" / "You'll be on List 53" / "Your next prayer puts you on List 54".
- Presence lower rungs: no dot (dot = now), keep the verb — "640 prayed this
  hour", "4,113 prayed today"; hide the marker if it can't fit whole.
- Unsealed seal: unpressed neutral blank (`raisedHigh` + relief) with a faint
  debossed bloom; no dashed ring, no circled "+".
- Bloom kept visible by rendering wax body and impression as separate layers
  (impression centered on the visible part); D2 art to ship as layers.
- Monday navy accepted as distinct from action blue; gold border beside
  Sunday's gold wax to be checked on device.
- Changes ("joins" / "isn't carried") are named only in Your portion; the
  earlier "named at the Amen invitation" was a spec error.
- Closing notice when only you are carried: "List 52 closes in 3 min · pray to
  be on List 53"; no clock icon.
- Long text: never shrink below the user's type size; status may wrap to two
  lines (no mid-sentence "…"); counts wrap at the middle dot; presence hides
  first; at accessibility sizes the world block may drop below the stamp.
Rejected: hiding the avatar row when not on today's list (hides it from anyone
who skipped a day); "640 this hour" (verbless, reads as live); truncating the
status with "…" or shrinking the counts (breaks Dynamic Type).

### Decision: Community card — first-build tuning
**Timestamp:** 2026-11-02 (refines the same-day card redesign)
Stamp crop deeper (offset ~−36 pt left / ~−32 pt up, ~65% visible; bloom kept
on the visible part via separate layers). Presence moves from the right of the
title row to its own left-aligned third line beside the stamp ("● N praying
now"). Status line weight follows state: `ink` until covered, `inkMuted` once
covered. Card avatars 24 → 28 pt. Status sits ~6–8 pt under the avatars;
bottom padding equals top (~20 pt).
Why: on device the right-aligned marker floated on a different baseline and
broke the left column, while the space beside the stamp under the counts sat
empty; the avatars read tiny beside 44 pt rows; the stamp crop wasn't decisive
enough; the done-state sentence competed with the gold border.

### Decision: Community card — second round of build answers
**Timestamp:** 2026-11-02
Unsealed body uses the existing `unsealed` token (kept), not `raisedHigh`;
until D2 it shows the stamp image's own impression (with its "+") in that
neutral. Until layered art exists, use the full deeper offset anyway — outer
petals may clip, but the bloom's center must stay visible. Status line wraps
with no cap (no "…"). World block moves below the stamp when the title or
either count can't fit on one line beside it.

### Decision: Community card — third round of build answers
**Timestamp:** 2026-11-02
Prayer-mode checkbox stays in the trailing slot, aligned to the title line (like
a row's checkbox to its name). Card avatars use the same initials as their row
avatars ("DK", "D", "EO"), ≥11 pt, since single initials collided (Dad / Daniel
Kim). Dark theme only: stamps get a ~1 pt rim light on visible edges and a
modest body lift, since most ritual waxes sink into the dark card; light theme
and wax identities unchanged. Status gap stays 8 pt; padding was already
equal (the imbalance was optical — no change).

### Decision: Dark-theme wax separation — scope and details
**Timestamp:** 2026-11-02
The rim/lift lives in the `WaxSeal` component, so every seal on a dark surface
gets it (card, Amen invitation, Today's list); beads under ~24 pt get the lift
only. Even rim accepted until layered D2 art allows a directional one. Sunday's
gold gets no lift (keeps it apart from the held border). The unsealed blank
gets a subtle neutral rim, no lift.

### Decision: Community card — stamp crop and avatar overlap retuned
**Timestamp:** 2026-11-02
Stamp crop targets ~70% visible, tuned by outcome (whole bloom center and most
petals visible), starting near −24 / −20 pt; the −36/−32 build hid too much.
Card avatar overlap ≤ ~4–5 pt so two-letter initials ("EO", "DK") aren't
covered; the full-width row has room.

### Decision: Photographed wax seals at large sizes (planned)
**Timestamp:** 2026-11-02
Eric will shoot macro photos of each weekday's stamp (plus an unsealed blank),
cut out with transparency, and bundle them for large seal sizes (≥ ~40 pt:
community card, Today's list, Amen invitation). Vectors remain for small sizes
(beads, pewter streak badge). `WaxSeal` keeps its API and chooses by size. Shoot
guide in design-direction §6. Later, the day's own ritual seal can replace the
set.
Why: the seal is the real on-camera object, which the design scopes as the
place for the physical/antique look; one photographed object in a flat UI
reads premium; it makes "ink vs wax" literal; real highlights separate dark
waxes in dark mode better than a drawn rim.
Rejected: photos at small sizes (turn to mush); mixing a vector unsealed blank
with photo seals; photographic textures anywhere else in the UI.
Not yet built: no app work until the photos exist (open-questions D3).

### Decision: Prayer-mode halo kept; behavior tuned
**Timestamp:** 2026-11-03
Keep the gold screen-edge halo (originally inspired by the Siri edge glow). It
fades in (~400 ms) on start and out on cancel/end; at rest it is nearly still
(at most an ~8 s breath, opacity ~0.65 ↔ 0.85); it flares once with the Amen
seal stamp; inward blur ≤ ~12 pt to keep the pill/Amen corners clean; fully
static under Reduce Motion. Spec: design-direction §7–§8.
Why: it is the clearest "you're in prayer" signal and fits gold = held;
keeping it nearly still protects Amen → seal as the one signature motion,
avoids reading as Siri, and saves battery over long sessions.
Rejected: top-edge-only glow (too easy to miss); full-background warm tint
(washes neutrals, weakens gold = held); glow only on the prayer pill (loses
the sense of a set-apart space).

### Decision: Prayer-mode halo — build answers
**Timestamp:** 2026-11-03
Session end = the final Amen (FAB Amen, or the invitation's Amen when shown);
the halo stays through the invitation and is gone before the closing phase.
Flare on the final Amen only: ~500 ms, opacity → 1.0 and reach ~1.3×, then the
~400 ms fade-out begins (fade waits for flare). Flare starts at the Amen tap
until a seal-stamp animation exists, then retimes to stamp impact via one
tunable offset. Fade-out ~400 ms on both cancel and end. The ≤ ~12 pt limit is
the visible reach from the edge at rest; the flare may exceed it briefly.
Reduce Motion: static at ~0.75.
Why: a flare that plays while fading reads as nothing, so they run in
sequence; opacity alone (+0.15) is too subtle to register, so the flare also
widens briefly; 0.75 sits mid-breath so the static halo matches what others
see on average rather than its peak.

### Decision: Prayer-mode halo — second round of build answers
**Timestamp:** 2026-11-03
Supersedes "gone before the closing phase" from the earlier entry today: the
closing sheet and Still-to-hold fold start immediately at Amen; the ~900 ms
flare + fade play beneath them. Any Amen that commits a prayer flares,
including welcome-back; Discard gets a plain fade. Flare peak 0.99 accepted.
Flare shape: fast rise (~150 ms ease-out), slower settle (~350 ms).
Why: holding the closing sheet ~1 s would make Amen feel laggy and the
moment should land on tap; the halo releasing as the sheet arrives reads as
a natural hand-off. One rule for every committing Amen avoids special cases.
Rejected: delaying the closing sheet/fold for the halo.

### Decision: Name/intention detail page — layout, beads, praying in place
**Timestamp:** 2026-11-03
Spec: `docs/product/detail-page.md`. Order: top section (avatar, name, status) →
counts → Intentions → History, with a blue "Pray for {alias}" button. Beads are
plain ~9 pt wax-colored dots (sealVariant, dark-theme lift) on a neutral thread;
week/month rows show every bead, year rows counts only; gaps are a thread break
with "Off the list · N days". Mixed weekday colors accepted pending a render.
**Praying from a detail page stays on the page** (supersedes 2026-10-18 "returns
to Home in prayer mode"): non-subject sections fade out; the subject is
pre-checked and credited at Amen; intentions are credited only if checked; "Pray
for others" goes to Home still in prayer. Amen, the invitation and the closing
sheet play on the page, then history fades back with updated counts. v1 leaves
out period expansion into individual prayers.
Why: you open Dad's page to be with Dad; jumping to everyone's list breaks that
focus. Stripping the page down (hide, not disable) avoids disabled states
across many surfaces, and the session is already app-level, so no prayer logic
is duplicated. Stamp detail can't be seen at bead size, so D2 doesn't block.
Rejected: navigating to Home pre-checked (context switch); dimming/disabling
history in place (noise in prayer); beads on year rows (365 dots → texture).
Revisit later: whether the subject should be lockable as checked on its page.

### Decision: Detail page — first round of build answers
**Timestamp:** 2026-11-03
Spec updated in `detail-page.md`. Praying on the page uses Home's controls:
Cancel top-left (the mockup's ✕-in-pill was an error), the capsule morphs into
the round pray/Amen button, the pill shows timer · "with N" (no search). The
name gets a trailing checkbox like a Home row; Home's selection rules apply,
so an intention page credits its parent. System back = "Pray for others" (go
Home, keep praying). Restored drafts resume on Home. Sections fade back when
the closing sheet is dismissed. Status lines name the subject ("Dad will be on
List 53"); no status line when not carried; intention pages have no avatar
(parent name link + gold held dot); "Pray" on self and intention pages. Bead
rows: label → strand → text, no ♡; locale week start; empty halves left out;
gaps only between beads, shown on the newer row; unsealed current bead uses
the neutral `unsealed` color; Answered hint in v1. ⋯ v1: edit name/alias,
Answered (no note), Release and Archive with confirm, Archive hidden on self;
Home's quick actions get the same commands.
Why: one prayer-mode vocabulary across screens; no trailing gap, since a gap
up to today reads as a reminder of absence and the status line already states
the present; counts landing in view when the sheet clears is the payoff for
staying on the page.
Rejected: storing where a prayer began to restore the detail page (rare,
adds state); "Pray for Me" / "Pray for {intention text}" labels.

### Decision: Detail page — second round of build answers
**Timestamp:** 2026-11-03
Bead strand: one fixed pitch for all rows, left-aligned, wrap on overflow;
rows newest first, beads oldest → newest within a row (supersedes "gap at the
end of the newer row" → now its start). Unsealed current bead uses a lighter
neutral (≥ 3:1) since the `unsealed` body vanishes on dark. Answered hint only
on the intention's page; an Answered-only period stays. "You prayed once";
year added to "Begun" for earlier years; ✎ counts lag until notes sync;
section titles match Home name style. Default mock stays sealed (dev control
shows unsealed).
Why: a strand reads like a line of text and grows with time, so the newest
bead belongs at the right; fixed pitch keeps every bead the same object
instead of a layout artifact; the answered moment is the gratitude payoff and
shouldn't disappear on a quiet day.
Still open: Sunday gold vs held gold, faint dark waxes — needs the render.

### Decision: Detail-page history — one strand, this week only
**Timestamp:** 2026-11-03
Supersedes the per-period bead strand (2026-10-18) and today's round-2 rules
for pitch, wrapping and cross-period gaps. Only "This week" draws beads (≤ 7,
~12–14 pt, wax colors, oldest → newest); missed lists this week are an
unlabeled thread break. Older periods are text rows (counts + ✎/Answered
hints). "Off the list · N days" is retired.
Why: the first render (Me page, Sep–Nov mock) read as confetti: weekday wax
colors carry no meaning across 20+ beads, every strand repeated the "On N
lists" count beneath it, and labeled gaps marked absence. Seven beads in a
week map to the seven weekday seals, so the colors finally mean something,
and bigger beads fix the faint dark waxes.
Rejected: monochrome beads on every row (still a dot matrix); dropping beads
entirely (loses the tie to the physical seals).

### Decision: Week strand — render review answers
**Timestamp:** 2026-11-03
Render of the simplified History reads calm. Missed lists = one spacing step
of bare thread regardless of count. Unsealed current bead = hollow `inkMuted`
ring in both themes (supersedes "lighter neutral, ≥ 3:1": a filled gray bead
out-shone five of seven waxes on dark, and no lighter neutral reaches 3:1 in
light). Waxes keep real colors despite low dark contrast, since the counts
line carries meaning. Sunday's amber bead is distinct from held gold. The
current list always counts in This week. 13 pt beads / 22 pt pitch, tune by
eye. Closes the mixed-color/dark-wax render check.
Why: the in-progress bead should be the quietest thing on the strand, not the
loudest; an empty ring says "not sealed yet" the way the unsealed blank does.
Rejected: brightening waxes (they're the real seal colors); one slot per
missed list (turns the break into a count of absence).

### Decision: Native apps — iOS in SwiftUI first, Android in Compose before launch
**Timestamp:** 2026-11-05 (SUPERSEDES Flutter as the app stack)
The app is built natively: iOS first in SwiftUI (iOS 26, Liquid Glass), then
Android in Kotlin + Jetpack Compose (Material 3). Android at parity is a hard
gate for public launch; the beta can be iOS-only. Both use the generated SQL
Connect SDKs (Swift, Kotlin) and native Firebase SDKs. The Flutter build in
`app/` is reference only. Rules stay on the server or in the spec, so neither
app invents behavior; build each feature on iOS first and port it while fresh.
Why: Flutter still doesn't render real Liquid Glass (not even in `cupertino_ui`
1.0 as of Aug 2026), and the bars, sheets, menus and search are where native
familiarity matters most (e.g. the filter menu rendered as flat gray). The
client is thin, so a second native app is mostly UI work. The platform-neutral
spec is the real asset, and AI-assisted building makes two native codebases
affordable.
Rejected: staying on Flutter (imitation glass that is always behind Apple);
Kotlin Multiplatform shared logic (complexity for little logic on the client).
Risk: Android matters for a global prayer audience, so it must not slip past
launch.

### Decision: Fidelity tiers — signature components match, native chrome varies
**Timestamp:** 2026-11-05
Tier A (custom signature components: avatars and rings, threads, rows, the
community card, seals, bead strand, prayer mode, pray button, Amen → seal,
color and type roles) gets exact values in the spec, and both apps match them.
Tier B (menus, popovers, sheets, alerts, search, bars, switches, pickers) uses
the platform component, and the spec defines only content and behavior, not
padding, radius or color. Where a platform can't render a detail, the platform
wins (e.g. the filter menu's gold check at 0 is monochrome in a system menu).
See design-direction.md §0.
Why: the custom parts carry +Prayer's identity; the chrome should feel like
the phone.

### Decision: Native folder layout + screenshot reference
**Timestamp:** 2026-11-05
Native projects live at `apps/ios/` (SwiftUI, first) and `apps/android/`
(Kotlin + Compose), each with its own `CLAUDE.md` and Firebase client config.
`app/` stays as the Flutter reference (tagged `flutter-reference`) until it is
retired. Screenshots of approved screens go in `docs/product/reference/` as
reference only; the spec wins when they differ.
Why: separate native roots keep path-scoped CI simple and leave the Flutter
build intact to look back at.

### Decision: Icons are the platform's symbol set (SF Symbols on iOS)
**Timestamp:** 2026-11-05 (SUPERSEDES design-direction §9 "one thin-line family, e.g. Phosphor")
iOS uses SF Symbols at a light weight, Android uses Material Symbols Outlined
at a light weight. The praying hands and the bloom are drawn as custom
symbols on each platform to match. One family per platform, no mixing.
Why: native chrome (menus, toolbars, search, swipe actions) renders the
platform's symbols, which track text weight and Dynamic Type; Phosphor inside
Liquid Glass chrome would read as a port. Tier A has almost no generic icons.

### Decision: Flutter's tuned values win over the spec's earlier figures
**Timestamp:** 2026-11-05
Where `app/lib/theme/tokens.dart` and design-direction differed, the
values tuned on device in the Flutter build are adopted and the spec updated:
avatar initials at 70% white (was 80%; vermilion and olive drop to ~2.6–2.9:1,
accepted); `thread` its own value `#3A3F47` / `#C3CCDD` (was = `hairline`);
card stamp 110 pt at −23/−15 (was ~104 at −24/−20); pill and pray button
62 pt (was ~56–60); cluster avatars 24 pt (Today's list, Your portion) and
32 pt (Amen invitation) (was 28–32); the check's spring 420 ms on
ease-out-back. `design/tokens.json` holds these values.
Why: they were tuned by eye on device; the spec's figures were starting points.

### Decision: Floating bar on native glass; scroll edges and search tiers
**Timestamp:** 2026-11-05
Answers to the iOS Phase 0 tier questions (design-direction §0, §4):
- The pill and pray button are Tier A in layout (our arrangement and sizes)
  on the platform's glass material.
- On iOS the scroll edges are Tier B: the platform's soft scroll edge effect,
  no custom blur and dim. The tuned curve stays the reference for Android's
  dim fallback.
- The search field docked above the keyboard is a sanctioned Tier B
  exception: a custom row (so the compact pray button sits beside it) built
  from the platform's native text field on glass.
Why: native where the platform already does it well; custom only where the
spec's behavior (Pray always reachable) needs it.

### Decision: Connector renames for the Swift SDK
**Timestamp:** 2026-11-05
`GetMyHeader.self` → `selfSubject`; `parent { id }` → `parentId` in
GetMySubjects, SearchMySubjects and GetMyPortion; `parentSubject: parent { … }`
in GetSubjectDetail and GetMyArchivedSubjects.
Why: firebase-tools 15.x Swift codegen doesn't escape the `self` keyword and
nests a same-named struct for a `parent` selection, so the generated package
didn't compile. No shipped client used these operations.

### Decision: Roca is licensed for app embedding
**Timestamp:** 2026-11-05
Eric confirmed the Roca license covers embedding in the iOS and Android apps.
The license file is still to be added to the repo.

### Decision: iOS Phase 0 answers (cache, sheets, filter counts, icon, launch, theme)
**Timestamp:** 2026-11-05
- **Client cache:** the Swift SDK caches query results persistently
  (`clientCache`, `maxAge: 0`, Swift target only), so Home loads offline and
  is still fresh whenever online. The app clears the cache on sign-out and on
  account deletion (privacy.md, auth-onboarding.md).
- **Sheets:** the Amen invitation, the closing sheet and the add sheet are
  native sheets with detents; the signature components inside them stay
  Tier A (design-direction §0).
- **Filter menu counts** (SUPERSEDES trailing counts and the gold check at 0):
  the count goes in the item's title ("Still to hold · 3"). At 0 there is no
  count and no check, since a system menu's check means "the active filter";
  the item shows the subtitle "Everyone's held today." (design-direction §4).
- **App icon:** an interim icon built from `+prayer_icon.svg`; the layered
  Icon Composer icon is a later design task (open-questions D4).
- **Launch screen:** the wordmark centered on `ground`, in light and dark
  (auth-onboarding.md).
- **Theme** (SUPERSEDES "Dark theme is the primary design", app-brief §0, and
  the Flutter build's dark default): both themes are fully designed; the app
  follows the system, with a device-local System/Light/Dark setting in You
  (screens.md).
- **Reference screenshots** are renamed `<screen>-<state>-<theme>.png` and
  indexed in `docs/product/reference/README.md`.

### Decision: Sign-out, device data, and the filter menu's zeros
**Timestamp:** 2026-11-05
Answers to the iOS Phase 0 ambiguities (A1–A7):
- **Sign-out (A1):** no Sign out row while anonymous. Once linked, "Sign out"
  sits at the bottom of You, with the confirmation "Your names stay with your
  account. Sign in to bring them back." The offline queue is flushed first;
  if prayers are still unsynced, ask "1 prayer hasn't synced yet. Sign out
  anyway?" Never drop them silently. Afterwards the user lands at the start
  of onboarding, which gets a quiet "Already have an account? Sign in" link
  (auth-onboarding.md, screens.md).
- **Clearing device data (A2):** sign-out and deletion clear the SQL Connect
  cache (by deleting the SDK's cache folder, guarded by a test, since the SDK
  has no clear API), the Realtime Database local cache, and the offline
  queue. The queue is flushed on sign-out and discarded on deletion.
- **Backups (A3):** the SQL Connect and RTDB caches and the offline queue are
  excluded from iCloud backup. The queue stays in Application Support (not
  Caches) so iOS never purges it (privacy.md).
- **One line at zero (A4):** "Everyone's been held today." for both the menu
  subtitle and the Still to hold empty state.
- **Never show 0 (A5)** (SUPERSEDES "Carried · 0"-style counts): at 0 the
  count is dropped ("Carried"). Only Still to hold gets the subtitle.
- **Interim icon (A6):** the SVG's own colors (brand, not UI), a single layer;
  iOS derives dark and tinted. Real variants come with D4.
- **Appearance (A7):** stays device-local; its place in You is fine unless You
  gains a display group, where it would go.

### Decision: iPhone only for now
**Timestamp:** 2026-11-05
The iOS app targets iPhone only (`TARGETED_DEVICE_FAMILY` 1). iPad is
considered once the style and the core experience are where we love them.
Why: one layout to perfect first; the spec only describes phone screens.

### Decision: +Prayer publishes from its own LLC's developer account
**Timestamp:** 2026-11-05
+Prayer will be published under a new LLC, enrolled as an Organization in the
Apple Developer Program (and its own Google Play account), not under Eric's
existing account. The bundle ID will likely change to the LLC's (e.g.
`com.plusprayer.app`; final value open, Q30).
- Development continues under the current team with `dev.hammock.plusprayer`.
- **No App Store Connect app record and no TestFlight upload under the
  current account.** Switch the team and bundle ID before the first upload.
Why: the App Store groups every app from one account (developer page, "More
by this developer", seller name), with no per-app hiding, and +Prayer must
stand alone, apart from Eric's fitness app. Switching before the beta avoids
an app transfer (only possible after a release) and keeps Sign in with Apple
user IDs stable (they're scoped to the developer team, so a later move would
force a user migration).

### Decision: Halo edge line, a breath you can see, a glass pray button
**Timestamp:** 2026-11-05
From the first look at prayer mode on device (iOS):
- **Halo = a solid 2 pt gold line on the screen's edge + the glow over it**,
  as in the Flutter build. The line is steady (it fades in and out with the
  session only); the glow breathes and flares.
- **The glow's breath is quicker and deeper:** ~5 s cycle (was ~8 s), glow
  opacity ~0.4 ↔ 1.0 (was 0.65 ↔ 0.85). Reduce Motion: static at ~0.7.
  SUPERSEDES the "~8 s, 0.65 ↔ 0.85" values in the 2026-11-03 halo entries.
- **The pray button is interactive Liquid Glass tinted action blue**
  (SUPERSEDES "solid action blue, never glass"). It still reads as solid
  blue; while counting down the tint dims and the glass stops responding.
Why: the line gives the edge a distinct "held" frame the glow only accents;
the old breath was too slow and quiet to notice; a rigid disc felt dead next
to the glass controls that give under the finger, and the system's own
press response is the native feel (iOS's prominent glass buttons work this
way, a UIKit button would add nothing).

### Decision: The header avatar is on tinted glass
**Timestamp:** 2026-11-05
Your avatar in Home's header (→ You) sits on interactive Liquid Glass tinted
with your avatar tone, like the pray button on blue.
Why: it's a floating control like the others and should give under the
finger the same way; the tint keeps it reading as your avatar.

### Decision: The gap between name groups is measured as seen
**Timestamp:** 2026-11-05
The ~24–28 pt between name groups (design-direction §3) is the visible gap,
from the last row's text to the next avatar. The rows' own padding counts
toward it, and the last intention in a group doesn't add its 40 pt pitch's
empty space below it (its tap target still reaches 40 pt, into the gap).
Why: on device the gap came out ~45 pt (24 pt added on top of ~17 pt of
empty row and the name row's 4 pt inset), so groups read as far apart.

### Decision: Add sheet name form — inline avatar, one-tap save, intention offer in place
**Timestamp:** 2026-11-05
- The name form shows a ~72 pt avatar preview at the top, then Name ("Printed
  on the list") and Alias ("Only you see this"). Name is focused on open.
- The tone is **picked when the sheet opens** from the user's least-used tones
  among active names (ties random), shown on the empty circle before typing,
  and **stored as `avatarTone` on create**. Initials fill in live; the color
  never changes while typing. The id hash stays as the fallback for rows with
  no stored tone.
- v1: the avatar is preview-only. v2: tap → tone swatches (+ photo), here and
  in Edit at once; a user-chosen tone replaces the auto pick.
- Add saves in one tap. The sheet then slides in place to "{alias} is on your
  list. Add an intention for {alias}?" (Not now / Add).
Why: the name is what gets carried, so it's committed on the first tap; the
avatar is decoration and shouldn't gate it. A changing color per keystroke
reads as broken; least-used tones keep neighbors on Home apart. The helper
lines teach the name/alias split at the one moment it matters.
Rejected: a Name-or-Intention choice screen first (a tap for everyone to serve
the minority; ＋ already defaults to Name); opening the detail page in create
mode (too heavy); a Name → Next → Avatar → Next → Intention wizard (each step
is a drop-off point, and most users would just tap through the avatar step).

### Decision: Add sheet keeps the keyboard up when switching tabs
**Timestamp:** 2026-11-05
Switching Name ⇄ Intention focuses the new tab's text field in the same frame;
the name picker ("For ( M ) Me") opens a native menu/popup without taking
focus; the sheet has one height for both tabs. The user can still dismiss the
keyboard; the app never hides it on its own when a text field is next.
Why: in the Flutter build, switching to Intention dropped focus (the picker
seemed first), so the keyboard slid out and back in, which felt jarring. The
picker defaults to "Me" and is rarely changed, so the intention text is the
primary input. A sheet height change on switch was the second source of jump.
Rejected: letting the keyboard hide/show per tab; forcing the keyboard to stay
up against a user dismissal.

### Decision: Add sheet details (app/ agent questions)
**Timestamp:** 2026-11-05
- Initials preview follows Home's rule live (Name's initials until Alias has
  text, then the alias's); the jump shows truthfully what Home will show.
- Least-used tones count all active subjects on Home incl. Me, by visible
  tone (stored or hashed fallback); re-picking on each open is fine.
- Offer step: horizontal push, field focused, {alias} falls back to name,
  Add disabled when empty, sheet closes after Add (offered once).
- Picker items: small monogram + alias, Home order, Me first.
- Native segmented control; content top-aligned, no avatar on Intention,
  spare height below.
Why: keep the preview honest, the tone pick stateless, and the flow short;
avatars in the picker because color is how users find their people.

### Decision: Intention name picker isn't searchable in v1
**Timestamp:** 2026-11-06
v1 keeps a plain native menu of all names. Search is deferred (open-questions
D5): past ~10 names, the menu becomes Me + 5 most recent + "All names…",
pushing a searchable list inside the sheet with focus kept (keyboard rule).
Why: most intentions for others are added from the name's page (picker
hidden), and footer ＋ intentions are mostly for Me (the default), so the
picker sees light use on short lists; a native Menu can't hold a search
field, and a custom list now buys little.

### Decision: Add sheet layout answers + pool-full messaging and daily upsell cadence
**Timestamp:** 2026-11-06
- Toolbar buttons (Cancel/Add; offer step Not now/Add, no back). Intention tab
  Add closes when carried; pool full shows the saved-privately step with Done.
- Pool full is said **in the sheet** ("{alias} is saved for your own prayers.
  All {pool} places on the list are in use."); Home shows no mark.
  SUPERSEDES app-brief's Home row line "Not on the list · all 15 places in
  use" (it marked absence, against design-direction §5, and 15 was stale:
  `basePremiumPool = 10`, and the pool comes from the entitlement).
- Upsell cadence: a stronger invitation only on the first full-pool add of
  the local day; afterwards only a small "Your portion" link; none when no
  larger pool exists. Device-local "shown today".
- Validation live under the field (~0.5 s debounce, Add disabled); caps stop
  input with a counter in the last 10 chars; offline line "Adding needs a
  connection."; helper text as captions, not placeholders; tone count = names
  incl. Me.
Why: an upsell on every add past the limit is too much for someone adding the
people they love; once a day keeps the path visible without nagging. Captions
survive typing, placeholders don't. Monetization flow to be refined later.

### Note: Add-sheet upsell cadence is PROPOSED, not decided
**Timestamp:** 2026-11-06
Eric asked to keep the once-a-day cadence (previous entry) as a pending idea,
not a decision. The app builds it as a placeholder; the open question is
open-questions Q31 (alternative: first time ever, then at most weekly).

### Decision: Add sheet — placeholders until Membership exists, more copy, 500 cap
**Timestamp:** 2026-11-06
- Hide the whole membership invitation and "Your portion" link until those
  screens exist (a sales line with nowhere to go is a dead end).
- `basePremiumPool` goes into client `/config` (backend); app fallback 10.
- After a private name's offered intention is added, close silently.
- Copy: intention placeholder "e.g. Healing after surgery", caption "Printed
  on the list"; free pool line "Your free place on the list is in use." (the
  self is always carried free, so "1 place" misstates it); a private
  intention reads "This intention is saved for your own prayers." (intention
  text can be long or painful, so it's never quoted); 500 cap line "You've
  reached 500 names and intentions. Archive some to add more."
- The free-tier case is added to open-questions Q31.

### Decision: basePremiumPool has one source; the 500 cap counts active items
**Timestamp:** 2026-11-06
- `basePremiumPool` lives only in RTDB `/config`: the server's trial/base
  grant reads it (as the grace cap does) with fallback 10, and the app reads
  it for the add sheet. SUPERSEDES the `BASE_PREMIUM_POOL` Functions param.
- The ~500 abuse cap counts only active subjects (on Home, incl. Answered),
  not archived/released/purged. A quiet ~5,000 total-row hard cap (generic
  error) guards against archive-and-add abuse.
- Production `seed:config` (adds only missing keys) runs right before the
  function change deploys; until then both sides fall back to 10.
Why: two sources would let the sheet promise a number the server doesn't
grant. Counting archived items would eventually lock a faithful long-time
user out with no remedy and make "Archive some to add more" false; the cap
exists against abuse, not to limit a practice.

### Decision: Seed done; generic add failure copy; hard cap is a param
**Timestamp:** 2026-11-06
- Eric ran `seed:config` on production 2026-11-06, so `/config` has
  `basePremiumPool`. Order relative to the function deploy never mattered
  (both sides fall back to 10); corrects the previous entry.
- Add sheet generic failure line: "Couldn't add this right now. Try again in
  a little while." (covers the ~5,000 hard cap and unexpected errors).
- The ~5,000 hard cap is a Functions param like `SUBJECT_CAP`: server-only
  values may be params; client-visible ones live in `/config`. "Quiet" means
  no dedicated copy, not untunable.

### Decision: Add sheet failure line keeps Add enabled
**Timestamp:** 2026-11-06
After a generic failure Add stays enabled so retrying is one tap; the line
clears on edit or on the next Add (offline line also persists while offline).
Confirms the app/ agent's provisional reading.

### Decision: Search reuses the bar; the countdown is a pie inside the button
**Timestamp:** 2026-11-06
- **Search:** 🔎 turns the pill's own glass into the search field; the pray
  button stays its own circle beside it. With the keyboard up both ride above
  it at 52 pt (`size.bar.compact`); with text the pill stays a field until ✕.
  In prayer, the field hides the timer and "with N" while searching.
  SUPERSEDES the docked search row with a compact pray button inside it
  (2026-10-27/11-05).
- **Countdown:** a small pie inside the dimmed pray button (0.4 of its
  diameter) runs down to nothing over ~5 s, then Amen. No ring outside, no
  change in size. The Amen invitation's button uses the same component and
  drops its seconds counter. SUPERSEDES the decaying ring (prayer-flow
  2026-10-17) and "seconds count up in the center".
Why: the pill and the pray button are the two objects people learn on Home;
search becomes a third state of the same pill (as prayer already is), the
way the iOS 26 tab bar morphs into search, instead of a second, smaller pray
button in a different shape. The ring sat far outside the button, made it
suddenly larger and swept the whole edge: a lot of motion for "wait a
moment". Progress inside the control is Apple's own pattern (App Store
download, Dynamic Island timer). Built and judged on device (contrast of the
blue pie on the dimmed disc is good as built).
Rejected: the docked row with a compact pray button (two pray buttons in two
shapes); a tighter ring (still a sweep around the whole button).

### Decision: Search's empty state is live
**Timestamp:** 2026-11-06
"No matches for “…”" shows as soon as nothing matches and its line updates
as the query changes; it isn't hidden and re-shown while typing. SUPERSEDES
"show the empty state only after typing pauses (~500–700 ms)" (2026-10-29).
Why: the rows filter in real time, so a delayed empty state felt off (waiting
won't make a match appear), and hiding and re-showing it on each keystroke
was janky. The `duration.searchPause` token is removed.

### Note: Pool unit "people, not items" is PROPOSED (Q32)
**Timestamp:** 2026-11-06
Discussed, not decided: count carried people (Me free), each printing with
up to 1 chosen intention (config), the rest as "and N more". The current
names + intentions rule stands until Eric decides; agents should not change
pool counting yet. Add-sheet carry row, "Make room", For row and the "the
list" copy rule wait on this.

### Note: Extra printed intentions would be a tier property, not an add-on (PROPOSED, Q32)
**Timestamp:** 2026-11-06
If more than one printed intention per person is ever offered, it's a higher
per-person cap on a tier (e.g. Plus: 25 people · up to 3 each), not a shared
add-on pool. Launch with one tier and cap 1, and measure "Print this one
instead" before adding a tier.
Why: an add-on pool brings back two meters and cross-person swaps, sells
"the why", and needs a second subscription group.

### Decision: Add sheet redesign — copy rule, labels, carry row, "is added", For row
**Timestamp:** 2026-11-06
- **Copy rule:** "the list" only means the printed list; never "your list".
  ("Mike is on your list" and "All 10 places on the list" read as the user's
  own screen.)
- **Labels:** Name ("e.g. Gary Olson", caption "Printed on the list") and
  "What you call them · optional" ("e.g. Dad", "Only you see this").
  SUPERSEDES placeholder-only fields ("Their name" read oddly; "e.g. Dad"
  alone didn't say what the field was).
- **Carry row** on both tabs and the offer step: bloom, "Carry onto the list"
  (not "List N": the number changes daily and the community card shows it),
  toggle on by default with room, meter "{used} of {pool} {unit} used" via
  one formatter (unit pending Q32). Full pool: off + disabled + "Make room
  for {alias}" / "this intention", **visible but inert** for now. An
  intention under a deliberately uncarried name starts off, stays enabled,
  and shows "Also carries {alias}" when turned on.
- **After Add:** serif "{alias} is added." in every case, then the intention
  offer with focus kept (fixes the keyboard dropping when the pool was full).
  SUPERSEDES the pool-full message step, the free/singular pool lines, the
  saved-privately [Done] step and the daily membership invitation (Q31
  updated: the carry row's link is the upsell spot).
- **For row:** one Home-style row (40 pt avatar + serif name + "Change")
  pushing a searchable "Who is this for?" (everyone, Home order, Me first).
  SUPERSEDES the native picker menu; closes D5.
Why: telling the user up front whether an item is carried removes the
after-the-fact surprise and the "your list" confusion; a persistent quiet
link is a humane upsell spot; a single row plus search shows people as
people without ranking anyone out of a visible strip.
Rejected: avatar strip for the For picker (busy; ranks loved ones by
position); "Carry onto List N" (changes daily).

### Decision: Add sheet carry-row details (app/ agent questions)
**Timestamp:** 2026-11-06
- `addSubject` gains `carry` / `carryParent` inputs, pool-checked atomically,
  returning the carried result (schema-brief). Rejected: a second
  setCarriedItems call (races).
- No "deliberately uncarried" distinction (the data can't tell): any
  intention under an uncarried name starts off.
- "Also carries {alias} · uses N {unit}" states the true cost.
- Meter previews the result with the toggle; over-pool reads "All {pool}
  {unit} in use"; free-tier name line pending Q32.
- "Make room" always under the meter; bare "Make room" before a name exists;
  inert button with VoiceOver hint "Not available yet".
- Intention tab gets an "Intention" label; offer field keeps only the caption.
- Picker: neutral checkmark on the current person, Home's empty-search copy.
- If the server's carried result differs from the toggle, say so inline
  instead of closing silently.

### Decision: addSubject carry details (backend/ agent questions)
**Timestamp:** 2026-11-06
Return `effectivelyCarried` alongside the flags; all-or-nothing carry;
no-effect `carryParent` ignored; the re-carry cost counts flagged intentions
on both sides; the simultaneous-device race is an accepted known gap (no
User version counter yet; over-limit trimming covers it). Q32 not applied.
Why: the race needs two devices adding at the same instant and overshoots by
an item at most, while an optimistic-lock version on User touches every
carry-changing write; a partial carry would print Dad without the reason the
user just wrote.

### Decision: Carry row wording and end states (app/ agent follow-ups)
**Timestamp:** 2026-11-06
"Make room" always under the meter (fixed contradictory "beside it");
"uses N" counts the whole effect including this item; pool of 1 reads "Your
one place is in use"; "Make room" shows on the free Name tab too; the
server-disagrees state is an end state (top line, Done only, read-only form,
keyboard down) on both the Intention tab and the offer step; curly quotes in
"Nothing matches".

### Decision: Add sheet polish from device testing
**Timestamp:** 2026-11-06
- Switch "on" track = `inkMuted` app-wide (full ink glared in dark mode).
- No "Printed on the list" captions on Name or Intention; the carry row says
  what prints, and with groups the name is also what members see. "Only you
  see this" stays under the alias.
- Meter counts what's **left**, excluding this item ("3 places left", "This
  uses your last place", "All 10 places in use"). SUPERSEDES the preview
  meter, which read "10 of 10 used" while the toggle was still on and allowed.
- "Make room for {alias}" updates after a ~0.6 s typing pause with a ~150 ms
  crossfade; search and initials stay live (search results are the thing
  being looked at, and local filtering is instant).
Rejected: a once-per-second update while typing (flashes partial names).

### Decision: Carry row follow-ups (offer-step line, last places, prefill)
**Timestamp:** 2026-11-06
Server-disagrees line sits under the header on the offer step (fixed the
contradiction); when turning carry on takes all remaining places (e.g. an
intention that also carries its name), the meter reads "This uses your last
{N} places" and the Also-carries line drops "· uses N"; a prefilled name
shows in "Make room for…" at once, later edits wait for the pause.

### Decision: Switch off track dimmed; on stays inkMuted
**Timestamp:** 2026-11-06
Off track = `ink` at ~14%, on track stays `inkMuted`, via `switchTrackOn` /
`switchTrackOff` tokens. On device the default off track was a mid gray close
to `inkMuted`, so states read only by knob position.
Rejected: action blue for "on" (blue means act; a settings screen of blue
switches would dilute it); a brighter on track (glared).

### Decision: iOS keeps the native switch (system off track)
**Timestamp:** 2026-11-06
iOS can't recolor the native switch's off track, so iOS keeps the native
switch with only the on tint (`inkMuted`); `switchTrackOff` is Android-only.
Why: native behavior (drag, glass knob, accessibility On/Off labels, future
iOS changes) outweighs a subtle tint difference; iOS users read switches by
knob position. Rejected: a custom ToggleStyle (replaces a native control);
a shape behind the native switch (its translucent track blends lighter).

### Decision: Add sheet form type — labels in ink, muted for hints only, trailing bloom
**Timestamp:** 2026-11-06
- The sheet is labeled controls stacked (label → control → hint). All
  labels, including "Carry onto the list", = 15 pt semibold ink; input text
  17 pt regular ink; hints/meter 13 pt `inkMuted`; "Make room" 13 pt blue.
- The bloom trails the carry label (~17 pt; `inkMuted` on, `carriedMark`
  off), matching how the mark trails names on Home.
Why: labels and the carry title are the same role, so they match; muting
labels would leave the empty sheet nearly all gray (placeholders, hints,
meter), so color separates structure (ink) from secondary text (muted) and
size separates labels from content. Bold 17 pt labels out-shouted the content.
Rejected: muted labels (gray soup); a leading 22 pt bloom (broke the label
edge and didn't match the row mark's trailing position).

### Decision: Add sheet uses an X for cancel
**Timestamp:** 2026-11-06
The add sheet's leading Cancel becomes the iOS 26 round glass X (VoiceOver
"Cancel"); Add stays a word; the offer step keeps "Not now" (it isn't a
cancel: the name is saved). A discard confirmation for typed text is
deferred (open-questions D6).

### Decision: Add sheet type pass follow-ups
**Timestamp:** 2026-11-06
Serif header aligns to the shared text edge; status lines 15 pt regular ink;
validation errors 13 pt ink; 6 pt before the bloom; "Who is this for?" uses
the native inline navigation title (it's a pushed view, not a form label).

### Decision: Add sheet edges — avatar rows and notice lines
**Timestamp:** 2026-11-06
Avatar rows put the avatar on the shared edge with the name after it (Home
layout); the top notice lines are left-aligned on the shared edge, not
centered (centered read as toasts, apart from the form).

### Decision: Carry-row bloom stays inkMuted; centered on the label
**Timestamp:** 2026-11-06
The carry row's bloom is `inkMuted` in every state, ~15 pt, centered on the
label's cap height. SUPERSEDES dimming it to `carriedMark` when off: that is
the color the mark has on Home rows, where it means "carried", so the off
state said the opposite. The toggle alone carries on/off. On device the
glyph also sat too high.

### Decision: Add sheet group spacing
**Timestamp:** 2026-11-06
One ~24 pt gap between groups, measured from a group's last element (field
or hint) to the next label; label → field ~8 pt, field → hint ~6 pt. On
device the gap above "What you call them" (~19 pt) was smaller than the gap
above "Carry onto the list" (~25 pt); Eric preferred the larger one.

### Decision: Intention field grows to 3 lines
**Timestamp:** 2026-11-06
The intention input wraps and grows 1 → 3 lines (80 chars ≈ 2 lines), on the
Intention tab and the offer step. No newlines (it prints as one line):
Return submits, pasted breaks become spaces. Name/alias stay single-line.
Why: a single-line field hid most of an 80-character intention, the text
people most want to reread before saving.

### Decision: Add sheet optical spacing details
**Timestamp:** 2026-11-06
Gaps measured optically (bottom of the element above to the next cap
height; baseline for labels over fields, below descenders for hints and the
carry label). Offer step: "{alias} is added." → its question ~10 pt optical
(one header block, serif descender room trimmed), not the 24 pt group gap
(read ~31 pt on device). Toggle centered on the carry label's line,
overhanging without moving the layout.

### Decision: One hint gap, toggle centered on the row, one form-group component
**Timestamp:** 2026-11-06
- One hint gap (~6 pt) for every hint. SUPERSEDES the 2 pt carry-label → meter
  gap (a spec error: it made "2 places left" cramped beside the properly
  spaced "Only you see this").
- The carry toggle centers on the label + hint block (iOS Settings subtitle
  row). SUPERSEDES centering on the label line (the label then sat high
  against the toggle).
- Every group is one shared form-group view (label + optional trailing mark,
  control, optional hint, optional trailing accessory) spaced only by form
  tokens, so groups can't drift apart again.
Why: Eric was finding per-element variances by eye; both came from the spec
giving the carry row its own values. Tokens already existed (design/tokens.json
→ PP.space.form*); the fix is fewer special cases and one component.

### Decision: The add sheet is a native Form
**Timestamp:** 2026-11-06
The add sheet is rebuilt on SwiftUI's native `Form` (inset grouped): section
headers for labels, footers for hints ("Only you see this", "Make room…",
validation), a native Toggle with the meter as its subtitle, a native
navigation row for "For", a native searchable list for "Who is this for?".
Forms and settings-style screens join design-direction §0's native (Tier B)
list. SUPERSEDES today's hand-specified form type, spacing, optical gaps,
toggle centering, shared text edge, form tokens (`formGroup`,
`formLabelToField`, `formFieldToHint`, `formLabelToHint`) and the custom
form-group component; behavior and copy are unchanged.
Why: we were re-creating Apple's form by hand and Eric kept finding
variances by eye; the native form gets spacing, alignment, Dynamic Type,
VoiceOver and keyboard scrolling right for free. "The unique WOW things
won't come from a custom form" (Eric): custom effort goes to the signature
moments (Amen → seal, the ring, the cluster), not to forms.
Cost accepted: platform section-header style instead of our 15 pt semibold
labels; inset grouped rows instead of free-floating fields.

### Decision: Add sheet native-rebuild follow-ups
**Timestamp:** 2026-11-06
- Avatar lives in the Name row (~40 pt, leading, Home-row size), not a 72 pt
  centered row; `.listSectionSpacing(.compact)`. The big preview pushed the
  carry section out of view, and avatar + name previews the Home row.
- Standard large sheet. The keyboard rises with the sheet in one motion
  (focus set before presentation; UIKit bridge if needed). On device it
  arrived after a delay.
- "Who is this for?": search starts inactive (title + back visible; keyboard
  down on that tap-only screen). Auto-activating caused delayed focus and an
  X-then-back exit.
- Bloom: carryRow 15 pt via `@ScaledMetric(relativeTo: .body)`.
- **One intention form for a known person** (offer step and "+ Intention"
  from a name): toolbar "Add an intention", a header row with avatar +
  serif name (as on Home), "Added." under it on the offer step only, then
  "Intention" + field, then carry. Eric's call, from the Flutter long-press
  "+ Intention" sheet: when the person is given, show them nicely rather
  than as a selectable control. Rejected: a static "For" row (reads as a
  disabled control); the "{alias} is added." + question header (the
  question didn't label the field).
- Confirmed agent calls: Settings-style For row in system font; notice row
  as plain ink text; "Also carries…" as a second subtitle line; ink
  checkmark.

### Decision: Offer step wording tightened
**Timestamp:** 2026-11-06
Offer step: no toolbar title; avatar + serif name with a quiet "Added"
subtitle; field header "Intention · optional"; toolbar Skip / Add. From a
name's page: same form, no subtitle, header "Intention", X / Add.
SUPERSEDES the "Add an intention" toolbar title (it competed with "Added")
and "Not now" (it answered a question no longer asked).
Why: with the question gone, the optional header states the offer, "Skip"
names the alternative plainly, and "Added" is the single confirmation.

### Decision: Offer step asks "Add an intention now?"
**Timestamp:** 2026-11-06
The offer step's field header is the question "Add an intention now?"
(sentence case), replacing "Intention · optional". Skip / Add and the
"Added" subtitle stay; the from-a-name form keeps "Intention".
Why: the question keeps the offer's warmth; as the field's own header it
reads as about the field; "now" pairs with Skip (later is fine); "intention"
teaches the app's word. The name is omitted because it sits right above.
Considered: "Anything specific to pray for?" (warmer, but doesn't teach
"intention"); "…for {alias}?" (repeats the name, long names break).

### Decision: Live preview row, default spacing, "Added" as the offer title
**Timestamp:** 2026-11-06
- Name tab opens with a live preview row: ~40 pt avatar + serif display name
  (alias else name; empty = toned circle + muted "New name"), exactly as on
  Home. It's the same header row the offer step shows, so the person stays
  put while the form below changes. SUPERSEDES the avatar in the Name row
  (initials followed the alias, "S" beside "Matt Burdick").
- Default section spacing. SUPERSEDES `.listSectionSpacing(.compact)` ("Only
  you see this" read as belonging to the carry section).
- Offer step: toolbar title "Added", no subtitle under the name, question
  header "Add an intention now?" (Eric: general → specific; the old "Add an
  intention" title + "Added" subtitle ran specific → general and competed).

### Decision: Add sheet follow-ups (app/ agent questions, round 3)
**Timestamp:** 2026-11-06
- Preview row and person header use the Home-row avatar token (44 pt); the
  For row and picker stay 40 pt.
- Home rows get a native long-press context menu with only "Add intention"
  for now (the from-a-name form needs an entry point); other actions join
  as built.
- The focus helper attaching when its view enters the window is accepted as
  the SwiftUI equivalent of viewWillAppear.
- Leaving "Who is this for?" by back (no pick) also refocuses the intention
  field.
- `.textCase(nil)` not required (iOS 26 headers aren't uppercased).
- The bloom's `.font(.system(size:))` from the scaled token is an accepted
  exception to the no-fixed-font rule (it's a glyph sized to text).
- Stale lines fixed in screens.md (keyboard) and app-brief.md (summary).

### Decision: The avatar lives in the field it comes from (to try, A → B → C)
**Timestamp:** 2026-11-06
Eric's idea: a ~30 pt avatar inside the Name field (empty state "…"), moving
into the alias field on its first character and back when it's cleared, so
the initials always sit in the field they come from. Fields keep their
normal height and both reserve the avatar's space. Motion is tried in order,
each time-boxed: A in-row with the iOS 26 glass morph / matched geometry; B
an overlay layer above the form; C in-row shrink/grow. v2: tinted glass,
tap → color/photo menu.
Why: the top preview row was busy, and an avatar fixed in the Name row
showed the alias's initials beside the name. The glass morph is the
platform's own motion, so it doesn't compete with Amen → seal.
SUPERSEDES the live preview row (286bf14) for the Name tab; the offer step
keeps its avatar + serif name header.

### Decision: The new person's avatar is a toolbar control; Add splits off the X
**Timestamp:** 2026-11-06
- Name tab toolbar: leading = the new person's tinted-glass avatar (like
  your own avatar in Home's header), initials following the display name;
  v2 tap → color/photo. Center = segmented control. X fixed at the far
  right on both tabs; Add (blue tint) splits off to its left once there's
  text and merges back if cleared.
- Name and alias are standard form rows; no avatar in the form.
SUPERSEDES the in-field avatar (b54f6d9): animating between rows failed,
and the glass merge forced glass fields that didn't match the form.
Rejected: the X turning into Add in the same spot (one place must keep one
meaning, or closing becomes saving by accident).
Why: no form space used, so the carry section stays in view; the toolbar
avatar is a glass control by nature, ready for v2 customizing.

### Decision: Contacts-style name block; standard toolbar (to try)
**Timestamp:** 2026-11-06
Name tab: one grouped row, a ~64 pt avatar on the left spanning stacked
"Full name" / "What you call them (optional)" fields, one footer (draft
copy). Toolbar back to X · segmented · Add at opposite ends.
SUPERSEDES the toolbar avatar and Add splitting off beside the X (2f54c29):
the toolbar had four controls, the avatar read as a button, and Add next to
X invited accidental closes.
Why: the classic iOS Contacts layout makes the avatar big enough to read as
a person without adding height, so the carry section (the upgrade surface)
stays in view. Open: per-field labels become placeholders (Eric unsure);
footer copy needs work; fallback is the two section headers.
