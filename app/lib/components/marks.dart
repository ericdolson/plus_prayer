// Marks of presence (design-direction.md §5, §7). Rows mark presence, never
// absence: gold means held. A held avatar wears a gold ring, a held intention
// a gold dot, both until local midnight; in prayer they appear live as rows
// are checked. Crisp gold in both themes — no static glow; checking one gives
// a brief bloom (dark mode) that settles into the crisp mark. Decorative: rows
// say it in words.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../domain/rules/selection.dart';
import '../hooks/use_bloom.dart';
import '../hooks/use_reduce_motion.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// The held mark around a name's avatar — or, with [borderRadius], around
/// the community card: 2 pt crisp gold, 2 pt gap, always solid (holding is
/// whole, however you prayed; partial is only the prayer-mode check). Drawn
/// outside the child's bounds, so it never shifts layout. Fades in and out,
/// and blooms briefly when it turns on — the same for a name and the card.
class HeldRing extends HookWidget {
  const HeldRing({super.key, required this.held, required this.child, this.borderRadius});

  final bool held;
  final Widget child;

  /// The child's corners; null for a round child (an avatar).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final reduceMotion = useReduceMotion();
    final ring = pp.size.heldRing;
    final outset = ring + pp.size.heldRingGap;
    final bloom = useBloom(held, pp.motion.bloom);
    final glow = c.heldGlow;
    final radius = borderRadius;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Under the child, so the bloom can't wash over it.
        Positioned(
          left: -outset,
          top: -outset,
          right: -outset,
          bottom: -outset,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: held ? 1 : 0,
              duration: reduceMotion ? pp.motion.quick : pp.motion.settle,
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
                  // Concentric with the child's corners.
                  borderRadius: radius?.add(BorderRadius.circular(outset)),
                  border: Border.all(color: c.heldGold, width: ring),
                  boxShadow: glow == null || bloom == 0
                      ? null
                      : [BoxShadow(color: glow.withValues(alpha: glow.a * bloom), blurRadius: pp.space.lg)],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The small gold dot where the thread meets a held intention. Holds its
/// space when not shown. Crisp; blooms briefly when it turns on.
class HeldDot extends HookWidget {
  const HeldDot({super.key, required this.held});

  final bool held;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final reduceMotion = useReduceMotion();
    final d = pp.size.heldDot;
    final bloom = useBloom(held, pp.motion.bloom);
    final glow = c.heldGlow;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: held ? 1 : 0,
        duration: reduceMotion ? pp.motion.quick : pp.motion.settle,
        curve: Curves.easeOut,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.heldGold,
            boxShadow: glow == null || bloom == 0
                ? null
                : [BoxShadow(color: glow.withValues(alpha: glow.a * bloom), blurRadius: d * 1.6, spreadRadius: d * .2)],
          ),
        ),
      ),
    );
  }
}

/// The row's trailing slot: empty in nav mode; in prayer a check fades in.
/// Unchecked = a neutral circle; held = gold with a check, sprung in (the one
/// spring in the app, design-direction.md §8); partial (a name with only some
/// of its intentions held) = a gold circle with a dash.
class PrayerCheck extends HookWidget {
  const PrayerCheck({super.key, required this.inPrayer, required this.state});

  final bool inPrayer;
  final HoldState state;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final reduceMotion = useReduceMotion();
    final d = pp.size.check;

    final Widget mark = switch (state) {
      HoldState.none => Container(
          key: const ValueKey('none'),
          width: d,
          height: d,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.inkMuted)),
        ),
      HoldState.partial => Container(
          key: const ValueKey('partial'),
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.heldGold, width: 1.5)),
          child: Container(width: d * .4, height: 1.5, color: c.heldGold),
        ),
      HoldState.held => Container(
          key: const ValueKey('held'),
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.heldGold),
          child: Icon(PPIcons.check, size: d * .62, color: c.onHeld),
        ),
    };

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: d,
        child: AnimatedOpacity(
          opacity: inPrayer ? 1 : 0,
          duration: reduceMotion ? pp.motion.quick : pp.motion.settle,
          child: AnimatedSwitcher(
            duration: reduceMotion ? pp.motion.quick : pp.motion.spring,
            reverseDuration: pp.motion.quick,
            switchInCurve: reduceMotion ? Curves.easeOut : Curves.easeOutBack,
            transitionBuilder: (child, animation) => reduceMotion || child.key != const ValueKey('held')
                ? FadeTransition(opacity: animation, child: child)
                : ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
            child: mark,
          ),
        ),
      ),
    );
  }
}
