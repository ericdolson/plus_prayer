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
Phase 0 is done (open items in `PHASE-0.md`). Build order: `app-brief.md`
§6. Built so far (see "Components so far" below and `git log`): the theme
and signature components, Home's rows, shell, community card and prayer mode,
and the domain models + mock data source: Home runs on `HomeModel` over the
mock repositories, the filter works (counts, context rows, linger then fold,
empty states); Amen ends in the list invitation and the closing sheet with
the journal entry; the add sheet (footer ＋) adds names and intentions; search docks
above the keyboard; a name's page as a dashboard (the person, the carry
card with "Prints with", intentions with the ＋, the History preview), where
adding a name lands, and a minimal intention page; the pool counts people
(Q32); the History screen (filter, All · Held · Lists · Journal · Answered,
the strand, the day sheet); praying in place on both pages. Next: the rest
of the pages (⋯), Prayer detail and past lists' pages (their History
rows are inert until then), then build order step 3 (onboarding, auth,
setSelfName).
Still open in prayer mode: backgrounding and the welcome-back question, the
presence draft, the first Amen's onboarding steps. Also pending: the offline
queue (Data/Queue, replacing the mock's in-memory hold), a debug menu for the
mock's scenario controls.

## Stack
- SwiftUI, **iOS 26** minimum (Liquid Glass), **iPhone only** (2026-11-05),
  Swift 6 language mode (strict concurrency), Xcode 27 or later (the project
  file format needs it). The app target isolates to the main actor by default
  (`SWIFT_DEFAULT_ACTOR_ISOLATION`); mark pure helpers `nonisolated`.
- **Observation** (`@Observable`) for all shared state. No `ObservableObject`,
  no Combine for new code.
- Swift Package Manager only (no CocoaPods).
- Firebase iOS SDK: Auth (Apple, Google, Anonymous), Realtime Database,
  Analytics, Crashlytics, Messaging. SQL Connect through the generated
  `PlusPrayerConnector` package.
- Bundle ID **`dev.hammock.plusprayer`** for now (the same Firebase iOS app as
  the Flutter build). Agents don't change it. It's expected to move to the new
  LLC's account and ID (e.g. `com.plusprayer.app`) before the first TestFlight
  upload; open-questions Q30, decisions.md 2026-11-05.

## Ownership — Eric only
- **Signing, team, capabilities, entitlements** (Sign in with Apple, push,
  background modes, App Groups), provisioning, App Store Connect.
- **Never create the App Store Connect app record or upload a build to
  TestFlight** under the current (personal) team. +Prayer ships from the new
  LLC's account.
- Adding a **package dependency** to the Xcode project (Xcode's MCP server
  has no tool for it). Agents ask, naming the package, version and products.
- `GoogleService-Info.plist` (build input; lives in the app target, not
  `backend/`).

## Xcode project rules
- **Never edit the project file by hand.** Xcode 27 writes it as
  `PlusPrayer.xcodeproj/project.xcproj` (a readable format that replaces
  `project.pbxproj`); the rule holds for it too. Not with sed, not with a
  script, not "just one line".
- Change the project through **Xcode's MCP server** (`xcrun mcpbridge`,
  configured as `xcode`): `UpdateTargetBuildSetting`, `XcodeNewTarget`,
  `XcodeMakeDir`, `AddEntitlement`, `AddInfoPlist`; `BuildProject`,
  `RunAllTests` and `RenderPreview` to verify. Without it, ask Eric.
- Command-line builds work too:
  `xcodebuild -project apps/ios/PlusPrayer.xcodeproj -scheme PlusPrayer
  -destination 'generic/platform=iOS Simulator' build`.
