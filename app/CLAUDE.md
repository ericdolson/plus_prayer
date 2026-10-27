# app/ — Flutter App Context

Inherits all brand-wide truths from the root CLAUDE.md. Product behavior lives
in docs/product/ (read the README there first); this file is build rules only. The app is the long-term
product and the sole meaningful revenue vehicle (freemium subscription).

## Status
Build order step 1–2 (app-brief §6) in progress on mock data. Launches AFTER
the social audience-building phase. Social funnels into the app.

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
- **Streaks:** calendar days in the user's local timezone (changed 2026-10-17;
  see docs/product/streaks-reminders.md).
- **Name + nickname:** subjects have publicName (printed/shown) and an optional
  personalLabel (owner-only, intimate).

## Account naming (from schema)
`displayName` (how the app addresses the user, not unique) ships now. Unique
`username` is DEFERRED until social/discovery features — then prompt existing
users to pick a handle.

## Store copy reconciliation TODO
App-store tagline historically drafted as "One list. Every faith. Every day."
Web tagline (more recent, preferred) is "One list. Everyone. Every day."
RESOLVED 2026-10-18: use "Everyone" in the store too (faith-agnostic brand,
familiar ritual words like Amen/grace kept in-app). Splash line: "Your name,
carried by the world."

## Legacy prototype code
The old Firestore proof of concept lives in `legacy_poc/` (outside `lib/`,
excluded from the build and from `flutter analyze`). Reference only: its
in-prayer mode and screen halo are the right ideas; its Firestore, `PPFirebase`
singleton, global `ChangeNotifier`s and inline styles are not patterns to follow.

---

## Architecture conventions

### Layers (dependencies point down only)
```
features/   screens + feature widgets (Home, prayer mode, add sheet, …)
components/ shared visual components (app-brief §4) — no data access
state/      Riverpod providers + controllers (PrayerSession, Home view model)
data/       repository interfaces, mock + real implementations, write queue
domain/     pure Dart: models + rules (no Flutter imports) — unit-tested
theme/      tokens + ThemeData + ThemeExtensions
l10n/       every user-facing string (ARB → gen-l10n)
```
- `domain/` never imports Flutter, Riverpod, or Firebase. Product rules
  (selection rules, input validation, effective carry, effective streak,
  presence ladder, row status line, avatar cluster) live here as pure
  functions so they're testable and shared by every screen.
- `components/` take plain values and callbacks. They never read providers.
- `features/` compose components and read state through providers.

### Folder structure
```
lib/
  main.dart                 bootstrap: picks the environment (mock | firebase)
  app/                      app.dart (MaterialApp.router), router.dart, environment.dart
  domain/models/            Subject, CurrentList, UserHeader, LiveStats, AppConfig, PrayerDraft, …
  domain/rules/             selection.dart, validation.dart, carry.dart, streak.dart, …
  data/repositories/        abstract interfaces (one per backend surface)
  data/mock/                in-memory implementations + seed data
  data/sqlconnect/          (step 4) SDK-backed implementations
  data/rtdb/                (step 4) RTDB-backed implementations
  data/queue/               offline write queue
  state/                    providers.dart + controllers
  components/               monogram_avatar.dart, avatar_cluster.dart, wax_seal.dart, …
  features/home/ …          one folder per screen/flow
  hooks/                    reusable flutter_hooks (use_reduce_motion, use_ticker, …)
  theme/                    tokens.dart, pp_theme.dart, app_theme.dart
  l10n/                     app_en.arb (+ generated)
  dataconnect_generated/    GENERATED by the backend — never edit by hand
  firebase_options.dart     build input — keep
```

### State management: flutter_hooks + Riverpod (`hooks_riverpod`)
- Widgets are `HookWidget` (pure UI state) or `HookConsumerWidget` (reads
  providers). Local UI state = hooks (`useState`, `useAnimationController`,
  `useTextEditingController`, custom hooks in `hooks/`).
- Shared/app state = Riverpod providers, declared by hand (no codegen) in
  `state/`. Repositories are providers, so the environment (mock vs firebase)
  and tests swap them with `ProviderScope(overrides: …)`. No global singletons.
- Streams from repositories → `StreamProvider`; multi-step flows (a prayer
  session) → `Notifier` controllers with immutable state.
- Derived values (row status lines, carry line, filters) are computed by
  `domain/rules` functions inside providers, not inside widgets.

### Navigation
- `go_router`. Home (`/`) is the only screen with the footer; everything else
  pushes with a back arrow (`/subject/:id`, `/history`, `/list`, …).
- You (settings) is the POC's full-height sheet over Home, opened from the
  header avatar (`features/you`), not a route.
- Prayer mode is NOT a route: it's Home in a different state (in-place mode,
  prayer-flow.md). Bottom sheets (add sheet, invitation, note) are modal sheets.
- Onboarding resume is a router `redirect` derived from data (no self name →
  onboarding), never a stored step counter.

### Repositories (SQL Connect + RTDB behind one seam)
One interface per backend surface; screens never touch the SDK or RTDB.
- `SubjectRepository` — getMySubjects / searchMySubjects / addSubject /
  updateSubject / reorder / resolve / archive (SQL Connect + callables).
- `ListRepository` — getCurrentListMeta / getMyListStatus (SQL Connect) merged
  with RTDB `/lists/current` (live count + `closesAt`).
