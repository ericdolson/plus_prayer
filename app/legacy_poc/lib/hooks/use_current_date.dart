import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../utils/date_utils.dart';

DateTime useCurrentDate() {
  useListenable(_currentDate);

  return _currentDate.date;
}

String useCurrentDateKey() {
  useListenable(_currentDate);
  var dateKey = useMemoized(() {
    return makeDateKey(_currentDate.date);
  }, [_currentDate.date]);

  return dateKey;
}

class _CurrentDate extends ChangeNotifier {
  late DateTime date;

  _CurrentDate() {
    var now = DateTime.now();
    date = now;

    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    // Set a timer to update the date at midnight
    Timer(durationUntilMidnight, () {
      date = DateTime.now();
      notifyListeners();

      // After the initial timer, update the date every 24 hours
      Timer.periodic(Duration(days: 1), (_) {
        date = DateTime.now();
        notifyListeners();
      });
    });
  }
}

var _currentDate = _CurrentDate();