// The header streak badge (design-direction.md §4): the seal is always pewter,
// and the number carries the state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/components/streak_badge.dart';
import 'package:plusprayer/components/wax_seal.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/user_header.dart';
import 'package:plusprayer/domain/rules/streak.dart';
import 'package:plusprayer/l10n/app_localizations.dart';
import 'package:plusprayer/theme/app_theme.dart';
import 'package:plusprayer/theme/pp_theme.dart';

Future<PPColors> pumpBadge(WidgetTester tester, StreakBadgeState state, int days) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: Material(child: Center(child: StreakBadge(state: state, days: days))),
  ));
  await tester.pump();
  return PPColors.dark;
}

PewterSeal sealOf(WidgetTester tester) => tester.widget<PewterSeal>(find.byType(PewterSeal));

void main() {
  testWidgets('prayed today: full pewter seal, number in ink', (tester) async {
    final c = await pumpBadge(tester, StreakBadgeState.sealedToday, 12);
    expect(sealOf(tester).dimmed, isFalse);
    expect(tester.widget<Text>(find.text('12')).style?.color, c.ink);
  });

  testWidgets('alive, not yet today: dimmer seal, number in inkMuted', (tester) async {
    final c = await pumpBadge(tester, StreakBadgeState.alive, 12);
    expect(sealOf(tester).dimmed, isTrue);
    expect(tester.widget<Text>(find.text('12')).style?.color, c.inkMuted);
  });

  testWidgets('zero: dim seal, no number', (tester) async {
    await pumpBadge(tester, StreakBadgeState.none, 0);
    expect(sealOf(tester).dimmed, isTrue);
    expect(find.text('0'), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the badge never renders a wax seal, and the seal is ~22 pt', (tester) async {
    for (final state in StreakBadgeState.values) {
      await pumpBadge(tester, state, 3);
      expect(find.byType(WaxSeal), findsNothing);
      expect(tester.getSize(find.byType(PewterSeal)), const Size.square(22));
    }
  });

  test('the prayed-today state clears at local midnight, keeping the streak', () {
    const day = LocalDate(2026, 11, 1);
    const user = UserHeader(id: 'u', includeLimit: 3, currentStreak: 12, lastListLocalDate: day);
    expect(streakBadgeState(user, day), StreakBadgeState.sealedToday);
    expect(streakBadgeState(user, day.addDays(1)), StreakBadgeState.alive);
    expect(effectiveStreak(user, day.addDays(1)), 12);
  });
}