- `UserRepository` — getMyHeader, getMyReminders, updateMySettings,
  create/updateReminder. Settings writes are online commands for now; the
  screen shows the new value at once (`useOptimistic`) and puts it back if
  the write fails.
- `PrayerRepository` — logPrayer / updatePrayerNote (through the write queue).
- `LiveRepository` — RTDB `/stats/live`, `/config` (compiled-in defaults),
  own `/presence/{uid}/{deviceId}` incl. the in-progress prayer draft.
Interfaces expose `Stream`s for anything the UI watches and `Future`s for
commands. The real SQL Connect implementation re-fetches (or uses the SDK's
query `subscribe`) after writes; the UI can't tell the difference from the mock.
Mock implementations hold seed data in memory, simulate latency, and can be
flipped offline to exercise the queue.

### Offline write queue (prayer-flow.md: a prayer must succeed with no signal)
- Every client write is a serializable `PendingWrite` (op name + JSON args)
  with a client id. `logPrayer` carries its client-generated UUID, so a resend
  is a no-op on the server (`ON CONFLICT DO NOTHING`).
- The queue persists to device storage before the UI moves on, sends FIFO
  (a note edit can't overtake its prayer), retries with backoff on transient
  errors, and drops + reports permanent ones (`invalid-argument`, …).
- Flushes on launch, on app resume, after each enqueue, and on reconnect.
- Repositories apply the write optimistically to their local cache at enqueue
  time ("Prayed today" shows immediately, offline).
- The in-progress prayer draft is NOT a queued write: it lives in the presence
  node (RTDB offline persistence; mirrored locally in the mock).
- Callables that need the server's answer (addSubject returns the id and the
  carry decision) are online-only for now; see the open question in the
  handoff notes.

### Theming — no raw styles in widgets
- The visual system is `docs/product/design-direction.md` (overrides
  app-brief on visuals). Minimal, modern, expensive: space, crisp type, few
  signals per row, color only when it means something.
- `theme/tokens.dart` holds the raw palettes (the POC's two themes: dark =
  charcoal grounds and cool ink, light = pale blue grounds and navy ink),
  recolored by meaning: **blue = do this** (pray button, Amen, invitation,
  primary buttons), **gold = held** (rings, intention dots, halo, "Answered"),
  everything else neutral, switches included. No red, no pink. Plus wax
  colors by `sealVariant`, 16 avatar tones, spacing, radii, durations. It is
  the ONLY file that contains color literals. Contrast is checked there
  (WCAG AA); `inkFaint` is decorative only.
- `PPColors` / `PPSpacing` / `PPSizes` / `PPMotion` / `PPBars` hang off one
  `ThemeExtension` with semantic names (`ink`, `inkMuted`, `cardSurface`,
  `thread`, `primary`, `heldGold`, `heldGoldText`, `heldGlow`, `halo`, …).
  Widgets read them via `context.pp.colors`, `context.pp.space`.
- Type: Roca only for names on Home, list numbers, and big lines; everything
  else the platform system font (SF Pro on iOS). Text styles come from
  `Theme.of(context).textTheme`; tweak with `copyWith(color: …)` from
  semantic colors only. No `fontSize:` or `Color(0x…)` in feature/component
  code.
- Icons: `PPIcons` only (Phosphor Light, bundled, plus the custom praying
  hands). Never `Icons.*`.
- Light and dark both ship (`AppTheme.light()` / `.dark()`, `PPColors.light`
  / `.dark`). Dark is the default; the mode (System/Light/Dark) is a
  device-local preference (`themeModeProvider`), read before the first frame.
  Held marks (rings, intention dots, the card border) are crisp gold in both
  themes; `heldGlow` (dark only, null in light) is used solely for the prayer
  halo and the brief bloom on check (`useBloom`).
- Bars are `Frosted` (blur on iOS, semi-opaque elsewhere); the list scrolls
  beneath header and footer.
- Layout from the POC where design-direction.md doesn't say otherwise; move
  its inline styles into tokens.
- Layout uses `EdgeInsetsDirectional` / `AlignmentDirectional` (RTL later).

### Motion & accessibility
- Every animation checks `useReduceMotion()` (`MediaQuery.disableAnimations`)
  — reduced motion swaps springs, pulses, and the check bloom for simple fades.
- One signature moment (Amen → the seal). The prayer check's small spring is
  the only spring; everything else is quiet and quick.
- Screen readers read every name: avatar clusters expose all names in their
  `Semantics` label, rows merge semantics into one sentence, prayer-mode rows
  are `checked`/`mixed` toggles.
- Caps count grapheme clusters (`characters` package), never `String.length`.

### Copy
- All user-facing strings live in `lib/l10n/app_en.arb` so brand voice can be
  reviewed in one file. Never hard-code strings in widgets.
- Copy comes from the spec (app-brief, feature files). Don't invent product
  copy; if a string is missing from the spec, use the plainest wording and
  list it for review.

### Testing
- `test/domain/` — unit tests for the rules (selection, validation, carry,
  streak, …). These are the contract; write them with the rule.
- `test/data/` — repository/queue behavior against the mock + fake storage.
- `test/features/` — widget tests with `ProviderScope` overrides and the mock
  environment; check semantics labels for names.
- Run `flutter analyze` and `flutter test` before committing.
