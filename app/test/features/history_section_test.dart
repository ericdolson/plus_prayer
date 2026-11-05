import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plusprayer/app/environment.dart';
import 'package:plusprayer/components/bead_strand.dart';
import 'package:plusprayer/data/mock/mock_backend.dart';
import 'package:plusprayer/features/detail/history_section.dart';
import 'package:plusprayer/l10n/app_localizations.dart';
import 'package:plusprayer/state/providers.dart';
import 'package:plusprayer/theme/app_theme.dart';

import '../helpers.dart';

Future<MockBackend> _pump(WidgetTester tester, String id, {TextDirection direction = TextDirection.ltr}) async {
  final backend = MockBackend(now: () => testNow, latency: Duration.zero, liveDrift: false);
  final overrides = await mockOverrides(backend);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...overrides,
      clockProvider.overrideWithValue(() => testNow),
      nowProvider.overrideWith((ref) => Stream.value(testNow)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: ListView(children: [HistorySection(subjectId: id)])),
      ),
    ),
  ));
  await settle(tester);
  addTearDown(backend.dispose);
  return backend;
}

void main() {
  testWidgets('Dad: rows speak their counts and the current list; one strand', (tester) async {
    await _pump(tester, 'dad');
    final labels = [
      for (final e in find.byType(Semantics).evaluate())
        if ((e.widget as Semantics).properties.label case final l?) l,
    ];
    expect(find.text('History'), findsOneWidget);
    // testNow = Mon Oct 19; en_US weeks start Sunday: this week = Oct 18–19.
    // One sentence per row, every count in words; only this week draws beads.
    expect(labels, contains('This week. You prayed 2 times. On 2 lists · current. 1 note'));
    expect(labels, contains('Last week. You prayed 6 times. On 5 lists. 1 note'));
    expect(find.byType(BeadStrand), findsOneWidget);
    expect(find.textContaining('Begun · '), findsOneWidget);
  });

  testWidgets('a private intention: prayers, no strand; an answered one gets its hint', (tester) async {
    await _pump(tester, 'dad-2');
    expect(find.byType(BeadStrand), findsNothing);
    expect(find.textContaining('You prayed'), findsWidgets);
    expect(find.textContaining('On '), findsNothing);

    await _pump(tester, 'mom-1');
    expect(find.text('Answered'), findsOneWidget);
  });

  testWidgets('the current bead follows the seal (being filmed → wax) and RTL lays out', (tester) async {
    final backend = await _pump(tester, 'dad', direction: TextDirection.rtl);
    backend.setSealed(false);
    await settle(tester);
    expect(tester.takeException(), isNull);
    backend.setSealed(true);
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
