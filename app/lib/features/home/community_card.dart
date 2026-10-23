// The community card (design-direction.md §6; formerly the pinned list row):
// a flat tonal surface at the top of Home. Scale first, then presence, then
// your carry status with the avatar cluster:
//
//   (seal)  List 52
//           4,345 people · 31,208 prayers
//           ● 258 praying now                 (by the ladder; never 0)
//   (JE) You, (D) Dad ●●● + 3 not yet carried on List 53
//
// After praying with the list, the cluster lights up gold and the line becomes
// "will be on List 53". Tap → Today's list; in prayer the whole card is the
// checkable "hold the list" target.

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
import '../../domain/rules/presence.dart';
import '../../domain/rules/selection.dart';
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

class CommunityCard extends ConsumerWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final carry = model.prayedWithList ? l10n.carryWillBe(list.nextListNumber) : l10n.carryNotYet(list.nextListNumber);
    final people = [for (final s in model.carried) clusterPerson(s, l10n)];
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
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter),
      child: Semantics(
        button: !inPrayer,
        checked: inPrayer ? listHeld : null,
        label: [
          sealLabel,
          scale,
          if (presenceText != null) presenceText,
          '${people.map((p) => p.name).join(', ')} $carry',
          if (closingText != null) closingText,
        ].join('. '),
        excludeSemantics: true,
        child: Material(
          color: c.cardSurface,
          borderRadius: radius,
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
                      HeldRing(
                        held: listHeld,
                        diameter: pp.size.seal,
                        child: WaxSeal(variant: list.sealVariant, size: pp.size.seal),
                      ),
                      SizedBox(width: pp.space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.listTitle(list.listNumber), style: context.text.titleMedium),
                            SizedBox(height: pp.space.xxs),
                            Text(scale, style: context.text.bodySmall),
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
                  AvatarCluster(
                    people: people,
                    trailing: carry,
                    held: model.prayedWithList,
                    surface: c.cardSurface,
                    style: context.text.bodySmall?.copyWith(color: model.prayedWithList ? c.ink : c.inkMuted),
                  ),
                  if (closingText != null) ...[
                    SizedBox(height: pp.space.md),
                    Row(
                      children: [
                        Icon(PPIcons.clock, size: pp.size.rowIcon, color: c.ink),
                        SizedBox(width: pp.space.sm),
                        Expanded(child: Text(closingText, style: context.text.bodySmall?.copyWith(color: c.ink))),
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
