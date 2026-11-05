// The name / intention detail page (detail-page.md). One layout for both:
//
//   ‹                                  ⋯
//              ( D )          ← 72 pt avatar, gold ring if held today
//               Dad           ← Roca
//        Dad will be on List 53     ← status line (detail_status.dart)
//   Held by you · 47 prayers
//   Carried by the world · 61,204 prayers · 19 lists
//   Intentions                ← Home's intention rows (names only)
//   ＋ Add intention for Dad
//   History                   ← history_section.dart
//                          ( 🙏 Pray for Dad )
//
// An intention's page has no avatar: its parent name above a Roca title, a
// gold dot before it when held today, and no Intentions section.
//
// Praying here stays here: everything that isn't the subject fades out (the
// status, counts, History, the add link, ⋯ and ‹), the subject is
// pre-checked, Cancel takes ‹'s place, the capsule becomes the round
// pray/Amen button and the prayer pill fades in beside it. "Pray for others"
// (and system back) goes to Home, still praying. Amen, the invitation and the
// closing sheet play over this page (Home, mounted beneath every pushed
// page, presents them for the app-level session); the stripped sections fade
// back as the closing sheet is dismissed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/router.dart';
import '../../components/glass.dart';
import '../../components/marks.dart';
import '../../components/monogram_avatar.dart';
import '../../components/scroll_edge.dart';
import '../../components/thread.dart';
import '../../domain/models/subject.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/card_carry.dart';
import '../../domain/rules/detail_status.dart';
import '../../domain/rules/home_filter.dart';
import '../../domain/rules/row_status.dart';
import '../../domain/rules/selection.dart';
import '../../domain/rules/subject_tree.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/detail_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../add/add_sheet.dart';
import '../home/home_bar.dart';
import '../home/home_header.dart';
import '../home/subject_row.dart';
import '../prayer/prayer_halo.dart';
import 'history_section.dart';
import 'subject_actions.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final tree = ref.watch(subjectTreeProvider).value;
    final subject = tree?[subjectId];
    final phase = ref.watch(prayerSessionProvider.select((s) => s.phase));
    final inPrayer = phase == PrayerPhase.praying || phase == PrayerPhase.invitation;
    // Stripped from the start of a prayer until the closing sheet is gone.
    final stripped = phase != PrayerPhase.idle;

    return PopScope(
      // System back in prayer = "Pray for others": Home, still praying (from
      // a page pushed on another page, too).
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || !inPrayer) return;
        final router = GoRouter.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) => router.go(Routes.home));
      },
      child: PrayerHalo(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  PinnedHeaderSliver(child: _Header(subject: subject, inPrayer: inPrayer, stripped: stripped)),
                  if (tree != null && subject != null)
                    SliverToBoxAdapter(
                      child: _Body(subject: subject, tree: tree, inPrayer: inPrayer, stripped: stripped),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: homeBarClearance(context, searchOpen: false) + pp.space.xl),
                  ),
                ],
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: pp.bars.bottomEdgeHeight,
                child: ScrollEdge(ground: pp.colors.background, look: pp.bars.bottomEdge, bottom: true),
              ),
              if (subject != null)
                PositionedDirectional(start: 0, end: 0, bottom: 0, child: _Bar(subject: subject, inPrayer: inPrayer)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.subject, required this.tree, required this.inPrayer, required this.stripped});

  final Subject subject;
  final SubjectTree tree;
  final bool inPrayer;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final s = subject;
    final gutter = EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: pp.space.sm),
        if (s.isName)
          _NameTop(subject: s, tree: tree, inPrayer: inPrayer, stripped: stripped)
        else
          _IntentionTop(subject: s, tree: tree, inPrayer: inPrayer, stripped: stripped),
        _Strip(
          shown: !stripped,
          child: Padding(
            padding: gutter.add(EdgeInsetsDirectional.only(top: pp.space.xl)),
            child: _Counts(subjectId: s.id),
          ),
        ),
        if (s.isName)
          _Intentions(name: s, tree: tree, inPrayer: inPrayer, stripped: stripped)
        else
          _Strip(shown: inPrayer, child: const _PrayForOthers()),
        _Strip(
          shown: !stripped,
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: pp.space.xxl),
            child: HistorySection(subjectId: s.id),
          ),
        ),
      ],
    );
  }
}

/// ‹ and ⋯ on their own glass; in prayer, Cancel in ‹'s place and no ⋯.
class _Header extends StatelessWidget {
  const _Header({required this.subject, required this.inPrayer, required this.stripped});

