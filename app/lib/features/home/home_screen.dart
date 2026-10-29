// Home = the prayer screen (screens.md, design-direction.md): the community
// card on top, then your names and their intentions. The only screen with the
// floating bar. Prayer happens here, in place: the gold halo forms, the
// header's nav steps away, the bar becomes the prayer bar, checks fade into
// the rows — search and filter stay as they were. Header and bar are frosted;
// the list scrolls beneath both. Nothing waits under a pull-down for now.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/halo.dart';
import '../../components/scroll_edge.dart';
import '../../components/thread.dart';
import '../../domain/rules/home_filter.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';
import '../../theme/pp_icons.dart';
import '../add/add_sheet.dart';
import '../prayer/closing_sheet.dart';
import '../prayer/invitation_sheet.dart';
import '../prayer/welcome_back_dialog.dart';
import 'home_bar.dart';
import 'home_header.dart';
import 'community_card.dart';
import 'subject_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final inPrayer = ref.watch(prayerSessionProvider.select((s) => s.isActive));
    final searchOpen = ref.watch(homeQueryProvider.select((q) => q.searchOpen));

    ref.listen(prayerSessionProvider, (previous, next) {
      if (next.phase == PrayerPhase.invitation && previous?.phase != PrayerPhase.invitation) {
        showInvitationSheet(context);
      }
      if (next.phase == PrayerPhase.closing && previous?.phase != PrayerPhase.closing) {
        // Under Still to hold, what was just held lingers, then folds away.
        final logged = next.logged;
        if (logged != null && ref.read(homeQueryProvider).filter == HomeFilter.stillToHold) {
          ref.read(lingerProvider.notifier).hold(
            [...logged.subjectIds, if (logged.communityListId != null) cardLingerKey],
            linger: pp.motion.linger,
            fold: MediaQuery.disableAnimationsOf(context) ? pp.motion.quick : pp.motion.fold,
          );
        }
        showClosingSheet(context).whenComplete(() => ref.read(prayerSessionProvider.notifier).close());
      }
      if (next.awaitingWelcomeBack && !(previous?.awaitingWelcomeBack ?? false)) {
        showWelcomeBackDialog(context);
      }
    });

    return Halo(
      active: inPrayer,
      child: Scaffold(
        // The bar docks search above the keyboard itself.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                const PinnedHeaderSliver(child: HomeHeader()),
                SliverToBoxAdapter(child: SizedBox(height: pp.space.sm)),
                const _CardSlot(),
                const _SubjectRows(),
                const _CarriedHelper(),
                // The last row scrolls fully clear of the floating bar.
                SliverToBoxAdapter(
                  child: SizedBox(height: homeBarClearance(context, searchOpen: searchOpen) + pp.space.xl),
                ),
              ],
            ),
            // What scrolls under the floating bar dissolves into the bottom of the screen.
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: pp.bars.bottomEdgeHeight,
              child: ScrollEdge(ground: pp.colors.background, look: pp.bars.bottomEdge, bottom: true),
            ),
            const PositionedDirectional(start: 0, end: 0, bottom: 0, child: HomeBar()),
          ],
        ),
      ),
    );
  }
}

/// The community card and the gap below it, when the filter and search
/// allow it (home_state.dart); folds away like a row.
class _CardSlot extends ConsumerWidget {
  const _CardSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    if (!ref.watch(communityCardShownProvider)) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: _Fold(
        folding: ref.watch(communityCardFoldingProvider),
        child: Column(
          children: [
            const CommunityCard(),
            SizedBox(height: pp.space.xl),
          ],
        ),
      ),
    );
  }
}

class _SubjectRows extends HookConsumerWidget {
  const _SubjectRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final rows = ref.watch(homeRowsProvider).value;
    final tree = ref.watch(subjectTreeProvider).value;
    final folding = ref.watch(foldingRowsProvider);
    final query = ref.watch(homeQueryProvider);
    final typed = query.text.trim();
    // Only once typing pauses, so it doesn't flicker while a name is typed.
    final settled = useDebounced(typed, pp.motion.searchPause);
    if (rows == null || tree == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (rows.isEmpty && typed.isNotEmpty) {
      return SliverToBoxAdapter(
        child: settled == typed ? _NothingMatches(query: typed) : const SizedBox.shrink(),
      );
    }
    // Nothing left, the list included.
    if (rows.isEmpty &&
        query.filter == HomeFilter.stillToHold &&
        query.text.trim().isEmpty &&
        !ref.watch(communityCardShownProvider)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter, vertical: pp.space.xl),
          child: Text(
            L10n.of(context).filterEmptyStillToHold,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: pp.colors.inkMuted),
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => _Fold(
        key: ValueKey(rows[i].subject.id),
        folding: folding.contains(rows[i].subject.id),
        child: SubjectRow(
          row: rows[i],
          tree: tree,
          first: i == 0,
          thread: threadPartAt(rows, i),
        ),
      ),
    );
  }
}

