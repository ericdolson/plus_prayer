import 'package:flutter/material.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';

class LockablePrayIcon extends StatelessWidget {
  final Color color;
  final double opacity;
  final bool selected;
  final double selectedOpacity;
  final double size;

  const LockablePrayIcon(
      {super.key,
      required this.color,
      this.opacity = .2,
      required this.selected,
      this.selectedOpacity = 1,
      this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(PlusPrayer.praying_hands,
            size: size, color: color.withValues(alpha:selected ? selectedOpacity : opacity)),
        Icon(PlusPrayer.praying_hands_outlined_thick, size: size, color: color),
      ],
    );
  }
}
