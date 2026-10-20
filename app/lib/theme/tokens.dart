// Raw design tokens. This is the ONLY file in lib/ that holds color literals,
// font sizes, and durations. Everything else reads the semantic names in
// pp_theme.dart through `context.pp`.
//
// Direction (root CLAUDE.md): darker over lighter, antique over bright. The
// base is the brand navy (#0C1B29) pushed deeper; ink is warm parchment, not
// white; the accent is ember (the oil lamp in the ritual), not electric blue.

import 'package:flutter/painting.dart';

abstract final class PPPalette {
  // Grounds — brand navy, deepened.
  static const night = Color(0xFF070E15);
  static const navy = Color(0xFF0C1B29);
  static const navyRaised = Color(0xFF12232F);
  static const navyHigh = Color(0xFF1A2C3A);
  static const hairline = Color(0xFF243645);

  // Ink — aged paper.
  static const parchment = Color(0xFFE9E0CF);
  static const parchmentMuted = Color(0xFFA99F8E);
  static const parchmentFaint = Color(0xFF6E6A60);

  // Light of the ritual.
  static const ember = Color(0xFFD9A05B);
  static const emberDeep = Color(0xFF9A6A33);
  static const emberGlow = Color(0xFFE8B670);

  // Status (copy rules §5: muted gray → soft gold; never red).
  static const carriedGold = Color(0xFFC8AE6E);
  static const unprayedRose = Color(0xFFC98A93); // the POC's pink, aged

  // Brand accent, used sparingly (focus rings, links).
  static const brandBlue = Color(0xFF0580F9);
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

  /// The unsealed state (before the list is published): bare, unwaxed.
  static const unsealed = Color(0xFF2A3A47);
}

/// Monogram avatar tones, indexed by `PrayerSubject.avatarTone` (0–15, the
/// placeholder bound the backend checks). Muted, antique, legible under
/// parchment ink. Placeholder palette — retune here, the index stays stable.
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
}

abstract final class PPRadiusTokens {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class PPSizeTokens {
  static const double avatar = 44;
  static const double avatarSmall = 28;
  static const double avatarTiny = 20;
  static const double seal = 48;
  static const double fab = 68;
  static const double unprayedDot = 7;
  static const double intentionIndent = 56;
}

abstract final class PPMotionTokens {
  static const quick = Duration(milliseconds: 160);
  static const settle = Duration(milliseconds: 320);
  static const calm = Duration(milliseconds: 700);
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