/// Search found nothing (design-direction.md §4, 2026-10-29): one layout for
/// every case. One line (the query truncates, never the sentence) and a blue
/// + Add, prefilled with the query; in prayer, the line only. If a filter
/// hides matches under All, a one-line match hint says how many, with Show
/// (→ All, the query kept). Archived matches ("In your archive", Restore)
/// come with the archive (build step 6).
class _NothingMatches extends ConsumerWidget {
  const _NothingMatches({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final inPrayer = ref.watch(prayerSessionProvider.select((s) => s.isActive));
    final inAll = ref.watch(searchMatchesInAllProvider) ?? 0;
    final quiet = context.text.bodyLarge?.copyWith(color: pp.colors.inkMuted);

    // The sentence around the query, so only the query gives way.
    const slot = '\u0000';
    final sentence = l10n.searchNoMatches(slot);
    final at = sentence.indexOf(slot);
    final before = at < 0 ? sentence : sentence.substring(0, at);
    final after = at < 0 ? '' : sentence.substring(at + slot.length);
    final line = Semantics(
      label: l10n.searchNoMatches(query),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(before, style: quiet),
          Flexible(child: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis, style: quiet)),
          Text(after, style: quiet),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(pp.space.gutter, pp.space.xl, pp.space.gutter, 0),
      child: Column(
        children: [
          line,
          // Adding mid-prayer isn't a goal.
          if (!inPrayer) ...[
            SizedBox(height: pp.space.sm),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: pp.colors.primary),
              onPressed: () => showAddSheet(context, initialText: query),
              icon: Icon(PPIcons.add, size: pp.size.rowIcon),
              label: Text(l10n.searchAdd),
            ),
          ],
          if (inAll > 0) ...[
            SizedBox(height: pp.space.lg),
            _InAllCard(count: inAll, onShow: () => ref.read(homeQueryProvider.notifier).setFilter(HomeFilter.all)),
          ],
        ],
      ),
    );
  }
}

/// "1 match in All      Show →": the count, never the rows. Content, not a
/// floating control, so a flat card surface with a soft radius, not glass
/// (§4 "Glass vs. surface"). The whole card is one button.
class _InAllCard extends StatelessWidget {
  const _InAllCard({required this.count, required this.onShow});

  final int count;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final radius = BorderRadius.circular(pp.size.radiusHint);
    return Semantics(
      button: true,
      label: l10n.searchShowMatchesSpoken(count),
      excludeSemantics: true,
      onTap: onShow,
      child: Material(
        color: pp.colors.cardSurface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onShow,
          highlightColor: pp.colors.ink.withValues(alpha: pp.bars.pressed),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: pp.size.searchBar),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.md, vertical: pp.space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.searchMatchesInAll(count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(color: pp.colors.inkMuted),
                    ),
                  ),
                  SizedBox(width: pp.space.md),
                  Text(l10n.searchShow, style: context.text.labelLarge?.copyWith(color: pp.colors.primary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Under Carried, when it holds only you (or nothing): what Carried means,
/// quietly, below the list. Explains, never sells: plan limits live in Your
/// portion.
class _CarriedHelper extends ConsumerWidget {
  const _CarriedHelper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final query = ref.watch(homeQueryProvider);
    final rows = ref.watch(homeRowsProvider).value;
    final tree = ref.watch(subjectTreeProvider).value;
    final shown = query.filter == HomeFilter.carried &&
        query.text.trim().isEmpty &&
        rows != null &&
        tree != null &&
        carriedShowsOnlyYou(rows, tree);
    if (!shown) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final quiet = context.text.bodySmall?.copyWith(color: pp.colors.inkMuted);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(pp.space.gutter, pp.space.xl, pp.space.gutter, 0),
        child: Column(
          children: [
            Text(l10n.carriedHelperMeaning, textAlign: TextAlign.center, style: quiet),
            SizedBox(height: pp.space.xs),
            Text(l10n.carriedHelperKeep, textAlign: TextAlign.center, style: quiet),
            SizedBox(height: pp.space.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: pp.colors.primary),
              onPressed: () => context.push(Routes.portion),
              child: Text(l10n.carriedHelperChoose),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row leaving under Still to hold: folds shut as it fades (a fade alone
/// with Reduce Motion).
class _Fold extends HookWidget {
  const _Fold({super.key, required this.folding, required this.child});

  final bool folding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final anim = useAnimationController(duration: reduceMotion ? pp.motion.quick : pp.motion.fold);
    useEffect(() {
      folding ? anim.forward() : anim.reset();
      return null;
    }, [folding]);
    final shown = ReverseAnimation(CurvedAnimation(parent: anim, curve: Curves.easeInOut));
    final faded = FadeTransition(opacity: shown, child: child);
    if (reduceMotion) return faded;
    return SizeTransition(sizeFactor: shown, alignment: AlignmentDirectional.topStart, child: faded);
  }
}

/// Which part of the thread row [i] draws: a name with intentions shown below
/// starts it; each intention branches off; the last one ends it.
ThreadPart? threadPartAt(List<HomeRow> rows, int i) {
  final next = i + 1 < rows.length ? rows[i + 1] : null;
  final continues = next != null && next.isIntention;
  if (!rows[i].isIntention) return continues ? ThreadPart.trunk : null;
  return continues ? ThreadPart.branch : ThreadPart.lastBranch;
}
