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
  detents (design-direction §0). Revised 2026-11-06.
  - **Copy rule (whole app):** "the list" only ever means the **printed** list
    (named by number where useful). The user's own screen is never called a
    list ("your list" is never used); their items are simply "added".
  - From footer ＋: opens on **Name**; a native segmented control at the top
    switches Name | Intention. From a name's detail page (or row): opens as
    **Add intention for {alias}**, no For row (association implied).
  - New items go to the **bottom** of their level. Content is top-aligned on
    both tabs; the sheet keeps one height (the taller form), spare height
    falls below the content.
  - **Toolbar buttons:** Cancel (leading) / Add (trailing). Offer step: Not
    now (leading) / Add (trailing), no back button (the name is saved).
  - **Name tab, top to bottom:**
    - ~72 pt monogram avatar preview (detail-page size). Tone picked once at
      open (design-direction §1b), shown on the empty circle; initials fill
      in live following Home's rule (Name's initials until the alias has
      text, then the alias's, "GO" → "D"; intended). Color never changes
      while typing. **v1: preview only** (not tappable); v2: tap → tone
      swatches (+ photo), here and in Edit together.
    - Label **Name**, field placeholder "e.g. Gary Olson", muted caption
      "Printed on the list". Focused on open.
    - Label **What you call them · optional**, placeholder "e.g. Dad",
      caption "Only you see this".
    - **Carry row** (below).
  - **Intention tab, top to bottom:**
    - **For row:** looks like a Home row: ~40 pt avatar with initials + the
      serif name, trailing blue "Change". Default Me. Tapping it **pushes
      "Who is this for?"** inside the sheet: a search field (focused, so the
      keyboard stays up) over everyone in Home order, Me first, matching name
      + alias like Home search. Picking someone pops back and refocuses the
      intention field. No ranked strip or menu (nobody is "left off").
    - Label **Intention**, placeholder "e.g. Healing after surgery", caption
      "Printed on the list". Focused when the tab opens. (The offer step's
      field has no label, since its question labels it, but keeps the caption.)
    - "Who is this for?" keeps the sheet's height (list scrolls); the current
      person has a neutral ink checkmark; Home search's placeholder
      "Search"; no matches → 'Nothing matches "{query}".'; Return does
      nothing. Changing the person resets the carry toggle to that person's
      default.
    - **Carry row** (below).
  - **Carry row** (name tab, intention tab, offer step): the bloom, **"Carry
    onto the list"**, a toggle, and a muted meter line "{used} of {pool}
    {unit} used". `{unit}` comes from one formatter ("places" under today's
    rule; "people" if open-questions Q32 is adopted).
    - **On by default** while there's room. The user may turn it off (kept
      for their own prayers).
    - **Pool full:** off and disabled, with a small blue **"Make room for
      {alias}"** ("Make room for this intention" for intentions) beside it.
      **Visible now but inert** until Membership / Your portion exist; what
      its menu offers (add more places / free one up) is part of the
      monetization decision (Q31/Q32).
    - **Meter previews the result:** it counts this item while the toggle
      is on ("8 of 10" on, "7 of 10" off). Over the pool (e.g. a lapsed
      trial): "All {pool} {unit} in use", never "7 of 1". Free pool, Name
      tab: toggle disabled, meter "Free carries you and one intention of
      your own" (pending Q32 copy).
    - **Intention under an uncarried name** (any reason): the row starts off,
      enabled while there's room; turning it on shows the true cost, "Also
      carries {alias} · uses N {unit}" (re-carrying the name brings back its
      intentions still marked carried).
    - **"Make room"** sits under the meter, always (no jumping with name
      length). With nothing typed yet it reads "Make room"; it becomes "Make
      room for {alias}" once there's a name. Until it works it's a button
      with the VoiceOver hint "Not available yet" and no action.
    - **Server disagrees** (the pool filled from another device): if the
      server saves uncarried while the toggle was on, the sheet doesn't close
      silently: an inline line "Saved, but not carried. The list's places
      filled up." (+ Done on the intention tab; on the offer step it sits
      under the header).
    - Home never marks an uncarried item (design-direction §5).
  - **One tap to save.** Add saves at once; the sheet then pushes
    (horizontal, forward) to the offer: serif header **"{alias} is added."**
    (same in every case), "Add an intention for {alias}?", the intention
    field **focused** (keyboard stays up, including when the pool is full),
    and its carry row. {alias} falls back to the name. [Add] disabled while
    empty; after Add the sheet closes (one offer; more from the name's page).
  - **Intention tab Add:** saves and closes (the carry row already said
    whether it's carried).
  - **Keyboard stays up:** switching tabs focuses the new tab's field in the
    same frame; the For push focuses search, then returns focus. The app
    never hides the keyboard itself while a text field is next; user
    dismissal still works.
  - **Validation & states:** contact-info message live under the field ~0.5 s
    after typing pauses, Add disabled while shown. Caps stop input at the
    limit; a muted "34/40" counter only in the last 10 characters. Inline
    lines at the top: offline "Adding needs a connection." (Add disabled;
    stays while offline); generic failure "Couldn't add this right now. Try
    again in a little while." (Add stays enabled; clears on edit or next
    Add); ~500 cap "You've reached 500 names and intentions. Archive some to
    add more." (Add disabled). Text is always kept.
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
