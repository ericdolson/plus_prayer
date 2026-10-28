import 'package:flutter/material.dart';

import '../domain/rules/avatar_cluster.dart';
import '../l10n/app_localizations.dart';
import '../theme/pp_theme.dart';
import 'monogram_avatar.dart';

class ClusterPerson {
  const ClusterPerson({required this.name, required this.initials, required this.tone});

  /// As shown and read: "You", "Dad", "Daniel Kim".
  final String name;
  final String initials;
  final int tone;
}

/// The one avatar cluster (design-direction.md §6, 2026-10-27): grouped,
/// overlapping avatars first, then text that begins with names. You first,
/// then the user's order.
///
///   (●●●●●) You, Dad + 3 are on List 52           up to 5: every avatar, text counts
///   (●●●●+6) You, Dad and others are on List 52   more: 4 avatars + a gray disc
///
/// Thin rings in [surface] separate the overlaps. 24 pt avatars on the card;
/// larger ones (with initials) where there's room, like the invitation.
/// Screen readers hear every name.
class AvatarCluster extends StatelessWidget {
  const AvatarCluster({
    super.key,
    required this.people,
    required this.trailing,
    required this.surface,
    this.style,
    this.avatarSize,
  });

  final List<ClusterPerson> people;

  /// What follows the names: "are on List 52".
  final String trailing;

  /// What the cluster sits on, for the overlap rings.
  final Color surface;
  final TextStyle? style;

  /// Default: `clusterAvatar` (24 pt).
  final double? avatarSize;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pp = context.pp;
    final c = pp.colors;
    final d = avatarSize ?? pp.size.clusterAvatar;
    final layout = layoutCluster(people);
    final step = d * .7;
    final discs = layout.avatars.length + (layout.overflow > 0 ? 1 : 0);

    final named = layout.named;
    final names = switch (named.length) {
      1 => named.single.name,
      _ when layout.overflow > 0 => l10n.clusterAndOthers(named[0].name, named[1].name),
      _ when layout.counted > 0 => l10n.clusterCounted(named[0].name, named[1].name, layout.counted),
      _ => l10n.clusterTwo(named[0].name, named[1].name),
    };

    return Semantics(
      label: '${people.map((p) => p.name).join(', ')} $trailing',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: d + step * (discs - 1),
            height: d,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < layout.avatars.length; i++)
                  PositionedDirectional(
                    start: step * i,
                    child: MonogramAvatar(
                      initials: layout.avatars[i].initials,
                      tone: layout.avatars[i].tone,
                      size: d,
                      ring: true,
                      ringColor: surface,
                    ),
                  ),
                if (layout.overflow > 0)
                  PositionedDirectional(
                    start: step * layout.avatars.length,
                    child: Container(
                      width: d,
                      height: d,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.clusterOverflow,
                        border: Border.all(color: surface, width: d * .07),
                      ),
                      child: Text(
                        l10n.clusterOverflow(layout.overflow),
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        // Scales with the disc, like a monogram's initials.
                        style: context.text.labelMedium!.copyWith(color: c.inkMuted, fontSize: d * .4, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: pp.space.sm),
          Flexible(
            child: Text(
              '$names $trailing',
              style: style ?? context.text.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
