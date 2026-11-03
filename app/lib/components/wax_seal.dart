import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// The day's wax seal — the list row's avatar (list-lifecycle.md): the bloom
/// pressed into wax, one gray stamp tinted to the weekday's wax
/// (`sealVariant` 0 = Sunday … 6 = Saturday), so the colors stay the
/// `PPWax` tokens. Null [variant] = the unsealed state, before the list is
/// published ("being filmed"): the same stamp as a neutral blank in the
/// `unsealed` color with its relief, waiting for wax. (Until the D2 art it
/// shows the stamp's own impression.)
class WaxSeal extends StatelessWidget {
  const WaxSeal({super.key, required this.variant, this.size, this.semanticLabel});

  final int? variant;
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final d = size ?? context.pp.size.seal;
    final v = variant;
    // Dark theme (design-direction.md §6): a lifted body and a thin rim so
    // seals separate from dark surfaces; small seals get no rim.
    final rim = d >= context.pp.size.waxRimMinSize ? c.waxRim(v) : null;
    final Widget seal = v == null
        ? _Stamp(filter: _relief(c.unsealed), size: d)
        : _Stamp(filter: _tint(c.waxLifted(v), c.waxSheen(v)), size: d);
    final w = context.pp.size.waxRim;
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: d,
        child: rim == null
            ? seal
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  // The silhouette in the rim color, a hair larger, behind
                  // the stamp: a thin light along its edges.
                  Positioned(
                    left: -w,
                    top: -w,
                    child: _Stamp(filter: ColorFilter.mode(rim, BlendMode.srcIn), size: d + w * 2),
                  ),
                  seal,
                ],
              ),
      ),
    );
  }
}

/// The same stamp unwaxed, in pewter: the streak badge's seal
/// (design-direction.md §4). Never gold or a wax color: wax belongs to a
/// list, not to the user. Decorative; the badge carries the label.
class PewterSeal extends StatelessWidget {
  const PewterSeal({super.key, required this.size, this.dimmed = false});

  final double size;

  /// One step dimmer: not yet prayed with the list today, or no streak.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: _Stamp(filter: _relief(dimmed ? c.inkFaint : c.inkMuted), size: size),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.filter, required this.size});

  static const _asset = 'assets/img/wax_stamps/wax-neutral.png';

  final ColorFilter filter;
  final double size;

  @override
  Widget build(BuildContext context) => ColorFiltered(
        colorFilter: filter,
        child: Image.asset(
          _asset,
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      );
}

// The gray stamp's tones: its face sits at ~77% gray, its highlights near
// 100%.
const _stampFace = .77;
const _stampHighlight = 1.0;

/// Maps the gray stamp onto a wax: the face → [wax], highlights → [sheen],
/// shadows darker along the same line (clamped at black).
ColorFilter _tint(Color wax, Color sheen) {
  List<double> row(double w, double s) {
    final k = (s - w) / (_stampHighlight - _stampFace);
    final offset = (w - k * _stampFace) * 255;
    return [k / 3, k / 3, k / 3, 0, offset];
  }

  return ColorFilter.matrix([
    ...row(wax.r, sheen.r),
    ...row(wax.g, sheen.g),
    ...row(wax.b, sheen.b),
    0, 0, 0, 1, 0, //
  ]);
}

/// Moves the gray stamp's face onto [tint] and leaves its relief as drawn:
/// every tone keeps its distance from the face, so highlights lift and
/// shadows fall the same way in both themes.
ColorFilter _relief(Color tint) {
  List<double> row(double t) => [1 / 3, 1 / 3, 1 / 3, 0, (t - _stampFace) * 255];

  return ColorFilter.matrix([
    ...row(tint.r),
    ...row(tint.g),
    ...row(tint.b),
    0, 0, 0, 1, 0, //
  ]);
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
            // Lifted in dark like every seal; too small for a rim.
            wax: c.waxLifted(variant),
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
