# apps/ios/ — Native iOS App Context

Inherits all brand-wide truths from the root CLAUDE.md. Product behavior lives
in `docs/product/` (read the README there first, then `design-direction.md` §0
for fidelity tiers). This file is build rules only. Android (`apps/android/`)
ports each feature from here while it's fresh, so keep rules out of the views:
anything Android would also need belongs in the spec, the backend, or the
domain package.

`app/` is the Flutter reference build (tag `flutter-reference`). Read it for
intent (what a component does, which edge cases it handles). Don't port its
patterns: hooks, Riverpod, Material theming, and the custom chrome Flutter
needed (frosted menus, shader scroll edges) all have native answers here.

## Status
Phase 0 (conventions, tokens, assets plan) is mostly answered; the open
items and the project-creation steps are in `PHASE-0.md`. No Xcode project or
app Swift yet. Build order: `app-brief.md` §6.

## Stack
- SwiftUI, **iOS 26** minimum (Liquid Glass), Swift 6 language mode (strict
  concurrency), Xcode's current release.
- **Observation** (`@Observable`) for all shared state. No `ObservableObject`,
  no Combine for new code.
- Swift Package Manager only (no CocoaPods).
- Firebase iOS SDK: Auth (Apple, Google, Anonymous), Realtime Database,
  Analytics, Crashlytics, Messaging. SQL Connect through the generated
  `PlusPrayerConnector` package.
- Bundle ID **`dev.hammock.plusprayer`** (the same Firebase iOS app as the
  Flutter build). Don't change it.

## Ownership — Eric only
- **Signing, team, capabilities, entitlements** (Sign in with Apple, push,
  background modes, App Groups), provisioning, App Store Connect.
- Adding a **package dependency** to the Xcode project (it edits
  `project.pbxproj`). Agents ask, naming the package, version and products.
- `GoogleService-Info.plist` (build input; lives in the app target, not
  `backend/`).

## Xcode project rules
- **Never edit `project.pbxproj` by hand.** Not with sed, not with a script,
  not "just one line".
- The project uses **synchronized folders** (Xcode 16+): every file under
  `PlusPrayer/`, `PlusPrayerTests/` and `PlusPrayerUITests/` is in its target
  automatically. Add, move and delete Swift files on disk; never touch the
  project to do it.
- Build settings live in the project; prefer `INFOPLIST_KEY_*` settings over
  an Info.plist file. If a key has no build setting, ask Eric.
- Fonts are registered at launch (`CTFontManagerRegisterFontsForURL`), so
  adding one needs no plist edit.

## Folder structure
```
apps/ios/
  PlusPrayer.xcodeproj
  PlusPrayer/                  app target (synchronized folder)
    App/                       PlusPrayerApp, AppEnvironment (mock | emulator | firebase), Router
    Features/                  one folder per screen/flow: Home/, Prayer/, AddSheet/, Detail/, …
    Components/                Tier A signature components (no data access)
    State/                     @Observable models: HomeModel, PrayerSession, …
    Data/
      Repositories/            protocols, one per backend surface
      Mock/                    MockBackend + in-memory repositories + seed data
      SQLConnect/              repositories over PlusPrayerConnector
      RTDB/                    repositories over FirebaseDatabase
      Queue/                   the offline write queue
    Theme/                     Tokens.generated.swift (GENERATED), Theme.swift, Fonts.swift, PPIcon.swift
    Resources/                 Assets.xcassets, Fonts/, Localizable.xcstrings, GoogleService-Info.plist
  PlusPrayerTests/             Swift Testing: data, queue, state
  PlusPrayerUITests/           a few smoke flows
  Packages/PlusPrayerDomain/   local Swift package: models + rules, pure Swift
  PlusPrayerConnector/         GENERATED SQL Connect SDK. Never edit; regenerate from backend/
```

## Layers (dependencies point down only)
```
Features/     screens; compose Components, read State
Components/   Tier A visuals; plain values + closures in, no models, no repositories
State/        @Observable models; call repositories, derive view state via Domain
Data/         repositories (mock + real), offline queue
Domain        PlusPrayerDomain package: Foundation only
Theme/        tokens + semantic access; no logic
```
- **Domain is a separate package** so the compiler enforces purity: it can't
  import SwiftUI, Firebase or the connector. Product rules live there as pure
  functions with tests: selection (check/uncheck cascade), validation (caps,
  no phones/emails/links, verse refs allowed), effective carry, effective
  streak, presence ladder, row status line, card status line, avatar
  cluster, initials, avatar tone hash (FNV-1a mod 16, must match Flutter and
  Android). `swift test` runs them in seconds without a simulator.
- Domain models are our own types. Generated connector types never leave
  `Data/SQLConnect/`; map them at the repository boundary.
- Components take values and closures, never models. Each has `#Preview`s in
  both themes and at a large Dynamic Type size.

## State (Observation)
- Shared state = `@MainActor @Observable final class` models in `State/`.
  Views hold local UI state in `@State`. No singletons, no globals.