- **Installing on Eric's iPhone.** Xcode's Run hangs on "Preparing iPhone",
  so build and install from the command line (from the repo root):
  ```bash
  DD="${TMPDIR:-/tmp}/pp-dd-device-fresh"
  DEVICE=00008150-001A75D02639401C   # Eric's iPhone 17 Pro
  xcodebuild -project apps/ios/PlusPrayer.xcodeproj -scheme PlusPrayer \
    -configuration Debug -destination 'generic/platform=iOS' \
    -derivedDataPath "$DD" -allowProvisioningUpdates build
  xcrun devicectl device install app --device $DEVICE \
    "$DD/Build/Products/Debug-iphoneos/PlusPrayer.app"
  xcrun devicectl device process launch --terminate-existing \
    --device $DEVICE dev.hammock.plusprayer
  ```
  - Check first with `xcrun devicectl list devices`: the phone must show
    `connected`. `unavailable` (or error 4016) means it's locked, asleep, or
    neither cabled nor on the Mac's Wi-Fi; ask Eric rather than retrying.
  - The phone needs to be unlocked for the launch step.
  - Over Wi-Fi (no cable) the phone may show `available (paired)`, and the
    first command after it's been idle often fails with "Connection reset
    by peer" (error 4000/54) while bringing the link up. Run it once more;
    it then shows `connected`. Check the install's own exit status: a
    launch can succeed on the old build after a failed install.
  - Signing is automatic for the team in the project; never change the team
    or bundle ID to make an install work.
  - The build folder lives in `$TMPDIR`, which macOS prunes: a build that
    fails with "There is no Info.plist found at …/SourcePackages/artifacts/…"
    (or "no XCFramework found") has lost its downloaded Firebase binaries,
    and `-resolvePackageDependencies` doesn't bring them back. Build into a
    new folder name instead (it downloads them afresh); don't delete folders
    without asking Eric. (2026-11-06: `pp-dd-device` broke this way.)
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
- One `NavigationStack` with a typed path (`enum Route: Hashable`,
  `App/Route.swift`; `.routes()` maps it). Home is the root and the only
  screen with the floating bar; everything else pushes (`.subject(id)`,
  `.history(HistoryRequest)`; later `.todaysList`, …).
- **You** (settings) is a native sheet over Home, opened from the header
  avatar. The add sheet, the Amen invitation, the closing sheet and the note
  are native sheets with detents; Tier A components (ring button, cluster,
  seal) sit inside them.
- **Prayer mode is not a route**: it's Home in a different state
  (`prayer-flow.md`), or a page's (praying in place, below). The halo, the
  check haptic and the `PrayerSheet` sit on Home's `NavigationStack`, not
  on Home's content, so they show over a pushed page too.
- Onboarding is derived from data (no self name → onboarding), never a stored
  step counter.

## Repositories (SQL Connect + RTDB behind one seam)
Screens never touch the SDK or RTDB. Same surfaces as the Flutter build:
- `SubjectRepository`: getMySubjects / searchMySubjects; addSubject /
  updateSubject / setCarriedItems / restoreSubject (callables; restore is
  pool- and cap-aware, no connector mutation: a name over the pool or an
  intention to a person at the cap comes back off, `restoredCarryFlag` in
  PlusPrayerDomain, the mock mirrors it); `history()` (a `HistoryLog`:
  getMyPrayerHistory's prayers with what each held, and every list entry of
  your subjects, the entries getSubjectDetail returns per subject; an
  account-wide entries read is a backend ask before the real repository);
  reorder / resolve / archive / purge.
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
  is ink), never blue. Every `Toggle` uses `.ppSwitch()` (Theme/Switch.swift):
  the "on" track is `switchTrackOn` (inkMuted) with the standard white knob,
  both themes; the off track stays the system's (`switchTrackOff` is
  Android-only). Never a custom-drawn switch.
- **Tier B chrome is native**: menus (`Menu`), sheets, alerts, confirmation
  dialogs, the search field, toolbars, `Toggle`, pickers, share sheet. Take
  the platform's metrics and look; the spec gives only content and behavior.
  Don't build a custom replacement without a spec decision.
- Floating controls sit on Liquid Glass (`glassEffect`, grouped in a
  `GlassEffectContainer`): the pill (which becomes the search field), the
  header's badge and filter. The pill and pray button are our layout and sizes on
  native glass. The pray button is interactive glass tinted action blue, the header avatar glass tinted with its tone. In-content
  containers (community card, search match hint) are flat `cardSurface`,
  never glass.