  final Subject? subject;
  final bool inPrayer;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final s = subject;
    final duration = MediaQuery.disableAnimationsOf(context) ? pp.motion.quick : pp.motion.strip;
    return ScrollEdge(
      ground: pp.colors.background,
      look: pp.bars.topEdge,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(pp.space.md, pp.space.xs, pp.space.md, pp.space.sm),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: duration,
                child: inPrayer
                    ? const CancelPrayerButton(key: ValueKey('cancel'))
                    : stripped
                        ? SizedBox(key: const ValueKey('none'), height: pp.size.avatar)
                        : _GlassIcon(
                            key: const ValueKey('back'),
                            icon: PPIcons.back,
                            label: l10n.back,
                            onTap: () => context.pop(),
                          ),
              ),
              const Spacer(),
              if (s != null)
                _Strip(
                  shown: !stripped,
                  collapse: false,
                  child: _GlassIcon(
                    icon: PPIcons.more,
                    label: l10n.more,
                    onTap: () => showSubjectActions(context, s, onGone: () => context.pop()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        // The glass inside a 44 pt target.
        child: SizedBox.square(
          dimension: pp.size.avatar,
          child: Center(
            child: Glass(
              height: pp.size.headerGlass,
              width: pp.size.headerGlass,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(icon, size: pp.size.headerIcon, color: pp.colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The avatar, the name and the status line. In prayer the whole block is
/// the name's check (like a Home row), its checkbox in the trailing slot.
class _NameTop extends ConsumerWidget {
  const _NameTop({required this.subject, required this.tree, required this.inPrayer, required this.stripped});

  final Subject subject;
  final SubjectTree tree;
  final bool inPrayer;
  final bool stripped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final s = subject;
    final today = ref.watch(todayProvider);
    final selection = ref.watch(prayerSessionProvider.select((x) => x.selection));
    final hold = selection.stateOf(s.id, tree);
    final held = prayedToday(s, today) || (inPrayer && hold != HoldState.none);
    final title = _titleOf(s);
    final checkInset = (pp.size.avatarLarge - pp.size.check) / 2;

    final block = Column(
      children: [
        HeldRing(
          held: held,
          child: MonogramAvatar(initials: monogramOf(s), tone: avatarToneOf(s), size: pp.size.avatarLarge),
        ),
        SizedBox(height: pp.space.md),
        Text(title, textAlign: TextAlign.center, style: context.text.headlineMedium),
        _Strip(
          shown: !stripped,
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: pp.space.xs),
            child: _StatusLine(subject: s, centered: true),
          ),
        ),
      ],
    );

    return _Checkable(
      subject: s,
      inPrayer: inPrayer,
      hold: hold,
      label: title,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mirrors the check so the block stays centered.
            SizedBox(width: pp.size.check),
            Expanded(child: block),
            Padding(
              padding: EdgeInsetsDirectional.only(top: checkInset),
              child: PrayerCheck(inPrayer: inPrayer, state: hold),
            ),
          ],
        ),
      ),
    );
  }
}

/// The parent name (→ its page; plain text in prayer), the gold held dot and
/// the intention in Roca, the status line.
class _IntentionTop extends ConsumerWidget {
  const _IntentionTop({required this.subject, required this.tree, required this.inPrayer, required this.stripped});

  final Subject subject;
  final SubjectTree tree;
  final bool inPrayer;
  final bool stripped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final s = subject;
    final parent = tree.parentOf(s.id);
    final today = ref.watch(todayProvider);
    final selection = ref.watch(prayerSessionProvider.select((x) => x.selection));
    final hold = selection.stateOf(s.id, tree);
    final held = prayedToday(s, today) || (inPrayer && hold != HoldState.none);
    final titleStyle = context.text.headlineSmall!;
    final parentStyle = context.text.bodySmall;

    return _Checkable(
      subject: s,
      inPrayer: inPrayer,
      hold: hold,
      label: s.label,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parent != null)
                    inPrayer || stripped
                        ? Text(_titleOf(parent), style: parentStyle)
                        : InkWell(
                            onTap: () => context.push(Routes.subject(parent.id)),
                            child: Padding(
                              padding: EdgeInsetsDirectional.symmetric(vertical: pp.space.xs),
                              child: Text(_titleOf(parent), style: parentStyle),
                            ),
                          ),
                  SizedBox(height: pp.space.xs),
                  Text.rich(
                    TextSpan(children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: pp.space.sm),
                          child: HeldDot(held: held),
                        ),
                      ),
                      TextSpan(text: s.label),
                    ]),
                    style: titleStyle,
                  ),
                  _Strip(
                    shown: !stripped,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(top: pp.space.xs),
                      child: _StatusLine(subject: s, centered: false),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: pp.space.md),
            Padding(
              padding: EdgeInsetsDirectional.only(top: pp.space.xl),
              child: PrayerCheck(inPrayer: inPrayer, state: hold),
            ),
          ],
        ),
      ),
    );
  }
}

