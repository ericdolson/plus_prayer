// The community card (design-direction.md §6): a flat tonal surface at the
// top of Home. Scale first, then presence, then two lines about you:
//
//   (seal)  List 52
//           4,345 people · 31,208 prayers
//           ● 258 praying now                 (by the ladder; never 0)
//   (JE) You, (D) Dad ●●● + 3 are on List 52  today's list (hidden if you aren't on it)
//   Pray to carry them onto List 53            tomorrow, from the gate
//
// Held = the card's thin gold border: once you've prayed with the list today
// (your local day), live as soon as it's checked in prayer, cleared at local
// midnight — never by the flip. Tap → Today's list; in prayer the whole card
// is the checkable "hold the list" target.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../app/environment.dart';
import '../../app/router.dart';
import '../../components/avatar_cluster.dart';
import '../../components/marks.dart';
import '../../components/wax_seal.dart';
import '../../domain/models/subject.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/card_carry.dart';
import '../../domain/rules/presence.dart';
import '../../domain/rules/selection.dart';
import '../../hooks/use_reduce_motion.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../dev/mock_controls.dart';

/// "You" for the self; the alias (or name) for everyone else.
ClusterPerson clusterPerson(Subject s, L10n l10n) => ClusterPerson(
      name: s.isSelf ? l10n.clusterYou : s.label,
      initials: monogramOf(s),
      tone: avatarToneOf(s),
    );

class CommunityCard extends HookConsumerWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = useReduceMotion();
    final model = ref.watch(communityCardProvider);
    if (model == null) return const SizedBox.shrink();
    final pp = context.pp;
    final c = pp.colors;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final inPrayer = session.isActive;
    final listHeld = session.selection.listIncluded;
    final presence = ref.watch(presenceLineProvider);
    final closingMinutes = ref.watch(closingSoonMinutesProvider);
    final list = model.list;
    final carry = model.carry;
    final held = model.prayedWithList || (inPrayer && listHeld);

    final people = [for (final s in carry.onToday) clusterPerson(s, l10n)];
    final onTodayText = people.length == 1 && !carry.onToday.single.isSelf
        ? l10n.cardOnListIs(list.listNumber)
        : l10n.cardOnListAre(list.listNumber);
    final next = list.nextListNumber;
    final you = carry.aboutYouOnly;
    final statusText = switch (carry.status) {
      TomorrowStatus.covered => you ? l10n.cardCoveredYou(next) : l10n.cardCovered(next),
      TomorrowStatus.nextPrayerCarries => you ? l10n.cardNextPrayerYou(next) : l10n.cardNextPrayer(next),
      TomorrowStatus.prayToCarry => you ? l10n.cardPrayToBe(next) : l10n.cardPrayToCarry(next),
    };
    String? named(List<Subject> names, String Function(String, int, int) line) =>
        names.isEmpty ? null : line(names.first.label, names.length - 1, next);
    // Joining is only true once tomorrow is earned.
    final joinsText = carry.status == TomorrowStatus.covered ? named(carry.joining, l10n.cardJoins) : null;
    final notCarriedText = named(carry.notCarried, l10n.cardNotCarried);

    final sealLabel = list.isSealed ? l10n.listSealed(list.listNumber) : l10n.listBeingFilmed(list.listNumber);
    final scale = l10n.listScale(list.soulCount, list.prayerCount);
    final presenceText = switch (presence?.window) {
      PresenceWindow.now => l10n.presenceNow(presence!.count),
      PresenceWindow.lastHour => l10n.presenceLastHour(presence!.count),
      PresenceWindow.today => l10n.presenceToday(presence!.count),
      null => null,
    };
    final closingText = closingMinutes == null ? null : l10n.closesSoon(list.listNumber, closingMinutes);

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
    final glow = reduceMotion ? null : c.heldGlow;
    final quiet = context.text.bodySmall;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
      child: Semantics(
        button: !inPrayer,
        checked: inPrayer ? listHeld : null,
        label: [
          sealLabel,
          scale,
          if (presenceText != null) presenceText,
          if (people.isNotEmpty) '${people.map((p) => p.name).join(', ')} $onTodayText',
          statusText,
          if (joinsText != null) joinsText,
          if (notCarriedText != null) notCarriedText,
          if (closingText != null) closingText,
        ].join('. '),
        excludeSemantics: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: held ? 1 : 0),
          duration: reduceMotion ? pp.motion.quick : pp.motion.settle,
          curve: Curves.easeOut,
          builder: (context, t, child) => DecoratedBox(
            // Dark mode only: a soft outer glow under the border.
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: glow == null || t == 0
                  ? null
                  : [BoxShadow(color: glow.withValues(alpha: glow.a * t), blurRadius: pp.space.lg)],
            ),
            child: Material(
              color: c.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: c.heldGold.withValues(alpha: .75 * t), width: pp.size.cardBorder),
              ),
              child: child,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            // Dev only: scenario controls for the mock backend.
            onLongPress: kDebugMode && mock != null ? () => showMockControls(context, mock) : null,
            child: Padding(
              padding: EdgeInsets.all(pp.space.inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WaxSeal(variant: list.sealVariant, size: pp.size.seal),
                      SizedBox(width: pp.space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.listTitle(list.listNumber), style: context.text.titleMedium),
                            SizedBox(height: pp.space.xxs),
                            Text(scale, style: quiet),
                            if (presenceText != null) ...[
                              SizedBox(height: pp.space.xxs),
                              _Presence(text: presenceText, live: presence!.window == PresenceWindow.now),
                            ],
                          ],
                        ),
                      ),
                      PrayerCheck(inPrayer: inPrayer, state: listHeld ? HoldState.held : HoldState.none),
                    ],
                  ),
                  SizedBox(height: pp.space.lg),
                  if (people.isNotEmpty) ...[
                    AvatarCluster(people: people, trailing: onTodayText, surface: c.cardSurface, style: quiet),
                    SizedBox(height: pp.space.xs),
                  ],
                  Text(statusText, style: quiet?.copyWith(color: c.ink)),
                  if (joinsText != null) ...[
                    SizedBox(height: pp.space.xs),
                    Text(joinsText, style: quiet),
                  ],
                  // Build step 6: tap → Your portion.
                  if (notCarriedText != null) ...[
                    SizedBox(height: pp.space.xs),
                    Text(notCarriedText, style: quiet),
                  ],
                  if (closingText != null) ...[
                    SizedBox(height: pp.space.md),
                    Row(
                      children: [
                        Icon(PPIcons.clock, size: pp.size.rowIcon, color: c.ink),
                        SizedBox(width: pp.space.sm),
                        Expanded(child: Text(closingText, style: quiet?.copyWith(color: c.ink))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "● 258 praying now": the dot only when it's live.
class _Presence extends StatelessWidget {
  const _Presence({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Row(
      children: [
        if (live) ...[
          Container(
            width: pp.size.liveDot,
            height: pp.size.liveDot,
            decoration: BoxDecoration(shape: BoxShape.circle, color: pp.colors.ink),
          ),
          SizedBox(width: pp.space.xs + pp.space.xxs),
        ],
        Flexible(child: Text(text, style: context.text.bodySmall)),
      ],
    );
  }
}
