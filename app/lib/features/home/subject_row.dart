// A name or intention row (app-brief §3 Home). Title + one secondary line,
// unprayed dot left of the avatar, carried mark, `>` in nav / check in prayer.
// Intentions sit indented under their name and have no avatar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/marks.dart';
import '../../components/monogram_avatar.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/carry.dart';
import '../../domain/rules/home_filter.dart';
import '../../domain/rules/row_status.dart';
import '../../domain/rules/selection.dart';
import '../../domain/rules/subject_tree.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';
import '../add/add_sheet.dart';

class SubjectRow extends ConsumerWidget {
  const SubjectRow({super.key, required this.row, required this.tree, required this.index});

  final HomeRow row;
  final SubjectTree tree;

  /// Position on Home (the list row is 0), for the prayer-mode stagger.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = row.subject;
    final pp = context.pp;
    final l10n = L10n.of(context);
    final today = ref.watch(todayProvider);
    final session = ref.watch(prayerSessionProvider);
    final inPrayer = session.isActive;
    final hold = session.selection.stateOf(s.id, tree);
    final listRow = ref.watch(listRowProvider);
    final justAdded = ref.watch(justAddedNotCarriedProvider).contains(s.id);
    final status = rowStatus(
      s,
      today,
      justAddedNotCarried: justAdded && !isEffectivelyCarried(s, tree),
      poolLimit: ref.watch(poolLimitProvider),
    );
    final unprayed = !prayedToday(s, today);
    final carried = showsCarriedMark(s, tree);
    final carryConfirmed = listRow?.prayedWithList ?? false;
    final nextList = listRow?.list.nextListNumber;

    final title = s.isSelf ? (s.alias ?? s.publicName) : s.label;
    final statusText = _statusText(l10n, status);

    void onTap() {
      if (inPrayer) {
        final willHold = !session.selection.isHeld(s.id);
        ref.read(prayerSessionProvider.notifier).toggle(s.id);
        // The check is a moment: one light haptic; letting go is silent.
        if (willHold) HapticFeedback.lightImpact();
        return;
      }
      // A "Not on the list" row opens Your portion once it exists (build
      // step 6); until then every row opens its detail.
      context.push(Routes.subject(s.id));
    }

    // One sentence for screen readers, every name included.
    final spoken = [
      if (s.alias != null && s.alias != s.publicName) '${s.label}, ${s.publicName}' else s.publicName,
      if (statusText != null) statusText,
      if (unprayed) l10n.unprayedToday,
      if (carried && nextList != null) l10n.carriedMark(nextList),
    ].join('. ');

    final leading = s.isName
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              EmberGlow(
                state: hold,
                size: pp.size.avatar,
                child: MonogramAvatar(initials: monogramOf(s), tone: avatarToneOf(s)),
              ),
              if (carried)
                PositionedDirectional(
                  bottom: -3,
                  end: -3,
                  child: CarriedMark(confirmed: carryConfirmed),
                ),
            ],
          )
        : SizedBox(
            width: pp.size.avatarTiny,
            height: pp.size.avatarTiny,
            child: EmberGlow(
              state: hold,
              size: pp.size.avatarTiny,
              child: carried
                  ? CarriedMark(confirmed: carryConfirmed, size: pp.size.avatarTiny)
                  : Center(
                      child: Container(
                        width: pp.space.sm,
                        height: pp.space.sm,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: pp.colors.inkFaint),
                        ),
                      ),
                    ),
            ),
          );

    return Semantics(
      button: !inPrayer,
      checked: inPrayer ? hold != HoldState.none : null,
      mixed: inPrayer && hold == HoldState.partial ? true : null,
      label: spoken,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: s.isName && !inPrayer ? () => showAddSheet(context, forNameId: s.id) : null,
        child: Opacity(
          opacity: row.isContext ? .55 : 1,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: s.isIntention ? pp.size.intentionIndent : 0,
              end: pp.space.gutter,
              top: s.isName ? pp.space.md : pp.space.xs,
              bottom: s.isName ? pp.space.md : pp.space.xs,
            ),
            child: Row(
              children: [
                UnprayedDot(visible: unprayed),
                SizedBox(
                  width: s.isName ? pp.size.avatar : pp.size.avatarTiny,
                  child: Center(child: leading),
                ),
                SizedBox(width: pp.space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: s.isIntention ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: s.isName ? context.text.titleMedium : context.text.titleSmall,
                      ),
                      if (statusText != null) ...[
                        SizedBox(height: pp.space.xxs),
                        Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: status is AnsweredStatus ? pp.colors.carried : pp.colors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                EmberCheck(inPrayer: inPrayer, state: hold, index: index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _statusText(L10n l10n, RowStatus? status) => switch (status) {
        AnsweredStatus(:final on) => l10n.statusAnswered(on),
        PrayedTodayStatus() => l10n.statusPrayedToday,
        LastPrayedStatus(:final daysAgo) => l10n.statusLastPrayed(daysAgo),
        NotCarriedPoolFullStatus(:final limit) => l10n.statusNotCarriedFull(limit),
        null => null,
      };
}
