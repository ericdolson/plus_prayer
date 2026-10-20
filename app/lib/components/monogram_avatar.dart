import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// Initials on a muted, antique tone (prayer-flow.md: monograms at MVP; the
/// photo slot comes later via `avatarPath`). Decorative to screen readers —
/// the row or cluster around it reads the name.
class MonogramAvatar extends StatelessWidget {
  const MonogramAvatar({
    super.key,
    required this.initials,
    required this.tone,
    this.size,
    this.ring = false,
  });

  final String initials;

  /// Palette index (`avatarTone`).
  final int tone;
  final double? size;

  /// A thin ground-colored ring, for overlapping in a cluster.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final d = size ?? pp.size.avatar;
    return ExcludeSemantics(
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pp.colors.avatarTone(tone),
          border: ring ? Border.all(color: pp.colors.background, width: d * .07) : null,
        ),
        child: Text(
          initials,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textScaler: TextScaler.noScaling,
          // Initials scale with the disc, not with the text theme.
          style: context.text.titleMedium!.copyWith(
            fontSize: d * (initials.length > 1 ? .36 : .44),
            height: 1,
          ),
        ),
      ),
    );
  }
}
