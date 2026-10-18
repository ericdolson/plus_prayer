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
- **Flow:**
  1. Splash: "Your name, carried by the world."
  2. One plain screen: "Pray for today's list. Tomorrow, you're on it."
  3. **"What's your name?"** — a personal, getting-to-know-you step (not
     "what name should be carried"). Helper text conveys that their name will be
     carried by the world in prayer, so introducing themselves feels exciting.
     The answer becomes the self-subject ("Me") — the guarded entry that always
     exists. 40-char cap.
  4. "Who else do you hold?" — optional; add names/intentions (trial carries them).
  5. Main screen, list row pinned, pray FAB gently pulsing. No tour.
  6. After first Amen: "You'll be carried on List 53." → reminder choice
     (Morning/Midday/Evening) → notification permission.
- **Trial starts at the first prayer**, not at install.
- **Sign-in ("keep your list safe") prompts:** after first prayer (soft,
  dismissable), around a 3-day streak, and before the trial ends.
- **Account deletion:** immediate after one confirmation; deletes User,
  subjects, prayers. Past list entries are stripped of name/owner but list
  counts remain. Tell users to cancel subscriptions in their store account.
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
  app's greeting (first word). Maps to the self-subject's `publicName`;
  `User.displayName` mirrors it.

## OPEN
- Greeting edge cases when the first word isn't a first name ("Mr. Smith") —
  minor; fall back to no name in the greeting.
- **Faith positioning in onboarding** (faith-agnostic vs. slight Christian lean)
  — affects copy and any "tradition" question. See open-questions.md.

## DEFERRED
- Email/password or email-link sign-in.
- Usernames / handles.
