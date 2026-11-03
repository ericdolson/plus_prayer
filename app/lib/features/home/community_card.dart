// The community card (design-direction.md §6, 2026-11-02): two questions at a
// glance — is the list alive (the world), and are my people going onto the
// next list (you).
//
//   ▓▓▓▓▓▓   List 52                          the day's seal, ~104 pt,
//   ▓ seal ▓  4,345 people · 3,881 prayers    cropped into the corner
//   ▓▓▓▓     ● 239 praying now
//   (E)(D)(M)(D)(A)(R)(J)(K)(L)(B)            your carried people, filling
//   Pray to carry them onto List 53           the width; the status below
//
// Long text never shrinks or ends in "…": the status wraps, the counts wrap
// at the middle dot, the presence marker hides first, and at accessibility
// sizes the world block moves below the stamp.
//
// Held = the same gold ring as a held name (2 pt, 2 pt gap, same fade and
// bloom), around the card: once you've prayed with the list today (your local
// day), live as soon as it's checked in prayer, cleared at local midnight —
// never by the flip. Tap → Today's list; in prayer the whole card
// is the checkable "hold the list" target.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/environment.dart';
import '../../app/router.dart';
import '../../components/avatar_cluster.dart';
import '../../components/count_text.dart';
import '../../components/marks.dart';
import '../../components/monogram_avatar.dart';
import '../../components/wax_seal.dart';
import '../../domain/models/subject.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/card_carry.dart';
import '../../domain/rules/presence.dart';
import '../../domain/rules/selection.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../theme/pp_theme.dart';
import '../dev/mock_controls.dart';

/// "You" for the self; the alias (or name) for everyone else.
ClusterPerson clusterPerson(Subject s, L10n l10n) => ClusterPerson(
      name: s.isSelf ? l10n.clusterYou : s.label,
      initials: monogramOf(s),
      tone: avatarToneOf(s),
    );

