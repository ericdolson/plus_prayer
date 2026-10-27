// Raw design tokens. This is the ONLY file in lib/ that holds color literals,
// font sizes, and durations. Everything else reads the semantic names in
// pp_theme.dart through `context.pp`.
//
// Palettes: the POC's two themes (legacy_poc/lib/presentation/themes.dart),
// `darkTheme4` (charcoal grounds, cool ink) and `lightTheme3` (pale blue
// grounds, navy ink), recolored by meaning (design-direction.md §1):
//   blue  = do this (pray button, Amen, the invitation, primary buttons)
//   gold  = held (rings, intention dots, the prayer halo, "Answered")
//   everything else neutral. No red, no pink.
// Contrast checked (WCAG): ink and inkMuted ≥ 4.5:1 on ground and card;
// heldGold ≥ 3:1 (non-text); heldGoldText ≥ 4.5:1; onPrimary on primary
// 4.6:1 light, 3.8:1 dark (glyphs and large text). inkFaint is decorative
// only (~3:1 and below).

import 'package:flutter/painting.dart';

/// Shared by both palettes.
abstract final class PPPalette {
  /// Initials on an avatar tone (the tones are mid-dark in both themes).
  static const onAvatar = Color(0xFFF3F5F9);

  /// Drop shadows and wax shading.
  static const shadow = Color(0xFF000000);
}

/// The POC's `darkTheme4`, taken about halfway to black (2026-10-24): a
/// near-black ground like iOS and Gmail dark, with surfaces kept in clear
/// steps above it (the old ground is now roughly the card).
abstract final class PPDarkPalette {
  static const deepest = Color(0xFF07080A);
  static const groundLow = Color(0xFF0A0B0D); // pressed rows, splashes
  static const ground = Color(0xFF0E1012); // scaffold
  static const sheet = Color(0xFF16191D); // sheets and dialogs, a slight lift (iOS-style)
  static const card = Color(0xFF1A1D21); // the community card, settings groups (1.13:1 step)
  static const raised = Color(0xFF23272D); // fields, pills, the footer bar
  static const raisedHigh = Color(0xFF2E333A);
  static const hairline = Color(0xFF2A2E35); // also the intention thread

  // Ink — the POC's onSurface, stepped down toward the ground.
  static const ink = Color(0xFFD7E0EE); // 14.3:1 on ground
  static const inkMuted = Color(0xFF9097A1); // 6.5:1 on ground, 5.7:1 on card, 5.1:1 on raised
  static const inkFaint = Color(0xFF676D75); // decorative only

  // The POC's (and brand's) electric blue with white, as the pray button had
  // it. White on it is 3.8:1: fine for the glyph (≥3:1), short of 4.5:1 for
  // small text.
  static const primary = Color(0xFF0580F9);
  static const onPrimary = Color(0xFFFFFFFF);

  static const heldGold = Color(0xFFC8AE6E); // 8.8:1 on ground
  static const heldGoldText = heldGold;
  static const heldGlow = Color(0x59C8AE6E); // heldGold at 35%
  static const onHeld = ground;

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
  static const sheet = ground;
  static const raised = Color(0xFFF5F7FD); // POC surface: fields, the card
  static const card = raised;
  static const raisedHigh = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFD3DAE8);

  // Ink — the POC's dark blue onSurface, stepped up toward the ground.
  static const ink = Color(0xFF05294A); // 12.7:1 on ground
  static const inkMuted = Color(0xFF566D83); // 4.6:1 on ground (the POC's #5C748C was 4.2)
  static const inkFaint = Color(0xFF8A9BB0); // decorative only

  static const primary = Color(0xFF0573E0);
  static const onPrimary = Color(0xFFFFFFFF); // 4.6:1

  static const heldGold = Color(0xFF9A7A30); // 3.5:1 on ground: rings and dots only
  static const heldGoldText = Color(0xFF765A1C); // 5.6:1 on ground
  static const onHeld = Color(0xFFFFFFFF); // 4.0:1 on heldGold (a glyph, not text)

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

  /// Side margins on Home (design-direction.md §3), and text inset inside a
  /// card.
  static const double gutter = 20;
  static const double inset = 20;

  /// Between one name (with its intentions) and the next.
  static const double groupGap = 12;
}

abstract final class PPRadiusTokens {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double pill = 999;

  /// The community card.
  static const double card = 22;

  /// Top corners of the footer bar.
  static const double footer = 16;
}

abstract final class PPSizeTokens {
  /// Name rows (design-direction.md §3: one line, ~64 pt, ~44 pt avatar).
  static const double avatar = 44;
  static const double nameRow = 64;
  static const double intentionRow = 44;

  /// The profile at the top of You.
  static const double avatarLarge = 72;
  static const double avatarSmall = 28;
  static const double avatarTiny = 20;
  static const double seal = 44;

  /// Held ring: width and gap from the avatar (§5).
  static const double heldRing = 2;
  static const double heldRingGap = 2;

  /// The community card's gold border once you've prayed with the list today.
  static const double cardBorder = 1.5;

  /// The gold dot where the thread meets a held intention.
  static const double heldDot = 5;

  /// The intention thread's stroke.
  static const double thread = 1;

  /// The prayer-mode check in a row's trailing slot.
  static const double check = 24;

  /// The live dot beside "praying now".
  static const double liveDot = 6;

  /// The streak badge's logo seal.
  static const double badgeSeal = 24;

  /// The pray button (the POC's 85 pt FAB), docked in the footer's notch.
  static const double fab = 85;
  static const double footerHeight = 56;
  static const double notchMargin = 8;
  static const double footerIcon = 28;
  static const double headerIcon = 24;

  /// Minimum height of a settings row.
  static const double settingsRow = 56;

  /// Chevrons and menu marks at the end of a row.
  static const double rowIcon = 20;

  /// A time wheel (reminder times).
  static const double wheelPicker = 216;

  /// The wordmark at the foot of You.
  static const double wordmark = 22;

  /// Pull past this to reveal search (iOS Mail).
  static const double pullToSearch = 64;
}

abstract final class PPMotionTokens {
  static const quick = Duration(milliseconds: 160);
  static const settle = Duration(milliseconds: 320);
  static const calm = Duration(milliseconds: 700);

  /// The check's spring — the only spring in the app (design-direction.md §8).
  static const spring = Duration(milliseconds: 420);
  static const haloBreath = Duration(milliseconds: 2400);
}

/// Translucent bars (design-direction.md §4).
abstract final class PPMaterialTokens {
  static const double barBlur = 24;

  /// Fill over the blur.
  static const double barTint = .72;

  /// Fill where blur isn't used (Android, low-end).
  static const double barOpaque = .94;
}

abstract final class PPFontTokens {
  /// Display serif from the POC: names on Home, list numbers, big lines only
  /// (design-direction.md §2).
  static const display = 'Roca';

  /// Body text is the platform's system font (SF Pro on iOS, Roboto on
  /// Android): no family set, so Material's platform typography supplies it.
  static const String? body = null;
}
