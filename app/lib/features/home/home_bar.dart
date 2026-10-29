// Home's floating bar (design-direction.md §4, 2026-10-27): a translucent
// pill and, beside it on the thumb side, the round blue pray button of the
// same height. No slab, no notch. Both change in place in prayer:
//
//   Normal:     ( History  🔎  ＋ )   ( 🙏 )
//   In prayer:  ( 3:12 · with 229   🔎 )   ( Amen )
//
// The button carries the decaying 5 s ring, then becomes Amen; before that
// only the header's Cancel exits (nothing logged). Search stays in reach in
// prayer; Cancel is kept away from Amen.
//
// Search: 🔎 opens a field docked just above the keyboard (Slack-style); the
// list filters live behind it. The keyboard hides the bar, so the field then
// carries a compact pray button (Amen with its ring in prayer): Pray is never
// out of reach. With the keyboard down the field sits above the bar, so a
// prayer started mid-search keeps it until it's closed; left empty, it
// closes itself when it loses focus.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/glass.dart';
import '../../components/ring_button.dart';
import '../../domain/rules/presence.dart';
import '../../hooks/use_elapsed.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
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

/// The bar floats this far above the bottom edge: just above the keyboard
/// while it's up (the bar itself steps aside then), else near the home
/// indicator.
double _bottomGap(BuildContext context) {
  final pp = context.pp;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboard > 0) return keyboard + pp.space.sm;
  return math.max(MediaQuery.paddingOf(context).bottom - pp.space.sm, pp.size.barInset);
}

/// How much of the screen's bottom the bar (and a docked search field)
/// covers: the list pads its end by this so the last row scrolls clear.
double homeBarClearance(BuildContext context, {required bool searchOpen}) {
  final pp = context.pp;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
  final search = searchOpen ? pp.size.searchBar + (keyboard ? 0 : pp.space.sm) : 0.0;
  return _bottomGap(context) + search + (keyboard ? 0 : pp.size.bar);
}

/// Place at the bottom of Home's stack, over the list (`Scaffold` with
/// `resizeToAvoidBottomInset: false`).
class HomeBar extends HookConsumerWidget {
  const HomeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final searchOpen = ref.watch(homeQueryProvider.select((q) => q.searchOpen));
    final focus = useFocusNode();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;

