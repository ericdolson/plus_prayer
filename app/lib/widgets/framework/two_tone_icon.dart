import 'package:flutter/material.dart';

class TwoToneIcon extends StatelessWidget {
  final Color backgroundColor;
  final Color color;
  final IconData icon;
  final IconData outlinedIcon;
  final double size;

  const TwoToneIcon(
      {super.key,
      required this.backgroundColor,
      required this.color,
      required this.icon,
      required this.outlinedIcon,
      this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(icon, color: backgroundColor, size: size),
        Icon(outlinedIcon, color: color, size: size),
      ],
    );
  }
}
