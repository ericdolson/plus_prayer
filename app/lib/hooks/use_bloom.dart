import 'package:flutter/animation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'use_reduce_motion.dart';

/// The check moment's gold bloom (design-direction.md §8): when [on] turns
/// true after the first build, returns 0 → 1 → 0 over [duration] (a quick
/// swell, a slower settle into the crisp ring). Already-held on first build
/// doesn't bloom, and Reduce Motion never blooms (the mark simply fades in).
double useBloom(bool on, Duration duration) {
  final reduceMotion = useReduceMotion();
  final controller = useAnimationController(duration: duration);
  final previous = useRef(on);
  useEffect(() {
    if (on && !previous.value && !reduceMotion) controller.forward(from: 0);
    if (!on) controller.value = 0;
    previous.value = on;
    return null;
  }, [on]);
  final t = useAnimation(controller);
  if (t == 0 || t == 1) return 0;
  return _swell.transform(t);
}

final _swell = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 65),
]);