/// In prayer the top block is one toggle, like a Home row.
class _Checkable extends ConsumerWidget {
  const _Checkable({
    required this.subject,
    required this.inPrayer,
    required this.hold,
    required this.label,
    required this.child,
  });

  final Subject subject;
  final bool inPrayer;
  final HoldState hold;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!inPrayer) return child;
    return Semantics(
      checked: hold != HoldState.none,
      mixed: hold == HoldState.partial ? true : null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          final willHold = hold == HoldState.none;
          ref.read(prayerSessionProvider.notifier).toggle(subject.id);
          if (willHold) HapticFeedback.lightImpact();
        },
        child: child,
      ),
    );
  }
}

/// What the page calls the subject: the alias, "Me" for the self.
String _titleOf(Subject s) => s.isSelf ? (s.alias ?? s.publicName) : s.label;

class _StatusLine extends ConsumerWidget {
  const _StatusLine({required this.subject, required this.centered});

  final Subject subject;
  final bool centered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final status = ref.watch(detailStatusProvider(subject.id));
    if (status == null) return const SizedBox.shrink();
    final name = _titleOf(subject);
    final (text, color) = switch (status) {
      DetailAnswered(:final on) => (l10n.statusAnswered(on), pp.colors.heldGoldText),
      DetailCarry(:final status, :final voice, :final nextList, :final covered) => (
          switch ((voice, status)) {
            (StatusVoice.self, TomorrowStatus.covered) => l10n.cardCoveredYou(nextList),
            (StatusVoice.self, TomorrowStatus.nextPrayerCarries) => l10n.cardNextPrayerYou(nextList),
            (StatusVoice.self, TomorrowStatus.prayToCarry) => l10n.cardPrayToBe(nextList),
            (StatusVoice.intention, TomorrowStatus.covered) => l10n.detailCoveredIt(nextList),
            (StatusVoice.intention, TomorrowStatus.nextPrayerCarries) => l10n.detailNextPrayerIt(nextList),
            (StatusVoice.intention, TomorrowStatus.prayToCarry) => l10n.detailPrayToCarryIt(nextList),
            (StatusVoice.name, TomorrowStatus.covered) => l10n.detailCovered(name, nextList),
            (StatusVoice.name, TomorrowStatus.nextPrayerCarries) => l10n.detailNextPrayer(name, nextList),
            (StatusVoice.name, TomorrowStatus.prayToCarry) => l10n.detailPrayToCarry(name, nextList),
          },
          // Ink while it asks something of you; muted once covered.
          covered ? pp.colors.inkMuted : pp.colors.ink,
        ),
      DetailClosing(:final voice, :final list, :final minutes, :final nextList) => (
          switch (voice) {
            StatusVoice.self => l10n.closesSoonYou(list, minutes, nextList),
            StatusVoice.intention => l10n.detailClosesSoonIt(list, minutes),
            StatusVoice.name => l10n.detailClosesSoon(list, minutes, name),
          },
          pp.colors.ink,
        ),
    };
    // Full width, so it centers inside the strip's fold.
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: context.text.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}

/// "Held by you · N prayers" always; "Carried by the world · …" once ever
/// carried. The world count runs live for the current list.
class _Counts extends ConsumerWidget {
  const _Counts({required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final view = ref.watch(subjectHistoryViewProvider((id: subjectId, firstDayOfWeek: firstDay))).value;
    if (view == null) return const SizedBox.shrink();
    final c = view.counts;
    final style = context.text.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.detailHeldByYou(c.heldByYou), style: style),
        if (c.everCarried) ...[
          SizedBox(height: pp.space.xs),
          Text(
            l10n.detailCarriedByWorld(l10n.detailWorldPrayers(c.worldPrayers), l10n.detailWorldLists(c.lists)),
            style: style,
          ),
        ],
      ],
    );
  }
}

/// A name's intentions: Home's rows exactly (thread, held dot, carried mark,
/// Answered), checkable in prayer; the add link; "Pray for others" in prayer.
class _Intentions extends StatelessWidget {
  const _Intentions({required this.name, required this.tree, required this.inPrayer, required this.stripped});

