# App Brief — handoff for the Flutter session

_Written 2026-10-18 from the product meetings of 2026-10-17/18._
**Audience:** an agent building the Flutter app in `app/`. This pulls every
screen, component, flow, state, and copy rule into one place. Each section names
the spec file behind it — read it when a rule is unclear. Data shapes come from
`schema-brief.md`; don't invent fields. The existing `app/` code is a hacky
Firestore POC: **reference only** (its in-prayer mode and halo are the right
idea), not a pattern to follow.

---

## 0. Non-negotiables
- **Brand voice** (root `CLAUDE.md`): observational, spare, human. No hype, no
  urgency, no confetti. At most one restrained emotional line per moment.
- **Darker over lighter; antique over bright.** Dark theme is the primary design.
- **Privacy:** names are never public. Counts only for anything shared. Aliases
  are owner-only. Intention text never appears in notifications.
- **No ledger of absences:** never show empty days, ratios ("14 of 16"), zeros
  for streaks, or "0 lists". Counts only grow.
- **Never a silent choice:** the app never drops someone from the list without
  telling the user, and never auto-switches modes.
- **Humane upsell:** never fire an upgrade prompt on a freshly added subject;
  paywall moments are quiet and appear where the user is already acting.
- **The community is the offering:** the list prayer is the primary habit.

## 1. Architecture guidance
- **Data:** SQL Connect generated Dart SDK (named operations only — never compose
  queries). **Live:** RTDB `/stats/live`, `/lists/current` (incl. `closesAt`),
  `/config` (with compiled-in defaults), and the user's own
  `/presence/{uid}/{deviceId}` (also the in-progress prayer draft).
- **Offline-first:** a prayer must succeed with no signal. `logPrayer` uses a
  client-generated UUID and queues; drafts persist via RTDB offline persistence.
  Only the very first launch needs a connection ("Connect to begin").
- **Notifications:** `flutter_local_notifications` `zonedSchedule`, rescheduled
  ~7 days ahead on each app open (iOS 64-pending cap). FCM only for the opt-in
  "Today's list is live".
- **Analytics from day one** (Firebase Analytics): first_open, name_set,
  first_prayer, prayer_logged (with/without list), invitation_shown/accepted,
  last_call_opened, streak_milestone, grace_offer_accepted/declined,
  trial_started, trial_ended, paywall_shown, purchase, sign_in_linked.
  D1/D7/D30 retention derives from these. Never log names or intention text.
- **Min app version** from `/config`: gentle blocking screen if below.
- **Layouts:** no hard-coded left/right (RTL later). Text in any script; caps
  count grapheme clusters (40 name / 80 intention).
- **State is derived from data, not step counters** (e.g. onboarding resume).

## 2. Navigation (screens.md)
- **Home** is the only screen with the footer. Everything else pushes with a back
  arrow.
- **Header:** left = avatar (→ You) with the **streak badge** beside it; right =
  search + filter. No centered title.
- **Footer:** `[ History ]  ( 🙏 )  [ ＋ Add ]`. In prayer it becomes
  `[ timer ]  ( Amen )  [ with N · ✕ ]` in place.

## 3. Screens

