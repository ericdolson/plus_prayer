// Footer (screens.md): [ History ]  ( 🙏 )  [ ＋ Add ].
// In prayer it becomes the prayer bar, in place:
//   [ timer ]  ( Amen )  [ with N · ✕ ]
// The FAB carries the decaying 5 s ring, then becomes Amen; before that only
// ✕ exits (nothing logged).

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
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

class HomeFooter extends HookConsumerWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final config = ref.watch(configProvider);
    final clock = ref.watch(clockProvider);
    final notifier = ref.read(prayerSessionProvider.notifier);
    final reduceMotion = useReduceMotion();
    final inPrayer = session.phase == PrayerPhase.praying || session.phase == PrayerPhase.invitation;
    final duration = reduceMotion ? Duration.zero : pp.motion.settle;

    final Widget start;
    final Widget end;
    if (inPrayer) {
      start = _PrayerTimer(key: const ValueKey('timer'), startedAt: session.startedAt, clock: clock);
      end = const _WithOthersAndClose(key: ValueKey('with'));
    } else {
      start = TextButton.icon(
        key: const ValueKey('history'),
        onPressed: () => context.push(Routes.history),
        icon: const Icon(Icons.history_rounded),
        label: Text(l10n.history),
      );
      end = TextButton.icon(
        key: const ValueKey('add'),
        onPressed: () => showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
      );
    }

    return Material(
      color: pp.colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.sm, vertical: pp.space.sm),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  heightFactor: 1,
                  child: AnimatedSwitcher(duration: duration, child: start),
                ),
              ),
              RingButton(
                // A fresh ring per prayer.
                key: ValueKey(session.prayerId),
                startedAt: inPrayer ? session.startedAt : null,
                duration: config.minPrayer,
                clock: clock,
                semanticLabel: inPrayer ? l10n.amen : l10n.pray,
                onPressed: inPrayer ? notifier.amen : () => notifier.start(),
                complete: inPrayer ? Text(l10n.amen) : null,
                child: Icon(PPIcons.prayingHands, size: pp.size.fab * .4),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: AnimatedSwitcher(duration: duration, child: end),
                ),
              ),
            ],
          ),
        ),
      ),
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
        child: Text(text, style: context.text.labelSmall?.copyWith(color: context.pp.colors.ember)),
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
          icon: Icon(Icons.close_rounded, color: pp.colors.inkMuted),
          onPressed: () => ref.read(prayerSessionProvider.notifier).cancel(),
        ),
      ],
    );
  }
}
