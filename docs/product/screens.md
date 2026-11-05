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
- **Add sheet (one bottom sheet, two entry points):**
  - From footer ＋: defaults to **Add name**; can switch to intention, which
    reveals a name picker (default "Me").
  - From a name's detail page (or row): opens as **Add intention for {alias}**,
    picker hidden (association implied).
  - New items go to the **bottom** of their list.
- **Screens:** Home · Today's list (seal, video, counts, who's carried →
  portion) · Past lists · Name/Intention detail · Your portion · History
  (account-wide, grouped by day, streak/grace marks) · Prayer detail (note) ·
  You (settings) · Archived · Membership/paywall · Onboarding.
- **You (settings) contents:** name (edit limit), sign-in/link, membership
  (trial, upgrade, restore), reminders, notifications (incl. "Show names in
  notifications"), notifications, grace offers toggle,
  Archived, privacy & terms, delete account, about the ritual. Settings are
  stored on the User record (sync across devices). Location consent: later.
