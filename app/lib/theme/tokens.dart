// Raw design tokens. This is the ONLY file in lib/ that holds color literals,
// font sizes, and durations. Everything else reads the semantic names in
// pp_theme.dart through `context.pp`.
//
// Palettes: the POC's two themes (legacy_poc/lib/presentation/themes.dart):
// `darkTheme4` (charcoal grounds, cool ink) and `lightTheme3` (pale blue
// grounds, navy ink), sharing its primary blue for prayer (the pray button,
// the ring, Amen, the halo). Dark is the primary design (app-brief §0).

import 'package:flutter/painting.dart';

/// Shared by both palettes.
abstract final class PPPalette {
  // The POC's primary blue.
  static const blue = Color(0xFF0580F9);
  static const onBlue = Color(0xFFFFFFFF);

  /// Initials on an avatar tone (the tones are mid-dark in both themes).
  static const onAvatar = Color(0xFFF3F5F9);

  /// Drop shadows and wax shading.
  static const shadow = Color(0xFF000000);
}

/// The POC's `darkTheme4`.
abstract final class PPDarkPalette {
  static const deepest = Color(0xFF111315); // POC surfaceBright
  static const groundLow = Color(0xFF16191B); // POC surfaceTint
  static const ground = Color(0xFF1D2124); // POC scaffold, sheets, dialogs
  static const raised = Color(0xFF2D313A); // POC surface: the bottom bar, fields
  static const raisedHigh = Color(0xFF383D47);
  static const hairline = Color(0xFF343943);

  // Ink — the POC's onSurface, stepped down toward the ground.
  static const ink = Color(0xFFD7E0EE);
  static const inkMuted = Color(0xFF9097A1);
  static const inkFaint = Color(0xFF676D75);

  static const primaryGlow = Color(0xFF5AA9FB);

  // Status (copy rules §5: muted gray → soft gold; never red).
  static const carriedGold = Color(0xFFC8AE6E);
  static const unprayedRose = Color(0xFFC98A93); // the POC's pink, aged

  /// The POC's barrier: black at .75.
  static const scrim = Color(0xBF000000);

  /// The unsealed seal (before the list is published): bare, unwaxed.
  static const unsealed = Color(0xFF30353D);
}

/// The POC's `lightTheme3`.
abstract final class PPLightPalette {
  static const deepest = Color(0xFFD7DFEE);
  static const groundLow = Color(0xFFE1E7F3); // POC surfaceTint
  static const ground = Color(0xFFE9EEF9); // POC scaffold, sheets
  static const raised = Color(0xFFF5F7FD); // POC surface: the bottom bar, fields
  static const raisedHigh = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFD3DAE8);

  // Ink — the POC's dark blue onSurface, stepped up toward the ground.
  static const ink = Color(0xFF05294A);
  static const inkMuted = Color(0xFF5C748C);
  static const inkFaint = Color(0xFF8A9BB0);

  static const primaryGlow = Color(0xFF0573E0);

  static const carriedGold = Color(0xFF9A7A30);
  static const unprayedRose = Color(0xFFC2566F); // the POC's pink.shade400, aged

  static const scrim = Color(0x6605294A);
  static const unsealed = Color(0xFFC9D1DF);
}

/// Wax colors by `PrayerList.sealVariant` (0 = Sunday … 6 = Saturday), from the
/// 7-day rotation in ritual/CLAUDE.md. Metallic waxes get a lighter sheen.
abstract final class PPWax {
  static const List<Color> base = [
    Color(0xFFA9822F), // Sunday — Royal Gold
    Color(0xFF1E2C4A), // Monday — Navy Blue
    Color(0xFF6E1B20), // Tuesday — Deep Red
    Color(0xFF4F1C3A), // Wednesday — Metallic Garnet Purple
    Color(0xFF1C4330), // Thursday — Deep Green
    Color(0xFF7F6A3C), // Friday — Antique Brass
    Color(0xFF55382A), // Saturday — Brown
  ];
  static const List<Color> sheen = [
    Color(0xFFE2C46E),
    Color(0xFF4A5F8A),
    Color(0xFFA8454B),
    Color(0xFF8E4A74),
    Color(0xFF4E8063),
    Color(0xFFC2A86A),
    Color(0xFF8C654E),
  ];
}

/// Monogram avatar tones, indexed by `PrayerSubject.avatarTone` (0–15, the
/// placeholder bound the backend checks). Muted, antique, legible under
/// the light ink. Placeholder palette — retune here, the index stays stable.
abstract final class PPAvatarTones {
  static const List<Color> all = [
    Color(0xFF4B5D6B), // slate
    Color(0xFF6B5444), // walnut
    Color(0xFF4F6650), // moss
    Color(0xFF6E4B53), // mulberry
    Color(0xFF5C5A43), // olive
    Color(0xFF45556F), // dusk blue
    Color(0xFF735E3E), // ochre
    Color(0xFF5A4A64), // heather
    Color(0xFF3F6262), // verdigris
    Color(0xFF6A4E3E), // umber
    Color(0xFF55634A), // sage
    Color(0xFF64535B), // ash rose
    Color(0xFF4A5A57), // pewter green
    Color(0xFF6F5A4E), // clay
    Color(0xFF4D4F66), // indigo smoke
    Color(0xFF5F5A50), // stone
  ];
}

abstract final class PPSpaceTokens {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Text inset inside a grouped card (settings rows).
  static const double inset = 20;
}

abstract final class PPRadiusTokens {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double pill = 999;

  /// Top corners of the footer bar.
  static const double footer = 16;
}

abstract final class PPSizeTokens {
  static const double avatar = 48;
  /// The profile at the top of You.
  static const double avatarLarge = 72;
  static const double avatarSmall = 28;
  static const double avatarTiny = 20;
  static const double seal = 48;
  /// The pray button (the POC's 85 pt FAB), docked in the footer's notch.
  static const double fab = 85;
  static const double footerHeight = 56;
  static const double notchMargin = 8;
  static const double footerIcon = 30;
  /// The POC's unprayed dot, centered in a gutter-wide column left of the avatar.
  static const double unprayedDot = 8;
  /// Intentions start under their name's avatar.
  static const double intentionIndent = 48;
  /// Minimum height of a settings row.
  static const double settingsRow = 56;
  /// Chevrons and menu marks at the end of a row.
  static const double rowIcon = 20;
  /// A time wheel (reminder times).
  static const double wheelPicker = 216;
  /// The wordmark at the foot of You.
  static const double wordmark = 22;
}

abstract final class PPMotionTokens {
  static const quick = Duration(milliseconds: 160);
  static const settle = Duration(milliseconds: 320);
  static const calm = Duration(milliseconds: 700);
  /// The POC's elastic check.
  static const bounce = Duration(milliseconds: 700);
  static const haloBreath = Duration(milliseconds: 2400);
  static const stagger = Duration(milliseconds: 25);
}

abstract final class PPFontTokens {
  /// Display serif from the POC (names, titles, numbers).
  static const display = 'Roca';

  /// Body text.
  static const body = 'Roboto';

  /// Tabular figures (timer).
  static const mono = 'RobotoMono';
}