    void onSearch() {
      if (searchOpen) {
        focus.requestFocus();
      } else {
        ref.read(homeQueryProvider.notifier).openSearch();
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(pp.size.barInset, 0, pp.size.barInset, _bottomGap(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (searchOpen) _SearchField(focus: focus, withPray: keyboard),
          if (!keyboard) ...[
            if (searchOpen) SizedBox(height: pp.space.sm),
            Row(
              children: [
                Expanded(child: _Pill(onSearch: onSearch)),
                SizedBox(width: pp.space.md),
                const HomePrayButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends HookConsumerWidget {
  const _Pill({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final reduceMotion = useReduceMotion();
    final inPrayer = _inPrayer(session);

    return Glass(
      height: pp.size.bar,
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : pp.motion.settle,
        child: inPrayer
            ? _PrayerBar(key: const ValueKey('prayer'), startedAt: session.startedAt, onSearch: onSearch)
            : Row(
                key: const ValueKey('nav'),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BarIcon(icon: PPIcons.history, label: l10n.history, onPressed: () => context.push(Routes.history)),
                  _BarIcon(icon: PPIcons.search, label: l10n.search, onPressed: onSearch),
                  _BarIcon(icon: PPIcons.add, label: l10n.add, onPressed: () => showAddSheet(context)),
                ],
              ),
      ),
    );
  }
}

/// The round blue pray button beside the pill; Amen in prayer. [compact]:
/// the smaller one at the end of the docked search field.
class HomePrayButton extends ConsumerWidget {
  const HomePrayButton({super.key, this.compact = false});

  final bool compact;

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
      size: compact ? pp.size.prayCompact : pp.size.bar,
      // The compact ring stays inside the field.
      ringGap: compact ? pp.space.xs : null,
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
      complete: inPrayer
          ? (compact
              ? FittedBox(child: Padding(padding: EdgeInsets.all(pp.space.xs), child: Text(l10n.amen)))
              : Text(l10n.amen))
          : null,
      child: Icon(PPIcons.prayingHands, size: compact ? pp.size.rowIcon : pp.size.barIcon),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      iconSize: pp.size.barIcon,
      color: pp.colors.ink,
      icon: Icon(icon),
    );
  }
}

/// "3:12 · with 229   🔎"
class _PrayerBar extends ConsumerWidget {
  const _PrayerBar({super.key, required this.startedAt, required this.onSearch});

  final DateTime? startedAt;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final stats = ref.watch(liveStatsProvider).value;
    final threshold = ref.watch(configProvider).presenceDisplayThreshold;
    final others = stats == null ? null : othersInPrayer(stats, threshold);
    final quiet = context.text.bodyMedium?.copyWith(color: pp.colors.inkMuted);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: pp.space.xl),
      child: Row(
        children: [
          _PrayerTimer(startedAt: startedAt, clock: ref.watch(clockProvider)),
          if (others != null) ...[
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.sm),
                child: Text('·', style: quiet),
              ),
            ),
            Flexible(
              child: Semantics(
                label: l10n.prayingWithSpoken(others),
                excludeSemantics: true,
                child: Text(l10n.prayingWith(others), maxLines: 1, overflow: TextOverflow.ellipsis, style: quiet),
              ),
            ),
          ],
          const Spacer(),
          _BarIcon(icon: PPIcons.search, label: l10n.search, onPressed: onSearch),
          SizedBox(width: pp.space.xs),
        ],
      ),
    );
  }
}

class _PrayerTimer extends HookWidget {
  const _PrayerTimer({required this.startedAt, required this.clock});

  final DateTime? startedAt;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final elapsed = useElapsed(startedAt, clock: clock);
    final text = formatElapsed(elapsed);
    return Semantics(
      label: L10n.of(context).timeInPrayer(text),
      excludeSemantics: true,
      child: Text(text, style: context.text.labelSmall),
    );
  }
}

/// Docked above the keyboard (or the bar); filters the list live.
class _SearchField extends HookConsumerWidget {
  const _SearchField({required this.focus, required this.withPray});

  final FocusNode focus;

  /// The keyboard is up and hides the bar: carry the compact pray button.
  final bool withPray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final queryCtl = ref.read(homeQueryProvider.notifier);
    final search = useTextEditingController(text: ref.read(homeQueryProvider).text);
    // Leaving the field empty closes it.
    useEffect(() {
      void onFocus() {
        if (!focus.hasFocus && search.text.trim().isEmpty) queryCtl.closeSearch();
      }

      focus.addListener(onFocus);
      return () => focus.removeListener(onFocus);
    }, [focus]);
    const none = InputBorder.none;
    return Glass(
      height: pp.size.searchBar,
      child: Row(
        children: [
          SizedBox(width: pp.space.lg),
          Icon(PPIcons.search, size: pp.size.rowIcon, color: pp.colors.inkMuted),
          Expanded(
            child: TextField(
              controller: search,
              focusNode: focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: queryCtl.setText,
              decoration: InputDecoration(
                hintText: l10n.search,
                filled: false,
                border: none,
                enabledBorder: none,
                focusedBorder: none,
                isDense: true,
                contentPadding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.sm),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.closeSearch,
            iconSize: pp.size.rowIcon,
            icon: Icon(PPIcons.close, color: pp.colors.inkMuted),
            onPressed: queryCtl.closeSearch,
          ),
          if (withPray) const HomePrayButton(compact: true),
          SizedBox(width: pp.space.xs),
        ],
      ),
    );
  }
}