- Scroll edges are native: the soft scroll edge effect, no custom blur or dim.
- **`@FocusState` inside `safeAreaBar` content doesn't read back** (iOS 26):
  setting it focuses the field, but it stays `false` while the field has
  focus. Home's dock (`HomeDock`) follows the keyboard's notifications
  instead and uses focus only to set it. Check this before relying on focus
  state in a bar.
- Search reuses the bar (design-direction §4, decided 2026-11-06): the
  pill's glass becomes a native `TextField` (🔍 field ✕), the pray button
  stays its own circle beside it, and with the keyboard up both ride above it
  at `size.bar.compact`.
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
  `node design/generate/index.mjs` (`--check` fails if it's stale). Never
  edit by hand.
- Custom symbols (`Assets.xcassets/Symbols/pp.*.symbolset`): regenerate from
  their source SVGs with `design/generate/symbol.py` (usage in its header).

## Components so far (build step 1)
- `MonogramAvatar` — initials on a tone; one letter or color only when small.
- `.heldRing(_:cornerRadius:step:)`, `HeldDot` — gold held marks with the
  check bloom. The ring scales in steps (`HeldRingStep`: small 1.5/1.5 up to
  ~32 pt, medium 2/2 at 40–44 pt and the card, large 3/3 at ~96 pt; tokens
  `size.held.ring*`).
- `CarryCard` — a page's flat `cardSurface` card: its controls, a hairline,
  the status line as footer (the self page: the status only).
- `CarriedLabel` (single-line rows: the mark follows the ellipsis) and
  `CarriedMark.after` (inline, for text that wraps).
- `NameRow`, `IntentionRow`, `SecondaryLine`: Home rows on plain values; each
  row draws its part of the intention thread (`.thread(_:)`, `ThreadShape`).
- `WaxSeal` (7 waxes by sealVariant, unsealed blank, dark-theme lift and rim)
  and `PewterSeal`: one gray stamp tinted with Core Image color matrices in
  sRGB (no Metal: the toolchain isn't installed by default).
- `StreakBadge`; Home shell: `HomeHeader`, `HomeFilterControl` (native menu,
  chip when active), `HomeBar` + `PrayButton`, placed with `safeAreaBar` so
  the native soft scroll edge applies.
- `CommunityCard`: cropped seal, world block (beside the seal, or below it
  when it can't fit), measured avatar row with "+N", status line from the
  gate; held ring as its border. Rules in PlusPrayerDomain (`Card.swift`).
- Prayer mode: `PrayerSession` (State/, @Observable; selection rules in
  PlusPrayerDomain `Selection.swift`), `PrayerCheck` in each row's trailing
  slot and the card's, `Halo` (a steady 2 pt edge line + a breathing glow; ConcentricRectangle follows the display's
  corners; breath, Amen flare, Reduce Motion static), `PrayButton` with the
  5 s countdown to Amen, Cancel in the header (confirm past 30 s), the
  prayer bar (timer · "with N" · search).
- `CountdownButton` (the pray button and the invitation share it): during
  the ~5 s a small pie inside the dimmed disc runs down to nothing
  (`number.countdownPie`), then Amen; no ring outside, no change in size
  (design-direction §4, decided 2026-11-06; the invitation has no seconds
  counter). `AvatarCluster`
  (outside the card: ≤5 every avatar and a count, more → 4 + "+N";
  `layoutCluster` in PlusPrayerDomain).
- `Features/Prayer/PrayerSheet`: one native sheet, sized to its content
  (`fittedDetent()`), shows the Amen invitation and then becomes the closing
  sheet in place (no dismiss and re-present between them). The invitation
  can't be swiped away; dismissing the closing sheet ends the session.
- `HomeView` is the root, on `HomeModel` + `PrayerSession` from the
  environment; `ComponentGallery` stays for previews.
- Strings: `App/L10n.swift` over `Resources/Localizable.xcstrings` (explicit
  keys, plural variations).

## Data and state so far (build step 2)
- PlusPrayerDomain: models (`Subject`, `CurrentList`, `MyListStatus`,
  `UserHeader`, `LiveStats`, `AppConfig`, `NewPrayer`, `LocalDate`,
  `HistoryLog`) and rules: `SubjectTree`, carry (`Carry.swift`, Q32
  2026-11-08: the pool counts people, `carriedPeople`, `checkPool`; an
  intention's `isCarried` = chosen to print with its person, at most
  `AppConfig.intentionsPerPerson` (/config, default 1) per person;
  `isEffectivelyCarried` = chosen ∧ person carried, Home's mark;
  `nameCarryOffer` / `nameCarryMeter` for a person's toggle,
  `intentionCarryOffer` for "Print with {alias}", `choosing` /
  `printsWith` build setCarriedItems' set, `restoredCarryFlag`), the
  carry card's footer (`carryStatus`), History (`History.swift`:
  `scopedHistory` for everyone / a person with their intentions / an
  intention, `historyDays`, `strand` (today first, empty runs folded to one
  gap per month, month tabs, this month and last; older months and years as
  rows; Begun), `recentStrand` (the preview row), `historyTotals` (the
  tiles), `heldByDay` / `journalByDay` / `answeredSummaries` /
  `peopleHeld`, `prayerTime`, the local-prayer fold),
  Home's filter (`visibleGroups`, `filterCount`, `communityCardShown`),
  streak (`effectiveStreak`, `afterListPrayer`, `streakBadgeState`), the
  local-prayer fold, the gate (`tomorrowStatus(list:…)`), row status,
  `monogram`. Ported from Flutter's `domain/rules`, same cases in the tests.
- `Data/Repositories`: protocols for what's built so far (Home's reads and
  `logPrayer`); `Watched<Value>` streams a value (current first, then
  changes). Each surface grows with its feature.
- `Data/Mock`: `MockBackend` (main-actor, in-memory, applies the server's
  rules; `online`, `advanceClock`, `flipList`, `setSealed`, `setClosesAt`,
  `setStats`, live drift), `MockSeed.standard` (Flutter's seed: the
  reference screenshots, plus Lena Park added today), repositories over it.
  `MockHistory.seeded`: ~50 days of lists (you and what you carried, a few
  missed) and prayers that each hold several people (some days two, one
  auto-saved, some journal entries); nobody held after their `lastPrayed`,
  so Home's gold matches. Dad near-daily; Aunt Bea private with gaps; Mom's
  answered intention (its day has an entry); Lena only today. `MockPrayerRepository`
  holds prayers in memory until the backend takes them; the real queue
  replaces it.
- `App/AppEnvironment`: `-PPEnvironment mock|emulator|firebase`; only mock
  exists, the others log and fall back to it until build step 4.
- `State/HomeModel`: watches the repositories in `run()` (the view's
  `.task`), derives rows, counts, header and card through the domain;
  `log(_:)` sends Amen's prayer and starts the linger under Still to hold;
  `saveNote` queues the journal entry after it. `HomeModel+History`: the
  log (watched in `run()`, unsent prayers folded in) shaped into
  `historyPreview(_:)`, `historyScreen(_:)`, `historyDaySheet(_:scope:)`,
  `historyChip(_:)`.
- `PrayerSession`: phases idle → praying → (invitation) → closing → idle.
  The committing Amen (`amen(prayedWithListToday:)` or
  `amenFromInvitation()`) returns the `NewPrayer` for Home to log
  (`amen(logTo:)` does both, for Home and the pages); the selection stays
  through closing so held rings don't blink. `start(list:on:)` with a
  page's subject id sets `page` (in memory only; a restored draft would
  resume on Home) and pre-checks it (an intention's name with it; no
  haptic); `leavePage()` keeps praying and the checks; cancel and close
  clear it.
