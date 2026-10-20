import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../hooks/use_elapsed.dart';
import '../hooks/use_reduce_motion.dart';
import '../theme/pp_theme.dart';

/// The decaying ring shared by the pray FAB and the list invitation
/// (prayer-flow.md: "same visual language"). From [startedAt] the ring decays
/// over [duration] (the 5 s minimum); then [complete] appears and the button
/// becomes tappable. Before that, taps do nothing.
///
/// With no [startedAt] it is a plain round button showing [child].
/// Reduced motion: the ring steps once a second instead of sweeping.
class RingButton extends HookWidget {
  const RingButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.startedAt,
    this.duration = const Duration(seconds: 5),
    this.complete,
    this.onPressed,
    this.size,
    this.clock = DateTime.now,
  });

  final Widget child;
  final Widget? complete;
  final String semanticLabel;
  final DateTime? startedAt;
  final Duration duration;
  final VoidCallback? onPressed;
  final double? size;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final elapsed = useElapsed(startedAt, smooth: !reduceMotion, until: duration, clock: clock);
    final d = size ?? pp.size.fab;
    final running = startedAt != null;
    final progress = running
        ? (reduceMotion ? elapsed.inSeconds / duration.inSeconds : elapsed.inMicroseconds / duration.inMicroseconds)
            .clamp(0.0, 1.0)
        : 1.0;
    final done = !running || progress >= 1;
    final enabled = done && onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: d,
        child: CustomPaint(
          painter: _RingPainter(
            remaining: running ? 1 - progress : 0,
            track: pp.colors.hairline,
            ring: pp.colors.ember,
          ),
          child: Padding(
            padding: EdgeInsets.all(d * .09),
            child: Material(
              color: done ? pp.colors.ember : pp.colors.surfaceRaised,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : pp.motion.settle,
                    child: KeyedSubtree(
                      key: ValueKey(done && complete != null),
                      child: IconTheme.merge(
                        data: IconThemeData(color: done ? pp.colors.onEmber : pp.colors.ember),
                        child: DefaultTextStyle.merge(
                          style: context.text.labelLarge!.copyWith(
                            color: done ? pp.colors.onEmber : pp.colors.ember,
                          ),
                          child: done && complete != null ? complete! : child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.remaining, required this.track, required this.ring});

  /// 1 → full ring, 0 → gone.
  final double remaining;
  final Color track;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    if (remaining <= 0) return;
    final stroke = size.shortestSide * .045;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * remaining, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ring);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.remaining != remaining || old.ring != ring || old.track != track;
}
