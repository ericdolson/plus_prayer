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
  detents (design-direction §0).
  - From footer ＋: defaults to **Add name**; can switch to intention, which
    reveals a name picker (default "Me").
  - From a name's detail page (or row): opens as **Add intention for {alias}**,
    picker hidden (association implied).
  - New items go to the **bottom** of their list.
  - **Name form (2026-11-05):** a ~72 pt monogram avatar sits at the top
    (same size as the detail page), then Name ("Printed on the list") and
    Alias ("Only you see this"). Name is focused on open. The avatar shows its
    tone from the moment the sheet opens, empty until the first letter is
    typed; initials then fill in live from the same source Home uses. The
    color never changes while typing. **v1: the avatar is a preview only**
    (not tappable); v2 makes it tap → tone swatches (+ photo when photos ship),
    here and in Edit together.
  - **One tap to save.** No Next steps or wizard: Add saves the name at once.
    The sheet then slides in place to the offer "{alias} is on your list. Add
    an intention for {alias}?" with the intention field ready and
    [Not now] / [Add]. Not now loses nothing (the name is already saved).
  - **Keyboard stays up across tabs (2026-11-05):** switching Name ⇄
    Intention moves focus to the new tab's text field in the same frame, so
    the keyboard never hides and reappears. The intention's name picker is a
    compact control above the field ("For ( M ) Me") that opens a native
    menu/popup over the sheet without taking focus from the field. The sheet
    keeps one height for both tabs (sized to the taller form). Opened from a
    name's page, the intention field is focused at once. The app never hides
    the keyboard itself while a text field is next; a user swipe-down/tap-out
    still dismisses it.
  - **Details (2026-11-05):**
    - Tabs are a native segmented control (Name | Intention) at the top.
      Content is top-aligned on both tabs; the Intention tab has no avatar,
      and its spare height falls below the content.
    - The preview follows Home's initials rule live: Name's initials until
      Alias has text, then the alias's ("GO" → "D"). The jump is intended.
    - Least-used tone counts every active subject shown on Home, including
      Me, by the tone you see (stored, else the hashed fallback). A fresh pick
      on each open is fine (nothing kept on cancel).
    - The offer step is a horizontal push (forward) inside the sheet, with
      the intention field focused (keyboard stays up). {alias} falls back to
      the name when there's no alias. [Add] is disabled while empty; after
      Add the sheet closes (one offer; more intentions from the name's page).
    - Picker menu items show a small monogram avatar + alias (color is how
      people find their people), in Home order with Me first. Android port:
      an exposed dropdown. **No search in v1**; a searchable "All names…"
      step is deferred (open-questions D5).
    - **Buttons** live in the native sheet toolbar: name form Cancel
      (leading) / Add (trailing); offer step Not now (leading) / Add
      (trailing), no back button (the name is already saved).
    - **Intention tab Add:** carried → save and close, no offer. Pool full →
      the saved-privately step below, with only [Done].
    - **Pool full (never silent; Home shows no mark, design-direction §5):**
      the step after Add says "{alias} is saved for your own prayers. All
      {pool} places on the list are in use." ({pool} from the entitlement),
      with the intention offer still below it for names.
      - **Cadence is PROPOSED (open-questions Q31); build it as an isolated,
        easy-to-change rule.** Placeholder:
      - **First full-pool add of the user's local day:** a stronger, still
        humane invitation under that line, e.g. "Membership carries up to
        {premiumPool} of your people each day." + blue [See membership].
      - **Later adds that day:** only a small blue text link "Your portion"
        (it holds the upgrade path). No card, no repeat.
      - Already on the top pool (no larger tier to offer): only "Your
        portion", never an upsell.
      - "Shown today" is device-local (low stakes).
    - **Validation:** contact-info message shows live, inline under the
      field, ~0.5 s after typing pauses; Add is disabled while it shows.
      Caps stop input at the limit; a muted "34/40" counter appears only in
      the last 10 characters. Offline: an inline line at the top, "Adding
      needs a connection.", Add disabled, text kept.
    - **Helper text** is a muted footnote caption under each field ("Printed
      on the list" / "Only you see this"), not a placeholder. Placeholders:
      "Their name" / "e.g. Dad".
    - **Tone count** (clarified): names only, Me included (intentions have
      no avatar).
    - **Until Membership / Your portion exist:** hide the whole membership
      invitation (sentence and button) and the "Your portion" link; show only
      the saved-privately line. `{premiumPool}` comes from client `/config`
      (`basePremiumPool`), compiled fallback 10.
    - **Pool full → offered intention → Add:** the sheet closes with no
      further message (the pool was already explained).
    - **More copy:** intention placeholder "e.g. Healing after surgery";
      intention caption "Printed on the list". Pool of 1 (free): "{alias} is
      saved for your own prayers. Your free place on the list is in use."
      (never "The 1 place"; you are always carried free). Intention saved
      privately: "This intention is saved for your own prayers." (never quote
      the intention text).
    - **Offline line** shows while offline and after a failed Add; text kept.
    - **Generic failure** (incl. the quiet ~5,000 hard cap and any unexpected
      server error): inline line at the top, "Couldn't add this right now.
      Try again in a little while.", text kept and Add stays enabled (retry
      is one tap). The line clears when the text is edited or Add is tapped
      again; the offline line also stays while still offline.
    - **~500-item cap:** inline line at the top, "You've reached 500 names
      and intentions. Archive some to add more.", Add disabled.
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
