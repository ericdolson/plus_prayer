// Semantic theme for +Prayer. Widgets read `context.pp.colors.ink`, never a
// raw color, so the palette can be retuned in tokens.dart alone.

import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class PPColors {
  const PPColors({
    required this.brightness,
    required this.background,
    required this.backgroundLow,
    required this.surface,
    required this.surfaceRaised,
    required this.cardSurface,
    required this.hairline,
    required this.thread,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.primary,
    required this.onPrimary,
    required this.heldGold,
    required this.heldGoldText,
    required this.heldGlow,
    required this.onHeld,
    required this.halo,
    required this.onAvatar,
    required this.shadow,
    required this.scrim,
    required this.deepest,
    required this.unsealed,
  });

  final Brightness brightness;

  /// Screen ground; sheets and dialogs.
  final Color background;

  /// A step below the ground (pressed rows, splashes).
  final Color backgroundLow;

  /// Text fields, pills, the footer bar.
  final Color surface;

  /// Menus and controls on a surface.
  final Color surfaceRaised;

  /// The community card and settings groups: a flat tonal step up from the
  /// ground (no shadow, no border).
  final Color cardSurface;

  final Color hairline;

  /// The line from a name's avatar to its intentions. Always neutral.
  final Color thread;

  /// Primary text.
  final Color ink;

  /// Secondary text, intentions (≥ 4.5:1 on ground and card).
  final Color inkMuted;

  /// Decorative only: placeholders, unchecked marks. Never essential text.
  final Color inkFaint;

  /// Blue = do this: the pray button, Amen, the invitation, primary buttons.
  /// Never status, toggles, or checks.
  final Color primary;

  /// Text and icons on a primary fill.
  final Color onPrimary;

  /// Gold = held: rings, intention dots, the halo. Non-text.
  final Color heldGold;

  /// Gold text ("Answered · Oct 6").
  final Color heldGoldText;

  /// Soft glow around held marks; dark mode only (it washes out in light).
  final Color? heldGlow;

  /// A glyph on a gold fill (the prayer check).
  final Color onHeld;

  /// Screen-edge glow in prayer mode (gold).
  final Color halo;

  /// Initials on an avatar tone.
  final Color onAvatar;

  /// Drop shadows and wax shading (apply alpha at the use site).
  final Color shadow;

  /// Behind modal sheets and dialogs (alpha included).
  final Color scrim;

  /// The far end of the ground scale.
  final Color deepest;

  /// The seal before the list is published.
  final Color unsealed;

  static const dark = PPColors(
    brightness: Brightness.dark,
    background: PPDarkPalette.ground,
    backgroundLow: PPDarkPalette.groundLow,
    surface: PPDarkPalette.raised,
    surfaceRaised: PPDarkPalette.raisedHigh,
    cardSurface: PPDarkPalette.card,
    hairline: PPDarkPalette.hairline,
    thread: PPDarkPalette.hairline,
    ink: PPDarkPalette.ink,
    inkMuted: PPDarkPalette.inkMuted,
    inkFaint: PPDarkPalette.inkFaint,
    primary: PPDarkPalette.primary,
    onPrimary: PPDarkPalette.onPrimary,
    heldGold: PPDarkPalette.heldGold,
    heldGoldText: PPDarkPalette.heldGoldText,
    heldGlow: PPDarkPalette.heldGlow,
    onHeld: PPDarkPalette.onHeld,
    halo: PPDarkPalette.heldGold,
    onAvatar: PPPalette.onAvatar,
    shadow: PPPalette.shadow,
    scrim: PPDarkPalette.scrim,
    deepest: PPDarkPalette.deepest,
    unsealed: PPDarkPalette.unsealed,
  );

  static const light = PPColors(
    brightness: Brightness.light,
    background: PPLightPalette.ground,
    backgroundLow: PPLightPalette.groundLow,
    surface: PPLightPalette.raised,
    surfaceRaised: PPLightPalette.raisedHigh,
    cardSurface: PPLightPalette.card,
    hairline: PPLightPalette.hairline,
    thread: PPLightPalette.hairline,
    ink: PPLightPalette.ink,
    inkMuted: PPLightPalette.inkMuted,
    inkFaint: PPLightPalette.inkFaint,
    primary: PPLightPalette.primary,
    onPrimary: PPLightPalette.onPrimary,
    heldGold: PPLightPalette.heldGold,
    heldGoldText: PPLightPalette.heldGoldText,
    heldGlow: null,
    onHeld: PPLightPalette.onHeld,
    halo: PPLightPalette.heldGold,
    onAvatar: PPPalette.onAvatar,
    shadow: PPPalette.shadow,
    scrim: PPLightPalette.scrim,
    deepest: PPLightPalette.deepest,
    unsealed: PPLightPalette.unsealed,
  );

  /// Wax color for a seal variant (0 = Sunday … 6 = Saturday); null = unsealed.
  Color wax(int? sealVariant) => sealVariant == null ? unsealed : PPWax.base[sealVariant % PPWax.base.length];

  Color waxSheen(int? sealVariant) => sealVariant == null ? unsealed : PPWax.sheen[sealVariant % PPWax.sheen.length];

  /// Monogram tone by palette index (`avatarTone`).
  Color avatarTone(int tone) => PPAvatarTones.all[tone % PPAvatarTones.all.length];

  PPColors lerp(PPColors other, double t) => PPColors(
        brightness: t < .5 ? brightness : other.brightness,
        background: Color.lerp(background, other.background, t)!,
        backgroundLow: Color.lerp(backgroundLow, other.backgroundLow, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
        cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
        hairline: Color.lerp(hairline, other.hairline, t)!,
        thread: Color.lerp(thread, other.thread, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
        inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
        primary: Color.lerp(primary, other.primary, t)!,
        onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
        heldGold: Color.lerp(heldGold, other.heldGold, t)!,
        heldGoldText: Color.lerp(heldGoldText, other.heldGoldText, t)!,
        heldGlow: Color.lerp(heldGlow, other.heldGlow, t),
        onHeld: Color.lerp(onHeld, other.onHeld, t)!,
        halo: Color.lerp(halo, other.halo, t)!,
        onAvatar: Color.lerp(onAvatar, other.onAvatar, t)!,
        shadow: Color.lerp(shadow, other.shadow, t)!,
        scrim: Color.lerp(scrim, other.scrim, t)!,
        deepest: Color.lerp(deepest, other.deepest, t)!,
        unsealed: Color.lerp(unsealed, other.unsealed, t)!,
      );
}

@immutable
class PPSpacing {
  const PPSpacing();

  double get xxs => PPSpaceTokens.xxs;
  double get xs => PPSpaceTokens.xs;
  double get sm => PPSpaceTokens.sm;
  double get md => PPSpaceTokens.md;
  double get lg => PPSpaceTokens.lg;
  double get xl => PPSpaceTokens.xl;
  double get xxl => PPSpaceTokens.xxl;
  double get xxxl => PPSpaceTokens.xxxl;
  double get inset => PPSpaceTokens.inset;

  /// Horizontal page margin (20 pt).
  double get gutter => PPSpaceTokens.gutter;
  double get groupGap => PPSpaceTokens.groupGap;
}

@immutable
class PPSizes {
  const PPSizes();

  double get avatar => PPSizeTokens.avatar;
  double get nameRow => PPSizeTokens.nameRow;
  double get intentionRow => PPSizeTokens.intentionRow;
  double get avatarLarge => PPSizeTokens.avatarLarge;
  double get avatarSmall => PPSizeTokens.avatarSmall;
  double get avatarTiny => PPSizeTokens.avatarTiny;
  double get seal => PPSizeTokens.seal;
  double get heldRing => PPSizeTokens.heldRing;
  double get heldRingGap => PPSizeTokens.heldRingGap;
  double get heldRingSmall => PPSizeTokens.heldRingSmall;
  double get heldRingGapSmall => PPSizeTokens.heldRingGapSmall;
  double get heldDot => PPSizeTokens.heldDot;
  double get thread => PPSizeTokens.thread;
  double get check => PPSizeTokens.check;
  double get liveDot => PPSizeTokens.liveDot;
  double get badgeSeal => PPSizeTokens.badgeSeal;
  double get fab => PPSizeTokens.fab;
  double get footerHeight => PPSizeTokens.footerHeight;
  double get notchMargin => PPSizeTokens.notchMargin;
  double get footerIcon => PPSizeTokens.footerIcon;
  double get headerIcon => PPSizeTokens.headerIcon;
  double get settingsRow => PPSizeTokens.settingsRow;
  double get rowIcon => PPSizeTokens.rowIcon;
  double get wheelPicker => PPSizeTokens.wheelPicker;
  double get wordmark => PPSizeTokens.wordmark;
  double get pullToSearch => PPSizeTokens.pullToSearch;
  double get radiusSm => PPRadiusTokens.sm;
  double get radiusMd => PPRadiusTokens.md;
  double get radiusLg => PPRadiusTokens.lg;
  double get radiusCard => PPRadiusTokens.card;
  double get radiusFooter => PPRadiusTokens.footer;
}

@immutable
class PPMotion {
  const PPMotion();

  Duration get quick => PPMotionTokens.quick;
  Duration get settle => PPMotionTokens.settle;
  Duration get calm => PPMotionTokens.calm;
  Duration get spring => PPMotionTokens.spring;
  Duration get haloBreath => PPMotionTokens.haloBreath;
}

@immutable
class PPBars {
  const PPBars();

  double get blur => PPMaterialTokens.barBlur;
  double get tint => PPMaterialTokens.barTint;
  double get opaque => PPMaterialTokens.barOpaque;
}

/// One extension carrying every +Prayer token group.
@immutable
class PPTheme extends ThemeExtension<PPTheme> {
  const PPTheme({required this.colors});

  final PPColors colors;
  PPSpacing get space => const PPSpacing();
  PPSizes get size => const PPSizes();
  PPMotion get motion => const PPMotion();
  PPBars get bars => const PPBars();

  static const dark = PPTheme(colors: PPColors.dark);
  static const light = PPTheme(colors: PPColors.light);

  @override
  PPTheme copyWith({PPColors? colors}) => PPTheme(colors: colors ?? this.colors);

  @override
  PPTheme lerp(ThemeExtension<PPTheme>? other, double t) {
    if (other is! PPTheme) return this;
    return PPTheme(colors: colors.lerp(other.colors, t));
  }
}

extension PPThemeContext on BuildContext {
  PPTheme get pp => Theme.of(this).extension<PPTheme>() ?? PPTheme.dark;
  TextTheme get text => Theme.of(this).textTheme;
}
