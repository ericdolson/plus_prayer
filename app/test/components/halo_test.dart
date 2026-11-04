import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/components/halo.dart';
import 'package:plusprayer/theme/app_theme.dart';

class _CountingPainter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(_CountingPainter old) => false;
}

void main() {
  testWidgets('the breathing halo never repaints the screen beneath it', (tester) async {
    final screen = _CountingPainter();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Halo(mode: HaloMode.on, child: CustomPaint(painter: screen, size: Size.infinite)),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    final before = screen.paints;

    // Several seconds of breathing, frame by frame.
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(screen.paints, before);
  });

  testWidgets('the glow is painted once; breathing only fades its layer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const Halo(mode: HaloMode.on, child: SizedBox.expand()),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    final glow = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: find.byType(Halo), matching: find.byType(RepaintBoundary)).last,
    );
    final before = glow.debugSymmetricPaintCount + glow.debugAsymmetricPaintCount;

    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(glow.debugSymmetricPaintCount + glow.debugAsymmetricPaintCount, before);
  });

  group('behavior (design-direction.md §7)', () {
    Widget halo(HaloMode mode, {bool reduceMotion = false}) => MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Halo(mode: mode, child: const SizedBox.expand()),
          ),
        );

    Opacity? layer(WidgetTester tester) {
      final found = find.descendant(of: find.byType(Halo), matching: find.byType(Opacity));
      return found.evaluate().isEmpty ? null : tester.widget<Opacity>(found);
    }

    double opacity(WidgetTester tester) => layer(tester)?.opacity ?? 0;

    double reach(WidgetTester tester) {
      final paint = find.descendant(of: find.byType(Halo), matching: find.byType(CustomPaint)).last;
      return (tester.widget<CustomPaint>(paint).painter! as dynamic).reach as double;
    }

    // A started animation takes its first tick on the next frame.
    Future<void> show(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(widget);
      await tester.pump();
    }

    Future<void> settleIn(WidgetTester tester, {bool reduceMotion = false}) async {
      await tester.pumpWidget(halo(HaloMode.off, reduceMotion: reduceMotion));
      await show(tester, halo(HaloMode.on, reduceMotion: reduceMotion));
    }

    testWidgets('fades in over ~400 ms', (tester) async {
      await settleIn(tester);
      expect(opacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inExclusiveRange(0, .65));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inInclusiveRange(.65, .85));
    });

    testWidgets('at rest it breathes slowly between ~0.65 and ~0.85', (tester) async {
      await settleIn(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final seen = <double>[];
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 50)); // 10 s
        seen.add(opacity(tester));
        expect(reach(tester), 1);
      }
      expect(seen.reduce(math.min), closeTo(.65, .01));
      expect(seen.reduce(math.max), closeTo(.85, .01));
      // ~8 s per cycle: a twentieth of a second barely moves it.
      for (var i = 1; i < seen.length; i++) {
        expect((seen[i] - seen[i - 1]).abs(), lessThan(.01));
      }
    });

    testWidgets('✕ cancel: a plain ~400 ms fade-out, no flare', (tester) async {
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 2));
      final start = opacity(tester);
      await show(tester, halo(HaloMode.off));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inExclusiveRange(0, start));
      expect(reach(tester), 1);
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacity(tester), 0);
    });

    testWidgets('committing Amen: a ~500 ms flare (full and ~1.3× reach), then the ~400 ms fade', (tester) async {
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 2));
      final rest = opacity(tester);
      await show(tester, halo(HaloMode.amen));

      // A fast ease-out rise: most of the way there by half of it.
      await tester.pump(const Duration(milliseconds: 75));
      expect(reach(tester), greaterThan(1 + .3 * .6));

      // Peak at ~150 ms: full strength, ~1.3× the resting reach.
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(tester), closeTo(.99, .01));
      expect(reach(tester), closeTo(1.3, .01));

      // A slower ease-in-out settle: halfway down at its midpoint (~325 ms)…
      await tester.pump(const Duration(milliseconds: 175));
      expect(reach(tester), closeTo(1.15, .01));

      // …and back to rest before the fade begins.
      await tester.pump(const Duration(milliseconds: 174));
      expect(opacity(tester), closeTo(rest, .05));

      await tester.pump(const Duration(milliseconds: 2)); // flare done; fade starts
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inExclusiveRange(0, rest - .1));
      expect(reach(tester), 1);
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacity(tester), 0);
    });

    testWidgets('a new prayer during the Amen sequence takes the halo back', (tester) async {
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 1));
      await show(tester, halo(HaloMode.amen));
      await tester.pump(const Duration(milliseconds: 300));
      await show(tester, halo(HaloMode.on));
      await tester.pump(const Duration(seconds: 1));
      expect(opacity(tester), inInclusiveRange(.65, .85));
      expect(reach(tester), 1);
    });

    testWidgets('Reduce Motion: static at ~0.75, no flare, plain fades in and out', (tester) async {
      await settleIn(tester, reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inExclusiveRange(0, .75));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), .75);

      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(opacity(tester), .75);
      }

      await show(tester, halo(HaloMode.amen, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), inExclusiveRange(0, .75));
      expect(reach(tester), 1);
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacity(tester), 0);
    });
  });

  test('at rest the glow reaches no more than ~12 pt in from the edge', () {
    for (final width in [Halo.defaultGlowWidth, Halo.defaultGlowWidth * Halo.lightWidthScale]) {
      expect(Halo.inwardReach(width), lessThanOrEqualTo(12));
    }
  });
}
