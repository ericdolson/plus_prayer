# Auth & Onboarding

_Last updated: 2026-11-09_

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
- **Flow (redesigned 2026-11-09, second pass; supersedes the first 2026-11-09
  flow and the 2026-10-17 steps):** one stage, four steps, then Home. No
  Begin screen, no greeting, no tour, no progress indicator. Explorations and
  the reference mock: `design/explorations/onboarding/` (`d-merged/` is the
  one chosen; its `notes.md` has the motion spec and values).
  - **One stage.** Onboarding is a single surface, never pushed pages. A few
    anchors stay on screen and travel (the ground, the one blue button, the
    user's avatar, then the person's); text groups fade and rise in and out
    around them. Fixed slots on every step: ‹ Back top-left (steps 2–4), one
    quiet text action top-right (Sign in / Not now / Skip), the button at the
    bottom (above the keyboard when it's up, never under a field).
  - **Ground: Candlelight.** Home's own ground (`#0E1012`) with one warm,
    slowly breathing glow behind the content (warmth from light, not hue;
    not brown, not a gradient). Ink is Home's (`ink` / `inkMuted`) in both
    appearances. Reduce Motion: the glow is static.
  - **Type.** One Roca line per step at regular weight (never bold, never a
    bold sans title); names in Roca bold; questions, body, labels and
    captions in the system sans. One primary pill (blue, the only colored
    control); quiet actions are plain text.
  1. **Your name.** "Here, we pray for each other." (Roca) · "What's your
     name?" · one field (sans, centered, placeholder "Your name"; 40-char cap)
     · **Continue** (lit once there's text; Return also continues) · **Sign
     in** top-right (a native sheet: Continue with Apple / Continue with
     Google / Not now). **No keyboard on arrival**: tapping the field raises
     it. A new account from Sign in prefills the name (Apple gives it on first
     authorization) and continues the same flow; an existing account skips
     onboarding.
  2. **The moment.** The typed name becomes the same name in Roca in place,
     the avatar forms above it (fade, scale, a settling blur; no letters fly),
     and the name settles onto a printed "List 53" paper line (stand-in: a
     photographed line of the real list paper with the name set live over
     it). Then: "Pray with today's list. Tomorrow your name is on it." · "The
     list is printed and sealed each day, and kept private." · **Continue**.
     No wax seal and no haptic here: both belong to the first Amen.
  3. **Someone you pray for** (optional). "Who do you pray for?" · the add
     sheet's labeled fields in onboarding's type (no form chrome): **Name**
     ("e.g. Julie Olson", caption "Printed on the list") · **What you call
     them · optional** ("e.g. Mom", caption "Only you see this") · their
     avatar forms with the first letter (initials from the alias once there
     is one) · **Continue** (lit once there's a name) · **Not now** top-right
     (→ Home). Carried by default (the pre-trial pool), no switch. One person
     at most in onboarding.
  4. **Their intention** (optional). Only them (not the user): their avatar
     travels up as the anchor, "Mom" (alias, else name) under it, then
     "Carried on the list with you." with the carried mark · "What are you
     praying for, for Mom?" · "A request: healing, a new job, peace. It can
     print with their name." · field ("e.g. Healing after surgery") · **Add**
     · **Skip** top-right. It becomes their chosen intention. Add and Skip
     both go to Home.
  5. **Hand-off to Home.** The glow goes out and the ground becomes Home's
     (dark; in light appearance it dissolves to `#E9EEF9`); the user's avatar
     travels to the header, the person's into their row; the card, rows and
     pill fade in; the blue button becomes the pray button, last. The card
     says "Pray to carry you and Mom onto List 53" ("Pray to be on List 53"
     with no person). Nothing else asks for attention.
  - **Reduce Motion:** every transition is a short fade; nothing travels,
    scales or blurs.
- **After the first Amen** (unchanged order, now the only asks after
  onboarding): "You'll be carried on List 53." → reminder time
  (Morning/Midday/Evening) → the notification permission. Then, back on
  Home, **one quiet line under the Me row**: "Add an intention for yourself"
  (blue, opens the add-intention form for Me) with "It prints beside your
  name." and a ×. It stays until used or dismissed (dismissed for good);
  never shown before the first prayer, so the first Home has only Pray lit.
  The self intention is not asked in onboarding.
- **No tour** (re-checked 2026-11-09): the hand-off's order (header, rows,
  card, the pray button last) introduces Home. Revisit only if beta testers
  get lost (open-questions Q34).
- For people 40+: one decision per step, labeled buttons (no swipes or
  carousel), ‹ Back on every step after the first, full Dynamic Type.
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
    lands at the start of onboarding (step 1, with Sign in
    top-right).
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
