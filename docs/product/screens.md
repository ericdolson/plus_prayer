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
  detents (design-direction §0). Revised 2026-11-06: **built on the native
  form** (SwiftUI `Form`, inset grouped; Compose equivalent later). The spec
  defines content and behavior; the platform owns spacing, type, alignment
  and row styling (Tier B).
  - **Copy rule (whole app):** "the list" only ever means the **printed** list
    (named by number where useful). The user's own screen is never called a
    list ("your list" is never used); their items are simply "added".
  - From footer ＋: opens on **Name**; a native segmented control in the
    toolbar switches Name | Intention. From a name's detail page (or row):
    opens as the **intention form for that person** (below), no For row.
  - **Sheet size:** the standard large sheet. **The keyboard rises with the
    sheet** in one motion: focus is set before presentation (`.defaultFocus`
    / `@FocusState` in `onAppear`, no delayed dispatch); if SwiftUI can't do
    it reliably, a small UIKit text-field bridge calling
    `becomeFirstResponder` in `viewWillAppear`.
  - Form uses the **default** section spacing (compact made a footer read as
    belonging to the next section).
  - New items go to the **bottom** of their level.
  - **Toolbar:** round glass **X** (leading; VoiceOver "Cancel") / **Add**
    (trailing, a word). Offer step: **Skip** / **Add**, no back button (the
    name is saved). No discard confirmation for now (open-questions D6).
  - **Form styling:** the form's own background is hidden so the sheet keeps
    its material; rows use `raised`; headers, footers and row text use the
    platform's styles with our color roles (ink, `inkMuted` via the system
    secondary role, blue only for actions).
  - **Name tab (form sections, top to bottom):**
    1. **Live preview row** (clear row, top): the person exactly as on
       Home: **~40 pt avatar + the serif display name** (alias if set,
       else the name). Empty: the toned circle + a muted serif "New name".
       Tone picked once at open (design-direction §1b); initials and name
       update live together, so the initials always match the words beside
       them. Color never changes while typing. **v1: preview only**; v2:
       tap the avatar → tone swatches (+ photo), here and in Edit together.
       The same row is the header of the next step (continuity).
       SUPERSEDES the avatar inside the Name row (its initials followed the
       alias and looked disconnected from the typed name) and the earlier
       72 pt centered circle.
    2. Header **Name** · field "e.g. Gary Olson" (single line). Focused on
       open.
    3. Header **What you call them · optional** · field "e.g. Dad" (single
       line) · footer **"Only you see this"**.
    4. **Carry section** (below).
  - **Intention tab:**
    1. **For** — a native navigation row: ~40 pt avatar with initials + the
       name, Settings-style ("For · (D) Dad ›", system font), default Me.
       Pushes **"Who is this for?"** (native inline title): a native list
       with a search field that **starts inactive** (title and back stay
       visible; search is one tap away; the keyboard goes down here because
       this screen is for tapping, a narrow exception to the keyboard rule)
       over everyone in Home order, Me first, matching name + alias like
       Home search; the current person has the native checkmark (ink); no matches
       → 'Nothing matches "{query}".' Picking pops back and refocuses the
       intention field. Changing the person resets the carry toggle to that
       person's default.
    2. Header **Intention** · field "e.g. Healing after surgery", **grows
       1 → 3 lines** (`axis: .vertical`, `lineLimit(1...3)`). No line
       breaks: Return submits (same as Add), pasted breaks become spaces.
       Focused when the tab opens.
    3. **Carry section** (below).
  - **Carry section** (name tab, intention tab, offer step): one native
    **Toggle** whose label is the title **"Carry onto the list ✱"** with the
    bloom trailing it (as the mark trails names on Home; `inkMuted` in every
    state; `size.carriedMark.carryRow` = 15 pt applied via
    `@ScaledMetric(relativeTo: .body)`, so ~15 pt at default and scaling with
    Dynamic Type) and the **meter as the toggle's subtitle**
    (the platform styles and aligns it). Section footer holds **"Make room
    for {alias}"** (a blue button) when the pool is full. `{unit}` comes from
    one formatter ("places" today; "people" if Q32 is adopted).
    - **On by default** while there's room; the user may turn it off (kept
      for their own prayers).
    - **Meter (what's left, not including this item; never changes when the
      toggle flips):** "{left} {unit} left"; on, and the item's full cost
      equals what's left: "This uses your last place" / "…your last {N}
      places"; full or over the pool: "All {pool} {unit} in use" (pool of 1:
      "Your one place is in use"). Free pool, Name tab: toggle disabled,
      "Free carries you and one intention of your own" (pending Q32).
    - **Pool full:** toggle off and disabled; footer "Make room for {alias}"
      ("Make room for this intention" for intentions; bare "Make room"
      before a name exists). **Visible but inert** until Membership / Your
      portion exist (VoiceOver hint "Not available yet"); its menu is part of
      the monetization decision (Q31/Q32). The name in it updates after
      typing pauses ~0.6 s with a ~150 ms crossfade; a prefilled name shows
      at once. Search results and avatar initials stay live.
    - **Intention under an uncarried name** (any reason): starts off,
      enabled while there's room; when on, a second subtitle line shows "Also carries
      {alias} · uses N {unit}" (N counts everything it carries, this item
      included: re-carrying the name brings back its intentions still
      flagged). If that takes all that's left, it reads "This uses your last
      {N} places" and drops the "· uses N".
    - Home never marks an uncarried item (design-direction §5).
  - **Intention form for a known person** (the offer step after adding a
    name, and "+ Intention" from a name's page or row; one layout):
    a clear header row with the person as on Home: **~40 pt avatar + the
    serif name** (the same row as the Name tab's live preview); then the
    growing intention field (focused, keyboard stays up even when the pool
    is full); then the carry section. No For row: the person is given, not
    chosen. {alias} falls back to the name.
    - **Offer step:** native toolbar title **"Added"** (what just happened;
      the form below is the specific next step; no subtitle under the
      name); the field's section header is the question **"Add an
      intention now?"** in sentence case (`.textCase(nil)`), without the
      name (it's right above; long names would break it); toolbar **Skip**
      (leading; closes, the name is saved) / **Add** (trailing).
    - **From a name's page or row:** no toolbar title; field header
      **"Intention"**; toolbar **X** / **Add**.
  - **One tap to save.** Add saves the name at once; the sheet then pushes
    (horizontal, forward) to the offer step above. [Add] disabled while
    empty; after Add the sheet closes (one offer; more from the name's
    page). SUPERSEDES the serif "{alias} is added." + "Add an intention for
    {alias}?" header block (the question didn't read as the field's label).
    Offer-step toolbar: **Skip** / Add (SUPERSEDES "Not now", which only fit
    the old question).
  - **Intention tab Add:** saves and closes (the carry section already said
    whether it's carried).
  - **Keyboard stays up:** switching tabs focuses the new tab's field in the
    same frame; the For push focuses search, then returns focus. The app
    never hides the keyboard itself while a text field is next; user
    dismissal still works.
  - **Validation & states** (as section footers or a top notice row: plain
    ink text on a clear row; errors in ink, never red): contact-info message under the field
    ~0.5 s after typing pauses, Add disabled while shown. Caps stop input at
    the limit; a "34/40" counter in the footer only in the last 10
    characters. Notice row at the top: offline "Adding needs a connection."
    (Add disabled; stays while offline); generic failure "Couldn't add this
    right now. Try again in a little while." (Add stays enabled; clears on
    edit or next Add); ~500 cap "You've reached 500 names and intentions.
    Archive some to add more." (Add disabled). Text is always kept.
  - **Server disagrees** (pool filled from another device; `effectivelyCarried`
    false while the toggle was on, or either item uncarried with
    carryParent): don't close silently. The notice row says "Saved, but not
    carried. The list's places filled up."; toolbar shows only Done; the
    form becomes read-only (end state; keyboard down). On the intention form
    for a known person the line sits under the header row.
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
