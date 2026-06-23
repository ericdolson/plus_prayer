import 'package:flutter/material.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/widgets/framework/two_tone_icon.dart';

class TwoTonePrayIcon extends StatelessWidget {
  final Color color;
  final double opacity;
  final bool selected;
  final double selectedOpacity;
  final double size;

  const TwoTonePrayIcon(
      {super.key,
      required this.color,
      this.opacity = 0.2,
      required this.selected,
      this.selectedOpacity = 1,
      this.size = 24});

  @override
  Widget build(BuildContext context) {
    return TwoToneIcon(
        backgroundColor: color.withValues(alpha:selected ? selectedOpacity : opacity),
        color: color,
        icon: PlusPrayer.praying_hands,
        outlinedIcon: PlusPrayer.praying_hands_outlined_thick,
        size: size);

    return Stack(
      children: [
        Icon(PlusPrayer.praying_hands,
            size: size, color: color.withValues(alpha:selected ? selectedOpacity : opacity)),
        Icon(PlusPrayer.praying_hands_outlined_thick, size: size, color: color),
      ],
    );
  }
}
