// ThemeData built from the tokens. Material components get their look here so
// feature code can use stock widgets (FilledButton, TextField, …) without
// passing styles.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pp_theme.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(PPTheme.dark);

  static ThemeData _build(PPTheme pp) {
    final c = pp.colors;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: c.ember,
      onPrimary: PPPalette.night,
      secondary: c.carried,
      onSecondary: PPPalette.night,
      error: c.unprayed, // never a bright red (copy rules §5)
      onError: PPPalette.night,
      surface: c.background,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: PPPalette.night,
      surfaceContainerLow: c.background,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.hairline,
      outlineVariant: c.hairline,
      shadow: PPPalette.night,
      scrim: PPPalette.night,
    );

    final text = _textTheme(c);
    final radiusMd = BorderRadius.circular(PPRadiusTokens.md);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: PPFontTokens.body,
      textTheme: text,
      extensions: [pp],
      splashFactory: InkSparkle.splashFactory,
      highlightColor: c.surfaceRaised.withValues(alpha: .4),
      splashColor: c.surfaceRaised.withValues(alpha: .5),
      iconTheme: IconThemeData(color: c.inkMuted, size: 24),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: .5, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        modalBarrierColor: PPPalette.night.withValues(alpha: .7),
        dragHandleColor: c.inkFaint,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PPRadiusTokens.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        barrierColor: PPPalette.night.withValues(alpha: .7),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PPRadiusTokens.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        hintStyle: text.bodyLarge?.copyWith(color: c.inkFaint),
        labelStyle: text.bodyMedium?.copyWith(color: c.inkMuted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.unprayed),
        counterStyle: text.bodySmall?.copyWith(color: c.inkFaint),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: PPSpaceTokens.lg,
          vertical: PPSpaceTokens.md,
        ),
        border: OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radiusMd, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.ember.withValues(alpha: .6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.unprayed.withValues(alpha: .6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.unprayed),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ember,
          foregroundColor: PPPalette.night,
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
        style: IconButton.styleFrom(foregroundColor: c.inkMuted, minimumSize: const Size(48, 48)),
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
        cursorColor: c.ember,
        selectionColor: c.ember.withValues(alpha: .3),
        selectionHandleColor: c.ember,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ember),
    );
  }

  static TextTheme _textTheme(PPColors c) {
    TextStyle display(double size, FontWeight weight, {double height = 1.2}) => TextStyle(
          fontFamily: PPFontTokens.display,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: c.ink,
        );
    TextStyle body(double size, FontWeight weight, Color color, {double height = 1.35}) => TextStyle(
          fontFamily: PPFontTokens.body,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color,
        );

    return TextTheme(
      // Onboarding lines, the welcome-back question.
      displaySmall: display(30, FontWeight.w700),
      headlineMedium: display(26, FontWeight.w700),
      // The invitation line ("Hold the 4,345 on List 52 …").
      headlineSmall: display(22, FontWeight.w400, height: 1.3),
      // Sheet titles.
      titleLarge: display(21, FontWeight.w700),
      // Row titles (names, "List 52").
      titleMedium: display(18, FontWeight.w700),
      // Intention row titles.
      titleSmall: display(16, FontWeight.w400),
      bodyLarge: body(16, FontWeight.w400, c.ink),
      bodyMedium: body(14, FontWeight.w400, c.ink),
      // Secondary row lines, captions.
      bodySmall: body(12.5, FontWeight.w500, c.inkMuted),
      labelLarge: body(15, FontWeight.w600, c.ink, height: 1.2),
      labelMedium: body(13, FontWeight.w600, c.inkMuted, height: 1.2),
      // Timer and counts: tabular figures.
      labelSmall: const TextStyle(
        fontFamily: PPFontTokens.mono,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontFeatures: [FontFeature.tabularFigures()],
      ).copyWith(color: c.ink),
    );
  }
}
