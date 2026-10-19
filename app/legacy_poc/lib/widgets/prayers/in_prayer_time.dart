import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';

class InPrayerTime extends HookWidget {
  DateTime startTime;

  InPrayerTime({super.key, required this.startTime});

  @override
  Widget build(BuildContext context) {
    final inPrayer = useInPrayer();
    final anim = useSingleTickerProvider();
    final Stopwatch stopwatch = Stopwatch();
  }
}