class CommunityCard extends ConsumerWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final model = ref.watch(communityCardProvider);
    final session = ref.watch(prayerSessionProvider);
    final inPrayer = session.isActive;
    final listHeld = session.selection.listIncluded;
    if (model == null) return const SizedBox.shrink();
    final held = model.prayedWithList || (inPrayer && listHeld);
    final c = pp.colors;
    final l10n = L10n.of(context);
    // In prayer the pill already shows "with N".
    final presence = inPrayer ? null : ref.watch(presenceLineProvider);
    final closingMinutes = ref.watch(closingSoonMinutesProvider);
    final list = model.list;
    final carry = model.carry;

    final next = list.nextListNumber;
    final you = carry.aboutYouOnly;
    final statusText = switch (carry.status) {
      TomorrowStatus.covered => you ? l10n.cardCoveredYou(next) : l10n.cardCovered(next),
      TomorrowStatus.nextPrayerCarries => you ? l10n.cardNextPrayerYou(next) : l10n.cardNextPrayer(next),
      TomorrowStatus.prayToCarry => you ? l10n.cardPrayToBe(next) : l10n.cardPrayToCarry(next),
    };
    // The closing notice replaces the status line; it never adds one.
    final lineText = closingMinutes == null
        ? statusText
        : you
            ? l10n.closesSoonYou(list.listNumber, closingMinutes, next)
            : l10n.closesSoon(list.listNumber, closingMinutes);
    // Always shown: you're always carried.
    final people = [for (final s in carry.carried) clusterPerson(s, l10n)];

    final sealLabel = list.isSealed ? l10n.listSealed(list.listNumber) : l10n.listBeingFilmed(list.listNumber);
    // (shown, spoken): only the last-hour rung has a shorter shown form.
    final (String, String)? presenceText = switch (presence?.window) {
      PresenceWindow.now => (l10n.presenceNow(presence!.count), l10n.presenceNow(presence.count)),
      PresenceWindow.lastHour => (l10n.presenceShortLastHour(presence!.count), l10n.presenceLastHour(presence.count)),
      PresenceWindow.today => (l10n.presenceToday(presence!.count), l10n.presenceToday(presence.count)),
      null => null,
    };

    void onTap() {
      if (inPrayer) {
        ref.read(prayerSessionProvider.notifier).toggleList();
        // The check is a moment: one light haptic; letting go is silent.
        if (!listHeld) HapticFeedback.lightImpact();
        return;
      }
      context.push(Routes.todaysList);
    }

    final mock = ref.watch(mockBackendProvider);
    final radius = BorderRadius.circular(pp.size.radiusCard);
    final quiet = context.text.bodySmall!;
    // Wraps rather than cut off ("List 53" is one unbreakable word). Ink while
    // it asks something of you; muted once covered (the gold border
    // celebrates).
    final covered = closingMinutes == null && carry.status == TomorrowStatus.covered;
    final line = Text(lineText, style: quiet.copyWith(color: covered ? c.inkMuted : c.ink));
    // The stamp's visible part, measured from the card's edges.
    final stampVisibleX = pp.size.cardStamp - pp.size.cardStampOffsetX;
    final stampVisibleY = pp.size.cardStamp - pp.size.cardStampOffsetY;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
      child: Semantics(
        button: !inPrayer,
        checked: inPrayer ? listHeld : null,
        label: [
          sealLabel,
          l10n.listScale(list.soulCount, list.prayerCount),
          if (presenceText != null) presenceText.$2,
          people.map((p) => p.name).join(', '),
          lineText,
        ].join('. '),
        excludeSemantics: true,
        // The same held mark as a name's avatar: 2 pt crisp gold, 2 pt gap, the
        // same fade and bloom.
        child: HeldRing(
          held: held,
          borderRadius: radius,
          child: Material(
            color: c.cardSurface,
            borderRadius: radius,
            // The corner crops the stamp.
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              // Dev only: scenario controls for the mock backend.
              onLongPress: kDebugMode && mock != null ? () => showMockControls(context, mock) : null,
              child: Stack(
                children: [
                  PositionedDirectional(
                    start: -pp.size.cardStampOffsetX,
                    top: -pp.size.cardStampOffsetY,
                    child: WaxSeal(variant: list.sealVariant, size: pp.size.cardStamp),
                  ),
                  Padding(
                    padding: EdgeInsets.all(pp.space.inset),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final indent = stampVisibleX - pp.space.inset + pp.space.md;
                        final world = _World(
                          title: l10n.listTitle(list.listNumber),
                          people: list.soulCount,
                          prayers: list.prayerCount,
                          check: inPrayer
                              ? PrayerCheck(inPrayer: inPrayer, state: listHeld ? HoldState.held : HoldState.none)
                              : null,
                          presence: presenceText == null
                              ? null
                              : _Presence(text: presenceText.$1, live: presence!.window == PresenceWindow.now),
                        );
                        final beside = _World.fitsBeside(
                          context,
                          width: box.maxWidth - indent,
                          title: l10n.listTitle(list.listNumber),
                          people: list.soulCount,
                          prayers: list.prayerCount,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (beside)
                              // Tall enough that the you block starts below the stamp.
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: stampVisibleY - pp.space.inset),
                                child: Padding(padding: EdgeInsetsDirectional.only(start: indent), child: world),
                              )
                            else ...[
                              // Accessibility sizes: below the stamp, full width.
                              SizedBox(height: stampVisibleY - pp.space.inset + pp.space.md),
                              world,
                            ],
                            SizedBox(height: pp.space.md),
                            if (people.length == 1)
                              // A single avatar (e.g. only you): the status beside it.
                              Row(
                                children: [
                                  MonogramAvatar(
                                    initials: monogramOf(carry.carried.single),
                                    tone: avatarToneOf(carry.carried.single),
                                    size: pp.size.cardAvatar,
                                  ),
                                  SizedBox(width: pp.space.sm),
                                  Expanded(child: line),
                                ],
                              )
                            else ...[
                              AvatarRow(
                                people: people,
                                surface: c.cardSurface,
                                avatarSize: pp.size.cardAvatar,
                                overlap: pp.size.cardAvatarOverlap,
                              ),
                              SizedBox(height: pp.space.sm),
                              line,
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The world block: three left-aligned lines — "List 52", the counts, and
/// presence (hidden when it doesn't fit, and in prayer). In prayer the
/// title row ends in the check.
class _World extends StatelessWidget {
  const _World({required this.title, required this.people, required this.prayers, this.check, this.presence});

  final String title;
  final int people;
  final int prayers;
  final Widget? check;
  final Widget? presence;

  /// Whether the block fits beside the stamp in [width] without breaking the
  /// title or either count apart (they may still wrap at the middle dot).
  static bool fitsBeside(
    BuildContext context, {
    required double width,
    required String title,
    required int people,
    required int prayers,
  }) {
    final l10n = L10n.of(context);
    final counts = _Counts.style(context);
    return width > 0 &&
        _lineWidth(context, title, context.text.titleMedium!) <= width &&
        _lineWidth(context, l10n.listPeople(people), counts) <= width &&
        _lineWidth(context, l10n.listPrayers(prayers), counts) <= width;
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // The title at its natural width (wrapping only if it's wider than
            // the whole block); the check gets what's left.
            final style = context.text.titleMedium!;
            final titleWidth = math.min(_lineWidth(context, title, style), box.maxWidth);
            final rest = box.maxWidth - titleWidth - pp.space.sm;
            return Row(
              children: [
                SizedBox(width: titleWidth, child: Text(title, style: style)),
                if (check != null && rest > 0) ...[
                  SizedBox(width: pp.space.sm),
                  SizedBox(
                    width: rest,
                    child: Align(alignment: AlignmentDirectional.centerEnd, child: check),
                  ),
                ],
              ],
            );
          },
        ),
        SizedBox(height: pp.space.xxs),
        _Counts(people: people, prayers: prayers),
        if (presence != null) ...[
          SizedBox(height: pp.space.xxs),
          presence!,
        ],
      ],
    );
  }
}

/// The width [text] takes on one line, at the user's text size.
double _lineWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// "4,345 people · 3,881 prayers": numbers in ink with tabular figures (only
/// changed digits crossfade), words in inkMuted, a thin middle dot with a
/// little extra space. When both don't fit on one line, they wrap at the dot:
/// people and prayers on separate lines, no dot.
class _Counts extends StatelessWidget {
  const _Counts({required this.people, required this.prayers});

  final int people;
  final int prayers;

  static TextStyle style(BuildContext context) =>
      context.text.bodySmall!.copyWith(color: context.pp.colors.inkMuted);

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final words = style(context);
    final numbers = words.copyWith(color: pp.colors.ink);
    final format = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final peopleText = l10n.listPeople(people);
    final prayersText = l10n.listPrayers(prayers);
    final gap = pp.space.sm;
    final peopleLine = Text.rich(countSpan(peopleText, format.format(people), style: words, numberStyle: numbers));
    final prayersLine = Text.rich(countSpan(prayersText, format.format(prayers), style: words, numberStyle: numbers));
    return LayoutBuilder(
      builder: (context, box) {
        final oneLine = _lineWidth(context, peopleText, words) +
                _lineWidth(context, l10n.countsSeparator, words) +
                gap * 2 +
                _lineWidth(context, prayersText, words) <=
            box.maxWidth;
        if (!oneLine) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [peopleLine, prayersLine]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            peopleLine,
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: gap),
              child: Text(l10n.countsSeparator, style: words),
            ),
            prayersLine,
          ],
        );
      },
    );
  }
}

/// "● 239 praying now": the dot only when it's live. Shown only if it fits
/// the line whole (never a cut-off number).
class _Presence extends StatelessWidget {
  const _Presence({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final style = context.text.bodySmall!.copyWith(color: pp.colors.inkMuted);
    final dot = live ? pp.size.liveDot + pp.space.xs + pp.space.xxs : 0.0;
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final fits = painter.width + dot <= box.maxWidth;
        painter.dispose();
        if (!fits) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              Container(
                width: pp.size.liveDot,
                height: pp.size.liveDot,
                decoration: BoxDecoration(shape: BoxShape.circle, color: pp.colors.ink),
              ),
              SizedBox(width: pp.space.xs + pp.space.xxs),
            ],
            Text(text, maxLines: 1, style: style),
          ],
        );
      },
    );
  }
}
