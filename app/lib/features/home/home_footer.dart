// Footer (screens.md): [ History ]  ( 🙏 )  [ ＋ Add ].
// In prayer it becomes the prayer bar, in place:
//   [ timer ]  ( Amen )  [ with N · ✕ ]
// Styled after the POC: a frosted bar with rounded top corners and a soft
// notch that holds the blue pray button (HomePrayButton, docked by the Scaffold).
// The button carries the decaying 5 s ring, then becomes Amen; before that
// only ✕ exits (nothing logged).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/frosted.dart';
import '../../components/notched_footer_shape.dart';
import '../../components/ring_button.dart';
import '../../domain/rules/presence.dart';
import '../../hooks/use_elapsed.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../add/add_sheet.dart';

String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

bool _inPrayer(PrayerSessionState s) => s.phase == PrayerPhase.praying || s.phase == PrayerPhase.invitation;

/// The bar. Use with `Scaffold(extendBody: true)` and [HomePrayButton] at
/// `FloatingActionButtonLocation.centerDocked`.
class HomeFooter extends HookConsumerWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final clock = ref.watch(clockProvider);
    final reduceMotion = useReduceMotion();
    final inPrayer = _inPrayer(session);
    final duration = reduceMotion ? Duration.zero : pp.motion.settle;

    final Widget start;
    final Widget end;
    if (inPrayer) {
      start = _PrayerTimer(key: const ValueKey('timer'), startedAt: session.startedAt, clock: clock);
      end = const _WithOthersAndClose(key: ValueKey('with'));
    } else {
      start = _FooterIcon(
        key: const ValueKey('history'),
        icon: PPIcons.history,
        label: l10n.history,
        onPressed: () => context.push(Routes.history),
      );
      end = _FooterIcon(
        key: const ValueKey('add'),
        icon: PPIcons.add,
        label: l10n.add,
        onPressed: () => showAddSheet(context),
      );
    }

    final shape = NotchedFooterShape(cornerRadius: pp.size.radiusFooter);
    // Frosted, shaped like the bar: the list shows through beneath it.
    return Frosted(
      color: pp.colors.surface,
      clipper: _FooterClipper(
        geometry: Scaffold.geometryOf(context),
        shape: shape,
        notchMargin: pp.size.notchMargin,
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        shape: shape,
        notchMargin: pp.size.notchMargin,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.center,
                child: AnimatedSwitcher(duration: duration, child: start),
              ),
            ),
            SizedBox(width: pp.size.fab + pp.size.notchMargin * 2),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.center,
                child: AnimatedSwitcher(duration: duration, child: end),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The footer's outline, notch included (as BottomAppBar clips itself).
class _FooterClipper extends CustomClipper<Path> {
  _FooterClipper({required this.geometry, required this.shape, required this.notchMargin}) : super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final double notchMargin;

  @override
  Path getClip(Size size) {
    final g = geometry.value;
    final button = g.floatingActionButtonArea?.translate(0, -(g.bottomNavigationBarTop ?? 0));
    return shape.getOuterPath(Offset.zero & size, button?.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_FooterClipper old) =>
      old.geometry != geometry || old.shape != shape || old.notchMargin != notchMargin;
}

/// The blue pray button docked in the footer's notch; Amen in prayer.
class HomePrayButton extends ConsumerWidget {
  const HomePrayButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final config = ref.watch(configProvider);
    final clock = ref.watch(clockProvider);
    final notifier = ref.read(prayerSessionProvider.notifier);
    final inPrayer = _inPrayer(session);

    return RingButton(
      // A fresh ring per prayer.
      key: ValueKey(session.prayerId),
      startedAt: inPrayer ? session.startedAt : null,
      duration: config.minPrayer,
      clock: clock,
      semanticLabel: inPrayer ? l10n.amen : l10n.pray,
      onPressed: inPrayer
          ? notifier.amen
          : () {
              HapticFeedback.lightImpact();
              notifier.start();
            },
      complete: inPrayer ? Text(l10n.amen) : null,
      child: Icon(PPIcons.prayingHands, size: pp.size.fab * .33),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      iconSize: pp.size.footerIcon,
      color: pp.colors.ink,
      icon: Icon(icon),
    );
  }
}

class _PrayerTimer extends HookWidget {
  const _PrayerTimer({super.key, required this.startedAt, required this.clock});

  final DateTime? startedAt;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final elapsed = useElapsed(startedAt, clock: clock);
    final text = formatElapsed(elapsed);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: context.pp.space.md),
      child: Semantics(
        label: L10n.of(context).timeInPrayer(text),
        excludeSemantics: true,
        child: Text(text, style: context.text.labelSmall),
      ),
    );
  }
}

class _WithOthersAndClose extends ConsumerWidget {
  const _WithOthersAndClose({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final stats = ref.watch(liveStatsProvider).value;
    final threshold = ref.watch(configProvider).presenceDisplayThreshold;
    final others = stats == null ? null : othersInPrayer(stats, threshold);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (others != null)
          Flexible(
            child: Text(
              l10n.prayingWith(others),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
          ),
        IconButton(
          tooltip: l10n.discardPrayer,
          icon: Icon(PPIcons.close, color: pp.colors.inkMuted),
          onPressed: () => ref.read(prayerSessionProvider.notifier).cancel(),
        ),
      ],
    );
  }
}
