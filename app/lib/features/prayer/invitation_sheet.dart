// The Amen invitation (prayer-flow.md, app-brief §3): Amen without the list,
// when the user hasn't prayed with it today, opens a standalone, quiet
// invitation — "Hold the 4,345 on List 52 in your prayer" — and who'll be
// carried. Tap → the same 5 s ring, seconds counting up, copy shifts to
// "Holding the 4,345 on List 52"; Amen appears after 5 s and they may stay
// longer. It extends the same prayer. Amen before tapping finishes without it.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/avatar_cluster.dart';
import '../../components/ring_button.dart';
import '../../components/wax_seal.dart';
import '../../hooks/use_elapsed.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';
import '../home/community_card.dart';

Future<void> showInvitationSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (_) => const InvitationSheet(),
    );

class InvitationSheet extends HookConsumerWidget {
  const InvitationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final notifier = ref.read(prayerSessionProvider.notifier);
    final model = ref.watch(communityCardProvider);
    final config = ref.watch(configProvider);
    final clock = ref.watch(clockProvider);
    final holdingSince = session.listHoldingSince;
    final elapsed = useElapsed(holdingSince, clock: clock);

    ref.listen(prayerSessionProvider.select((s) => s.phase), (_, phase) {
      if (phase != PrayerPhase.invitation && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    if (model == null) return const SizedBox.shrink();
    final list = model.list;
    final holding = holdingSince != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(pp.space.xl, pp.space.xxl, pp.space.xl, pp.space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaxSeal(variant: list.sealVariant, size: pp.size.seal * 1.3),
            SizedBox(height: pp.space.xl),
            Semantics(
              liveRegion: true,
              child: Text(
                holding
                    ? l10n.invitationHolding(list.soulCount, list.listNumber)
                    : l10n.invitationHold(list.soulCount, list.listNumber),
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
            ),
            SizedBox(height: pp.space.md),
            AvatarCluster(
              people: [for (final s in model.carried) clusterPerson(s, l10n)],
              trailing: l10n.carryWillBe(list.nextListNumber),
              style: context.text.bodyMedium?.copyWith(color: pp.colors.heldGoldText),
              surface: pp.colors.sheet,
              avatarSize: pp.size.clusterAvatarLarge,
              centered: true,
            ),
            SizedBox(height: pp.space.xxl),
            RingButton(
              key: ValueKey(holding),
              startedAt: holdingSince,
              duration: config.minPrayer,
              clock: clock,
              semanticLabel: holding ? l10n.amen : l10n.invitationHold(list.soulCount, list.listNumber),
              onPressed: holding ? notifier.amenFromInvitation : notifier.holdList,
              complete: holding ? Text(l10n.amen) : null,
              child: holding
                  ? Text('${elapsed.inSeconds}', style: context.text.titleLarge?.copyWith(color: pp.colors.primary))
                  : WaxSeal(variant: list.sealVariant, size: pp.size.seal * .8),
            ),
            SizedBox(height: pp.space.lg),
            // Finish without the list (only before tapping in).
            AnimatedOpacity(
              opacity: holding ? 0 : 1,
              duration: pp.motion.settle,
              child: TextButton(
                onPressed: holding ? null : notifier.amenFromInvitation,
                child: Text(l10n.amen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