- Dependencies are injected: `AppEnvironment` builds the repositories once
  (mock, emulator or firebase) and the app passes models down with
  `.environment(_:)`. Views read them with `@Environment(HomeModel.self)`.
  Tests and previews build models over mock repositories.
- Repositories expose `AsyncStream`/`AsyncSequence` for what the UI watches
  and `async throws` functions for commands. Models consume streams in
  `.task {}` so they cancel with the view.
- Derived values (row status lines, card status, filters, counts) are
  computed by Domain functions inside models, never inside views.
- Multi-step flows (a prayer session) are one model with an explicit state
  enum; no boolean soup.

## Navigation
- One `NavigationStack` with a typed path (`enum Route: Hashable`). Home is
  the root and the only screen with the floating bar; everything else pushes
  (`.subject(id)`, `.history`, `.todaysList`, …).
- **You** (settings) is a native sheet over Home, opened from the header
  avatar. The add sheet, the Amen invitation, the closing sheet and the note
  are native sheets with detents; Tier A components (ring button, cluster,
  seal) sit inside them.
- **Prayer mode is not a route**: it's Home in a different state
  (`prayer-flow.md`).
- Onboarding is derived from data (no self name → onboarding), never a stored
  step counter.

## Repositories (SQL Connect + RTDB behind one seam)
Screens never touch the SDK or RTDB. Same surfaces as the Flutter build:
- `SubjectRepository`: getMySubjects / searchMySubjects; addSubject /
  updateSubject / setCarriedItems (callables); reorder / resolve / archive /
  restore / purge.
- `ListRepository`: getCurrentListMeta / getMyListStatus (SQL Connect)
  merged with RTDB `/lists/current` (live count, `closesAt`).
- `UserRepository`: getMyHeader, reminders, updateMySettings. Settings writes
  are online commands; the view shows the new value at once and puts it
  back if the write fails.
- `PrayerRepository`: logPrayer / updatePrayerNote, through the queue.
- `LiveRepository`: RTDB `/stats/live`, `/config` (with compiled-in
  defaults), and the user's own `/presence/{uid}/{deviceId}` including the
  in-progress prayer draft.
The real SQL Connect implementation re-fetches after writes (or observes the
generated query refs); the UI can't tell it from the mock. Operation names
and auth come from `backend/dataconnect/connector/OPERATIONS.md`. Never
compose queries; if an operation is missing, ask for a backend change.

## Offline prayer queue (`prayer-flow.md`: a prayer must succeed with no signal)
- Every client write is a `PendingWrite` (operation name + `Codable` args)
  with a client id. `logPrayer` carries its client-generated UUID, so a resend
  is a no-op on the server.
- The queue is an `actor`. It persists to a file in Application Support
  (atomic write) **before** the UI moves on, sends FIFO (a note edit never
  overtakes its prayer), retries transient errors with backoff, and drops and
  reports permanent ones (`invalid-argument`, …).
- Flushes on launch, when the scene becomes active, after each enqueue, and
  on reconnect (`NWPathMonitor`).
- Repositories apply the write to their local cache at enqueue time, so held
  rings and the card's border show at once, offline.
- The in-progress draft is **not** a queued write: it lives in the presence
  node (RTDB with `isPersistenceEnabled`; mirrored locally in the mock).
- Callables that need the server's answer (addSubject returns the id and the
  carry decision) are online-only for now.

## Offline reads and the device cache
- The SQL Connect SDK caches every query result on disk (`clientCache`:
  persistent, `maxAge: 0`, set in `connector.yaml`). Online, queries go to the
  server and refresh the cache; offline, repositories fall back to
  `execute(fetchPolicy: .cacheOnly)`. That's how Home opens with no signal.
- The SDK scopes its cache file by Firebase uid, under
  `Documents/com.google.firebase.dataconnect/`. The SDK (11.12) has no public
  clear-cache API, so clearing deletes that folder; a test asserts the folder
  exists after a cached query, so an SDK change fails loudly.