- `Features/AddSheet/AddSheet` + `State/AddSheetModel` (screens.md, Add
  sheet, revised 2026-11-07): **native `Form`s** (inset grouped, Tier B:
  no hand-set padding, type size or alignment), background hidden, rows
  `raised`, default section spacing, the standard large sheet.
  Toolbar buttons, a segmented Name | Intention; section headers
  for labels, footers for hints, errors (ink) and the counter; a top notice
  row; a native Toggle whose subtitle is the meter (its bloom
  `size.carriedMark.carryRow` tall via `@ScaledMetric`), its footer "Make
  room for this intention". Toolbar: X · segmented control · Add at
  opposite ends. The Name tab: the avatar centered on its own clear row
  (`avatar.person`, 96 pt, ~8 pt row insets; initials follow the display
  name, `PPIcon.person` while empty via `MonogramAvatar(placeholder:)`),
  then Name and "What you call them · optional" (footer "Only you see
  this"); **no carry row**: Add saves the name auto-carried while there's
  room and closes onto the person's page (`addedNameId`; HomeView pushes
  it as the sheet goes), whose card footer says "Private · in your
  prayers only" when it isn't carried. (Tried and dropped 2026-11-06/07: the avatar inside or beside the
  fields, a preview row, a toolbar avatar with Add splitting off the X, a
  Contacts-style name block, a second "Added" step with a "Not now · Name ·
  Name + intention" control. A view can't move between `Form` rows, and an
  overlay layer animated only sometimes on device.) **Only the visible
  tab is in the hierarchy**, so only it is in the accessibility tree (a
  hidden `Form`'s rows, a native Toggle included, ignore
  `accessibilityHidden`). Switching tabs, `KeyboardPrimer.Handle.prime`
  takes the keyboard first and the new field takes it in `onChange(of:
  tab)` (not the form's `onAppear`: that also runs as the chooser pops,
  and focusing mid-pop lost the toolbar). **The keyboard rises with the sheet** through
  `KeyboardPrimer`: SwiftUI focuses a `Form` field only after the sheet
  settles (~0.5 s late, `.defaultFocus` included; checked on a simulator
  recording), so a hidden UIKit field takes first responder as the sheet
  enters the window and hands over when SwiftUI focuses the real field
  (keystrokes in between go through `typeAhead`). "Who is this for?" is a
  real push (`@State` path, `.searchable`), its search inactive and the
  keyboard down; the intention field refocuses in the list's `onDisappear`
  (pick or back; from the root's `onAppear` mid-pop it didn't always take).
  The add-intention form for a person (`Step.person`,
  `init(home:intentionFor:)`, from a Home row's long-press menu; the
  person's page later) is untitled with X / Add: the person's row (44 pt
  avatar + serif name), "Intention" and its field, the same carry toggle as
  the Intention tab. The intention fields grow 1 → 3
  lines; Return submits, pasted breaks become spaces. The carry row (Q32,
  screens.md) is "Print with {alias} ✱" ("Print with your name ✱" under
  Me), from `intentionCarryOffer`: on by default when the person is carried
  and has no chosen intention; at the cap it starts off with "Instead of
  “{chosen}”" (on = a swap, sent as an explicit `carry: true`); under a
  person who isn't carried it starts off (never spends a place by default)
  with "Also carries {alias} · N places left" (on sends `carryParent`);
  with no place for them: disabled, their full line ("All N places in use"
  / the free line) and "Make room for {alias}" (inert, hint "Not available
  yet", Q31). If the server's result differs from the toggle
  (`AddedSubject.differs(from:)`, on `effectivelyCarried`; all or nothing),
  the sheet says "Saved, but not carried…" and waits for Done.
  `NewSubject.carry` / `carryParent` follow schema-brief.md ("addSubject
  carry inputs"); the mock has them, the callable gets them next.
- `Features/Detail/PersonPage` (detail-page.md; slice 2, 2026-11-08): a
  name's page, pushed from a Home row (Home is a `NavigationStack` root with
  its bar hidden; `home.run()` is a `.task` on the stack, not Home's
  content, or a push would cancel the streams; the path's ids go through
  `SubjectPage`, which shows a person's or an intention's page).
  `HomeModel.page(_:)` gives the values: the 96 pt avatar (held ring, large
  step), the alias in Roca `displayTitle` with the printed name under it and
  nothing else (the status moved into the card; the counts moved into the
  tiles); the **carry card** (`CarryCard`): the native Toggle "Carry onto the list
  ✱" with `nameCarryMeter` as subtitle ("3 places left", "This uses your
  last place", "All 10 places in use" never negative, free "Free carries
  you and your intention"; off and full: disabled + "Make room for {alias}",
  inert); "Prints with  {chosen} ›" (only while carried with open
  intentions; "Name only" when none) pushing `PrintsWithList` (native
  checkmark list, Name only + open intentions; cap 1 moves the check; a
  swap, never pool-checked); a hairline; the status footer (`carryStatus`:
  "Pray with today's list to carry {alias} onto List 53", "Private · in your
  prayers only", the closing notice; self: the card holds the status only).
  Turning off asks nothing. Never silent: offline disabled with "Needs a
  connection."; a failure flips back with "All {pool} places filled up." /
  "Couldn't change this. Try again." (ink; until the next tap or leaving
  the page). Section titles in the system sans (`type.sectionTitle`, Title 3
  semibold); a plain blue ＋ (`size.hitTarget`, label "Add intention for
  {alias}") on the Intentions title; none yet: only the prominent "＋ Add a
  first intention for {alias}". Intention rows (Home's, no thread) push the
  intention's page. **History preview** (`HistoryPreviewSection`, from
  `historyPreview`): "History" with "See all ›", one non-wrapping row of the
  most recent strand items (as many as fit; no month tabs; never ending on
  a fold) under "Today ▾", then the tiles (flat `cardSurface`, hidden at
  zero; ≤3 in a row, 4 as 2×2): "N · your prayers" → Held, "N · lists" +
  "N prayers" (the world, live-stitched) → Lists, "N · in your journal" →
  Journal, "N · answered" (gold number) → Answered. "See all" → All; a node
  → All with that day's sheet. All push `Route.history`.
- **Praying in place** (detail-page.md "Praying on the page";
  `Features/Prayer/PrayInPlace.swift`, both pages): `PagePrayBar`
  (`.pagePrayBar {}`) is the pray-button slot, in a `safeAreaInset`, not a
  `safeAreaBar`: a `safeAreaBar` takes taps across its whole width (iOS 26,
  even holding only a clear non-hit-testable spacer), and the empty space
  beside the capsule must reach the content (a tile under it); so no native
  soft scroll edge under the page's bar. It's a blue interactive-glass capsule
  "🙏 Pray for {alias}" ("Pray" on the self page and intention pages;
  answered intentions too) that morphs (`glassEffectID`, `GlassID` passed
  into `CountdownButton`; Reduce Motion: `materialize`) into the round
  pray button, with the pill (`PrayerTimerLine`: timer · "with N", no 🔎)
  fading in beside it. The page is stripped while `session.page == id`
  (start through the closing sheet): the carry card, the History preview,
  the Intentions ＋ (and the first-intention button: the section goes when
  there are no intentions) and ‹ fade out (`duration.strip`; Reduce
  Motion: `quick`), and fade back as the closing sheet goes, with the new
  counts. Kept: the Intentions title. Cancel is a native toolbar button
  in ‹'s place (`navigationBarBackButtonHidden`), with the shared
  `discardPrayerDialog` past ~30 s. The name's check sits in the header's
  trailing slot (`CheckSlot`, balanced by a clear frame so the avatar
  stays centered), the whole header a toggle; the ring is held today or
  held now, as on Home. Intention rows check instead of pushing. On an
  intention's page the person's name is plain text and the title row is
  the toggle; there its name follows it (`releasingWithItsName` in
  PlusPrayerDomain: unchecking the intention lets the name go too, since
  it can't be unchecked there). "Pray for others" (`PrayForOthersLink`,
  under the intentions, under the name with none, under the intention on
  its page) calls `leavePage()`; HomeView pops to Home when `page` clears
  mid-prayer, and calls `leavePage()` when the path shrinks (back), so a
  swipe from a deeper page lands on Home too. **Swipe-back with the back
  button hidden**: `swipeBackWhileBackHidden(_:)` (a zero-size
  `UIViewControllerRepresentable`) takes the navigation controller's
  `interactivePopGestureRecognizer` delegate while praying (begins when
  there's a page to pop) and hands the original back after; check it after
  an iOS update. Mid-prayer a Home row checks, so no page opens.
- **History** (`Features/History`, history.md): `HistoryScreen` (pushed as
  `Route.history(HistoryRequest)`: scope, tab, day; Home's footer opens it
  unfiltered). The filter sits in the toolbar: the glyph opens
  `HistoryPeopleList` (searchable, Home order, Me first, the current one
  checked); then a chip "{alias} ×" (an intention's text, truncated at
  `size.history.chipMaxWidth`), × widens to everyone. Tabs: a native
  segmented `Picker` in a `safeAreaBar` (a `.menu` picker at accessibility
  sizes). All: the streak line and "Time in prayer" (unfiltered), "Today ▾",
  the strand in `StrandFlow` (Components/HistoryStrand: `StrandNodeMark`,
  `StrandGapMark`, `StrandMonthTab`), older rows, Begun; a node (a button
  labelled with its day and what happened) opens `HistoryDaySheet` (medium
  / large detents). Held and Journal: day headings, time · length, the
  cluster unfiltered (`AvatarCluster` with `trailing: nil`), ✎. Lists:
  `WaxSeal` at `size.history.listSeal` · "List 52" · date · prayers.
  Answered: rows push the intention's page. An empty tab shows one quiet
  inkMuted line (`HistoryScreenValues.emptyLine`: "No prayers yet", "Not on
  a list yet", "Add to journal after a prayer"); Answered stays blank.
  Held, Journal, the day sheet's
  prayers and Lists rows are inert (Prayer detail and past lists' pages
  don't exist yet).
- `Features/Detail/IntentionPage` (minimal): the person's name above
  (pushes their page), the title in `type.intentionTitle` (Title 2 semibold)
  with the gold dot when held, the counts, the carry card ("Print with
  {alias} ✱", "Instead of …", "Also carries …", footer incl. "Private while
  {alias} isn't carried"; none when Answered: gold "Answered · {date}"),
  the History preview filtered to it (no Answered tile). Not yet: ⋯
  (praying in place: above). Home's intention rows push it in browse mode (in
  prayer a tap checks the row).
- Search (`Features/Home/HomeSearch.swift`): 🔎 turns the pill into the
  search field (see Theming above); with text it stays a field until ×,
  even with the keyboard down. The query feeds Home's domain rules
  (name + alias, a name kept as context, the card hidden while there's
  text). No matches: one line where only the query truncates, + Add
  prefilled (hidden in prayer), the match hint when a filter hides matches.
  "In your archive" waits for the archive.
- UI smoke tests (`PlusPrayerUITests`, its own scheme): pray → Amen →
  invitation → hold → Amen → closing → "Add to journal" → the card's status;
  Dad's "your prayers" tile → History (chip "Dad", Held) → × → back → a
  preview node → its day sheet; ＋ → name
  (no carry row; tabs keep the keyboard; the For push drops it, a pick or
  back refocuses) → alias → Add → on Home;
  long-press Dad → Add intention ("Print with Dad") → on Home; Dad's page
  → Pray for Dad (stripped, Dad held) → Amen → invitation → Amen → closing
  → Done → the tile one higher, today's node held; an intention's page →
  Pray → Pray for others → Home with the checks kept → Cancel; Dad's page
  in prayer → edge swipe → Home, still praying; Aunt Bea's
  page ("Private · in your prayers only") → carry her → her first
  intention → the ＋; search → results → no matches →
  the match hint → ×. Screenshots are attached to
  the result bundle (`xcrun xcresulttool export attachments`). To check
  motion (the keyboard with the sheet), record the simulator during the
  test (`xcrun simctl io <udid> recordVideo`) and look at frames.
