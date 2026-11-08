# Screens & Navigation

_Last updated: 2026-10-18_

## Language & scripts (2026-10-18)
- App UI follows the device language, with an override in settings.
  `User.locale` stores the effective language for server-written content
  (push copy, future email, guided prayer).
- Names/intentions may be in any script even while the UI is English-only.
  40/80 caps count visible characters (grapheme clusters), not bytes.
- Print PDF must use fonts covering all scripts (e.g. Noto family).
- Layouts on both platforms use leading/trailing, never hard-coded left/right, so RTL works later.

## DECIDED
- **Orientation** (2026-11-07): phones are portrait only, on iOS and Android.
- **Avatar cluster component** (2026-10-18), reused on the list row, Amen
  invitation, Today's list page, and Your portion: you first, then carried names
  in the user's order (intentions have no avatars). On the community card
  (2026-11-02) it fills the card's width with a "+N" disc only on measured
  overflow, and no names in text — the status line follows below
  (design-direction §6). Other contexts may name the first one or two.
  Screen readers read every name.
- **Copy rule:** wherever the app says "the list", it says who's on it.
- **Home = the prayer screen** (personal list + pinned today's-list row). It is
  the only screen with the footer bar; other screens push with a back arrow.
- **Header:** left = avatar (→ You/settings) with the **streak badge** beside it
  (tap → streak sheet: current/best, grace days held, month view of days
  prayed); right = search + filter. No centered title. (2026-10-18)
- **Today's list page** shows the lifetime "You've been carried on N lists".
  No second streak anywhere; row secondary text stays carry status, not metrics.
- **Footer:** [ History ] ( 🙏 ) [ ＋ Add ]. In prayer it becomes the prayer bar
  in place: [ timer ] ( Amen ) [ with N · ✕ ].
- Starting a prayer from a detail page **stays on that page** (revised
  2026-11-03; was: returns to Home): the page strips down to the subject and
  its intentions, the subject pre-checked. See `detail-page.md`.
- **One detail page for names and intentions** — the intention version hides
  what doesn't apply (no nested intentions, no avatar edit) and adds its parent
  name + Answered/Release.
- **Add sheet (one bottom sheet, two entry points):** a native sheet with
  detents (design-direction §0), **built on the native form** (SwiftUI
  `Form`, inset grouped; Compose equivalent later). The spec defines content
  and behavior; the platform owns spacing, type, alignment and row styling
  (Tier B). Revised 2026-11-07: adding a name **lands on the person's page**,
  where intentions and carrying continue.
  - **Copy rule (whole app):** "the list" only ever means the **printed** list
    (named by number where useful). The user's own screen is never called a
    list ("your list" is never used); their items are simply "added".
  - From footer ＋: opens on **Name**; a native segmented control in the
    toolbar switches Name | Intention. From a person's page (or a Home
    row's long-press): opens the **add-intention form for that person**.
  - **Sheet size:** the standard large sheet. **The keyboard rises with the
    sheet** in one motion: focus is set before presentation (`.defaultFocus`
    / `@FocusState` in `onAppear`, no delayed dispatch); if SwiftUI can't do
    it reliably, a small UIKit text-field bridge calling
    `becomeFirstResponder` when its view enters the window.
  - Default section spacing. New items go to the **bottom** of their level.
  - **Form styling:** the form's own background is hidden so the sheet keeps
    its material; rows use `raised`; headers, footers and row text use the
    platform's styles with our color roles (ink, `inkMuted` via the system
    secondary role, blue only for actions).
  - **Toolbar (Name and Intention tabs):** round glass **X** (leading;
    VoiceOver "Cancel") · segmented control (center) · **Add** (trailing, a
    word), always at opposite ends.
  - **Name tab (who they are; carrying is managed on their page):**
    1. **Avatar** — its own clear row, **~96 pt, centered** (large: the
       avatar is how people recognize someone), with **tight vertical
       insets (~8 pt above and below)** so the row isn't airy. Tone picked
       once at open (design-direction §1b); initials follow the display
       name live (alias if set, else the name); **empty: a person glyph**
       (SF Symbol `person.fill`, white at the initials' 70% opacity) until
       typing begins.
       Color never changes. **v1 not tappable**; v2 tap → color / photo
       (here and in Edit).
    2. Header **Name** · field placeholder **"e.g. Gary Olson"** (single
       line). Focused on open. (No asterisk or "(Required)": Add stays
       disabled until there's a name.)
    3. Header **What you call them · optional** · placeholder **"e.g. Mom"**
       (single line) · footer **"Only you see this"**.
    - **Add saves the name** (auto-carried while there's room), **closes
      the sheet and opens the person's page** (detail-page.md), as Contacts
      and Calendar open what you just created. There, the person can be
      prayed for at once, "＋ Add a first intention for {alias}" invites the
      next step, and the carry card ("Private · in your prayers only",
      "Make room for {alias}" when full) is the upsell, every visit rather
      than only at add time; that private footer is how an uncarried name
      is never saved silently. **Interim, until the page exists in the
      app:** Add saves and closes back to Home, **except** when the name
      ends up not carried (no room, or the server disagrees): then the sheet
      stays with the notice row "Saved, but not carried. All {pool} places
      are in use." and only Done (read-only end state).
  - **Add-intention form for a person** ("＋ Add intention" / "Add
    a first intention for {alias}" on their page, and the long-press "Add
    intention" on a Home row): toolbar **X** / **Add**, no title; a clear
    header row with the person as on Home (Home-row avatar 44 pt + serif
    name; VoiceOver one item); header **"Intention"** + the growing field
    (1 → 3 lines, focused, Return = Add, no line breaks); then the same
    **carry toggle** as the Intention tab (below). Add saves and closes.
    SUPERSEDES the two-step "Added" step and its "Not now · Name · Name +
    intention" segmented control (7f13a83 / 55445f4 / f5dbd7a).
  - **Intention tab** (choosing who it's for; adds one intention):
    1. **For** — a native navigation row: ~40 pt avatar with initials + the
       name, Settings-style ("For · (D) Dad ›", system font), default Me.
       Pushes **"Who is this for?"** (native inline title): a native list
       with a search field that **starts inactive** (title and back stay
       visible; the keyboard goes down on this tap-only screen) over
       everyone in Home order, Me first, matching name + alias like Home
       search; the current person has the native checkmark (ink); no
       matches → 'Nothing matches "{query}".' Picking, or going back,
       returns and refocuses the intention field. Changing the person resets
       the carry toggle to that person's default.
    2. Header **Intention** · the growing intention field (1 → 3 lines;
       Return = Add; no line breaks). Focused when
       the tab opens.
    3. **Carry row** (Q32, 2026-11-08): one native **Toggle "Print with
       {alias} ✱"** (under Me: "Print with your name ✱"). On by default when
       the person has no chosen intention; when one is already chosen it
       starts off, with subtitle **"Instead of “{chosen intention}”"** (on =
       swap). Intentions cost no place. **Person not carried:** on also
       carries them: subtitle "Also carries {alias} · {left} places left";
       disabled with "Make room for {alias}" when the pool is full.
    - Add saves and closes.
  - **Meter** (carry controls on people; a place = one carried person, Q32
    2026-11-08): "{left} places left"; when this person takes the last one:
    "This uses your last place"; full or over: "All {pool} places in use"
    (never negative). Free tier, on a person: "Free carries you and your
    intention" with "Make room for {alias}". "Make room for {alias}" on the
    person page and the sheet's Name tab when full (the name is known, so
    there's no typing delay). Home never marks an uncarried item (design-direction
    §5).
  - **Accessibility:** only the visible tab's content is in the
    accessibility tree (the hidden tab's controls are removed or
    `accessibilityHidden`, never just faded).
  - **Keyboard stays up:** switching tabs focuses the new tab's field in the
    same frame; the For push drops it and returning refocuses. The app never
    hides the keyboard itself while a text field is next; user dismissal
    still works.
  - **Validation & states** (section footers or a top notice row: plain ink
    text on a clear row; errors in ink, never red): contact-info message
    under the field ~0.5 s after typing pauses, Add disabled while
    shown. Caps stop input at the limit; a "34/40" counter in the footer only
    in the last 10 characters. Notice row at the top: offline "Adding needs a
    connection." (Add disabled; stays while offline); generic failure
    "Couldn't add this right now. Try again in a little while." (Add stays
    enabled; clears on edit or next Add); ~500 cap "You've reached 500 names
    and intentions. Archive some to add more." (Add disabled). Text is
    always kept.
  - **Server disagrees** (pool filled from another device; the result isn't
    carried as chosen): don't close silently. "Saved, but not carried. The
    list's places filled up." (under the person header in the
    add-intention form; the top notice row on the Intention tab); toolbar shows only Done; read-only end
    state (keyboard down).
  - Least-used tone counts names only, Me included, by visible tone. `{pool}`
    comes from the entitlement; `basePremiumPool` from client `/config`
    (fallback 10).
- **Screens:** Home · Today's list (seal, video, counts, who's carried →
  portion) · Past lists · Name/Intention detail · Your portion · History
  (one screen: everyone or filtered to a person; All · Held · Lists · Journal · Answered;
  history.md) · Prayer detail (journal entry) ·
  You (settings) · Archived · Membership/paywall · Onboarding.
- **You (settings) contents:** name (edit limit), sign-in/link, membership
  (trial, upgrade, restore), reminders, notifications (incl. "Show names in
  notifications"), notifications, grace offers toggle, appearance
  (System/Light/Dark, default System; device-local, 2026-11-05),
  Archived, privacy & terms, delete account, about the ritual, and **Sign
  out** at the very bottom (only once the account is linked; never for an
  anonymous account; auth-onboarding.md). Settings are stored on the User
  record (sync across devices), except appearance (device-local; if You gains
  a display group, appearance moves into it). Location consent: later.