- **`DeviceDataWiper`** is the one place that clears device data (privacy.md):
  the SQL Connect cache folder, the RTDB local cache, and the offline queue.
  - **Sign-out** (linked accounts only): flush the queue; if prayers are still
    unsent, confirm ("1 prayer hasn't synced yet. Sign out anyway?",
    pluralized in the catalog). Never drop them without that answer. Then
    wipe, `Auth.signOut()`, and route to the start of onboarding.
  - **Account deletion:** after `deleteAccount` succeeds, discard the queue
    (don't flush), then wipe.
- **Backups:** the SQL Connect and RTDB cache folders and the queue file are
  excluded from iCloud backup (`isExcludedFromBackup`), set at launch. The
  queue lives in **Application Support** (never Caches, which iOS may purge).

## Mock backend and environments
- `AppEnvironment` picks one at launch from the scheme's launch argument
  `-PPEnvironment mock|emulator|firebase`. Debug defaults to **mock**.
- **mock**: in-memory seed data matching the reference screenshots (Me, Dad,
  Mom, Daniel Kim…), simulated latency, a debug toggle to go offline (to
  exercise the queue), a clock you can advance past midnight and the flip.
  No Firebase calls.
- **emulator**: the real repositories against the local emulators
  (`backend/firebase.json`: SQL Connect 9399, RTDB 9000, Auth 9099).
- **firebase**: production. Release builds only use this.
- Previews and tests always use mock.

## Theming: tokens only
- `design/tokens.json` (W3C Design Tokens) is the source of truth.
  `Theme/Tokens.generated.swift` is generated from it; never edit it, never
  copy a value out of it into a view.
- Views read semantic names only: `PP.color.ink`, `PP.space.gutter`,
  `PP.size.held.ring`, `PP.type.name`, `PP.duration.settle`. **No color
  literals, no `.font(.system(size:))`, no numeric padding or sizes** in
  Features/ or Components/. A missing value means a missing token: add it to
  `tokens.json` (and the spec) first.
- Colors are dynamic (light and dark in one `Color`). Both themes are fully
  designed; the app **follows the system** by default. The System/Light/Dark
  setting in You is device-local (`@AppStorage`), applied with
  `.preferredColorScheme` (nil for System).
- Type: Roca only for names on Home, list numbers and big lines; everything
  else the system font. Roca roles use `Font.custom(_:size:relativeTo:)` so
  they scale with Dynamic Type; system roles use the matching text style.
  Avatar initials are the system font and track the disc, not Dynamic Type.
- Color roles (design-direction §1): blue = do this, gold = held, everything
  else neutral. No red, no pink. Switches and controls are neutral (`.tint`
  is ink), never blue.
- **Tier B chrome is native**: menus (`Menu`), sheets, alerts, confirmation
  dialogs, the search field, toolbars, `Toggle`, pickers, share sheet. Take
  the platform's metrics and look; the spec gives only content and behavior.
  Don't build a custom replacement without a spec decision.
- Floating controls sit on Liquid Glass (`glassEffect`, grouped in a
  `GlassEffectContainer`): the pill, the header's badge and filter, the
  docked search field. The pill and pray button are our layout and sizes on
  native glass. The pray button stays solid action blue. In-content
  containers (community card, search match hint) are flat `cardSurface`,
  never glass.
- Scroll edges are native: the soft scroll edge effect, no custom blur or dim.
- The search row docked above the keyboard is the one sanctioned custom
  chrome: a native `TextField` on glass with the compact pray/Amen button at
  its end (design-direction §4).
- Icons: **SF Symbols** at a light weight, plus our custom symbols (praying
  hands, bloom) in the asset catalog, all through `PPIcon` (one file). No
  Phosphor, no other family.
- Layout uses leading/trailing, never left/right (RTL later).

## Motion and accessibility
- Every animation reads `@Environment(\.accessibilityReduceMotion)`. Reduce
  Motion swaps the check spring and bloom for a fade (`PP.duration.quick`),
  holds the halo static at its token opacity, and folds become fades.
- One signature moment: Amen → the seal. The check's spring is the only
  spring. Everything else is quiet and quick, with durations from tokens.
- Light haptic on check (`.sensoryFeedback`), once; uncheck is silent.
- VoiceOver reads every name: clusters expose all names; a row is one
  element with one sentence (", carried" appended when carried); prayer-mode
  rows are toggles with checked / mixed values; the card reads "List 52,
  sealed".
- Dynamic Type at every size; layouts reflow, never clip (`ViewThatFits`
  where the spec says a line moves or hides).
- Caps count grapheme clusters: Swift's `String.count` already does. Never
  `utf16.count` or `unicodeScalars.count`.

## Copy and localization
- Every user-facing string lives in `Resources/Localizable.xcstrings`, so the
  voice can be reviewed in one file. Use explicit keys with the English value
  and a comment saying where it appears (`home.card.status.prayToCarry`).
  Plurals use the catalog's variations, never string math.
- Copy comes from the spec (`app-brief.md`, feature files). Don't invent
  product copy; if a string is missing, use the plainest wording and list it
  for review.
- "List 53" always uses a non-breaking space.

## Tests
- `Packages/PlusPrayerDomain/Tests`: Swift Testing (`@Test`) for every rule.
  These are the contract; write them with the rule.
- `PlusPrayerTests`: repositories and the queue against the mock and a fake
  file store; models driving a prayer session end to end.
- `PlusPrayerUITests`: a few smoke flows on the mock (pray → Amen → card
  status; add a name).
- Previews are not tests, but every component has them.
- Before committing:
  ```bash
  swift test --package-path apps/ios/Packages/PlusPrayerDomain
  xcodebuild -project apps/ios/PlusPrayer.xcodeproj -scheme PlusPrayer \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
  ```

## Generated code
- `PlusPrayerConnector/`: regenerate from `backend/` with
  `firebase dataconnect:sdk:generate` after any connector change. Never edit
  by hand.
- `Theme/Tokens.generated.swift`: regenerate from `design/tokens.json` with
  the token generator. Never edit by hand.
