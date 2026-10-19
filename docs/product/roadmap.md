# Roadmap & Checklist

_Last updated: 2026-10-18. Built from the decisions in this folder. Tags:
**[be]** backend, **[app]** Flutter, **[ops]** Eric's pipeline/skills,
**[biz]** store/legal/business._

## Guiding constraint
The app must earn its build — an install costs far more friction than a 🙏.
Stage 1 is a private beta that tests whether the app is the right mechanism.

---

## Stage 0 — Foundations

### Schema changes (`schema.gql`) [be]
- [x] `PrayerSubject.parent` (nullable self-ref; required when kind = INTENTION; one level)
- [x] `PrayerSubject.isCarried` (user-chosen; auto-set while pool has room)
- [x] `PrayerSubject.avatarTone: Int` (palette index), `avatarPath: String` (photo seam)
- [x] Replace `answeredAt` with `resolvedAt` + `resolution` (ANSWERED | RELEASED)
- [x] `personalLabel` surfaced as "alias"; self alias = "Me"
- [x] `Prayer.localDate: Date!`
- [x] `User.timezone`, `lastListLocalDate` (replaces `lastPrayedListNumber`)
- [x] `User.graceDays`, `graceOfferPending`, `graceOffersEnabled`
- [x] `User.selfNameChangedAt`
- [x] Entitlement: `includeLimit` = pool beyond self name; free = 1 (own intention only);
      add `entitlementExpiresAt` + `trialStartedAt` for the reverse trial
- [x] `PrayerList.sealVariant: Int`; `PrayerList.scope` (default GLOBAL), unique (scope, listNumber)
- [x] `User.locale`
- [x] `Prayer.endedBy` (AMEN | AUTO)
- [x] Seams: `Prayer.mode` (MANUAL | GUIDED), `User.prayerVoice` (consent-gated)
- [x] `ReminderPreference` table (presets + custom later); grace offer fields
- [x] `PrayerList.closesAt`, `prayerSeconds`; `DailyStats` table
- [x] `setSelfName` callable; `mergeAccounts` function
- [x] `ExternalPerson` table (SOCIAL | BASE_SET, platform/handle or NamUs ID,
      displayName, firstSeen, activeFrom/Until)
- [x] `PrayerListEntry`: surrogate id; subject XOR externalPerson (DB check);
      moderation reason category
- [x] Update `OPERATIONS.md` (operation map)
- [ ] Write connector `.gql` operations with @auth + generate the Dart SDK

### Functions & live state [be]
- [ ] `onAuthUserCreated` (User + self "Me"; detect anon→permanent linking)
- [ ] `onPrayerLogged` (list count, streak + grace rules, last-hour stats)
- [ ] Admin-only callables (admin custom claim): assemble, moderate, publish,
      setEntitlement
- [ ] `assembleNextList`: settle N, ingest harvest, flip N+1 current, draft
      entries (app carried items + social + base set), auto-flag rules
- [ ] Prayer drafts in `/presence/{uid}/{deviceId}` + 6h auto-save job
- [ ] Presence: private `/presence/{uid}` + throttled public `/stats/live`
      publisher (~5s) + 1-min reconcile job
- [ ] RTDB + Storage rules (public-read `videos/`)
- [ ] RTDB `/config` (public-read, server-write): grace cap (2), grace
      interval (7), presence threshold (10), min app version — replaces Remote
      Config (usage-based pricing since 2026-09-01)

### Data & pipeline [ops]
- [ ] Backfill lists 1..N + participants from `publishing/*.json`
- [ ] Import NamUs base set as `ExternalPerson` rows
- [ ] Cut harvest / publish / finalize skills over to the DB (before launch)
- [ ] Print PDF skill reads from the DB
- [ ] Publish step sets videoPublishedAt, post links, sealVariant; uploads video

### App foundations [app]
- [ ] Fresh Flutter project (POC = reference only); architecture conventions in `app/CLAUDE.md`
- [ ] Generated SQL Connect Dart SDK wired up
- [ ] Offline-first prayer write queue
- [ ] ~500-name soft safety cap (abuse only, not a paywall)
- [ ] Analytics events from day one (first prayer, list prayer, D1/D7/D30,
      trial start, conversion, invitation accepted, last call opened)
- [ ] Minimum app version (RTDB `/config`)
- [ ] Design tokens: dark/antique palette, avatar tone palette, wax-seal vectors

---

## Stage 1 — Private beta (TestFlight / internal track)
Beta users get premium via a one-off grant (`includeLimit`) — no billing yet.

