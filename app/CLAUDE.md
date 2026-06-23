# app/ — Flutter App Context

Inherits all brand-wide truths from the root CLAUDE.md. The app is the long-term
product and the sole meaningful revenue vehicle (freemium subscription).

## Status
Not yet started. Launches AFTER the social audience-building phase. Social
funnels into the app.

## Stack
- Flutter + Firebase
- Auth: Google, Apple, Anonymous (no email/password for now). Apple is required
  on iOS if other social logins are offered.
- Data: SQL Connect generated typed SDK (operations defined in
  `backend/dataconnect/connector/`). The app invokes named operations — it does
  NOT compose queries.
- Live state: Realtime Database (presence "praying now", live list prayer count).

## Firebase client config lives HERE (not in backend/)
`lib/firebase_options.dart`, `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist` are build inputs and stay in the Flutter
project at their expected paths.

## Commands

```bash
# Run the app
flutter run
flutter run -d <device-id>
flutter devices  # list available devices

# Build
flutter build ios
flutter build apk

# Dependencies
flutter pub get
flutter pub upgrade

# Analyze / lint
flutter analyze

# Tests
flutter test
flutter test test/widget_test.dart  # single test file

# Regenerate splash screen
flutter pub run flutter_native_splash:create

# Regenerate app icon
flutter pub run icons_launcher:create
```

## Core app concepts (from schema design)
- **Souls vs Intentions:** unified subject with a `kind`. Souls are people
  (ongoing); intentions are requests with a lifecycle (can be marked answered —
  the gratitude payoff). Surface the distinction in structured UI.
- **Self is the dividend:** the user is always carried on the list for free.
  Paid tiers add slots for carrying OTHERS. Never frame paying as "pay to be
  carried."
- **The fold:** subjects are an ordered list; the top `includeLimit` non-self
  subjects are carried. Reorder, don't toggle. Below-the-fold subjects are the
  gentle, non-coercive upgrade prompt. Keep the prompt humane — never fire it on
  a freshly-added subject tied to a person in crisis.
- **Anonymous → permanent linking:** when an anon user signs in, LINK the
  account so souls/history carry over. Critical: the anon user is themselves a
  soul on the list.
- **Streaks:** consecutive list numbers prayed for (not calendar days).
- **Name + nickname:** subjects have publicName (printed/shown) and an optional
  personalLabel (owner-only, intimate).

## Account naming (from schema)
`displayName` (how the app addresses the user, not unique) ships now. Unique
`username` is DEFERRED until social/discovery features — then prompt existing
users to pick a handle.

## Store copy reconciliation TODO
App-store tagline historically drafted as "One list. Every faith. Every day."
Web tagline (more recent, preferred) is "One list. Everyone. Every day."
Reconcile to "Everyone" during app development. Splash line: "Your name,
carried by the world."

## Legacy prototype code
There is an older Firestore-based prototype in this directory (`flutter_hooks`,
`PPFirebase` singleton, Firestore collections). That architecture is superseded
by the SQL Connect design above. Treat any Firestore-referencing code as
reference/legacy, not as the implementation pattern to follow.
