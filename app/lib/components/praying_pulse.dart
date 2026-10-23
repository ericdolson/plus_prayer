import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../hooks/use_reduce_motion.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// The POC's in-prayer mark (InPrayerPrayingHandsAnimation2): praying hands
/// inside a breathing ring, with two fills swelling out and fading, one after
/// the other, every five seconds. Shown in the header while praying.
/// Decorative; the prayer bar says it in words.
///
/// Reduced motion: the hands and the ring, still.
class PrayingPulse extends HookWidget {
  const PrayingPulse({super.key, this.size = 44, this.color});

  final double size;
  final Color? color;

  static const _cycle = Duration(seconds: 5);

  static final _swell1 = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 60),
    TweenSequenceItem(tween: ConstantTween(1), weight: 20),
  ]);
  static final _fade1 = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 60),
    TweenSequenceItem(tween: ConstantTween(0), weight: 20),
  ]);
  static final _swell2 = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 40),
  ]);
  static final _fade2 = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
  ]);
  static final _breathe = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .7, end: .85), weight: 50),
    TweenSequenceItem(tween: Tween(begin: .85, end: .7), weight: 50),
  ]);

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pp.colors.primary;
    final reduceMotion = useReduceMotion();
    final controller = useAnimationController(duration: _cycle);
    useEffect(() {
      reduceMotion ? controller.stop() : controller.repeat();
      return null;
    }, [reduceMotion]);
    final t = useAnimation(controller);
    final eased = Curves.easeInOut.transform(t);

    Widget fill(double scale, double opacity) => Container(
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: opacity)),
        );

    final ring = size * (reduceMotion ? .8 : _breathe.transform(t));
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.withValues(alpha: .3)),
              ),
            ),
            if (!reduceMotion) ...[
              fill(_swell1.transform(eased), _fade1.transform(eased)),
              fill(_swell2.transform(eased), _fade2.transform(eased)),
            ],
            Icon(
              PPIcons.prayingHands,
              size: size / 2,
              color: c,
              shadows: [Shadow(color: c.withValues(alpha: .5), blurRadius: 10)],
            ),
          ],
        ),
      ),
    );
  }
}
