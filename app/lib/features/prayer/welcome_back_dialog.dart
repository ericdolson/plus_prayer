// Back after the resume window (prayer-flow.md): "Welcome back. Finish your
// prayer from 7:42?" [Amen] [Discard]. Duration runs until they left + up to
// 30 min. Never an automatic choice.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../state/prayer_session.dart';

Future<void> showWelcomeBackDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WelcomeBackDialog(),
    );

class WelcomeBackDialog extends ConsumerWidget {
  const WelcomeBackDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final startedAt = ref.watch(prayerSessionProvider.select((s) => s.startedAt));
    final notifier = ref.read(prayerSessionProvider.notifier);
    final time = startedAt == null
        ? ''
        : DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(startedAt.toLocal());

    Future<void> choose(Future<void> Function() action) async {
      Navigator.of(context).pop();
      await action();
    }

    return AlertDialog(
      content: Text(l10n.welcomeBackFinish(time)),
      actions: [
        TextButton(onPressed: () => choose(notifier.welcomeBackDiscard), child: Text(l10n.discard)),
        FilledButton(onPressed: () => choose(notifier.welcomeBackAmen), child: Text(l10n.amen)),
      ],
    );
  }
}
