// This week's bead strand (detail-page.md History, simplified 2026-11-03):
// one bead per list the item is on this week (≤ 7), ~13 pt, in that list's
// wax (`sealVariant`, lifted in dark like every seal; no rim at this size),
// oldest → newest in reading order, left-aligned on a thin neutral thread at
// a fixed pitch. A full week is the whole set of weekday waxes.
//
// - The current list's bead while unsealed ("being filmed") is a hollow ring
//   (~1.5 pt `inkMuted` stroke, no fill), in both themes; it fills with its
//   wax once sealed.
// - Lists missed between two beads: a quiet break in the thread (one pitch
//   of bare space), no label.
//
// Decorative: the period row says it in words.

import 'package:flutter/material.dart';

import '../domain/rules/history.dart';
import '../theme/pp_theme.dart';

class BeadStrand extends StatelessWidget {
  const BeadStrand({super.key, required this.items});

  /// Oldest → newest, as `rules/history.dart` builds them.
  final List<StrandItem> items;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final pitch = pp.size.beadPitch;
    return ExcludeSemantics(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: items.length * pitch,
          height: pp.size.bead,
          child: CustomPaint(
            painter: _StrandPainter(
              items: items,
              pitch: pitch,
              bead: pp.size.bead,
              threadWidth: pp.size.thread,
              threadColor: c.thread,
              waxOf: c.waxLifted,
              hollowColor: c.inkMuted,
              hollowStroke: pp.size.beadHollowStroke,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrandPainter extends CustomPainter {
  _StrandPainter({
    required this.items,
    required this.pitch,
    required this.bead,
    required this.threadWidth,
    required this.threadColor,
    required this.waxOf,
    required this.hollowColor,
    required this.hollowStroke,
    required this.textDirection,
  });

  final List<StrandItem> items;
  final double pitch;
  final double bead;
  final double threadWidth;
  final Color threadColor;
  final Color Function(int sealVariant) waxOf;
  final Color hollowColor;
  final double hollowStroke;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (textDirection == TextDirection.rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final y = size.height / 2;
    final thread = Paint()
      ..color = threadColor
      ..strokeWidth = threadWidth;
    // Thread runs bead edge to bead edge (so a hollow bead stays hollow); a
    // break leaves its slot bare.
    final r = bead / 2;
    double? previous;
    final beads = <(double, int?)>[];
    for (var i = 0; i < items.length; i++) {
      final x = i * pitch + pitch / 2;
      switch (items[i]) {
        case StrandBead(:final sealVariant):
          if (previous != null) canvas.drawLine(Offset(previous + r, y), Offset(x - r, y), thread);
          previous = x;
          beads.add((x, sealVariant));
        case StrandGap():
          previous = null;
      }
    }
    for (final (x, seal) in beads) {
      if (seal == null) {
        // Being filmed: a ring, its stroke inside the bead's outline.
        canvas.drawCircle(
          Offset(x, y),
          r - hollowStroke / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = hollowStroke
            ..color = hollowColor,
        );
      } else {
        canvas.drawCircle(Offset(x, y), r, Paint()..color = waxOf(seal));
      }
    }
  }

  @override
  bool shouldRepaint(_StrandPainter old) =>
      old.items != items ||
      old.pitch != pitch ||
      old.bead != bead ||
      old.threadColor != threadColor ||
      old.hollowColor != hollowColor ||
      old.textDirection != textDirection;
}
