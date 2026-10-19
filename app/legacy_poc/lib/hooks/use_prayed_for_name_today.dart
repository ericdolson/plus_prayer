import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_currentMetrics.dart';
import 'package:plusprayer/hooks/use_current_date.dart';
import 'package:plusprayer/hooks/use_userLastCommunityPrayer.dart';

import '../models/name.dart';

bool usePrayedForNameToday(Name name) {
  final currentDate = useCurrentDateKey();

  final didPrayToday =
      useMemoized(() => (name.lastPrayerDate ?? '') == currentDate, [name.lastPrayerDate, currentDate]);

  return didPrayToday;
}
