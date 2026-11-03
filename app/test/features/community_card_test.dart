// The community card on Home (design-direction.md §6, 2026-11-02), on the
// mock seed: List 52, 4,345 people, 3,880 prayers, 213 praying now; you,
// Dad, Mom, Daniel Kim, Our parish and Ukraine carried; not yet prayed today.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/live.dart';
import 'package:plusprayer/components/monogram_avatar.dart';
import 'package:plusprayer/components/wax_seal.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/prayer.dart';
import 'package:plusprayer/theme/app_theme.dart';
import 'package:plusprayer/theme/pp_theme.dart';
import 'package:plusprayer/features/home/community_card.dart';

import '../helpers.dart';

Finder inCard(Finder f) => find.descendant(of: find.byType(CommunityCard), matching: f);

void main() {
  testWidgets('the label reads the world, your carried people, then one status', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    await settle(tester);
    expect(
      find.bySemanticsLabel(
        'List 52, sealed. 4,345 people · 3,880 prayers. 213 praying now. '
        'You, Dad, Mom, Daniel Kim, Our parish, Ukraine. Pray to carry them onto List 53',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no "are on List" line and no differences lines', (tester) async {
    await pumpHome(tester);
    expect(inCard(find.textContaining('are on List')), findsNothing);
    expect(inCard(find.textContaining('joins you')), findsNothing);
    expect(inCard(find.textContaining("isn't carried")), findsNothing);
    expect(inCard(find.text('Pray to carry them onto List 53')), findsOneWidget);
  });

  testWidgets('presence is the third left-aligned line, hidden in prayer mode', (tester) async {
    await pumpHome(tester);
    final presence = inCard(find.text('213 praying now'));
    expect(presence, findsOneWidget);
    final title = inCard(find.text('List\u00A052'));
    final counts = inCard(find.textContaining('people', findRichText: true));
    // The line starts with the live dot.
    final line = find.ancestor(of: presence, matching: find.byType(Row)).first;
    expect(tester.getRect(line).left, closeTo(tester.getRect(title).left, 1));
    expect(tester.getRect(presence).top, greaterThanOrEqualTo(tester.getRect(counts).bottom));

    await tester.tap(find.bySemanticsLabel('Pray'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(inCard(find.text('213 praying now')), findsNothing);
  });

  testWidgets('28 pt avatars with the same initials as the rows, never below 11 pt', (tester) async {
    await pumpHome(tester);
    await settle(tester);
    final avatars = inCard(find.byType(MonogramAvatar));
    expect(avatars, findsWidgets);
    for (final e in avatars.evaluate()) {
      final avatar = find.byWidget(e.widget);
      expect(tester.getSize(avatar), const Size.square(28));
      final glyph = tester.widget<Text>(find.descendant(of: avatar, matching: find.byType(Text)));
      expect(glyph.style!.fontSize, greaterThanOrEqualTo(11));
    }
    // Overlap ≤ ~4–5 pt, so two-letter initials are never covered.
    final lefts = [for (final e in avatars.evaluate()) tester.getRect(find.byWidget(e.widget)).left]..sort();
    for (var i = 1; i < lefts.length; i++) {
      expect(lefts[i] - lefts[i - 1], greaterThanOrEqualTo(28 - 5));
    }
    // "DK" for Daniel Kim (not "D", which is Dad's).
    expect(find.descendant(of: avatars, matching: find.text('DK')), findsOneWidget);
  });

  testWidgets('dark theme only: the stamp gets a rim light layer', (tester) async {
    await pumpHome(tester);
    Finder layers() => find.descendant(of: inCard(find.byType(WaxSeal)), matching: find.byType(Image));
    expect(layers(), findsNWidgets(2));
  });

  testWidgets('light theme: the stamp stays one plain layer', (tester) async {
    await pumpHome(tester, theme: AppTheme.light());
    Finder layers() => find.descendant(of: inCard(find.byType(WaxSeal)), matching: find.byType(Image));
    expect(layers(), findsOneWidget);
  });

  testWidgets('the status is ink until covered, inkMuted once covered', (tester) async {
    final backend = await pumpHome(tester);
    await settle(tester);
    Color? colorOf(String text) => tester.widget<Text>(inCard(find.text(text))).style?.color;
    expect(colorOf('Pray to carry them onto List\u00A053'), PPColors.dark.ink);

    backend.applyPrayer(NewPrayer(
      id: 'p1',
      startedAt: testNow,
      prayedAt: testNow,
      durationSeconds: 60,
      localDate: LocalDate.of(testNow),
      timezone: 'America/Denver',
      listContextNumber: 52,
      subjectIds: const [],
      communityListId: 'list-52',
    ));
    await settle(tester);
    expect(colorOf("They'll be on List\u00A053"), PPColors.dark.inkMuted);
  });

  testWidgets('the closing notice replaces the status line', (tester) async {
    final backend = await pumpHome(tester);
    backend.setClosesAt(testNow.add(const Duration(minutes: 3)));
    await settle(tester);
    expect(inCard(find.text('List 52 closes in 3 min · pray to carry them')), findsOneWidget);
    expect(inCard(find.text('Pray to carry them onto List 53')), findsNothing);
  });

  testWidgets('the stamp is ~110 pt, cropped ~23 pt left and ~15 pt up (tuned by eye)', (tester) async {
    await pumpHome(tester);
    final seal = inCard(find.byType(WaxSeal));
    final card = find.byType(CommunityCard);
    expect(tester.getSize(seal), const Size.square(110));
    final cardBox = tester.getRect(find.descendant(of: card, matching: find.byType(Material)).first);
    final sealBox = tester.getRect(seal);
    expect(sealBox.left - cardBox.left, closeTo(-23, .5));
    expect(sealBox.top - cardBox.top, closeTo(-15, .5));
  });

  testWidgets('the avatar row shows even when you weren\'t on today\'s list', (tester) async {
    final handle = tester.ensureSemantics();
    final backend = await pumpHome(tester);
    // Not prayed with List 52, so nobody of yours is printed on List 53.
    backend.flipList();
    await settle(tester);
    expect(
      find.bySemanticsLabel(RegExp('^List\u00A053, being filmed\\..*You, Dad, Mom, Daniel Kim, Our parish, Ukraine\\. ')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the unsealed seal is a blank stamp, not a dashed ring', (tester) async {
    final backend = await pumpHome(tester);
    backend.flipList();
    await settle(tester);
    final seal = inCard(find.byType(WaxSeal));
    // The blank and, in dark, its neutral rim.
    expect(find.descendant(of: seal, matching: find.byType(Image)), findsNWidgets(2));
    expect(find.descendant(of: seal, matching: find.byType(CustomPaint)), findsNothing);
  });

  testWidgets('lower presence rungs keep their verb', (tester) async {
    final backend = await pumpHome(tester);
    backend.setStats(const LiveStats(prayingNow: 3, prayedLastHour: 640, prayedToday: 4113));
    await settle(tester);
    expect(inCard(find.text('640 prayed this hour')), findsOneWidget);
    backend.setStats(const LiveStats(prayingNow: 3, prayedLastHour: 4, prayedToday: 4113));
    await settle(tester);
    expect(inCard(find.text('4,113 prayed today')), findsOneWidget);
  });

  group('large type', () {
    // The test font (Ahem) is far wider than SF Pro, so the default size gets
    // a wider screen to fit on one line as it does on a phone.
    Future<void> pumpAt(WidgetTester tester, double scale, {double width = 393}) async {
      tester.view.physicalSize = Size(width * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpHome(tester);
      await settle(tester);
    }

    Finder counts(String word) => inCard(find.textContaining(word, findRichText: true));

    testWidgets('the counts share a line at the default size', (tester) async {
      await pumpAt(tester, 1, width: 600);
      expect(tester.getCenter(counts('people')).dy, tester.getCenter(counts('prayers')).dy);
    });

    testWidgets('the counts wrap at the middle dot, and nothing is cut off or shrunk', (tester) async {
      await pumpAt(tester, 2);
      expect(tester.getCenter(counts('prayers')).dy, greaterThan(tester.getCenter(counts('people')).dy));
      expect(inCard(find.byType(FittedBox)), findsNothing);
      final status = tester.widget<Text>(inCard(find.text('Pray to carry them onto List\u00A053')));
      expect(status.overflow, isNot(TextOverflow.ellipsis));
      expect(status.maxLines, isNull);
    });

    testWidgets('at accessibility sizes the world block moves below the stamp', (tester) async {
      await pumpAt(tester, 3);
      final seal = tester.getRect(inCard(find.byType(WaxSeal)));
      expect(tester.getRect(inCard(find.text('List\u00A052'))).top, greaterThanOrEqualTo(seal.bottom));
    });
  });
}
