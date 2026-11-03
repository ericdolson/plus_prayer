// Dark-theme wax separation (design-direction.md §6): part of WaxSeal, so
// every seal on a dark surface gets it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/components/wax_seal.dart';
import 'package:plusprayer/theme/app_theme.dart';
import 'package:plusprayer/theme/pp_theme.dart';

Future<void> pumpSeal(WidgetTester tester, {required ThemeData theme, int? variant = 1, double size = 104}) =>
    tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Center(child: WaxSeal(variant: variant, size: size)),
    ));

Finder layers() => find.descendant(of: find.byType(WaxSeal), matching: find.byType(Image));

void main() {
  testWidgets('dark: every seal gets the rim layer, no flag needed', (tester) async {
    await pumpSeal(tester, theme: AppTheme.dark());
    expect(layers(), findsNWidgets(2));
  });

  testWidgets('dark, below ~24 pt: no rim', (tester) async {
    await pumpSeal(tester, theme: AppTheme.dark(), size: 20);
    expect(layers(), findsOneWidget);
  });

  testWidgets('dark: the unsealed blank gets a rim too', (tester) async {
    await pumpSeal(tester, theme: AppTheme.dark(), variant: null);
    expect(layers(), findsNWidgets(2));
  });

  testWidgets('light: one plain layer', (tester) async {
    await pumpSeal(tester, theme: AppTheme.light());
    expect(layers(), findsOneWidget);
  });

  test('the lift: dark waxes only, never Sunday, never in light', () {
    expect(PPColors.dark.waxLifted(0), PPColors.dark.wax(0), reason: 'Sunday gold: no lift');
    expect(PPColors.dark.waxLifted(1), isNot(PPColors.dark.wax(1)), reason: 'Monday navy: lifted');
    for (var v = 0; v < 7; v++) {
      expect(PPColors.light.waxLifted(v), PPColors.light.wax(v));
    }
  });
}
