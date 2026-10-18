# Prayer Flow — the act of praying

_Last updated: 2026-10-17_

## DECIDED
- **`logPrayer` is an optimistic client write** (offline-capable — praying at a
  sentimental place without signal must not fail). Writes one `Prayer` +
  `PrayerSubjectLink` per included subject.
- **`Prayer` is immutable history.** Note is the only editable field
  (`updatePrayer` is NOTE-ONLY). No deletion.
- **`communityList`** set when the prayer is the user's community prayer for the
  current list; null for personal-only prayers.
- **`listContextNumber`** always set = current list number at prayer time.
- **What a prayer can hold** (2026-10-17): any combination of the current list
  and/or the user's own subjects — or nothing at all (a "general prayer").
  A prayer that does NOT include the list is valid and logged
  (`communityList` = null). Only a prayer that includes the current list earns
  the user (and their carried subjects) a place on the next list.
  SUPERSEDES the 2026-06-24 UI rule "community prayer must come before personal
  prayers" — there is no ordering requirement.
- **Main screen** (2026-10-17): the user's personal prayer list (souls +
  intentions), with today's list as a row pinned at the top.
- **Starting with focus** (2026-10-17): opening a row's detail (the current list
  or a subject) offers "pray" with that item already included; the user can add
  others.
- **Side effects are reactions** (`onPrayerLogged`): bump list count, mirror to
  RTDB, update streak. Not inside logPrayer.
