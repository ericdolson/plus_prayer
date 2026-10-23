import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// "7 of 10" on Your portion (monetization.md). Over-selecting is allowed and
/// shows "17 / 15" with a quiet upgrade mark; saving over the limit invites
/// the upgrade (not this component's job).
class PoolMeter extends StatelessWidget {
  const PoolMeter({super.key, required this.carried, required this.limit});

  final int carried;
  final int limit;

  bool get over => carried > limit;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final fraction = limit <= 0 ? 1.0 : (carried / limit).clamp(0.0, 1.0);
    return Semantics(
      label: over ? l10n.poolMeterOver(carried, limit) : l10n.poolMeter(carried, limit),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pp.size.radiusSm),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 4,
                backgroundColor: pp.colors.hairline,
                color: over ? pp.colors.primary : pp.colors.ink,
              ),
            ),
          ),
          SizedBox(width: pp.space.sm),
          Text(
            over ? l10n.poolMeterOver(carried, limit) : l10n.poolMeter(carried, limit),
            style: context.text.labelMedium?.copyWith(color: over ? pp.colors.primary : pp.colors.inkMuted),
          ),
          if (over) ...[
            SizedBox(width: pp.space.xs),
            Icon(PPIcons.upgrade, size: 14, color: pp.colors.primary),
          ],
        ],
      ),
    );
  }
}
