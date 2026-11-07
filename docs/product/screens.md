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
  (Tier B). Revised 2026-11-07: **two steps for a new name** (who they are,
  then what to carry), so the carry decision and the upsell live in one
  place.
  - **Copy rule (whole app):** "the list" only ever means the **printed** list
    (named by number where useful). The user's own screen is never called a
    list ("your list" is never used); their items are simply "added".
  - From footer ＋: opens on **Name**; a native segmented control in the
    toolbar switches Name | Intention. From a name's detail page (or row):
    opens the **person form** (step 2 below) for that person.
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
  - **Step 1 — Name tab (who they are; no carry here):**
    1. **Avatar** — its own clear row, **~64 pt, centered**. Tone picked
       once at open (design-direction §1b); initials follow the display
       name live (alias if set, else the name); empty: the tone with "…".
       Color never changes. **v1 not tappable**; v2 tap → color / photo
       (here and in Edit).
    2. Header **Name** · field placeholder **"e.g. Gary Olson"** (single
       line). Focused on open. (No asterisk or "(Required)": Add stays
       disabled until there's a name.)
    3. Header **What you call them · optional** · placeholder **"e.g. Mom"**
       (single line) · footer **"Only you see this"**.
    - **Add saves the name at once** (nothing is lost if they leave), carried
      by default while there's room (auto-carry, monetization.md), then the
      sheet pushes (horizontal, forward) to step 2.
  - **Step 2 — the person form** (after adding a name, and "+ Intention"
    from a name's page or row; one layout, the only place a specific
    person's carrying is decided):
    - Toolbar: after adding a name, native title **"Added"** and **Done**
      (trailing; no leading button, no back: the name is saved). From a
      name: **X** (leading) / **Done** (trailing), no title.
    - A clear header row with the person as on Home: **Home-row avatar
      (44 pt) + the serif name** (VoiceOver: one item, the name).
    - Field section: header **"Add an intention now?"** after adding a name
      ("Intention" from a name's page) · the intention field ("e.g. Healing
      after surgery"), **grows 1 → 3 lines** (`axis: .vertical`,
      `lineLimit(1...3)`; no line breaks: Return = Done, pasted breaks become
      spaces). Focused (keyboard stays up, even when the pool is full).
    - **Carry section:** header **"Carry onto the list ✱"** (bloom trailing,
      `inkMuted`, `size.carriedMark.carryRow` = 15 pt via
      `@ScaledMetric(relativeTo: .body)`); a native **segmented control
      "Not now · Name · Name + intention"**; footer = the meter, and "Make
      room for {alias}" when something doesn't fit.
      - **Default = the most that fits:** "Name" (or "Not now" if even the
        name doesn't fit). **Until the user touches the control**, typing
        an intention moves it to "Name + intention" if that fits; once
        they've picked a segment themselves, typing never overrides it.
        Clearing the intention while "Name + intention" is selected (auto or
        picked) falls back to "Name" and disables that segment; a picked
        "Not now" or "Name" is never changed. "Name + intention" is disabled
        while the intention is empty.
      - Segments that don't fit the pool are disabled, and "Make room for
        {alias}" (blue, **visible but inert** until Membership / Your
        portion exist; VoiceOver hint "Not available yet") sits under the
        meter. Its menu is part of the monetization decision (Q31/Q32).
      - From a name's page, the control starts at the person's current
        state (e.g. "Name" if the name is carried).
    - **Done** applies the carry choice and adds the intention if one was
      typed (empty = just the carry choice), then closes. Swiping the sheet
      away keeps the defaults (the name as saved in step 1).
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
    2. Header **Intention** · the growing field (as in step 2). Focused when
       the tab opens.
    3. **Carry row:** one native **Toggle** titled **"Carry onto the list ✱"**
       with the meter as its subtitle; footer "Make room for this intention"
       when it doesn't fit. On by default while there's room. **Intention
       under an uncarried name:** starts off, enabled while there's room;
       when on, a second subtitle line "Also carries {alias} · uses N {unit}"
       (N counts everything it carries, this item included: re-carrying the
       name brings back its intentions still flagged).
    - Add saves and closes.
  - **Meter** (both carry controls; what's left, not including this item):
    "{left} {unit} left"; when the selected choice takes all that's left:
    "This uses your last place" / "…your last {N} places"; full or over:
    "All {pool} {unit} in use" (pool of 1: "Your one place is in use").
    Free pool: "Free carries you and one intention of your own" (pending
    Q32). `{unit}` from one formatter ("places" today; "people" if Q32 is
    adopted). "Make room for {alias}" updates after typing pauses ~0.6 s
    with a ~150 ms crossfade; bare "Make room" before a name exists. Home
    never marks an uncarried item (design-direction §5).
  - **Keyboard stays up:** switching tabs focuses the new tab's field in the
    same frame; step 1 → step 2 keeps it up (the intention field takes
    focus); the For push drops it and returning refocuses. The app never
    hides the keyboard itself while a text field is next; user dismissal
    still works.
  - **Validation & states** (section footers or a top notice row: plain ink
    text on a clear row; errors in ink, never red): contact-info message
    under the field ~0.5 s after typing pauses, Add/Done disabled while
    shown. Caps stop input at the limit; a "34/40" counter in the footer only
    in the last 10 characters. Notice row at the top: offline "Adding needs a
    connection." (Add disabled; stays while offline); generic failure
    "Couldn't add this right now. Try again in a little while." (Add stays
    enabled; clears on edit or next Add); ~500 cap "You've reached 500 names
    and intentions. Archive some to add more." (Add disabled). Text is
    always kept.
  - **Server disagrees** (pool filled from another device; the result isn't
    carried as chosen): don't close silently. "Saved, but not carried. The
    list's places filled up." (under the person header in step 2; the top
    notice row on the Intention tab); toolbar shows only Done; read-only end
    state (keyboard down).
  - Least-used tone counts names only, Me included, by visible tone. `{pool}`
    comes from the entitlement; `basePremiumPool` from client `/config`
    (fallback 10).
- **Screens:** Home · Today's list (seal, video, counts, who's carried →
  portion) · Past lists · Name/Intention detail · Your portion · History
  (account-wide, grouped by day, streak/grace marks) · Prayer detail (note) ·
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
