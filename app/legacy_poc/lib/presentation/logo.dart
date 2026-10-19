import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/themes.dart';

class PlusPrayerLogoText extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const PlusPrayerLogoText({
    super.key,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text('+Prayer',
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.primary,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Baloo2',
        ));
  }
}

class PlusPrayerLogoTextOld extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const PlusPrayerLogoTextOld({
    super.key,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w900,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: PlusPrayerLogoTextSpan(
      context: context,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ));
  }
}

TextSpan PlusPrayerLogoTextSpan({
  required BuildContext context,
  required double fontSize,
  FontWeight fontWeight = FontWeight.w900,
  Color? color,
}) {
  return TextSpan(
    style: TextStyle(
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Roca',
    ),
    children: const [
      TextSpan(text: '+Pra'),
      TextSpan(
        text: 'y',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
      TextSpan(text: 'er'),
    ],
  );
}

class PPPPIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color iconColor;
  final double iconScale;
  late double outlineScale;
  late Color outlineColor;

  PPPPIcon({
    super.key,
    this.color = Colors.transparent,
    this.iconColor = Colors.black,
    this.iconScale = .6,
    this.size = 30,
  }) {
    outlineColor = Colors.transparent;
    outlineScale = 0;
  }

  PPPPIcon.outlined({
    super.key,
    this.color = Colors.white,
    this.iconColor = Colors.black,
    this.iconScale = .6,
    Color? outlineColor,
    this.outlineScale = .05,
    this.size = 30,
  }) {
    this.outlineColor = outlineColor ?? iconColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: outlineColor,
          width: size * outlineScale,
        ),
      ),
      child: Center(
        child: Icon(
          PlusPrayer.plus_dots_list,
          color: iconColor,
          size: size * iconScale,
          // shadows: [
            // Shadow(
            //   color: Theme.of(context).colorScheme.primary.withValues(alpha:.5),
            //   offset: const Offset(0, 0),
            //   blurRadius: size * .4,
            // ),
            // Shadow(
            //   color: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor,
            //   offset: Offset(2, 2),
            //   blurRadius: 0,
            // ),
            // Shadow(
            //   color: Theme.of(context).colorScheme.surfaceTint,
            //   offset: Offset(1, 1),
            //   blurRadius: 0,
            // ),
          // ],
        ),
      ),
    );
  }
}
