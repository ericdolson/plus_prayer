Native Android app (Kotlin + Jetpack Compose, Material 3). Not started; built after iOS, before public launch. Product rules live in docs/product/.

## Parity notes (things iOS has that the spec alone won't make obvious)
- Portrait only (screens.md).
- App icon and launch screen come from the Flutter app's assets; Android
  needs an adaptive icon and has its own splash question (open-questions D4,
  D7; auth-onboarding.md "Launch screen").
- Home header: avatar and streak badge 8 pt apart (design-direction §4).
- Restore is the `restoreSubject` callable, not a connector op; carry saves
  that only reduce carrying are always accepted (backend/dataconnect/
  connector/OPERATIONS.md). The server enforces both; just call them.
- Product rules shared with iOS live in `PlusPrayerDomain` (Swift) with
  tests; port those tests to Kotlin as the parity contract.
