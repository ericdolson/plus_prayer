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
    required this.hairline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.primary,
    required this.onPrimary,
    required this.primaryGlow,
    required this.halo,
    required this.carried,
    required this.unprayed,
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

  /// The footer bar, text fields.
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

  /// The prayer accent: the pray button, Amen, the ring, the held check.
  final Color primary;

  /// Text and icons on a primary fill.
  final Color onPrimary;

  /// The glow around a held avatar; primary-colored text on the ground.
  final Color primaryGlow;

  /// Screen-edge glow in prayer mode.
  final Color halo;

  /// "will be on List 53", the carried mark (soft gold).
  final Color carried;

  /// The unprayed dot.
  final Color unprayed;

  /// Initials on an avatar tone.
  final Color onAvatar;

  /// Drop shadows and wax shading (apply alpha at the use site).
  final Color shadow;

  /// Behind modal sheets and dialogs (alpha included).
  final Color scrim;

  /// The far end of the ground scale (text on status fills).
  final Color deepest;

  /// The seal before the list is published.
  final Color unsealed;

  static const dark = PPColors(
    brightness: Brightness.dark,
    background: PPDarkPalette.ground,
    backgroundLow: PPDarkPalette.groundLow,
    surface: PPDarkPalette.raised,
    surfaceRaised: PPDarkPalette.raisedHigh,
    hairline: PPDarkPalette.hairline,
    ink: PPDarkPalette.ink,
    inkMuted: PPDarkPalette.inkMuted,
    inkFaint: PPDarkPalette.inkFaint,
    primary: PPPalette.blue,
    onPrimary: PPPalette.onBlue,
    primaryGlow: PPDarkPalette.primaryGlow,
    halo: PPPalette.blue,
    carried: PPDarkPalette.carriedGold,
    unprayed: PPDarkPalette.unprayedRose,
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
    hairline: PPLightPalette.hairline,
    ink: PPLightPalette.ink,
    inkMuted: PPLightPalette.inkMuted,
    inkFaint: PPLightPalette.inkFaint,
    primary: PPPalette.blue,
    onPrimary: PPPalette.onBlue,
    primaryGlow: PPLightPalette.primaryGlow,
    halo: PPPalette.blue,
    carried: PPLightPalette.carriedGold,
    unprayed: PPLightPalette.unprayedRose,
    onAvatar: PPPalette.onAvatar,
    shadow: PPPalette.shadow,
    scrim: PPLightPalette.scrim,
    deepest: PPLightPalette.deepest,
    unsealed: PPLightPalette.unsealed,
  );

  /// Wax color for a seal variant (0 = Sunday … 6 = Saturday); null = unsealed.
  Color wax(int? sealVariant) =>
      sealVariant == null ? unsealed : PPWax.base[sealVariant % PPWax.base.length];

  Color waxSheen(int? sealVariant) =>
      sealVariant == null ? unsealed : PPWax.sheen[sealVariant % PPWax.sheen.length];

  /// Monogram tone by palette index (`avatarTone`).
  Color avatarTone(int tone) => PPAvatarTones.all[tone % PPAvatarTones.all.length];

  PPColors lerp(PPColors other, double t) => PPColors(
        brightness: t < .5 ? brightness : other.brightness,
        background: Color.lerp(background, other.background, t)!,
        backgroundLow: Color.lerp(backgroundLow, other.backgroundLow, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
        hairline: Color.lerp(hairline, other.hairline, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
        inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
        primary: Color.lerp(primary, other.primary, t)!,
        onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
        primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
        halo: Color.lerp(halo, other.halo, t)!,
        carried: Color.lerp(carried, other.carried, t)!,
        unprayed: Color.lerp(unprayed, other.unprayed, t)!,
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

  /// Horizontal page gutter.
  double get gutter => PPSpaceTokens.lg;
}

@immutable
class PPSizes {
  const PPSizes();

  double get avatar => PPSizeTokens.avatar;
  double get avatarLarge => PPSizeTokens.avatarLarge;
  double get avatarSmall => PPSizeTokens.avatarSmall;
  double get avatarTiny => PPSizeTokens.avatarTiny;
  double get seal => PPSizeTokens.seal;
  double get fab => PPSizeTokens.fab;
  double get footerHeight => PPSizeTokens.footerHeight;
  double get notchMargin => PPSizeTokens.notchMargin;
  double get footerIcon => PPSizeTokens.footerIcon;
  double get unprayedDot => PPSizeTokens.unprayedDot;
  double get intentionIndent => PPSizeTokens.intentionIndent;
  double get settingsRow => PPSizeTokens.settingsRow;
  double get rowIcon => PPSizeTokens.rowIcon;
  double get wheelPicker => PPSizeTokens.wheelPicker;
  double get wordmark => PPSizeTokens.wordmark;
  double get radiusSm => PPRadiusTokens.sm;
  double get radiusMd => PPRadiusTokens.md;
  double get radiusLg => PPRadiusTokens.lg;
  double get radiusFooter => PPRadiusTokens.footer;
}

@immutable
class PPMotion {
  const PPMotion();

  Duration get quick => PPMotionTokens.quick;
  Duration get settle => PPMotionTokens.settle;
  Duration get calm => PPMotionTokens.calm;
  Duration get bounce => PPMotionTokens.bounce;
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
