// Home = the prayer screen (screens.md): personal list with today's list
// pinned on top. The only screen with the footer. Prayer happens here, in
// place: the halo forms, the header's nav steps away, the footer becomes the
// prayer bar, rows become checks — search and filter stay as they were.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/halo.dart';
import '../../domain/rules/presence.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';
import '../prayer/closing_sheet.dart';
import '../prayer/invitation_sheet.dart';
import '../prayer/welcome_back_dialog.dart';
import 'home_footer.dart';
import 'home_header.dart';
import 'list_row.dart';
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

    return Halo(
      active: inPrayer,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _PresenceLine()),
                    const SliverToBoxAdapter(child: ClosingSoonBanner()),
                    const SliverToBoxAdapter(child: ListRow()),
                    SliverToBoxAdapter(child: Divider(indent: pp.space.gutter, endIndent: pp.space.gutter)),
                    const _SubjectRows(),
                    SliverToBoxAdapter(child: SizedBox(height: pp.space.xxl)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      itemBuilder: (context, i) => SubjectRow(key: ValueKey(rows[i].subject.id), row: rows[i], tree: tree),
    );
  }
}

/// "212 praying now" — quiet, by the ladder; hidden rather than ever 0.
class _PresenceLine extends ConsumerWidget {
  const _PresenceLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(presenceLineProvider);
    if (line == null) return const SizedBox.shrink();
    final l10n = L10n.of(context);
    final text = switch (line.window) {
      PresenceWindow.now => l10n.presenceNow(line.count),
      PresenceWindow.lastHour => l10n.presenceLastHour(line.count),
      PresenceWindow.today => l10n.presenceToday(line.count),
    };
    final pp = context.pp;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: pp.space.gutter, end: pp.space.gutter, bottom: pp.space.xs),
      child: Text(text, style: context.text.bodySmall),
    );
  }
}
