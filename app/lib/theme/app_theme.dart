// ThemeData built from the tokens. Material components get their look here so
// feature code can use stock widgets (FilledButton, TextField, …) without
// passing styles.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pp_theme.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(PPTheme.dark);
  static ThemeData light() => _build(PPTheme.light);

  /// Status bar icons that read on [c]'s ground.
  static SystemUiOverlayStyle overlayStyle(PPColors c) =>
      c.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  static ThemeData _build(PPTheme pp) {
    final c = pp.colors;
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.heldGold,
      onSecondary: c.onHeld,
      // No red or pink anywhere (design-direction.md §1): errors are ink.
      error: c.ink,
      onError: c.background,
      surface: c.background,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.deepest,
      surfaceTint: Colors.transparent,
      surfaceContainerLow: c.background,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.hairline,
      outlineVariant: c.hairline,
      shadow: c.shadow,
      scrim: c.shadow,
    );

    final text = _textTheme(c);
    final radiusMd = BorderRadius.circular(PPRadiusTokens.md);

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      // Null: the platform's system font (SF Pro on iOS) from Material's
      // platform typography.
      fontFamily: PPFontTokens.body,
      textTheme: text,
      extensions: [pp],
      splashFactory: InkSparkle.splashFactory,
      // The POC's row splash (surfaceTint).
      highlightColor: c.backgroundLow.withValues(alpha: .6),
      splashColor: c.backgroundLow,
      iconTheme: IconThemeData(color: c.inkMuted, size: 24),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: .5, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlayStyle(c),
      ),
      // Sheets and dialogs lift slightly off the ground (dark); fields on the
      // raised surface.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheet,
        modalBackgroundColor: c.sheet,
        modalBarrierColor: c.scrim,
        dragHandleColor: c.inkFaint,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PPRadiusTokens.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.sheet,
        barrierColor: c.scrim,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PPRadiusTokens.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: text.bodyLarge?.copyWith(color: c.inkFaint),
        labelStyle: text.bodyMedium?.copyWith(color: c.inkMuted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.ink),
        counterStyle: text.bodySmall?.copyWith(color: c.inkFaint),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: PPSpaceTokens.lg,
          vertical: PPSpaceTokens.md,
        ),
        border: OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.primary.withValues(alpha: .7)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.inkMuted),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.ink),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.inkFaint,
          textStyle: text.labelLarge,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PPRadiusTokens.pill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.inkMuted,
          textStyle: text.labelLarge,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.hairline),
          textStyle: text.labelLarge,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PPRadiusTokens.pill)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        // The POC's app bar and footer icons: full ink.
        style: IconButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 48)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.inkMuted,
          selectedBackgroundColor: c.surfaceRaised,
          selectedForegroundColor: c.ink,
          side: BorderSide(color: c.hairline),
          textStyle: text.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.background,
        selectedColor: c.surfaceRaised,
        side: BorderSide(color: c.hairline),
        labelStyle: text.labelMedium?.copyWith(color: c.inkMuted),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: c.ink),
        checkmarkColor: c.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PPRadiusTokens.pill)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceRaised,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: .35),
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      // Controls are neutral: ink when on, never blue (design-direction.md §1).
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.background : c.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ink : c.surfaceRaised,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      // Pull-down menus (Appearance, Language).
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(c.shadow.withValues(alpha: .5)),
          elevation: const WidgetStatePropertyAll(12),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radiusMd)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: PPSpaceTokens.xs)),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          foregroundColor: c.ink,
          iconColor: c.ink,
          textStyle: text.bodyLarge,
          minimumSize: const Size(200, 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: PPSpaceTokens.md),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: PPSizeTokens.footerHeight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: PPSpaceTokens.sm),
      ),
    );
  }

  static TextTheme _textTheme(PPColors c) {
    // Roca: names on Home, list numbers, big lines (design-direction.md §2).
    TextStyle display(double size, FontWeight weight, {double height = 1.2}) => TextStyle(
          fontFamily: PPFontTokens.display,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: 0,
          color: c.ink,
        );
    // System sans, with SF's tracking for its size.
    TextStyle body(double size, FontWeight weight, Color color, {double height = 1.3, double tracking = 0}) =>
        TextStyle(
          fontFamily: PPFontTokens.body,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: tracking,
          color: color,
        );

    return TextTheme(
      // Onboarding lines, the welcome-back question.
      displaySmall: display(30, FontWeight.w700),
      // Names as titles (the You sheet).
      headlineMedium: display(26, FontWeight.w700),
      // Big lines: the invitation, "You'll be carried on List 53".
      headlineSmall: display(22, FontWeight.w400, height: 1.3),
      // Sheet and dialog titles.
      titleLarge: body(20, FontWeight.w600, c.ink, tracking: -.45),
      // Names on Home and "List 52".
      titleMedium: display(19, FontWeight.w700),
      // Intentions on Home: smaller sans, muted.
      titleSmall: body(15, FontWeight.w400, c.inkMuted, tracking: -.23),
      bodyLarge: body(17, FontWeight.w400, c.ink, tracking: -.43),
      bodyMedium: body(15, FontWeight.w400, c.ink, tracking: -.23),
      // Secondary lines, captions.
      bodySmall: body(13, FontWeight.w400, c.inkMuted, tracking: -.08),
      labelLarge: body(15, FontWeight.w600, c.ink, height: 1.2, tracking: -.23),
      labelMedium: body(13, FontWeight.w500, c.inkMuted, height: 1.2, tracking: -.08),
      // Timer and counts: tabular figures.
      labelSmall: body(15, FontWeight.w500, c.ink, height: 1.2, tracking: -.23)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
