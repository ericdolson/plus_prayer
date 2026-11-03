import 'package:flutter/material.dart';

import '../domain/rules/streak.dart';
import '../l10n/app_localizations.dart';
import '../theme/pp_theme.dart';
import 'wax_seal.dart';

/// Header streak badge (streaks-reminders.md, design-direction.md §4): a
/// neutral pewter seal and the number, which carries the state.
/// Prayed with the list today → seal + N in ink; alive → seal one step dimmer
/// + N in inkMuted; zero → dim seal, no number (never "0"). Always tappable.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.state,
    required this.days,
    this.onTap,
  });

  final StreakBadgeState state;
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final showNumber = state != StreakBadgeState.none && days > 0;
    return Semantics(
      button: true,
      label: L10n.of(context).streakBadge(showNumber ? days : 0),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.sm, vertical: pp.space.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PewterSeal(size: pp.size.badgeSeal, dimmed: state != StreakBadgeState.sealedToday),
              if (showNumber) ...[
                SizedBox(width: pp.space.xs),
                Text(
                  '$days',
                  style: context.text.labelLarge?.copyWith(
                    color: state == StreakBadgeState.sealedToday ? pp.colors.ink : pp.colors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
