import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

import '../hooks/use_reduce_motion.dart';
import '../theme/pp_theme.dart';

/// The screen-edge glow that makes prayer mode unmistakable (prayer-flow.md).
/// Ported from the POC's SiriHalo: concentric blurred strokes following the
/// device's physical corner radius (screen_corner_radius), breathing slowly.
/// Ember instead of blue (the oil lamp, not a UI accent).
///
/// Reduced motion: no breathing; the halo simply appears.
class Halo extends HookWidget {
  const Halo({super.key, required this.active, required this.child, this.glowWidth = 10});

  final bool active;
  final Widget child;
  final double glowWidth;

  /// Most modern iPhones; used until (or unless) the real radius is known.
  static const fallbackCornerRadius = 44.0;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final cornerRadius = useState<double?>(null);
    useEffect(() {
      var mounted = true;
      ScreenCornerRadius.get().then((r) {
        if (mounted && r != null && r.topLeft > 0) cornerRadius.value = r.topLeft;
      }).catchError((_) {});
      return () => mounted = false;
    }, const []);

    final presence = useAnimationController(duration: pp.motion.calm);
    final breath = useAnimationController(duration: pp.motion.haloBreath);
    useEffect(() {
      if (active) {
        reduceMotion ? presence.value = 1 : presence.forward();
        if (!reduceMotion) breath.repeat(reverse: true);
      } else {
        breath.stop();
        reduceMotion ? presence.value = 0 : presence.reverse();
      }
      return null;
    }, [active, reduceMotion]);

    final pulse = useAnimation(breath);
    final shown = useAnimation(CurvedAnimation(parent: presence, curve: Curves.easeInOut));
    final opacity = shown * (reduceMotion ? .85 : .6 + .4 * Curves.easeInOut.transform(pulse));

    return CustomPaint(
      foregroundPainter: _HaloPainter(
        color: pp.colors.halo,
        glowWidth: glowWidth,
        cornerRadius: cornerRadius.value ?? fallbackCornerRadius,
        opacity: opacity,
      ),
      child: child,
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.color, required this.glowWidth, required this.cornerRadius, required this.opacity});

  final Color color;
  final double glowWidth;
  final double cornerRadius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final rect = Offset.zero & size;

    // Concentric strokes, outside → in; opacity and blur fall off inward.
    const layers = 8;
    for (var i = 0; i < layers; i++) {
      final t = i / (layers - 1);
      final shrink = glowWidth * t;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(shrink), Radius.circular(math.max(0, cornerRadius - shrink))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth / layers * 2
          ..color = color.withValues(alpha: ((1 - t) * opacity * .8).clamp(0, 1))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (1 - t) * 6 + 1),
      );
    }
    // A fine line on the edge itself.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.withValues(alpha: opacity.clamp(0, 1)),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.opacity != opacity || old.color != color || old.glowWidth != glowWidth || old.cornerRadius != cornerRadius;
}
