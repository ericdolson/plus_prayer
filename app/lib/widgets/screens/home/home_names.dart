import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_current_date.dart';
import 'package:plusprayer/hooks/use_names.dart';
import 'package:plusprayer/widgets/names/name_list.dart';

final random = Random();

class HomeNames extends HookWidget {
  final double bottomPadding;
  final bool filterUnprayed;

  const HomeNames({super.key, this.bottomPadding = 0, this.filterUnprayed = false});

  @override
  Widget build(BuildContext context) {
    final currentDateKey = useCurrentDateKey();
    final names = useNames();

    final filteredNames = useMemoized(() {
      if (filterUnprayed) {
        return names.where((name) => name.lastPrayerDate != currentDateKey).toList();
      }
      return names;
    }, [currentDateKey, filterUnprayed, names]);

    return NameList(
            bottomPadding: bottomPadding, filterUnprayed: filterUnprayed, names: filteredNames)
        .animate()
        .fadeIn(duration: 100.ms);
  }
}
