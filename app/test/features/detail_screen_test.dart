import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plusprayer/app/environment.dart';
import 'package:plusprayer/app/router.dart';
import 'package:plusprayer/data/mock/mock_backend.dart';
import 'package:plusprayer/features/detail/detail_screen.dart';
import 'package:plusprayer/features/home/home_screen.dart';
import 'package:plusprayer/l10n/app_localizations.dart';
import 'package:plusprayer/state/prayer_session.dart';
import 'package:plusprayer/state/providers.dart';
import 'package:plusprayer/theme/app_theme.dart';

import '../helpers.dart';

class _Clock {
  DateTime now = testNow;
}

class _App {
  _App(this.backend, this.router, this.container, this._clock);
  final MockBackend backend;
  final GoRouter router;
  final ProviderContainer container;
  final _Clock _clock;

  DateTime get now => _clock.now;
  set now(DateTime t) => _clock.now = t;

  PrayerSessionState get session => container.read(prayerSessionProvider);

  /// Ends a prayer left open (its heartbeat timer).
  Future<void> endPrayer(WidgetTester tester) async {
    await container.read(prayerSessionProvider.notifier).cancel();
    await settle(tester);
  }
}

/// The app on the mock backend, opened at [location] (Home beneath it).
Future<_App> _pump(WidgetTester tester, String location) async {
  // Wider than a phone: the test font's wide glyphs would crowd the pill.
  tester.view.physicalSize = const Size(1600, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final clock = _Clock();
  final backend = MockBackend(now: () => clock.now, latency: Duration.zero, liveDrift: false);
  final router = buildRouter(initialLocation: location);
  final container = ProviderContainer(overrides: [
    ...await mockOverrides(backend),
    clockProvider.overrideWithValue(() => clock.now),
    nowProvider.overrideWith((ref) => Stream.value(clock.now)),
    timezoneProvider.overrideWith((ref) async => 'America/Denver'),
  ]);
  final app = _App(backend, router, container, clock);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.dark(),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      routerConfig: router,
    ),
  ));
  await settle(tester);
  addTearDown(() {
    container.dispose();
    backend.dispose();
  });
  return app;
}

void main() {
  testWidgets('Dad\'s page: title, status, counts, intentions, history, pray button', (tester) async {
    await _pump(tester, Routes.subject('dad'));
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Dad'), findsOneWidget);
    // Not prayed with List 52 yet (seed: yesterday's streak).
    expect(find.text('Pray to carry Dad onto List 53'), findsOneWidget);
    expect(find.textContaining('Held by you · '), findsOneWidget);
    expect(find.textContaining('Carried by the world · '), findsOneWidget);
    expect(find.text('Intentions'), findsOneWidget);
    expect(find.textContaining('Healing after his surgery'), findsOneWidget);
    expect(find.textContaining('Rest for his heart'), findsOneWidget);
    expect(find.text('Add intention for Dad'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Pray for Dad'), findsOneWidget);
  });

  testWidgets('praying stays on the page: stripped, Dad pre-checked, intentions checkable', (tester) async {
    final app = await _pump(tester, Routes.subject('dad'));
    await tester.tap(find.text('Pray for Dad'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.session.isActive, isTrue);
    expect(app.session.selection.held, {'dad'});
    expect(find.byType(DetailScreen), findsOneWidget);
    // What isn't the subject is gone; Cancel and "Pray for others" are here.
    expect(find.textContaining('Held by you · '), findsNothing);
    expect(find.text('History'), findsNothing);
    expect(find.text('Add intention for Dad'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Pray for others'), findsOneWidget);

    await tester.tap(find.textContaining('Healing after his surgery'));
    await settle(tester);
    expect(app.session.selection.held, {'dad', 'dad-1'});
    // The name can be unchecked, which lets its intentions go too.
    await tester.tap(find.text('Dad'));
    await settle(tester);
    expect(app.session.selection.held, isEmpty);
    await app.endPrayer(tester);
  });

  testWidgets('"Pray for others" goes Home, still praying, checks kept', (tester) async {
    final app = await _pump(tester, Routes.subject('dad'));
    await tester.tap(find.text('Pray for Dad'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Pray for others'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(DetailScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.session.isActive, isTrue);
    expect(app.session.selection.held, {'dad'});
    await app.endPrayer(tester);
  });

  testWidgets('Amen on the page: invitation, closing, then the counts come back one higher', (tester) async {
    final app = await _pump(tester, Routes.subject('dad'));
    String heldLine() => (tester.widget<Text>(find.textContaining('Held by you · ')).data)!;
    final before = heldLine();
    await tester.tap(find.text('Pray for Dad'));
    await settle(tester);
    app.now = app.now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Amen'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    // The list hasn't been prayed today: the invitation; finish without it.
    expect(app.session.phase, PrayerPhase.invitation);
    await tester.tap(find.widgetWithText(TextButton, 'Amen'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(app.session.phase, PrayerPhase.closing);
    expect(find.byType(DetailScreen), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(app.session.phase, PrayerPhase.idle);
    expect(app.backend.loggedPrayerIds, hasLength(1));
    final after = heldLine();
    int n(String line) => int.parse(RegExp(r'(\d+)').firstMatch(line.replaceAll(',', ''))!.group(1)!);
    expect(n(after), n(before) + 1);
  });

  testWidgets('the self page: "Pray", "Add intention", no Archive', (tester) async {
    await _pump(tester, Routes.subject('self'));
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.text('Add intention'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
  });

  testWidgets('a private intention: parent above, no status line, "Pray" credits it and its name', (tester) async {
    final app = await _pump(tester, Routes.subject('dad-2'));
    expect(find.text('Dad'), findsOneWidget);
    expect(find.textContaining('List 53'), findsNothing);
    expect(find.text('Intentions'), findsNothing);
    await tester.tap(find.text('Pray'));
    await settle(tester);
    expect(app.session.selection.held, {'dad-2', 'dad'});
    await app.endPrayer(tester);
  });

  testWidgets('⋯ → Archive, confirmed: the name is gone and the page pops', (tester) async {
    final app = await _pump(tester, Routes.subject('daniel'));
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Archive'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Archive Daniel Kim?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Archive'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(app.backend.subjects.any((s) => s.id == 'daniel'), isFalse);
    expect(find.byType(DetailScreen), findsNothing);
  });

  testWidgets('⋯ → Answered on an intention: the status turns to "Answered"', (tester) async {
    await _pump(tester, Routes.subject('dad-1'));
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Answered'));
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Answered · '), findsOneWidget);
  });
}
