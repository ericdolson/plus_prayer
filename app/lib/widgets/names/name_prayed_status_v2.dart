import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../presentation/themes.dart';

class NameListTilePrayedStatus2 extends StatelessWidget {
  final bool prayed;
  final double width;

  const NameListTilePrayedStatus2({super.key, required this.prayed, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedScale(
          scale: prayed ? 0 : 1, duration: 200.ms, child: Center(child: UnprayedDot2(size: 8))),
    );
  }
}

class UnprayedDot2 extends StatelessWidget {
  final double borderSize;
  final double size;

  const UnprayedDot2({super.key, this.borderSize = 0, this.size = 7});

  @override
  Widget build(BuildContext context) {
    final finalSize = size + (borderSize * 2);

    return Container(
      width: finalSize,
      height: finalSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).extension<PPCustomTheme>()!.unprayedColor,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: borderSize,
        ),
      ),
    );
  }
}

class NameScreenPrayedStatus2 extends StatelessWidget {
  final int prayerCount;

  const NameScreenPrayedStatus2({super.key, required this.prayerCount});

  @override
  Widget build(BuildContext context) {
    final didPray = prayerCount > 0;
    final customTheme = Theme.of(context).extension<PPCustomTheme>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!didPray) UnprayedDot2(size: 8),
        if (!didPray) SizedBox(width: 6),
        if (!didPray)
          Text('Unprayed',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: customTheme.unprayedColor,
                  height: 1.2)),
        if (didPray)
          RichText(
              textScaler: MediaQuery.of(context).textScaler,
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: customTheme.infoColor,
                    height: 1.2),
                children: [
                  TextSpan(text: 'Prayed for '),
                  TextSpan(text: '$prayerCount', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' time${prayerCount == 1 ? '' : 's'}'),
                ],
              )),
      ],
    );
  }
}
