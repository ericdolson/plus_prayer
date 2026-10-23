// Home = the prayer screen (screens.md, design-direction.md): the community
// card on top, then your names and their intentions. The only screen with the
// footer. Prayer happens here, in place: the gold halo forms, the header's
// nav steps away, the footer becomes the prayer bar, checks fade into the rows
// — search and filter stay as they were. Header and footer are frosted; the
// list scrolls beneath both. Pull down to search.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'home_footer.dart';
import 'home_header.dart';
import 'community_card.dart';
import 'subject_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final inPrayer = ref.watch(prayerSessionProvider.select((s) => s.isActive));

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

    // Pull down past the threshold to reveal search (iOS Mail).
    bool onScroll(ScrollUpdateNotification n) {
      final query = ref.read(homeQueryProvider);
      if (!query.searchOpen && n.dragDetails != null && n.metrics.pixels < -pp.size.pullToSearch) {
        HapticFeedback.selectionClick();
        ref.read(homeQueryProvider.notifier).openSearch();
      }
      return false;
    }

    return Halo(
      active: inPrayer,
      child: Scaffold(
        // The list scrolls under the frosted footer, its corners and notch.
        extendBody: true,
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              const PinnedHeaderSliver(child: HomeHeader()),
              SliverToBoxAdapter(child: SizedBox(height: pp.space.sm)),
              const SliverToBoxAdapter(child: CommunityCard()),
              SliverToBoxAdapter(child: SizedBox(height: pp.space.xl)),
              const _SubjectRows(),
              // Clear of the footer and the docked button.
              SliverSafeArea(
                top: false,
                sliver: SliverToBoxAdapter(child: SizedBox(height: pp.size.fab / 2 + pp.space.xl)),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: const HomePrayButton(),
        bottomNavigationBar: const HomeFooter(),
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
