// The pinned row for today's list (app-brief §3 Home): the day's wax seal
// (unsealed before publish), "List 52", and who of yours it carries:
//   not yet → "You, Dad ●●● + 4 others are not yet carried on List 53" (muted)
//   prayed  → "… will be on List 53" (soft gold)

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

class ListRow extends ConsumerWidget {
  const ListRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(listRowProvider);
    if (model == null) return const SizedBox.shrink();
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final inPrayer = session.isActive;
    final hold = session.selection.listIncluded ? HoldState.held : HoldState.none;
    final list = model.list;

    final trailing =
        model.prayedWithList ? l10n.carryWillBe(list.nextListNumber) : l10n.carryNotYet(list.nextListNumber);
    final people = [for (final s in model.carried) clusterPerson(s, l10n)];
    final sealLabel = list.isSealed ? l10n.listSealed(list.listNumber) : l10n.listBeingFilmed(list.listNumber);

    void onTap() {
      if (inPrayer) {
        final willHold = !session.selection.listIncluded;
        ref.read(prayerSessionProvider.notifier).toggleList();
        if (willHold) HapticFeedback.lightImpact();
        return;
      }
      context.push(Routes.todaysList);
    }

    final mock = ref.watch(mockBackendProvider);
    return Semantics(
      button: !inPrayer,
      checked: inPrayer ? session.selection.listIncluded : null,
      label: '$sealLabel. ${people.map((p) => p.name).join(', ')} $trailing',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // Dev only: scenario controls for the mock backend.
        onLongPress: kDebugMode && mock != null ? () => showMockControls(context, mock) : null,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: pp.space.gutter, top: pp.space.md, bottom: pp.space.md),
          child: Row(
            children: [
              UnprayedDot(visible: !model.prayedWithList),
              EmberGlow(
                state: hold,
                size: pp.size.seal,
                child: WaxSeal(variant: list.sealVariant, size: pp.size.seal),
              ),
              SizedBox(width: pp.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.listTitle(list.listNumber), style: context.text.titleMedium),
                    SizedBox(height: pp.space.xxs),
                    AvatarCluster(
                      people: people,
                      trailing: trailing,
                      style: context.text.bodySmall?.copyWith(
                        color: model.prayedWithList ? pp.colors.carried : pp.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              EmberCheck(inPrayer: inPrayer, state: hold),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet "List 52 closes in 5 minutes" (only for anyone who hasn't prayed with
/// the list today). Tap to pray with the list.
class ClosingSoonBanner extends ConsumerWidget {
  const ClosingSoonBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(closingSoonMinutesProvider);
    final row = ref.watch(listRowProvider);
    if (minutes == null || row == null) return const SizedBox.shrink();
    final pp = context.pp;
    final session = ref.watch(prayerSessionProvider);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.gutter, vertical: pp.space.xs),
      child: Material(
        color: pp.colors.surface,
        borderRadius: BorderRadius.circular(pp.size.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(pp.size.radiusMd),
          onTap: () {
            final notifier = ref.read(prayerSessionProvider.notifier);
            if (session.isActive) {
              if (!session.selection.listIncluded) notifier.toggleList();
            } else {
              notifier.start(withList: true);
            }
          },
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.lg, vertical: pp.space.md),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: pp.colors.primary),
                SizedBox(width: pp.space.sm),
                Expanded(
                  child: Text(
                    L10n.of(context).closesSoon(row.list.listNumber, minutes),
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
