import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../hooks/use_reduce_motion.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';
import 'frosted.dart';

/// One row of a [FrostedMenu]; [selected] gets the check. [trailing] sits at
/// the row's end (a count); [trailingSpoken] is what screen readers hear for
/// it.
class FrostedMenuItem {
  const FrostedMenuItem({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.trailing,
    this.trailingSpoken,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final Widget? trailing;
  final String? trailingSpoken;
}

/// A pull-down menu on the app's frosted glass (design-direction.md §4): the
/// iOS menu's shape and motion in the app's tint, where the system menu is a
/// fixed gray. Anchored below [builder]'s widget, its edge lined up with the
/// anchor's nearer side; opens with a quick scale and fade from there (a
/// fade alone with Reduce Motion). The check sits leading, as on iOS.
///
/// Screen readers get a menu: announced as one, named [semanticLabel], each
/// row a radio item ("selected" on the checked one). Focus moves in on open
/// (to the checked row); tapping outside, the escape gesture (VoiceOver's
/// two-finger scrub) and scrolling what's beneath dismiss it.
class FrostedMenu extends HookWidget {
  const FrostedMenu({super.key, required this.items, required this.semanticLabel, required this.builder});

  final List<FrostedMenuItem> items;
  final String semanticLabel;
  final Widget Function(BuildContext context, MenuController menu) builder;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final menu = useMemoized(MenuController.new);
    final reduceMotion = useReduceMotion();
    final anim = useAnimationController(duration: pp.motion.quick);

    return RawMenuAnchor(
      controller: menu,
      onOpenRequested: (_, show) {
        show();
        anim.forward();
      },
      onCloseRequested: (hide) => anim.reverse().whenCompleteOrCancel(hide),
      builder: (context, menu, _) => builder(context, menu),
      overlayBuilder: (context, info) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Line up with the anchor's nearer side of the screen.
        final fromEnd = info.anchorRect.center.dx > info.overlaySize.width / 2;
        final origin = Alignment(fromEnd ? 1 : -1, -1);
        final inset = pp.space.sm;
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
        return Positioned(
          top: info.anchorRect.bottom + pp.space.xs,
          left: fromEnd ? null : info.anchorRect.left.clamp(inset, double.infinity),
          right: fromEnd ? (info.overlaySize.width - info.anchorRect.right).clamp(inset, double.infinity) : null,
          child: Semantics(
            role: SemanticsRole.menu,
            // A new scope with a name: VoiceOver and TalkBack move into it.
            scopesRoute: true,
            namesRoute: true,
            label: semanticLabel,
            explicitChildNodes: true,
            onDismiss: menu.close,
            child: TapRegion(
              groupId: info.tapRegionGroupId,
              onTapOutside: (_) => menu.close(),
              // No FadeTransition: a blur inside an opacity layer has nothing
              // to blur, so it would pop in at full opacity. The panel fades
              // its own blur, tint and rows instead.
              child: ScaleTransition(
                scale: reduceMotion ? const AlwaysStoppedAnimation(1) : Tween(begin: .85, end: 1.0).animate(curved),
                alignment: rtl ? Alignment(-origin.x, origin.y) : origin,
                child: AnimatedBuilder(
                  animation: curved,
                  builder: (context, _) => _Panel(
                    t: curved.value,
                    items: [
                      for (final item in items)
                        _Row(
                          item: item,
                          onPressed: () {
                            item.onPressed();
                            menu.close();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.t, required this.items});

  /// How far in (0 = hidden, 1 = shown): scales the blur, tint, edge, shadow
  /// and the rows' opacity together.
  final double t;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final radius = BorderRadius.circular(pp.size.radiusMd);
    final shadow = pp.bars.menuShadow;
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadow.color.withValues(alpha: shadow.color.a * t),
            blurRadius: shadow.blurRadius,
            offset: shadow.offset,
          ),
        ],
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: c.hairline.withValues(alpha: t), width: .5),
        ),
        child: Frosted(
          color: c.menu,
          tint: pp.bars.menuTint * t,
          blur: pp.bars.menuBlur * t,
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: pp.size.menuWidth,
              // Inside the blur, so this opacity doesn't hide what it blurs.
              // The rows stay in the semantics tree while fading (a menu
              // can't be empty).
              child: Opacity(
                opacity: t,
                alwaysIncludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, row) in items.indexed) ...[
                      if (i > 0) Divider(height: .5, thickness: .5, color: c.hairline),
                      row,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Without blur (Android, low-end) the fill is opaque: fading the whole
    // panel is safe there.
    return Frosted.blurs ? panel : Opacity(opacity: t, alwaysIncludeSemantics: true, child: panel);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onPressed});

  final FrostedMenuItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Semantics(
      role: SemanticsRole.menuItemRadio,
      inMutuallyExclusiveGroup: true,
      checked: item.selected,
      label: [item.label, if (item.trailingSpoken case final spoken?) spoken].join(', '),
      onTap: onPressed,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        // Focus moves in, onto the checked row.
        autofocus: item.selected,
        highlightColor: pp.colors.ink.withValues(alpha: pp.bars.pressed),
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: pp.size.menuRow),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.md, vertical: pp.space.sm),
            child: Row(
              children: [
                // Every row keeps the check's space, so the labels line up.
                Opacity(
                  opacity: item.selected ? 1 : 0,
                  child: Icon(PPIcons.check, size: pp.size.rowIcon, color: pp.colors.ink),
                ),
                SizedBox(width: pp.space.sm),
                Expanded(child: Text(item.label, style: context.text.bodyLarge)),
                if (item.trailing case final trailing?) ...[SizedBox(width: pp.space.sm), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
