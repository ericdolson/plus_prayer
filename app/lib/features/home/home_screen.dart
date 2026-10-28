// Home = the prayer screen (screens.md, design-direction.md): the community
// card on top, then your names and their intentions. The only screen with the
// floating bar. Prayer happens here, in place: the gold halo forms, the
// header's nav steps away, the bar becomes the prayer bar, checks fade into
// the rows — search and filter stay as they were. Header and bar are frosted;
// the list scrolls beneath both. Nothing waits under a pull-down for now.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/halo.dart';
import '../../components/thread.dart';
import '../../domain/rules/home_filter.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';
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
                const SliverToBoxAdapter(child: CommunityCard()),
                SliverToBoxAdapter(child: SizedBox(height: pp.space.xl)),
                const _SubjectRows(),
                // The last row scrolls fully clear of the floating bar.
                SliverToBoxAdapter(
                  child: SizedBox(height: homeBarClearance(context, searchOpen: searchOpen) + pp.space.xl),
                ),
              ],
            ),
            const PositionedDirectional(start: 0, end: 0, bottom: 0, child: HomeBar()),
          ],
        ),
      ),
    );
  }
}

class _SubjectRows extends ConsumerWidget {
  const _SubjectRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(homeRowsProvider).value;
    final tree = ref.watch(subjectTreeProvider).value;
    if (rows == null || tree == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => SubjectRow(
        key: ValueKey(rows[i].subject.id),
        row: rows[i],
        tree: tree,
        first: i == 0,
        thread: threadPartAt(rows, i),
      ),
    );
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
