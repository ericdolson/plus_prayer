// Stand-ins so navigation works end to end before the screens are built
// (detail, Today's list, History: build step 5). A back arrow
// and a title — nothing else.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

enum _Kind { subject, todaysList, history }

class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen.subject(String this.subjectId, {super.key}) : _kind = _Kind.subject;
  const PlaceholderScreen.todaysList({super.key})
      : _kind = _Kind.todaysList,
        subjectId = null;
  const PlaceholderScreen.history({super.key})
      : _kind = _Kind.history,
        subjectId = null;

  final _Kind _kind;
  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final title = switch (_kind) {
      _Kind.subject => ref.watch(subjectTreeProvider).value?[subjectId!]?.label ?? '',
      _Kind.todaysList => l10n.todaysList,
      _Kind.history => l10n.history,
    };
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