  final Subject name;
  final SubjectTree tree;
  final bool inPrayer;
  final bool stripped;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final intentions = tree.intentionsOf(name.id);
    final textStart = pp.space.gutter + pp.size.avatar + pp.space.md;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Strip(
          shown: !stripped,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(pp.space.gutter, pp.space.xxl, pp.space.gutter, pp.space.sm),
            child: Text(l10n.detailIntentions, style: context.text.titleMedium),
          ),
        ),
        if (stripped && intentions.isNotEmpty) SizedBox(height: pp.space.lg),
        for (var i = 0; i < intentions.length; i++)
          SubjectRow(
            key: ValueKey(intentions[i].id),
            row: HomeRow(intentions[i], isContext: false),
            tree: tree,
            thread: i == intentions.length - 1 ? ThreadPart.lastBranch : ThreadPart.branch,
          ),
        _Strip(
          shown: !stripped,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: textStart - pp.space.md, end: pp.space.gutter),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: pp.colors.primary),
                onPressed: () => showAddSheet(context, forNameId: name.id),
                icon: Icon(PPIcons.add, size: pp.size.rowIcon),
                label: Text(name.isSelf ? l10n.addIntention : l10n.addIntentionFor(_titleOf(name))),
              ),
            ),
          ),
        ),
        _Strip(shown: inPrayer, child: const _PrayForOthers()),
      ],
    );
  }
}

class _PrayForOthers extends StatelessWidget {
  const _PrayForOthers();

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: pp.space.lg),
      child: Center(
        child: TextButton(
          style: TextButton.styleFrom(foregroundColor: pp.colors.inkMuted),
          onPressed: () => context.go(Routes.home),
          child: Text(L10n.of(context).prayForOthers),
        ),
      ),
    );
  }
}

/// The pray-button slot: "Pray for Dad" as a blue capsule; in prayer the
/// round pray/Amen button with the prayer pill (timer · with N) beside it.
class _Bar extends ConsumerWidget {
  const _Bar({required this.subject, required this.inPrayer});

  final Subject subject;
  final bool inPrayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final s = subject;
    final startedAt = ref.watch(prayerSessionProvider.select((x) => x.startedAt));
    final duration = MediaQuery.disableAnimationsOf(context) ? pp.motion.quick : pp.motion.settle;
    final label = s.isName && !s.isSelf ? l10n.prayFor(_titleOf(s)) : l10n.pray;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(pp.size.barInset, 0, pp.size.barInset, barBottomGap(context)),
      child: Row(
        children: [
          Expanded(
            child: IgnorePointer(
              ignoring: !inPrayer,
              child: AnimatedOpacity(
                opacity: inPrayer ? 1 : 0,
                duration: duration,
                child: Glass(height: pp.size.bar, child: inPrayer ? PrayerBar(startedAt: startedAt) : const SizedBox()),
              ),
            ),
          ),
          SizedBox(width: pp.space.md),
          AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween(begin: .9, end: 1.0).animate(animation), child: child),
            ),
            child: inPrayer
                ? const HomePrayButton(key: ValueKey('amen'))
                : _PrayCapsule(
                    key: const ValueKey('pray'),
                    label: label,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(prayerSessionProvider.notifier).start(focusId: s.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrayCapsule extends StatelessWidget {
  const _PrayCapsule({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .7),
        child: Material(
          color: c.primary,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: SizedBox(
              height: pp.size.bar,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.lg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PPIcons.prayingHands, size: pp.size.rowIcon, color: c.onPrimary),
                    SizedBox(width: pp.space.sm),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(color: c.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section that steps aside while praying: fades and folds together
/// (~250 ms); with Reduce Motion a plain fade, then it's gone. Hidden
/// sections take no taps and aren't read. [collapse] false: fade only (the
/// header's ⋯, which keeps its place).
class _Strip extends HookWidget {
  const _Strip({required this.shown, required this.child, this.collapse = true});

  final bool shown;
  final Widget child;
  final bool collapse;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final reduceMotion = useReduceMotion();
    final anim = useAnimationController(duration: pp.motion.strip, initialValue: shown ? 1 : 0);
    useEffect(() {
      shown ? anim.forward() : anim.reverse();
      return null;
    }, [shown]);
    useListenable(anim);
    if (anim.isDismissed && collapse) return const SizedBox.shrink();
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
    Widget out = FadeTransition(opacity: curved, child: child);
    if (collapse && !reduceMotion) {
      out = SizeTransition(sizeFactor: curved, alignment: AlignmentDirectional.topStart, child: out);
    }
    return IgnorePointer(ignoring: !shown, child: ExcludeSemantics(excluding: !shown, child: out));
  }
}