- [ ] [app] Onboarding: splash → mechanic line → "What's your name?" → who else
      do you hold → main screen
- [ ] [app] Main screen: personal list (names + indented intentions), pinned list
      row with seal avatar + carry-status line, unprayed dots, search/filter
- [ ] [app] In-prayer mode: halo, nav removed, footer prayer bar (timer, "with N
      others", ✕), check = holding with ember + haptic, selection rules,
      FAB ring → Amen at 5s
- [ ] [app] List invitation at Amen (tap-then-ring, states who'll be carried)
- [ ] [app] Draft persistence + 30-min resume / "Finish your prayer?" recovery
- [ ] [app] Add name (40) / add intention (80, "For: Me" default); aliases;
      archive / restore / purge; resolve: Answered vs Release
- [ ] [app] "Your portion" screen: preview, carried meter, include/remove,
      Held for review / Not printed states
- [ ] [app] Subject detail: lists it's been on, world count (live stitch), my
      history, gaps in days
- [ ] [app] List detail: full-bleed self-hosted video, "being filmed" state
- [ ] [app] Streak = days with the world (header badge + sheet: sealed/hollow
      marks, monthly personal count), grace offers/bank, milestones
- [ ] [app] Local notifications: reminder choice, ~8pm last call, permission after first Amen
- [ ] [app] Presence line + footer count with fallback ladder
- [ ] [app] Sign-in / linking prompts (after first prayer, ~3-day streak)
- [ ] [app] In-app account deletion
- [ ] [biz] Privacy summary + draft policy/terms; 13+ gate
- [ ] [ops] Daily routine running fully on the DB

**Beta exit question:** does the app beat commenting 🙏 for the people who try it?

---

## Stage 2 — Public launch
- [ ] [biz] Price + tiers (Q3); billing provider (Q15 — RevenueCat favored for
      anonymous users + restore)
- [ ] [be] Entitlement webhook → `setEntitlement`
- [ ] [app] Reverse trial (14 days from first prayer, day-10 notice, end flow:
      invite → trim → second invite)
- [ ] [app] Paywall moments: over-limit meter (17/15) on save, "Not on the list ·
      all N places in use" on add; purchase before sign-in, sign-in prompt after
- [ ] [app] Opt-in "Today's list is live" push (FCM)
- [ ] [be] Turn on + tune the word blocklist / automated flagging
- [ ] [biz] Store listings ("One list. Everyone. Every day."), privacy labels,
      lawyer-reviewed policy
- [ ] [ops] Social funnel: `/go/` links, deep links into the app

## Stage 3 — Fast follows
- Guided prayer ("Help me pray") — premium, consent-gated tradition voice
- Photos for names (high priority)
- Running answered total on the list / captions
- Server-side print PDF + small web review console (so others can help)
- Private photo of a user's portion on the physical list

## Stage 4+ — Future (shape early decisions now)
- **Private, non-anonymous prayer groups** — tier-2 counts, group presence
  showing who, real names (aliases stay owner-only)
- **Tap-to-pray feed** of opt-in requests, unlocked by praying for the list
  (reuse the moderation pipeline)
- Usernames / following — at scale, seeing when people you follow are in prayer
- Link social handles to app accounts (Q18)
- Physical printing at 100k+ names (Q20)
- Location capture (consent-gated) + "where I prayed" map
- Child accounts; scheduled transition; server-side
  validation of the community rule; regions / data residency

### Early decisions these imply (already reflected above)
- **Groups via a share table, not `groupId`** (2026-10-18): later `Group` (type
  FAMILY | CIRCLE | CONGREGATION | ORGANIZATION, optional `parentGroup` for
  church → denomination), `Membership` (role), `Share` (subject → group or
  PUBLIC; one item, many targets). Family = a group type. Public feed = PUBLIC
  share target (intention text, never full names). Aliases stay owner-only.
- **Prayers may link to items owned by others** (group members praying for a
  shared item). "My prayers" always filters by who prayed; permission comes from
  the operation (owner, or member of a group the item is shared to). Tier-2 group
  counts fall out of this.
- **`PrayerList.scope`** (default GLOBAL) with list numbers unique per scope —
  room for future church/organization lists (possible business line).
- Noted for later: printed duplicates when two family members carry the same
  person; reporting/blocking (needed for groups/feed); GDPR data export; family /
  gift plans via a separate entitlement table; an **"In memory" state** for
  departed souls (praying for the dead is common in several traditions).
- Subject `parent` seam; groups via share table (no `groupId`)
- Presence keyed so it can be scoped to a group
- One moderation pipeline for list names, intentions, and future public text
