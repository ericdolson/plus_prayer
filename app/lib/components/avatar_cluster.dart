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

/// "(●) You, (●) Dad ●●● + 4 others will be on List 53" (screens.md).
/// You first, then carried names in the user's order; the first one or two
/// named beside their avatar, more overlapped up to 5, then "+ N others".
/// Screen readers hear every name, including the ones folded into "+ N".
class AvatarCluster extends StatelessWidget {
  const AvatarCluster({
    super.key,
    required this.people,
    required this.trailing,
    this.style,
    this.maxLines = 2,
  });

  final List<ClusterPerson> people;

  /// What follows the names: "will be on List 53".
  final String trailing;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pp = context.pp;
    final textStyle = style ?? context.text.bodySmall!;
    final avatar = (textStyle.fontSize ?? 13) * 1.45;
    final layout = layoutCluster(people);

    final spans = <InlineSpan>[];
    for (var i = 0; i < layout.named.length; i++) {
      final p = layout.named[i];
      if (i > 0) spans.add(const TextSpan(text: ', '));
      spans
        ..add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: MonogramAvatar(initials: p.initials, tone: p.tone, size: avatar),
        ))
        ..add(TextSpan(text: ' ${p.name}'));
    }
    if (layout.overlapped.isNotEmpty) {
      final step = avatar * .55;
      spans
        ..add(const TextSpan(text: ' '))
        ..add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            width: avatar + step * (layout.overlapped.length - 1),
            height: avatar,
            child: Stack(
              children: [
                for (var i = 0; i < layout.overlapped.length; i++)
                  PositionedDirectional(
                    start: step * i,
                    child: MonogramAvatar(
                      initials: layout.overlapped[i].initials,
                      tone: layout.overlapped[i].tone,
                      size: avatar,
                      ring: true,
                    ),
                  ),
              ],
            ),
          ),
        ));
    }
    if (layout.others > 0) spans.add(TextSpan(text: ' ${l10n.clusterOthers(layout.others)}'));
    spans.add(TextSpan(text: ' $trailing'));

    final spoken = '${people.map((p) => p.name).join(', ')} $trailing';
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(children: spans),
        style: textStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
        selectionColor: pp.colors.primary,
      ),
    );
  }
}
