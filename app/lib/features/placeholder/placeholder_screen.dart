// Stand-ins so navigation works end to end before the screens are built
// (Today's list, History: build step 5; Your portion: step 6). A back arrow
// and a title — nothing else.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum _Kind { todaysList, history, portion }

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen.todaysList({super.key}) : _kind = _Kind.todaysList;
  const PlaceholderScreen.history({super.key}) : _kind = _Kind.history;
  const PlaceholderScreen.portion({super.key}) : _kind = _Kind.portion;

  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final title = switch (_kind) {
      _Kind.todaysList => l10n.todaysList,
      _Kind.history => l10n.history,
      _Kind.portion => l10n.yourPortion,
    };
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
