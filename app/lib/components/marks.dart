// Small marks used on rows (app-brief §4): the unprayed dot, the carried mark,
// the ember glow + check for "holding this one now" (app-brief §4 names;
// drawn in the primary blue).

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../domain/rules/selection.dart';
import '../hooks/use_delayed.dart';
import '../hooks/use_reduce_motion.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// The POC's unprayed dot, centered in a gutter-wide column left of the
/// avatar. Scales away when prayed; keeps its column so rows don't shift. The
/// row's label says it in words.
class UnprayedDot extends StatelessWidget {
  const UnprayedDot({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final d = pp.size.unprayedDot;
    return ExcludeSemantics(
      child: SizedBox(
        width: pp.space.gutter,
        child: Center(
          child: AnimatedScale(
            scale: visible ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : pp.motion.quick,
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

/// Wraps an avatar: a soft glow while it's held in prayer. Appears once
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
                    color: pp.colors.primaryGlow.withValues(alpha: .55 * t),
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
                border: Border.all(color: pp.colors.primary.withValues(alpha: t), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// The row's trailing affordance, from the POC: `>` in nav mode; in prayer
/// ⊕ (not held) / ✓ (held) in the primary blue, bouncing in. Rows flip one
/// after another: pass the row's [index] for the POC's 25 ms stagger.
class EmberCheck extends HookWidget {
  const EmberCheck({super.key, required this.inPrayer, required this.state, this.index = 0});

  final bool inPrayer;
  final HoldState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final shown = useDelayed(inPrayer, reduceMotion ? Duration.zero : pp.motion.stagger * index);
    final Widget glyph;
    if (!shown) {
      glyph = Icon(Icons.chevron_right_rounded, key: const ValueKey('nav'), color: pp.colors.inkFaint);
    } else {
      glyph = switch (state) {
        HoldState.held => Icon(Icons.check_circle_rounded, key: const ValueKey('held'), color: pp.colors.primary),
        HoldState.partial =>
          Icon(Icons.remove_circle_outline_rounded, key: const ValueKey('partial'), color: pp.colors.primary),
        HoldState.none =>
          Icon(Icons.add_circle_outline_rounded, key: const ValueKey('none'), color: pp.colors.primary),
      };
    }
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        // Into prayer (and each check) bounces; back to `>` is immediate.
        duration: reduceMotion || !shown ? Duration.zero : pp.motion.bounce,
        reverseDuration: Duration.zero,
        switchInCurve: Curves.elasticOut,
        switchOutCurve: Curves.elasticIn,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: glyph,
      ),
    );
  }
}
