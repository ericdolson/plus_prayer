// Home header (design-direction.md §4): left = your avatar (→ You) with the
// streak badge; right = filter only (search is in the floating bar). The bar
// is frosted: the list scrolls beneath it. In prayer the nav side steps away
// for the POC's pulsing praying hands.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/frosted.dart';
import '../../components/monogram_avatar.dart';
import '../../components/praying_pulse.dart';
import '../../components/streak_badge.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/home_filter.dart';
import '../../domain/rules/streak.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../you/you_sheet.dart';

class HomeHeader extends HookConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final query = ref.watch(homeQueryProvider);
    final queryCtl = ref.read(homeQueryProvider.notifier);
    final inPrayer = ref.watch(prayerSessionProvider.select((s) => s.isActive));
    final showFilters = useState(false);
    final reduceMotion = useReduceMotion();
    final duration = reduceMotion ? Duration.zero : pp.motion.settle;

    final bar = Row(
      children: [
        AnimatedSwitcher(
          duration: duration,
          child: inPrayer
              ? Padding(
                  key: const ValueKey('praying'),
                  padding: EdgeInsetsDirectional.only(start: pp.space.xs),
                  child: PrayingPulse(size: pp.size.avatar, color: pp.colors.inkMuted),
                )
              : const _SelfAndStreak(key: ValueKey('self')),
        ),
        const Spacer(),
        IconButton(
          tooltip: l10n.filter,
          iconSize: pp.size.headerIcon,
          isSelected: query.filter != HomeFilter.all,
          style: IconButton.styleFrom(
            backgroundColor: query.filter != HomeFilter.all ? pp.colors.surface : null,
          ),
          icon: const Icon(PPIcons.filter),
          onPressed: () => showFilters.value = !showFilters.value,
        ),
      ],
    );

    return Frosted(
      color: pp.colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(pp.space.md, pp.space.xs, pp.space.sm, pp.space.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              bar,
              AnimatedSize(
                duration: duration,
                alignment: AlignmentDirectional.topStart,
                child: showFilters.value || query.filter != HomeFilter.all
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(top: pp.space.xs, start: pp.space.sm),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Wrap(
                            spacing: pp.space.sm,
                            children: [
                              for (final f in HomeFilter.values)
                                ChoiceChip(
                                  label: Text(_filterLabel(l10n, f)),
                                  selected: query.filter == f,
                                  showCheckmark: false,
                                  onSelected: (_) => queryCtl.setFilter(f),
                                ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _filterLabel(L10n l10n, HomeFilter f) => switch (f) {
        HomeFilter.all => l10n.filterAll,
        HomeFilter.unprayedToday => l10n.filterUnprayed,
        HomeFilter.carried => l10n.filterCarried,
      };
}

class _SelfAndStreak extends ConsumerWidget {
  const _SelfAndStreak({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final header = ref.watch(headerProvider).value;
    final self = ref.watch(subjectTreeProvider).value?.self;
    final today = ref.watch(todayProvider);
    if (header == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: L10n.of(context).you,
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showYouSheet(context),
            // A 32 pt avatar in a 44 pt target.
            child: Padding(
              padding: EdgeInsets.all(pp.space.xs + pp.space.xxs),
              child: MonogramAvatar(
                initials: self == null ? '' : monogramOf(self),
                tone: self == null ? 0 : avatarToneOf(self),
                size: pp.size.headerAvatar,
              ),
            ),
          ),
        ),
        StreakBadge(
          state: streakBadgeState(header, today),
          days: effectiveStreak(header, today),
          todayVariant: today.weekdayFromSunday,
          // Build step 5: the streak sheet.
          onTap: () {},
        ),
      ],
    );
  }
}
