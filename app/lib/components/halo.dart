import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

import '../hooks/use_reduce_motion.dart';
import '../theme/pp_theme.dart';

/// What the halo is doing (design-direction.md §7).
enum HaloMode {
  /// Not in prayer: faded out (✕ cancel fades out from [on]).
  off,

  /// In prayer, through the invitation: nearly still, one slow breath.
  on,

  /// An Amen that commits the prayer (the bar's, the invitation's, or
  /// welcome-back's): the flare, then the fade-out (the fade waits for it).
  amen,
}

/// The screen-edge glow that makes prayer mode unmistakable (prayer-flow.md).
/// Concentric blurred strokes following the device's physical corner radius
/// (screen_corner_radius). Gold: holding. An edge glow in dark mode; wider and
/// stronger in light mode so it doesn't vanish.
///
/// It frames the session; it is not a second signature motion
/// (design-direction.md §7): ~400 ms fades in and out, nearly still at rest,
/// and at a committing Amen one ~500 ms flare (brighter and ~1.3× the reach:
/// a fast ease-out rise, a slower ease-in-out settle) before the fade. At rest the visible glow stays within ~12 pt of the edge.
/// Reduce Motion: static at ~0.75, no flare; enter and exit stay plain fades.
class Halo extends HookWidget {
  const Halo({super.key, required this.mode, required this.child, this.glowWidth = defaultGlowWidth});

  final HaloMode mode;
  final Widget child;
  final double glowWidth;

  static const defaultGlowWidth = 6.0;

  /// Light mode widens the glow so it doesn't vanish on the pale ground.
  static const lightWidthScale = 1.2;

  /// Most modern iPhones; used until (or unless) the real radius is known.
  static const fallbackCornerRadius = 44.0;

  /// The breath's range at rest.
  static const restLow = .65;
  static const restHigh = .85;

  /// Reduce Motion's static level: mid-breath.
  static const restStill = .75;

  /// The flare's peak opacity and reach (× the resting reach).
  static const flarePeak = 1.0;
  static const flareReach = 1.3;

  /// How far the resting glow reaches in from the screen edge, in logical
  /// points. Kept ≤ ~12 so the corners behind the pill and Amen stay clean.
  @visibleForTesting
  static double inwardReach(double glowWidth) => _HaloPainter.inwardReach(glowWidth);

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

    // Enter and exit fade in every mode, Reduce Motion included.
    final presence = useAnimationController(duration: pp.motion.haloFade);
    final breath = useAnimationController(duration: pp.motion.haloBreath);
    final flare = useAnimationController(duration: pp.motion.haloFlare);
    final previous = useRef(HaloMode.off);
    useEffect(() {
      final from = previous.value;
      previous.value = mode;
      Timer? delay;
      var current = true;

      void fadeOut() {
        if (!current) return;
        breath.stop();
        presence.reverse();
      }

      switch (mode) {
        case HaloMode.on:
          flare.reset();
          presence.forward();
          reduceMotion ? breath.stop() : breath.repeat(reverse: true);
        case HaloMode.off:
          flare.reset();
          fadeOut();
        case HaloMode.amen:
          if (from != HaloMode.on || reduceMotion) {
            flare.reset();
            fadeOut();
            break;
          }
          void play() {
            if (!current) return;
            flare.forward(from: 0).whenCompleteOrCancel(fadeOut);
          }
          final offset = pp.motion.haloFlareOffset;
          offset == Duration.zero ? play() : delay = Timer(offset, play);
      }
      return () {
        current = false;
        delay?.cancel();
      };
    }, [mode, reduceMotion]);

    final light = pp.colors.brightness == Brightness.light;

    // The glow is its own layer, painted once: breathing only changes that
    // layer's opacity, so neither the glow nor the screen beneath it
    // repaints while you scroll in prayer. Only the brief flare repaints it.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: _HaloLayer(
              presence: presence,
              breath: breath,
              flare: flare,
              flareRise: pp.motion.haloFlareRise.inMicroseconds / pp.motion.haloFlare.inMicroseconds,
              reduceMotion: reduceMotion,
              color: pp.colors.halo,
              glowWidth: light ? glowWidth * lightWidthScale : glowWidth,
              strength: light ? .9 : .8,
              cornerRadius: cornerRadius.value ?? fallbackCornerRadius,
            ),
          ),
        ),
      ],
    );
  }
}

class _HaloLayer extends HookWidget {
  const _HaloLayer({
    required this.presence,
    required this.breath,
    required this.flare,
    required this.flareRise,
    required this.reduceMotion,
    required this.color,
    required this.glowWidth,
    required this.strength,
    required this.cornerRadius,
  });

  final AnimationController presence;
  final AnimationController breath;
  final AnimationController flare;

  /// The rise's share of the flare (0–1); the settle takes the rest.
  final double flareRise;
  final bool reduceMotion;
  final Color color;
  final double glowWidth;
  final double strength;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final pulse = useAnimation(breath);
    final flaring = useAnimation(flare);
    final shown = useAnimation(CurvedAnimation(parent: presence, curve: Curves.easeInOut));
    final rest = reduceMotion
        ? Halo.restStill
        : lerpDouble(Halo.restLow, Halo.restHigh, Curves.easeInOut.transform(pulse))!;
    // Brighten and widen fast (ease-out), then settle more slowly
    // (ease-in-out) back to rest.
    final boost = reduceMotion || flaring == 0 || flaring == 1
        ? 0.0
        : flaring < flareRise
            ? Curves.easeOut.transform(flaring / flareRise)
            : 1 - Curves.easeInOut.transform((flaring - flareRise) / (1 - flareRise));
    final opacity = shown * lerpDouble(rest, Halo.flarePeak, boost)!;
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      // Capped just under 1: a layer that drops out of compositing at 1.0
      // would repaint its parent, the screen. 0.99 reads as full.
      opacity: math.min(opacity, .99),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HaloPainter(
            color: color,
            glowWidth: glowWidth,
            reach: lerpDouble(1, Halo.flareReach, boost)!,
            strength: strength,
            cornerRadius: cornerRadius,
          ),
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.color,
    required this.glowWidth,
    this.reach = 1,
    required this.strength,
    required this.cornerRadius,
  });

  final Color color;
  final double glowWidth;

  /// Scales the whole glow inward (inset, stroke, blur): 1 at rest.
  final double reach;
  final double strength;
  final double cornerRadius;

  static const _layers = 8;
  static double _stroke(double glowWidth) => glowWidth / _layers * 2;
  static double _sigma(double t) => (1 - t) * 2 + 1;

  /// The deepest point any resting layer's blur reaches (≈ 3σ past its
  /// stroke). [reach] scales this linearly.
  static double inwardReach(double glowWidth) {
    var reach = 0.0;
    for (var i = 0; i < _layers; i++) {
      final t = i / (_layers - 1);
      reach = math.max(reach, glowWidth * t + _stroke(glowWidth) / 2 + 3 * _sigma(t));
    }
    return reach;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Concentric strokes, outside → in; opacity and blur fall off inward.
    for (var i = 0; i < _layers; i++) {
      final t = i / (_layers - 1);
      final shrink = glowWidth * reach * t;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(shrink), Radius.circular(math.max(0, cornerRadius - shrink))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke(glowWidth) * reach
          ..color = color.withValues(alpha: (1 - t) * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _sigma(t) * reach),
      );
    }
    // A fine line on the edge itself.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.color != color ||
      old.glowWidth != glowWidth ||
      old.reach != reach ||
      old.strength != strength ||
      old.cornerRadius != cornerRadius;
}
