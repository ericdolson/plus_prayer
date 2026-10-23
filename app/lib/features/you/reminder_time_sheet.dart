// Picks a reminder's time: a wheel in the display serif, then Done.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../domain/models/reminder.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/pp_theme.dart';

/// The chosen time, or null when dismissed.
Future<ClockTime?> showReminderTimeSheet(BuildContext context, {required String title, required ClockTime initial}) =>
    showModalBottomSheet<ClockTime>(
      context: context,
      builder: (_) => _ReminderTimeSheet(title: title, initial: initial),
    );

class _ReminderTimeSheet extends HookWidget {
  const _ReminderTimeSheet({required this.title, required this.initial});

  final String title;
  final ClockTime initial;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final picked = useState(initial);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(pp.space.xl, 0, pp.space.xl, pp.space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: pp.space.sm),
            SizedBox(
              height: pp.size.wheelPicker,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: pp.colors.brightness,
                  textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: context.text.headlineSmall),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                  initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
                  onDateTimeChanged: (t) => picked.value = ClockTime(t.hour, t.minute),
                ),
              ),
            ),
            SizedBox(height: pp.space.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context, picked.value),
              child: Text(L10n.of(context).done),
            ),
          ],
        ),
      ),
    );
  }
}
