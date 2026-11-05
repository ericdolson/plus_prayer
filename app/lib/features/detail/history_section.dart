// The detail page's History (detail-page.md History, simplified 2026-11-03):
//
//   History                                   ← Roca, the Home name style
//   This week                         ✎ 2     ← label, hints at the end
//   ●─●─●─●─●                                 ← the only strand: this week
//   You prayed 6 times · On 5 lists · current ← inkMuted, empty halves left out
//   Last week                         ✎ 1
//   You prayed 4 times · On 5 lists
//   …
//   Begun · Sep 12
//
// v1: rows aren't tappable (expansion is v2).

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/bead_strand.dart';
import '../../domain/rules/history.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';

class HistorySection extends ConsumerWidget {
  const HistorySection({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final view = ref.watch(subjectHistoryViewProvider((id: subjectId, firstDayOfWeek: firstDay))).value;
    if (view == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final begun = view.begun.toUtc();

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.history, style: context.text.titleMedium),
          for (final p in view.periods) ...[
            SizedBox(height: pp.space.lg),
            _PeriodRow(period: p),
          ],
          SizedBox(height: pp.space.lg),
          Text(
            begun.year == today.year ? l10n.historyBegun(begun) : l10n.historyBegunYear(begun),
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period});

  final HistoryPeriod period;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final p = period;
    final start = p.start.toUtc();
    final label = switch (p.kind) {
      PeriodKind.thisWeek => l10n.historyThisWeek,
      PeriodKind.lastWeek => l10n.historyLastWeek,
      PeriodKind.earlierThisMonth => l10n.historyEarlierIn(start),
      PeriodKind.month => l10n.historyMonth(start),
      PeriodKind.year => l10n.historyYear(start),
    };
    final onLists = p.listCount == 0
        ? null
        : p.onCurrentList
            ? l10n.historyCurrent(l10n.historyOnLists(p.listCount))
            : l10n.historyOnLists(p.listCount);
    final line = [
      if (p.prayerCount > 0) l10n.historyPrayed(p.prayerCount),
      if (onLists != null) onLists,
    ].join(' · ');
    final hint = context.text.labelMedium;

    return Semantics(
      label: [
        label,
        if (p.prayerCount > 0) l10n.historyPrayed(p.prayerCount),
        if (onLists != null) onLists,
        if (p.noteCount > 0) l10n.historyNotesSpoken(p.noteCount),
        if (p.answered) l10n.historyAnswered,
      ].join('. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.labelLarge)),
              if (p.answered) ...[
                Text(l10n.historyAnswered, style: hint?.copyWith(color: pp.colors.heldGoldText)),
                if (p.noteCount > 0) SizedBox(width: pp.space.md),
              ],
              if (p.noteCount > 0) ...[
                Icon(PPIcons.note, size: pp.size.hintIcon, color: pp.colors.inkMuted),
                SizedBox(width: pp.space.xxs),
                Text('${p.noteCount}', style: hint),
              ],
            ],
          ),
          if (p.showsStrand) ...[
            SizedBox(height: pp.space.sm),
            BeadStrand(items: p.strand),
          ],
          // An Answered-only period has the hint and no line.
          if (line.isNotEmpty) ...[
            SizedBox(height: pp.space.xs),
            Text(line, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}
