import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// The day's wax seal — the list row's avatar (list-lifecycle.md). Seven
/// stamps, one per weekday wax (`sealVariant` 0 = Sunday … 6 = Saturday), each
/// with its own pour shape. Null [variant] = the unsealed state, before the
/// list is published ("being filmed").
///
/// Painted placeholders for the 7 custom stamp vectors; swap the painter for
/// the real artwork when it exists — the API stays the same.
class WaxSeal extends StatelessWidget {
  const WaxSeal({super.key, required this.variant, this.size, this.semanticLabel, this.muted = false});

  final int? variant;
  final double? size;
  final String? semanticLabel;

  /// Quieter rendering (e.g. the streak badge when not yet prayed today).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final d = size ?? context.pp.size.seal;
    final painter = variant == null || muted
        ? _UnsealedPainter(outline: c.inkFaint, ground: c.surfaceRaised, filled: muted && variant != null)
        : _SealPainter(
            wax: c.wax(variant),
            sheen: c.waxSheen(variant),
            shadow: c.shadow,
            seed: variant!,
            stamp: true,
          );
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(dimension: d, child: CustomPaint(painter: painter)),
    );
  }
}

/// A small wax drop for the bead strand (stats-history.md): one bead per list
/// an item was on, in that list's wax.
class WaxBead extends StatelessWidget {
  const WaxBead({super.key, required this.variant, this.size = 14});

  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SealPainter(
            wax: c.wax(variant),
            sheen: c.waxSheen(variant),
            shadow: c.shadow,
            seed: variant,
            stamp: false,
          ),
        ),
      ),
    );
  }
}

/// An irregular pour, shaded from a top-left sheen, with a raised rim and an
/// embossed "+" (the pewter stamp, ritual/CLAUDE.md).
class _SealPainter extends CustomPainter {
  _SealPainter({
    required this.wax,
    required this.sheen,
    required this.shadow,
    required this.seed,
    required this.stamp,
  });

  final Color wax;
  final Color sheen;
  final Color shadow;
  final int seed;
  final bool stamp;

  Path _pour(Offset center, double r) {
    final rng = math.Random(seed * 7919 + 13);
    final lobes = 5 + rng.nextInt(4);
    final phase = rng.nextDouble() * math.pi * 2;
    final depth = .035 + rng.nextDouble() * .03;
    final path = Path();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * math.pi * 2;
      final wobble = 1 + depth * math.sin(t * lobes + phase) + depth * .5 * math.sin(t * (lobes + 3) - phase);
      final p = center + Offset(math.cos(t), math.sin(t)) * r * wobble;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 * .9;
    final pour = _pour(center, r);

    canvas.drawPath(
      pour.shift(Offset(0, r * .06)),
      Paint()
        ..color = shadow.withValues(alpha: .6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .08),
    );
    canvas.drawPath(
      pour,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.55),
          radius: 1.1,
          colors: [sheen, wax, Color.lerp(wax, shadow, .35)!],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    if (!stamp) return;

    // Raised rim where the stamp pressed in.
    final inner = r * .68;
    canvas.drawCircle(
      center,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .07
        ..shader = SweepGradient(
          colors: [sheen.withValues(alpha: .7), wax, Color.lerp(wax, shadow, .4)!, wax, sheen.withValues(alpha: .7)],
        ).createShader(Rect.fromCircle(center: center, radius: inner)),
    );

    // The "+", debossed: dark lower-right edge, light upper-left edge.
    final arm = r * .42;
    final width = r * .16;
    Path plus(Offset o) => Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + o, width: width, height: arm * 2),
        Radius.circular(width / 2),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + o, width: arm * 2, height: width),
        Radius.circular(width / 2),
      ));
    final edge = r * .035;
    canvas.drawPath(plus(Offset(edge, edge)), Paint()..color = sheen.withValues(alpha: .55));
    canvas.drawPath(plus(Offset(-edge, -edge)), Paint()..color = Color.lerp(wax, shadow, .55)!);
    canvas.drawPath(plus(Offset.zero), Paint()..color = Color.lerp(wax, shadow, .18)!);
  }

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.wax != wax || old.sheen != sheen || old.seed != seed || old.stamp != stamp || old.shadow != shadow;
}

/// Before the ritual: a bare, unwaxed disc with a faint "+" outline.
class _UnsealedPainter extends CustomPainter {
  _UnsealedPainter({required this.outline, required this.ground, required this.filled});

  final Color outline;
  final Color ground;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 * .86;
    if (filled) canvas.drawCircle(center, r, Paint()..color = ground);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * .06)
      ..color = outline;
    // Dashed ring.
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      final start = i / dashes * math.pi * 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, math.pi / dashes, false, stroke);
    }
    final arm = r * .38;
    canvas.drawLine(center - Offset(0, arm), center + Offset(0, arm), stroke..strokeCap = StrokeCap.round);
    canvas.drawLine(center - Offset(arm, 0), center + Offset(arm, 0), stroke);
  }

  @override
  bool shouldRepaint(_UnsealedPainter old) => old.outline != outline || old.ground != ground || old.filled != filled;
}
