// pubspec.yaml dependency:
//   screen_corner_radius: ^3.0.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

// ---------------------------------------------------------------------------
// SiriHalo widget
// ---------------------------------------------------------------------------

/// Wraps [child] with an animated amber "halo" border that follows the
/// physical corner radius of the device screen — just like the iOS Siri glow.
///
/// [active]    — show/animate the halo
/// [glowWidth] — depth of the inward fade in logical pixels
/// [color]     — halo color (defaults to Colors.amber)
///
/// Corner radius is fetched once via the screen_corner_radius package.
/// Falls back to [fallbackCornerRadius] on unsupported platforms / older OS.
class SiriHalo extends StatefulWidget {
  final Widget child;
  final bool active;
  final double glowWidth;
  final Color color;

  /// Fallback used while the radius is loading, or on unsupported platforms.
  /// 44 px matches most modern iPhones.
  final double fallbackCornerRadius;

  const SiriHalo({
    super.key,
    required this.child,
    this.active = true,
    this.glowWidth = 6.0,
    this.color = Colors.blueAccent,
    this.fallbackCornerRadius = 44.0,
  });

  @override
  State<SiriHalo> createState() => _SiriHaloState();
}

class _SiriHaloState extends State<SiriHalo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;
  double? _cornerRadius;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.active) _controller.repeat(reverse: true);

    _fetchCornerRadius();
  }

  Future<void> _fetchCornerRadius() async {
    final ScreenRadius? screenRadius = await ScreenCornerRadius.get();
    print('radius $screenRadius');
    if (!mounted || screenRadius == null) return;

    // Use the top-left corner as the representative screen radius.
    // All four corners are typically the same on real devices.
    setState(() => _cornerRadius = screenRadius.topLeft);
  }

  @override
  void didUpdateWidget(SiriHalo old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cornerRadius = _cornerRadius ?? widget.fallbackCornerRadius;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _HaloPainter(
            color: widget.color,
            glowWidth: widget.glowWidth,
            cornerRadius: cornerRadius,
            opacity: widget.active ? _pulse.value : 0.0,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _HaloPainter extends CustomPainter {
  final Color color;
  final double glowWidth;
  final double cornerRadius;
  final double opacity;

  _HaloPainter({
    required this.color,
    required this.glowWidth,
    required this.cornerRadius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final rect = Offset.zero & size;

    // Crisp outer edge — sits exactly on the screen boundary.
    final outerRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius),
    );

    // Paint 8 concentric strokes from outside -> inside.
    // Opacity and blur both decrease inward, creating the fade effect.
    const int layers = 8;
    for (int i = 0; i < layers; i++) {
      final double t = i / (layers - 1); // 0 = outermost, 1 = innermost
      final double shrink = glowWidth * t;
      final double layerOpacity = (1.0 - t) * opacity;

      final innerRRect = RRect.fromRectAndRadius(
        rect.deflate(shrink),
        Radius.circular(math.max(0, cornerRadius - shrink)),
      );

      canvas.drawRRect(
        innerRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (glowWidth / layers) * 2
          ..color = color.withOpacity(layerOpacity.clamp(0.0, 1.0))
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            // Softer blur on outer layers, sharper toward the inside.
            (1.0 - t) * 6.0 + 1.0,
          ),
      );
    }

    // Thin crisp neon line right on the screen edge.
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withOpacity(opacity.clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.opacity != opacity ||
          old.color != color ||
          old.glowWidth != glowWidth ||
          old.cornerRadius != cornerRadius;
}
