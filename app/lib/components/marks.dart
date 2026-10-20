// Small marks used on rows (app-brief §4): the unprayed dot, the carried mark,
// the ember glow + check for "holding this one now".

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../domain/rules/selection.dart';
import '../hooks/use_reduce_motion.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// A small dot left of an unprayed avatar (the POC's pink, aged). Keeps its
/// space when hidden so rows don't shift. The row's label says it in words.
class UnprayedDot extends StatelessWidget {
  const UnprayedDot({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final d = pp.size.unprayedDot;
    return ExcludeSemantics(
      child: SizedBox(
        width: d + pp.space.sm,
        child: Center(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : pp.motion.settle,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(shape: BoxShape.circle, color: pp.colors.unprayed),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carried on the next list: the POC's "+ dots" badge on the avatar corner.
/// Soft gold once the user has prayed with the list (it WILL print), muted
/// before.
class CarriedMark extends StatelessWidget {
  const CarriedMark({super.key, required this.confirmed, this.size = 18});

  final bool confirmed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.background),
        alignment: Alignment.center,
        child: Icon(PPIcons.plusDotsList, size: size * .66, color: confirmed ? c.carried : c.inkFaint),
      ),
    );
  }
}

/// Wraps an avatar: a soft ember glow while it's held in prayer. Appears once
/// (with a light haptic, fired by the caller); fading out is silent.
class EmberGlow extends HookWidget {
  const EmberGlow({super.key, required this.state, required this.child, this.size});

  final HoldState state;
  final Widget child;

  /// The avatar's diameter.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final controller = useAnimationController(duration: pp.motion.calm);
    final target = switch (state) {
      HoldState.none => 0.0,
      HoldState.partial => .5,
      HoldState.held => 1.0,
    };
    useEffect(() {
      if (reduceMotion) {
        controller.value = target;
      } else if (target > controller.value) {
        controller.animateTo(target, curve: Curves.easeOutCubic);
      } else {
        controller.animateTo(target, duration: pp.motion.settle);
      }
      return null;
    }, [target, reduceMotion]);
    final t = useAnimation(controller);
    final d = size ?? pp.size.avatar;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (t > 0)
          IgnorePointer(
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pp.colors.emberGlow.withValues(alpha: .55 * t),
                    blurRadius: d * .45 * t,
                    spreadRadius: d * .08 * t,
                  ),
                ],
              ),
            ),
          ),
        child,
        if (t > 0)
          IgnorePointer(
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: pp.colors.ember.withValues(alpha: t), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// The row's trailing affordance: `>` in nav mode, a check in prayer.
class EmberCheck extends StatelessWidget {
  const EmberCheck({super.key, required this.inPrayer, required this.state});

  final bool inPrayer;
  final HoldState state;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final Widget glyph;
    if (!inPrayer) {
      glyph = Icon(Icons.chevron_right_rounded, key: const ValueKey('nav'), color: pp.colors.inkFaint);
    } else {
      glyph = switch (state) {
        HoldState.held => Icon(Icons.check_circle_rounded, key: const ValueKey('held'), color: pp.colors.ember),
        HoldState.partial =>
          Icon(Icons.remove_circle_outline_rounded, key: const ValueKey('partial'), color: pp.colors.ember),
        HoldState.none => Icon(Icons.circle_outlined, key: const ValueKey('none'), color: pp.colors.inkFaint),
      };
    }
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : pp.motion.quick,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: glyph,
      ),
    );
  }
}
