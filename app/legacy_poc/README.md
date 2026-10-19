# legacy_poc — the old Firestore proof of concept

Moved here from `lib/` and `test/` on 2026-10-19 so it stays available as
reference. It is outside `lib/`, so it isn't compiled, and `analysis_options.yaml`
excludes it from `flutter analyze`.

Worth borrowing as ideas (some already ported into `lib/`):
- In-prayer mode: `lib/hooks/use_in_prayer.dart`, `lib/widgets/screens/home/home_v2.dart`
- Screen halo: `lib/widgets/animations/SiriHalo.dart` (CustomPainter + screen_corner_radius)
- Name row with the unprayed dot: `lib/widgets/names/name_list_tile.dart`
- Icon font: `lib/presentation/plus_prayer_icons.dart` (font file is in `assets/fonts/`)

Not patterns to follow: Firestore collections, the `PPFirebase` singleton,
global `ChangeNotifier` state, and inline colors/text styles.
