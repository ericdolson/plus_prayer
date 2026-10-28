import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// White initials on a bright tone (design-direction.md §1b) (prayer-flow.md: monograms at MVP; the
/// photo slot comes later via `avatarPath`). Decorative to screen readers —
/// the row or cluster around it reads the name. Small discs keep the letters
/// legible (`initialsMinGlyph`): two initials become one, and a disc too
/// small even for one is color only.
class MonogramAvatar extends StatelessWidget {
  const MonogramAvatar({
    super.key,
    required this.initials,
    required this.tone,
    this.size,
    this.ring = false,
    this.ringColor,
  });

  final String initials;

  /// Palette index (`avatarTone`).
  final int tone;
  final double? size;

  /// A thin ring in [ringColor] (default: the ground), for overlapping in a
  /// cluster.
  final bool ring;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final d = size ?? pp.size.avatar;
    final min = pp.size.initialsMinGlyph;
    final letters = initials.characters;
    // Initials scale with the disc, not with the text theme.
    final (String, double)? glyph = letters.length > 1 && d * .36 >= min
        ? (initials, d * .36)
        : letters.isEmpty || min > d * .5
            ? null
            : (letters.first, d * .44 < min ? min : d * .44);
    return ExcludeSemantics(
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pp.colors.avatarTone(tone),
          border: ring ? Border.all(color: ringColor ?? pp.colors.background, width: d * .07) : null,
        ),
        child: glyph == null
            ? null
            : Text(
                glyph.$1,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textScaler: TextScaler.noScaling,
                style: context.text.titleMedium!.copyWith(color: pp.colors.onAvatar, fontSize: glyph.$2, height: 1),
              ),
      ),
    );
  }
}
