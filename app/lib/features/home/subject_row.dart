// Home rows (design-direction.md §3, §5). One line each, no dividers, no
// chevrons. Names: a 44 pt avatar and the name in the serif, 52 pt (the
// avatar and its ring's room). Intentions: smaller muted sans on a thread
// from the name's avatar, their text aligned with the name's, on a ~40 pt
// pitch that is all tap target. An intention's line sits at the top of its
// row, so the first one hangs ~5 pt under its name and the group reads as
// one unit; the space goes between groups.
//
// Held today = the gold ring (names) or gold dot (intentions) until local
// midnight; in prayer the same marks appear live as rows are checked, and a
// check fades into the empty trailing slot. Secondary text only for
// exceptional states ("Answered · Oct 6", "Not on the list …").
//
// Tap → the item's own page (in prayer: check). Long-press → quick actions.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/marks.dart';
import '../../components/monogram_avatar.dart';
import '../../components/thread.dart';
import '../../domain/models/subject.dart';
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
import 'quick_actions.dart';

class SubjectRow extends ConsumerWidget {
  const SubjectRow({super.key, required this.row, required this.tree, this.first = false, this.thread});

  final HomeRow row;
  final SubjectTree tree;

  /// The first row on Home gets no group gap above it.
  final bool first;

  /// This row's part of the intention thread, if any.
  final ThreadPart? thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = row.subject;
    final pp = context.pp;
    final l10n = L10n.of(context);
    final today = ref.watch(todayProvider);
    final session = ref.watch(prayerSessionProvider);
    final inPrayer = session.isActive;
    final hold = session.selection.stateOf(s.id, tree);
    final justAdded = ref.watch(justAddedNotCarriedProvider).contains(s.id);
    final status = rowStatus(
      s,
      justAddedNotCarried: justAdded && !isEffectivelyCarried(s, tree),
      poolLimit: ref.watch(poolLimitProvider),
    );
    final held = prayedToday(s, today) || (inPrayer && hold != HoldState.none);
    final statusText = switch (status) {
      AnsweredStatus(:final on) => l10n.statusAnswered(on),
      NotCarriedPoolFullStatus(:final limit) => l10n.statusNotCarriedFull(limit),
      null => null,
    };

    void onTap() {
      if (inPrayer) {
        final willHold = !session.selection.isHeld(s.id);
        ref.read(prayerSessionProvider.notifier).toggle(s.id);
        // The check is a moment: one light haptic; letting go is silent.
        if (willHold) HapticFeedback.lightImpact();
        return;
      }
      // A "Not on the list" row opens Your portion once it exists (build
      // step 6); until then every row opens its own page.
      context.push(Routes.subject(s.id));
    }

    // One sentence for screen readers, every name included.
    final spoken = [
      if (s.alias != null && s.alias != s.publicName) '${s.label}, ${s.publicName}' else s.publicName,
      if (statusText != null) statusText,
      if (held && !inPrayer) l10n.heldToday,
    ].join('. ');

    final secondary = statusText == null
        ? null
        : Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: status is AnsweredStatus ? pp.colors.heldGoldText : pp.colors.inkMuted,
            ),
          );

    // An intention's first line, as tall as the check, at the top of the
    // row: its dot, the thread's branch and the check line up on it.
    final lineStyle = context.text.titleSmall!;
    final line = MediaQuery.textScalerOf(context).scale(lineStyle.fontSize!) * (lineStyle.height ?? 1);
    final band = math.max(pp.size.check, line);

    final content = s.isName
        ? _NameContent(subject: s, held: held, secondary: secondary)
        : _IntentionContent(subject: s, held: held, band: band, line: line, secondary: secondary);

    final threadPart = thread;
    final textStart = pp.space.gutter + pp.size.avatar + pp.space.md;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: s.isName && !first ? pp.space.groupGap : 0),
      child: Semantics(
        button: !inPrayer,
        checked: inPrayer ? hold != HoldState.none : null,
        mixed: inPrayer && hold == HoldState.partial ? true : null,
        label: spoken,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          // Intentions get theirs (Answered, Release, edit, archive) with build step 5.
          onLongPress: inPrayer || !s.isName ? null : () => showQuickActions(context, s),
          child: CustomPaint(
            painter: threadPart == null
                ? null
                : ThreadPainter(
                    part: threadPart,
                    color: pp.colors.thread,
                    strokeWidth: pp.size.thread,
                    radius: pp.size.threadRadius,
                    trunkX: pp.space.gutter + pp.size.avatar / 2,
                    endX: textStart - pp.space.sm - pp.size.heldDot / 2,
                    avatarDiameter: pp.size.avatar,
                    avatarClearance: pp.size.heldRing + pp.size.heldRingGap,
                    branchY: pp.space.xxs + band / 2,
                    textDirection: Directionality.of(context),
                  ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: s.isName ? pp.size.nameRow : pp.size.intentionRow),
              child: Opacity(
                opacity: row.isContext ? .55 : 1,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: s.isName ? pp.space.gutter : 0,
                    end: pp.space.gutter,
                    // A name: room for the held ring. An intention: its line at
                    // the top; the rest of the pitch is below it.
                    top: s.isName ? pp.space.xs : pp.space.xxs,
                    bottom: s.isName ? pp.space.xs : pp.space.sm,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Row(
                      crossAxisAlignment: s.isName ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        Expanded(child: content),
                        SizedBox(width: pp.space.md),
                        SizedBox(
                          height: s.isName ? null : band,
                          child: Center(child: PrayerCheck(inPrayer: inPrayer, state: hold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameContent extends StatelessWidget {
  const _NameContent({required this.subject, required this.held, this.secondary});

  final Subject subject;
  final bool held;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final s = subject;
    return Row(
      children: [
        HeldRing(
          held: held,
          child: MonogramAvatar(initials: monogramOf(s), tone: avatarToneOf(s)),
        ),
        SizedBox(width: pp.space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.isSelf ? (s.alias ?? s.publicName) : s.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              if (secondary != null) ...[SizedBox(height: pp.space.xxs), secondary!],
            ],
          ),
        ),
      ],
    );
  }
}

/// The dot column ends where the thread does; the text lines up with the
/// name's.
class _IntentionContent extends StatelessWidget {
  const _IntentionContent({
    required this.subject,
    required this.held,
    required this.band,
    required this.line,
    this.secondary,
  });

  final Subject subject;
  final bool held;

  /// The first line's band (≥ the check) and the text's line height in it.
  final double band;
  final double line;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final textStart = pp.space.gutter + pp.size.avatar + pp.space.md;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: textStart - pp.space.sm,
          height: band,
          child: Align(alignment: AlignmentDirectional.centerEnd, child: HeldDot(held: held)),
        ),
        SizedBox(width: pp.space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(top: (band - line) / 2),
                child:
                    Text(subject.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
              ),
              if (secondary != null) ...[SizedBox(height: pp.space.xxs), secondary!],
            ],
          ),
        ),
      ],
    );
  }
}
