import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';

class InPrayerScaffoldWrapper extends HookWidget {
  final Widget child;

  const InPrayerScaffoldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final inPrayer = useInPrayer();

    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: inPrayer.isInPrayer
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary,
            width: 10,
          ),
        ),
        child: child);
  }
}