- **Location: DEFERRED past MVP** (2026-10-18; supersedes "capture from day
  one"). Accepted that early prayers won't have it. Schema fields can stay
  nullable/unused.
- **Prayer notes at MVP** (2026-10-18): optional "Add a note" after Amen;
  private, editable later (note-only edits).
- **Live "in prayer" state is RTDB presence, not a Prayer row.**


## In-prayer UX (2026-10-17)

### DECIDED
- **Option B — prayer happens in place.** Starting a prayer does not change
  screens. The main list stays in view; search and filters (e.g. "unprayed")
  persist across the mode change because it is the same view.
- **Mode change is unmistakable:** a halo forms around the screen (POC already
  has it), header nav/menu access is removed, the bottom nav is repurposed as
  the prayer bar (elapsed time, others-in-prayer count, ✕ to cancel).
- **Rows in prayer:** the `>` affordance becomes a checkbox. Tapping a row checks
  it ("I'm holding this one now"). In nav mode, tapping a row opens its detail.
- **The check is a moment, not a checkbox:** checking adds a subtle halo/sparkle
  on the avatar/name so the act carries weight.
- **The pray FAB stays in place.** On start it gets a decaying ring for the
  minimum time, then becomes **Amen**.
- **Minimum time ≈ 5 seconds.** A quick, earnest prayer must not be blocked.
  ✕ is available at any time.
- **No list pre-check.** If the prayer ends without the current list included
  (and the user hasn't prayed for it yet), Amen opens a quiet, standalone
  invitation to hold today's list — a special moment of its own.
- **List invitation = tap-then-ring** (2026-10-17). One tap starts a 5s ring
  (same visual language as the FAB), seconds count up in the center, copy shifts
  to "holding the 4,345 on List 52". Amen appears after 5s; they can stay longer.
  The invitation also states the reward: "You [and Mom, Dad] will be carried on
  List 53" — naming only subjects actually carried (wording for paid slots TBD
  in the monetization meeting).
- **Unprayed indicator:** a small dot to the left of each unprayed avatar
  (POC uses pink). The current-list row shows it too.

### DECIDED (2026-10-18, confirmed from PROPOSED)
- One Prayer per session; the list invitation at Amen extends the same prayer.
- Under 5s: ✕ or leaving discards (nothing logged). Amen isn't available before
  5s, so the only sub-5s exit is an explicit cancel — no silent loss.
- A prayer that starts before the ~6am flip counts for the list current at start.
- Avatar tone stored as a palette index; nullable `avatarPath` seam for photos.

### PROPOSED (needs confirmation)
- **Check moment restraint:** a soft ember/glow (darker over brighter), light
  haptic, once per check; uncheck is silent; respect Reduce Motion.
- (moved to DECIDED: tap-then-ring)
- **One prayer, not two:** the invitation extends the same Prayer — the write
  happens once, at final close, with `communityList` set if they accepted.
  Dismissing writes the prayer without the list. Duration includes both parts.
- **Under the minimum:** ✕ or leaving before 5s discards (nothing logged).
- **List flip mid-prayer** (~6am MT): credit the list that was current when the
  prayer started (`listContextNumber` = list at start).
- **Session survives backgrounding/crash:** persist in-progress state locally;
  RTDB presence uses `onDisconnect`.

## Main screen rows (2026-10-17)

### DECIDED
- **Row anatomy:** title line (list number / soul name / intention) + one line of
  smaller secondary text.
- **Current-list row (pinned top) secondary text** reflects carry status:
  - not yet prayed: "You and [avatars] + 4 others are not yet carried on List 53"
    (soft muted color),
  - prayed: "You and [avatars] + 4 others will be on List 53" (soft positive color).
  Overlapping avatars of the user's carried subjects. The list detail page shows
  them in full.

- **Secondary text = one state-dependent line** (2026-10-17), same in nav and
  in-prayer modes: answered → "Answered · Oct 3"; prayed today →
  "Prayed today · 12 days"; otherwise → "Last prayed 3 days ago". World count
  and list history live on the detail page. A small mark shows if the subject
  is carried on the next list.
- **Avatars at MVP = monograms** (initials on a muted tone). **Photos are a
  high-priority fast-follow after release** (significant emotional weight).
- **Avatar color:** computed by default, user can change it (see PROPOSED).

### PROPOSED
- Avatar color: default derived from a hash of the subject ID (not the name, so
  renaming doesn't change it), from a small curated palette of muted/antique
  tones that work in light and dark. User can pick another palette swatch on the
  edit screen. Store a palette index (`PrayerSubject.avatarTone: Int`), not a
  hex value, so the palette can be retuned later. Add nullable
  `avatarPath: String` now as the seam for photos (private Storage, owner-only).
- Copy: "carried" instead of "planned"; avoid red (urgency) — muted gray →
  soft green/gold.
- **Free users' list row** names only who is actually carried (self, until paid
  slots exist). Below-the-fold subjects never appear as "will be on." (Paid-slot
  wording is part of the monetization meeting.)

- **Guided prayer ("Help me pray", working name)** (2026-10-18): post-MVP
  premium feature (some free per week, then upgrade). Generates a prayer in the
  user's chosen tradition voice from the current list + their unprayed items;
  "I prayed this" logs one prayer holding exactly those items. Add schema seams
  now: `Prayer.mode` (MANUAL | GUIDED), consent-gated `User.prayerVoice`.
  Before building: religion = special-category data (explicit consent, privacy
  policy), confirm AI provider data terms (no training), carefully written
  prompts per tradition + a "flag this prayer" path, frame as help with words.

## OPEN
- **In-progress prayers — option C** (2026-10-18): the draft lives in RTDB in
  the user's presence node (startedAt, checked item IDs only, listIncluded,
  lastActiveAt heartbeat ~1/min while foregrounded). The `Prayer` row is still
  written ONCE at Amen (history stays immutable; no in-progress rows in Postgres).
  RTDB offline persistence covers offline starts.
- **Returning after backgrounding:** back within ~30 min → resume quietly
  (locked-screen prayer is normal); later → "Welcome back. Finish your prayer
  from 7:42?" [Amen] [Discard], duration = until they left + up to 30 min.
  Later enhancement: let the user say whether they were in prayer the whole time
  or "pick up where they left off".
- **Presence while backgrounded:** keeps counting for ~30 min, then drops.
- **Never returns:** a server job auto-saves drafts after ~6h. Estimated
  duration = last foreground moment + up to 30 min, capped at 4h from start;
  `Prayer.endedBy = AUTO` (vs AMEN); shown with "~" ("~38 min"). Counts toward
  streak, gate, and totals, on the local day it STARTED. No duration limit while
  actively in prayer (quiet 4h sanity cap on the recorded value).
- **Drafts are per device at MVP** (`/presence/{uid}/{deviceId}`); no
  cross-device continuation and never an automatic mode switch. Later: a quiet
  banner on other devices ("A prayer from 7:42 is open on your phone" —
  Continue here / Amen / Discard). Presence counts people, not devices.
- **Post-prayer moment:** what does the user see after finishing (you're on List
  N+1, streak +1, count)?
- **Offline:** what does the UI show for a queued prayer (list number may have
  flipped by the time it syncs — `listContextNumber` uses client's view?).

## DEFERRED
- Server-side validation of the community rule.
