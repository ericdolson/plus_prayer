// Semantic theme for +Prayer. Widgets read `context.pp.colors.ink`, never a
// raw color, so the palette can be retuned in tokens.dart alone.

import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class PPColors {
  const PPColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.ember,
    required this.onEmber,
    required this.emberGlow,
    required this.halo,
    required this.carried,
    required this.unprayed,
    required this.accent,
  });

  /// Screen ground.
  final Color background;

  /// Sheets, the footer bar.
  final Color surface;

  /// Cards and pressed rows on a surface.
  final Color surfaceRaised;
  final Color hairline;

  /// Primary text.
  final Color ink;

  /// Secondary lines, quiet captions.
  final Color inkMuted;

  /// Disabled, placeholders, chevrons.
  final Color inkFaint;

  /// The prayer accent: FAB, Amen, ring, the held check.
  final Color ember;

  /// Text and icons on an ember fill.
  final Color onEmber;
  final Color emberGlow;

  /// Screen-edge glow in prayer mode.
  final Color halo;

  /// "will be on List 53", the carried mark (soft gold).
  final Color carried;

  /// The unprayed dot.
  final Color unprayed;

  /// Brand blue, used sparingly (focus, links).
  final Color accent;

  static const dark = PPColors(
    background: PPPalette.navy,
    surface: PPPalette.navyRaised,
    surfaceRaised: PPPalette.navyHigh,
    hairline: PPPalette.hairline,
    ink: PPPalette.parchment,
    inkMuted: PPPalette.parchmentMuted,
    inkFaint: PPPalette.parchmentFaint,
    ember: PPPalette.ember,
    onEmber: PPPalette.night,
    emberGlow: PPPalette.emberGlow,
    halo: PPPalette.ember,
    carried: PPPalette.carriedGold,
    unprayed: PPPalette.unprayedRose,
    accent: PPPalette.brandBlue,
  );

  /// Wax color for a seal variant (0 = Sunday … 6 = Saturday); null = unsealed.
  Color wax(int? sealVariant) =>
      sealVariant == null ? PPWax.unsealed : PPWax.base[sealVariant % PPWax.base.length];

  Color waxSheen(int? sealVariant) =>
      sealVariant == null ? PPWax.unsealed : PPWax.sheen[sealVariant % PPWax.sheen.length];

  /// Monogram tone by palette index (`avatarTone`).
  Color avatarTone(int tone) => PPAvatarTones.all[tone % PPAvatarTones.all.length];

  PPColors lerp(PPColors other, double t) => PPColors(
        background: Color.lerp(background, other.background, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
        hairline: Color.lerp(hairline, other.hairline, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
        inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
        ember: Color.lerp(ember, other.ember, t)!,
        onEmber: Color.lerp(onEmber, other.onEmber, t)!,
        emberGlow: Color.lerp(emberGlow, other.emberGlow, t)!,
        halo: Color.lerp(halo, other.halo, t)!,
        carried: Color.lerp(carried, other.carried, t)!,
        unprayed: Color.lerp(unprayed, other.unprayed, t)!,
        accent: Color.lerp(accent, other.accent, t)!,
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

  /// Horizontal page gutter.
  double get gutter => PPSpaceTokens.lg;
}

@immutable
class PPSizes {
  const PPSizes();

  double get avatar => PPSizeTokens.avatar;
  double get avatarSmall => PPSizeTokens.avatarSmall;
  double get avatarTiny => PPSizeTokens.avatarTiny;
  double get seal => PPSizeTokens.seal;
  double get fab => PPSizeTokens.fab;
  double get unprayedDot => PPSizeTokens.unprayedDot;
  double get intentionIndent => PPSizeTokens.intentionIndent;
  double get radiusSm => PPRadiusTokens.sm;
  double get radiusMd => PPRadiusTokens.md;
  double get radiusLg => PPRadiusTokens.lg;
}

@immutable
class PPMotion {
  const PPMotion();

  Duration get quick => PPMotionTokens.quick;
  Duration get settle => PPMotionTokens.settle;
  Duration get calm => PPMotionTokens.calm;
  Duration get haloBreath => PPMotionTokens.haloBreath;
  Duration get stagger => PPMotionTokens.stagger;
}

/// One extension carrying every +Prayer token group.
@immutable
class PPTheme extends ThemeExtension<PPTheme> {
  const PPTheme({required this.colors});

  final PPColors colors;
  PPSpacing get space => const PPSpacing();
  PPSizes get size => const PPSizes();
  PPMotion get motion => const PPMotion();

  static const dark = PPTheme(colors: PPColors.dark);

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
