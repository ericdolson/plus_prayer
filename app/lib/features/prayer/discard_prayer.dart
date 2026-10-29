// Cancel in prayer (design-direction.md §4): under ~30 s the prayer is discarded at
// once; past that, "Discard this prayer?" [Keep praying] [Discard].

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/prayer_session.dart';
import '../../state/providers.dart';

Future<void> discardPrayer(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(prayerSessionProvider.notifier);
  if (!notifier.shouldConfirmDiscard(ref.read(clockProvider)())) return notifier.cancel();
  final l10n = L10n.of(context);
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.discardPrayerQuestion),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.keepPraying)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.discard)),
      ],
    ),
  );
  if (discard ?? false) await notifier.cancel();
}
