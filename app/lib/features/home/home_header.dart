// Home header (design-direction.md §4): left = your avatar (→ You) with the
// streak badge; right = filter only (search is in the floating bar). No bar:
// the list scrolls beneath and dissolves into the top of the screen (the
// scroll edge); the controls sit on their own glass.
//
//   Normal:     [avatar][streak] …… [filter] or [Still to hold ×]
//   In prayer:  [Cancel]         …… [filter] or [Still to hold ×]
//
// The filter icon opens a small pull-down menu anchored to it (on iOS the
// app's own frosted menu, the system one being a fixed gray; Material's
// elsewhere): All · Still to hold · Carried, the current one checked, each
// with its count (muted, at the end; Still to hold at 0 is a gold check). An active filter takes the icon's place as one chip, its ×
// inside (→ All); tapping the label reopens the menu. Neutral, never blue.
//
// In prayer, Cancel (a word, so it isn't mistaken for the chip's ×) takes the
// avatar's place, out of the thumb zone by Amen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/frosted_menu.dart';
import '../../components/scroll_edge.dart';
import '../../components/glass.dart';
import '../../components/monogram_avatar.dart';
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
import '../prayer/discard_prayer.dart';
import '../you/you_sheet.dart';

class HomeHeader extends HookConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final inPrayer = ref.watch(prayerSessionProvider.select((s) => s.isActive));
    final reduceMotion = useReduceMotion();
    final duration = reduceMotion ? Duration.zero : pp.motion.settle;

    return ScrollEdge(
      ground: pp.colors.background,
      look: pp.bars.topEdge,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(pp.space.md, pp.space.xs, pp.space.sm, pp.space.sm + 10),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: duration,
                child: inPrayer ? const _Cancel(key: ValueKey('cancel')) : const _SelfAndStreak(key: ValueKey('self')),
              ),
              const Spacer(),
              const _FilterMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

String filterLabel(L10n l10n, HomeFilter f) => switch (f) {
      HomeFilter.all => l10n.filterAll,
      HomeFilter.stillToHold => l10n.filterStillToHold,
      HomeFilter.carried => l10n.filterCarried,
    };

/// "Cancel" on glass: ends the prayer without saving (asks first past
/// ~30 s).
class _Cancel extends ConsumerWidget {
  const _Cancel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final radius = BorderRadius.circular(pp.size.headerGlass / 2);
    return Semantics(
      button: true,
      hint: l10n.discardPrayer,
      // The glass inside a 44 pt target.
      child: SizedBox(
        height: pp.size.avatar,
        child: Center(
          child: Glass(
            height: pp.size.headerGlass,
            child: InkWell(
              borderRadius: radius,
              onTap: () => discardPrayer(context, ref),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.md),
                child: Center(
                  widthFactor: 1,
                  child: Text(l10n.cancelPrayer, style: context.text.labelLarge),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The filter icon, or the active filter's chip, with the menu anchored to
/// it.
class _FilterMenu extends ConsumerWidget {
  const _FilterMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final current = ref.watch(homeQueryProvider.select((q) => q.filter));
    final queryCtl = ref.read(homeQueryProvider.notifier);
    final ios = Theme.of(context).platform == TargetPlatform.iOS;

    Widget anchor(MenuController menu) {
      void toggle() => menu.isOpen ? menu.close() : menu.open();
      if (current == HomeFilter.all) return _FilterIcon(label: l10n.filter, onTap: toggle);
      return _ActiveFilter(
        label: filterLabel(l10n, current),
        onTap: toggle,
        onClear: () => queryCtl.setFilter(HomeFilter.all),
      );
    }

    // Every row keeps the check's space, so the labels line up.
    Widget check(HomeFilter f) => Opacity(
          opacity: f == current ? 1 : 0,
          child: Icon(PPIcons.check, size: pp.size.rowIcon, color: pp.colors.ink),
        );

    // Counts live here only, never on Home. Still to hold at 0 is a small
    // gold check, not "0".
    final counts = ref.watch(filterCountsProvider);
    bool allHeld(HomeFilter f) => f == HomeFilter.stillToHold && counts?[f] == 0;
    Widget? count(HomeFilter f) {
      final n = counts?[f];
      if (n == null) return null;
      if (allHeld(f)) return Icon(PPIcons.check, size: pp.size.menuCheck, color: pp.colors.heldGold);
      return Text(
        NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(n),
        style: context.text.bodyLarge?.copyWith(color: pp.colors.inkMuted),
      );
    }

    String? countSpoken(HomeFilter f) {
      final n = counts?[f];
      if (n == null) return null;
      return allHeld(f) ? l10n.filterAllHeldSpoken : l10n.filterCountSpoken(n);
    }

    if (ios) {
      // The system menu is a fixed gray; this one is the app's glass.
      return FrostedMenu(
        semanticLabel: l10n.filter,
        items: [
          for (final f in HomeFilter.values)
            FrostedMenuItem(
              label: filterLabel(l10n, f),
              selected: f == current,
              trailing: count(f),
              trailingSpoken: countSpoken(f),
              onPressed: () => queryCtl.setFilter(f),
            ),
        ],
        builder: (context, menu) => anchor(menu),
      );
    }
    return MenuAnchor(
      menuChildren: [
        for (final f in HomeFilter.values)
          MenuItemButton(
            leadingIcon: check(f),
            trailingIcon: count(f),
            onPressed: () => queryCtl.setFilter(f),
            child: Text(filterLabel(l10n, f)),
          ),
      ],
      builder: (context, menu, _) => anchor(menu),
    );
  }
}

/// The round filter icon on glass, inside a 44 pt target.
class _FilterIcon extends StatelessWidget {
  const _FilterIcon({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Semantics(
      button: true,
      child: Tooltip(
        message: label,
        child: SizedBox.square(
          dimension: pp.size.avatar,
          child: Center(
            child: Glass(
              height: pp.size.headerGlass,
              width: pp.size.headerGlass,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(PPIcons.filter, size: pp.size.headerIcon, color: pp.colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The active filter in the icon's place: [Still to hold ×]. The label
/// reopens the menu; × returns to All. Raised glass and ink: neutral.
class _ActiveFilter extends StatelessWidget {
  const _ActiveFilter({required this.label, required this.onTap, required this.onClear});

  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final height = pp.size.headerGlass;
    return SizedBox(
      height: pp.size.avatar,
      child: Center(
        child: Glass(
          height: height,
          selected: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                selected: true,
                hint: l10n.filter,
                child: InkWell(
                  borderRadius: BorderRadiusDirectional.horizontal(start: Radius.circular(height / 2))
                      .resolve(Directionality.of(context)),
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: pp.space.md, end: pp.space.xxs),
                    child: Center(
                      widthFactor: 1,
                      child: Text(label, maxLines: 1, style: context.text.labelMedium?.copyWith(color: pp.colors.ink)),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.clearFilter,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadiusDirectional.horizontal(end: Radius.circular(height / 2))
                      .resolve(Directionality.of(context)),
                  onTap: onClear,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: pp.space.xxs, end: pp.space.sm),
                    child: SizedBox(
                      height: height,
                      child: Icon(PPIcons.close, size: pp.size.chipClose, color: pp.colors.inkMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        SizedBox(width: pp.space.xxs),
        Glass(
          height: pp.size.headerGlass,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.xs),
            child: StreakBadge(
              state: streakBadgeState(header, today),
              days: effectiveStreak(header, today),
              todayVariant: today.weekdayFromSunday,
              // Build step 5: the streak sheet.
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}
