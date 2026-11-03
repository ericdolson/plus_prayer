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
/// Text that won't fit on one line beside the avatars runs full-width below
/// them instead (2026-10-28), so "List 52" never wraps beside the cluster.
/// Screen readers hear every name.
class AvatarCluster extends StatelessWidget {
  const AvatarCluster({
    super.key,
    required this.people,
    required this.trailing,
    required this.surface,
    this.style,
    this.avatarSize,
    this.centered = false,
  });

  final List<ClusterPerson> people;

  /// What follows the names: "are on List 52".
  final String trailing;

  /// What the cluster sits on, for the overlap rings.
  final Color surface;
  final TextStyle? style;

  /// Default: `clusterAvatar` (24 pt).
  final double? avatarSize;

  /// Center the avatars and text when the text runs below (the invitation).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pp = context.pp;
    final d = avatarSize ?? pp.size.clusterAvatar;
    final layout = layoutCluster(people);
    final step = d * _overlap;
    final discs = layout.avatars.length + (layout.overflow > 0 ? 1 : 0);

    final named = layout.named;
    final names = switch (named.length) {
      1 => named.single.name,
      _ when layout.overflow > 0 => l10n.clusterAndOthers(named[0].name, named[1].name),
      _ when layout.counted > 0 => l10n.clusterCounted(named[0].name, named[1].name, layout.counted),
      _ => l10n.clusterTwo(named[0].name, named[1].name),
    };

    final text = '$names $trailing';
    final textStyle = style ?? context.text.bodySmall;
    final avatarsWidth = d + step * (discs - 1);
    final avatars = _Discs(people: layout.avatars, overflow: layout.overflow, size: d, surface: surface);

    return Semantics(
      label: '${people.map((p) => p.name).join(', ')} $trailing',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final beside = box.maxWidth - avatarsWidth - pp.space.sm;
          final painter = TextPainter(
            text: TextSpan(text: text, style: textStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout(maxWidth: beside > 0 ? beside : 0);
          final fits = beside > 0 && !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatars,
                SizedBox(width: pp.space.sm),
                Flexible(child: Text(text, style: textStyle, maxLines: 1))
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              avatars,
              SizedBox(height: pp.space.xs),
              Text(
                text,
                style: textStyle,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The community card's avatar row (design-direction.md §6, 2026-11-02): your
/// carried people filling the width, the "+N" disc only when they don't fit
/// (measured). Screen readers hear every name.
class AvatarRow extends StatelessWidget {
  const AvatarRow({
    super.key,
    required this.people,
    required this.surface,
    required this.avatarSize,
    required this.overlap,
  });

  final List<ClusterPerson> people;
  final Color surface;
  final double avatarSize;

  /// How far each disc overlaps the last, in points.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final d = avatarSize;
    return Semantics(
      label: people.map((p) => p.name).join(', '),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final fill = fillRow(people.length, discCapacity(box.maxWidth, d, d - overlap));
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Discs(
              people: people.take(fill.shown).toList(),
              overflow: fill.overflow,
              size: d,
              surface: surface,
              step: d - overlap,
            ),
          );
        },
      ),
    );
  }
}

/// Each disc starts this far (× its size) after the last.
const _overlap = .7;

/// Overlapping avatars, then the "+N" disc. Thin rings in [surface] separate
/// the overlaps.
class _Discs extends StatelessWidget {
  const _Discs({
    required this.people,
    required this.overflow,
    required this.size,
    required this.surface,
    this.step,
  });

  final List<ClusterPerson> people;
  final int overflow;
  final double size;
  final Color surface;

  /// From one disc's start to the next; default ×[_overlap] of the size.
  final double? step;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final d = size;
    final step = this.step ?? d * _overlap;
    final discs = people.length + (overflow > 0 ? 1 : 0);
    return SizedBox(
      width: discs == 0 ? 0 : d + step * (discs - 1),
      height: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < people.length; i++)
            PositionedDirectional(
              start: step * i,
              child: MonogramAvatar(
                initials: people[i].initials,
                tone: people[i].tone,
                size: d,
                ring: true,
                ringColor: surface,
              ),
            ),
          if (overflow > 0)
            PositionedDirectional(
              start: step * people.length,
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
                  L10n.of(context).clusterOverflow(overflow),
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  // Scales with the disc, like a monogram's initials.
                  style: context.text.labelMedium!.copyWith(color: c.inkMuted, fontSize: d * .4, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
