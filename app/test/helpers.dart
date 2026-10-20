import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plusprayer/app/environment.dart';
import 'package:plusprayer/data/mock/mock_backend.dart';
import 'package:plusprayer/features/home/home_screen.dart';
import 'package:plusprayer/l10n/app_localizations.dart';
import 'package:plusprayer/state/providers.dart';
import 'package:plusprayer/theme/app_theme.dart';

/// A fixed "now" for widget tests: Monday 2026-10-19, 9:00 local.
final testNow = DateTime(2026, 10, 19, 9);

/// Pumps Home on the mock backend (no latency, no live drift, fixed clock).
Future<MockBackend> pumpHome(WidgetTester tester, {DateTime Function()? clock}) async {
  final now = clock ?? () => testNow;
  final backend = MockBackend(now: now, latency: Duration.zero, liveDrift: false);
  final overrides = await mockOverrides(backend);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...overrides,
      clockProvider.overrideWithValue(now),
      nowProvider.overrideWith((ref) => Stream.value(now())),
      timezoneProvider.overrideWith((ref) async => 'America/Denver'),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: const HomeScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump();
  addTearDown(backend.dispose);
  return backend;
}

/// Lets async work (mock latency, stream hops) finish. Not pumpAndSettle:
/// the halo breathes while praying, so the tree never settles.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
