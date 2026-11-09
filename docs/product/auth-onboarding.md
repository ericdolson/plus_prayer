# Auth & Onboarding

_Last updated: 2026-10-17_

## DECIDED
- **Methods:** Google, Apple, Firebase Anonymous. No email/password for now.
  Apple is required on iOS when other social logins are offered.
- **User creation is server-side:** `onAuthUserCreated` auth trigger creates the
  `User` row + self-`PrayerSubject` in one transaction ("you are the first soul"
  is true from second one). Not a client `signUp` mutation (2026-06-24).
- **Anonymous → permanent must LINK** (Firebase account linking) so souls and
  history carry over. The trigger must detect linking and not create a second User.
- **Anonymous users get the full surface** — no `isAnonymous` gate on operations.
- **Naming:** `displayName` (non-unique, how the app addresses the user) ships now.
  Unique `username` deferred until social/discovery.
- **Splash line:** "Your name, carried by the world."

## DECIDED — first run (2026-10-17)
- **Anonymous-first.** No sign-in wall. Anonymous auth is created silently.
- **Launch screen** (2026-11-05): the wordmark centered on `ground`, in light
  and dark. It's the platform's static launch screen, not step 1 below.
  Assets (2026-11-07): the wordmark is the Flutter app's splash image
  (`app/assets/splash_image.png`; iOS uses it as `LaunchImage` 1x–3x at its
  natural size); `ground` is #E9EEF9 light, #0E1012 dark. Android: see
  open-questions D7.
- **Flow (revised 2026-11-09; supersedes the 2026-10-17 steps):** three
  screens, a guided first add only for those who want it. No tour.
  1. **Welcome:** a full-bleed photograph of the sealed list in warm low
     light (names never legible; interim: the large `WaxSeal` on a dark
     ground), text on the lower third: **"Your name, carried by the world."**
     (Roca) · "One list. Everyone. Every day." · **Begin** (prominent) · quiet
     **"Already have an account? Sign in"**. Later upgrade: a 5–8 s silent
     loop of the list being stitched and sealed.
  2. **Name:** only **"What's your name?"** (Large Title, sans), a 96 pt avatar
     that fills with initials as you type, one field with the name set in
     Roca (how it prints), **Continue** above the keyboard. Nothing else.
     40-char cap; it becomes the self subject ("Me").
  3. **Welcome back:** no avatar (2026-11-09: the name screen's big avatar
     twice in a row felt heavy) · **"Welcome, {full name}."** (Roca; the
     full name as printed, never a guessed first name) · "Pray with today's
     list. Tomorrow your name is on it, and the world prays for you." ·
     divider · **"Who else do you hold?"** · "Keep the people you pray for
     here. When you want, carry them on the list too." · **"＋ Add someone"**
     and **"Add others later"** (→ Home) · faint footer: "The list is
     printed, sealed and kept private. Your name is never shared or shown
     publicly."
  4. **Someone you pray for** (only after "Add someone"): "Who's someone you
     pray for?" · the **add sheet's own fields**, in its order: **Name**
     (required; "e.g. Julie Olson", caption "Printed on the list") · **What
     you call them · optional** ("e.g. Mom", caption "Only you see this").
     The captions do the teaching; no extra helper (2026-11-09) ·
     avatar fills as they type · "{alias} will be carried on the list with
     you." (carried by default, no switch) · **Continue**.
  5. **An intention** (optional): "What are you praying for, for {alias}?" ·
     "An intention is a request: healing, a new job, peace. One can be
     printed with their name on the list." · field with an example · **Add** / **Skip**.
     It becomes their chosen intention.
  Then back to screen 3, where the people added show as a row of small
  avatars (**only them**, never you: the question is "who *else*"; no row
  before the first add); the buttons become
  **"＋ Add another"** (opens the regular add sheet, no extra help) and
  **Continue** (→ Home).
  6. After first Amen: "You'll be carried on List 53." → reminder choice
     (Morning/Midday/Evening) → notification permission.
- For people 40+: one decision per screen, labeled buttons (no swipes or
  carousel), ‹ back on every step after the first, full Dynamic Type.
- Screens 2–5 use the app's ground (calm through space, content centered);
  only screen 1 is photographic.
- **Trial starts at the first prayer**, not at install. **Before the first
  prayer the user has the trial's pool** (`basePremiumPool`, 10) so people
  added in onboarding are carried; the 14-day clock still starts at the
  first prayer (2026-11-09).
- **Sign-in ("keep your list safe") prompts:** after first prayer (soft,
  dismissable), around a 3-day streak, and before the trial ends.
- **Account deletion:** immediate after one confirmation; deletes User,
  subjects, prayers. Past list entries are stripped of name/owner but list
  counts remain. Tell users to cancel subscriptions in their store account.
  The device's cached data is cleared too (privacy.md).
- **Sign out** (2026-11-05):
  - Only for a linked account: no Sign out row while the account is
    anonymous. Once linked, "Sign out" sits at the bottom of You.
  - Confirmation: "Your names stay with your account. Sign in to bring them
    back."
  - The offline queue is flushed first. If prayers still haven't synced, ask:
    "1 prayer hasn't synced yet. Sign out anyway?" Unsynced prayers are never
    dropped silently.
  - Signing out clears the device's cached data (privacy.md), and the user
    lands at the start of onboarding (step 1, with its "Already have an
    account? Sign in" link).
- **Account deletion and the device:** the offline queue is discarded (not
  flushed), and the device's cached data is cleared (privacy.md).
- **Names are never shown in recordings.** Privacy always holds; the filmed list
  is never legible.

- **Pay before sign-in** (2026-10-17): purchase is never gated on signing in.
  Right after purchase, prompt: "Keep your list safe, and use your membership on
  your other devices." Skipping is the user's risk; gentle reminders continue.
  Store receipts restore the subscription; data only survives if signed in.
- **Self-name edits:** free until the name is first printed, then once per
  7 days, server-enforced (`selfNameChangedAt`), with the next-available date
  shown plainly. Frequent changes are a moderation signal.
- **One name field** for the user: the same text is printed and used for the
  app's greeting, **in full** (2026-11-09: never a guessed first name;
  "Sarah Beth Parker" can't be split reliably in any language). A short form,
  if ever needed, is asked for in You, never inferred. Maps to the self-subject's `publicName`;
  `User.displayName` mirrors it.

- **Self subject creation** (2026-10-18): `onAuthUserCreated` creates the User
  only (nullable `displayName`); an idempotent server callable `setSelfName(name)`
  creates the self subject ("Me"). Onboarding requires it before the main screen.
- **Onboarding resume is state-based:** User without a self name → "What's your
  name?"; name exists → main screen ("Who else" was optional; ＋ covers it).
- **First launch offline:** a quiet "Connect to begin" screen (anon sign-in needs
  network); offline works after that.
- **Fresh install, existing account signs in:** skip onboarding, load their list.
- **Linking conflict** (anon → Google/Apple account that already has data): if
  the anonymous account is empty, switch silently; if both have data, offer
  [Use my existing account] or [Merge both] with a warning that duplicates may
  need cleanup. Merge = server `mergeAccounts` (see schema-brief §6).
- **First printed** (for the self-name edit limit) = first entry APPROVED on a
  PUBLISHED list.

## OPEN
- Greeting edge cases when the first word isn't a first name ("Mr. Smith") —
  minor; fall back to no name in the greeting.
- **Faith positioning in onboarding** (faith-agnostic vs. slight Christian lean)
  — affects copy and any "tradition" question. See open-questions.md.

## DEFERRED
- Email/password or email-link sign-in.
- Usernames / handles.