### Onboarding (auth-onboarding.md)
1. Splash: "Your name, carried by the world."
2. One plain line: "Pray for today's list. Tomorrow, you're on it."
3. **"What's your name?"** — personal, warm; helper text that their name will be
   carried by the world in prayer, plus the privacy sentence ("Printed once on a
   single private copy. Never shared, never shown."). Calls `setSelfName`.
4. "Who else do you hold?" — optional; add names/intentions (trial carries them).
5. Home; pray button gently pulses. No tour.
6. After first Amen: "You'll be carried on List 53." → reminder choice
   (Morning default on) → notification permission.
- Anonymous auth is silent. Resume by state: no self name → step 3; else Home.
- Sign-in prompts ("Keep your list safe"): after first prayer (soft), ~3-day
  streak, before trial end, and right after any purchase. Purchase never
  requires sign-in. Link conflicts: empty anon → switch silently; both have data
  → [Use my existing account] / [Merge both] with a duplicates warning.

### Home (prayer-flow.md, screens.md)
- **Pinned list row** (top): wax-seal avatar (unsealed + "being filmed" before
  publish; sealed in that day's wax after), "List 52", avatar cluster + carry
  line: not yet → "You, Dad ●●● + 4 others are not yet carried on List 53"
  (muted); prayed → "…will be on List 53" (soft green/gold). During the 5-min
  close window: quiet "List 52 closes in 5 minutes" banner (only if not prayed
  with the list today).
- **Rows:** names (manual drag order; self "Me" pinned top), intentions indented
  under their name. Title + one secondary line: "Answered · Oct 3" /
  "Prayed today" / "Last prayed 3 days ago". Small mark if carried on the next
  list. Unprayed dot (POC pink) left of unprayed avatars. No metrics on rows.
- **Search + filter** (All · Unprayed today · Carried) persist across modes.
- **Presence line:** quiet, using the ladder (live ≥10 → last hour ≥10 → today
  ≥10 → hidden). Never 0.
- Nav mode: tap row → detail. In prayer: tap row → check.

### In-prayer mode (prayer-flow.md)
- Begin: halo forms around the screen, header nav removed, footer becomes the
  prayer bar (elapsed timer, "with N", ✕). Rows' `>` becomes a checkbox.
- **Check = "holding this one now"**: soft ember glow on the avatar/name + light
  haptic, once; uncheck silent; respect Reduce Motion.
- Selection: checking an intention also holds its name; checking a name doesn't
  check its intentions; unchecking a name unchecks them; partial state on names.
- **FAB:** decaying ring for 5s, then becomes **Amen**. Before 5s only ✕ exits
  (discard, nothing logged).
- **Amen without the list** (and not yet prayed with it today): standalone quiet
  invitation — "Hold the 4,345 on List 52 in your prayer" + who'll be carried
  ("You, Daniel + 4 others will be on List 53"). **Tap** → 5s ring with seconds
  counting up → Amen appears; may stay longer. Extends the same prayer.
- After the final Amen: optional "Add a note" (private), then the closing line.
- Starting from a detail page returns to Home in prayer with that item checked.
- Backgrounding: back within ~30 min → resume quietly; later → "Welcome back.
  Finish your prayer from 7:42?" [Amen] [Discard]. Drafts are per device; no
  cross-device UI at MVP.
- Prayer started before `closesAt` counts for that list; after it, the app
  treats N+1 as current (no special UI).

### Add sheet (screens.md)
One bottom sheet. From footer ＋: **Add name** (40), switchable to intention with a
name picker (default "Me"). From a name's detail/row: **Add intention for {alias}**
(80), picker hidden. Optional alias. New items go to the bottom. After adding a
name, offer once: "Add an intention for Dad?". Auto-carried while the pool has
room; when full, the new row shows "Not on the list · all 15 places in use"
(tap → Your portion).

### Name / Intention detail (stats-history.md)
One page; intentions hide what doesn't apply and add parent name + resolve.
- Header cards: "Held by you · N prayers" (always); "Carried by the world · N
  prayers · N lists" (only if ever carried; live-stitched for the current list).
- **Bead strand history**: period rows (This week, Last week, Earlier in {month},
  months, years; last "Begun · {date}"), each "♡ You prayed N times" + "On N
  lists" (+ "· current"); beads = lists it was on, colored by that list's wax;
  gaps = one neutral line "Off the list · N days". Hints: "✎ 3" notes,
  "✦ Answered". Tap period → prayers with notes, list numbers, answered moment.
- Actions: Pray (with focus), Add intention (names), Edit (name 40 / alias /
  note / avatar tone), Archive; intentions: **Resolve** → Answered (optional
  thanks note; leaves the list; stays on Home as "Answered · praying in
  gratitude") or Release (no gratitude implied; to archive).
- "Me" detail shows your own beads (lists you were on).

### Today's list (list-lifecycle.md)
Seal, full-bleed self-hosted video (sound off until tapped; "being filmed"
placeholder until published), counts (souls, intentions, prayers, praying now),
avatar cluster of who of yours is on it, link to Your portion, "You've been
carried on N lists" (lifetime), "All lists" → Past lists.

### Past lists
Each list number with its seal, date, counts, video.

### Your portion (monetization.md)
Illustrative preview of the user's part of the printed list (names with their
intentions). Meter "7 of 10" (free: your name + 1). Tap to include/remove; an
intention requires its name. Over-selecting allowed ("17 / 15" + upgrade mark);
saving over the limit invites upgrade; declining **blocks save** and returns with
extras highlighted. States: "Held for review", "Not printed · {category}",
"Waiting for your choice" (entitlement ended).

### History (stats-history.md)
Prayers grouped by day: time · duration ("7:42 am · 12 min"; auto-saved "~38
min"), what it held, note indicator. Header: "Time in prayer · 2h 14m this week
· 61h all time". Link to the streak sheet. Never ranked or celebrated.

### Prayer detail
What it held, duration, note (editable — the only editable field).

### Streak badge & sheet (streaks-reminders.md)
- Badge states: prayed with the list today → seal in today's wax + N; streak
  alive, not yet today → muted seal + N; zero → muted seal, **no number**.
  Always tappable.
- Sheet: what the badge means ("days with the world"), current + best, grace
  days held (up to 2 marks), month view with **sealed** marks (list days, wax
  color) and **hollow** marks (personal-only days), "Days in prayer this month:
  26", optional month prayer time.
- Grace offer after each 7 list days: "Seven days kept. A grace day is yours if
  you'd like it." [Keep it] [No thanks]; after a decline offer "Don't offer
  again". Full bank: "Seven days kept. Your grace days are full."
- Milestones 7/30/100/365: one plain line. After a break: "Welcome back. {name}
  is still here." No zero, no broken icon.

### You (settings)
Name (edit limit: free until first printed, then once per 7 days — "You can
change this again on Oct 24"), sign-in/link, membership (trial status, upgrade,
restore purchases), reminders (Morning/Midday/Evening toggles + times),
notifications ("Today's list is live" opt-in; "Show names in notifications"),
grace offers toggle, language override, Archived, privacy & terms, delete
account (immediate after one confirmation; note to cancel store subscription),
about the ritual.

### Archived
Archived + released items; restore (names restore only cascade-archived
intentions) or purge.

### Membership / trial end
Reverse trial: 14 days from first prayer, no card. Day-10 local notice. At the
end: invite to subscribe (keep everything) → if declined, Your portion to trim
to free → second invite if still over. Same flow when a subscription lapses
(≤7-day soft landing).

## 4. Shared components
- **Monogram avatar:** initials on a muted/antique tone (`avatarTone` index;
  default from id hash); photo slot reserved for later.
- **Avatar cluster:** you first, then carried names in user order; first one or
  two named with their avatar beside each name; more overlapped, max 5, then
  "+ N others". Screen readers read every name.
- **Wax seal / bead:** 7 vector stamps (wax colors fixed by weekday via
  `sealVariant`); unsealed state.
- **Ring button:** the FAB's 5s decaying ring and the invitation's ring share one
  component.
- **Halo:** screen-edge glow for prayer mode (POC `CustomPainter` +
  `screen_corner_radius`).
- **Ember check**, **unprayed dot**, **carried mark**, **pool meter**.

## 5. Copy rules
- Wherever "the list" appears, say who's on it ("4,345 people, including you
  and Daniel").
- "Carried", never "planned". Avoid red for status.
- Familiar ritual words stay: Amen, grace day. Brand/store: "One list.
  Everyone. Every day."
- Notifications: reminders + last call (~8pm, only if not prayed with the list
  today): not prayed → "A moment for prayer before the day ends."; prayed but
  not with the list → "Today's list is still open. Hold them with you before
  the day ends." Names/aliases allowed (setting can hide); intention text never.

## 6. Suggested build order
1. Project skeleton, theme tokens, components (§4) on mock data.
2. Home + in-prayer mode + invitation + add sheet (mock).
3. Onboarding + auth + `setSelfName`.
4. Wire generated SDK + RTDB (once the backend session ships operations).
5. Detail page (bead strand), Today's list, History, streak sheet.
6. Your portion, settings, archive, deletion, local notifications, analytics.
7. Membership/trial flows (Stage 2 billing; beta uses a grant).

## 7. Not in MVP (don't build, don't block)
Photos, guided prayer ("Help me pray" — schema seams only), location, groups /
sharing / feed, cross-device draft banner, moment reminders, custom reminders,
answered running total, "In memory".
