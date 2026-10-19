import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../presentation/plus_prayer_icons.dart';

class InPrayerPrayingHandsAnimation extends HookWidget {
  final double size;

  const InPrayerPrayingHandsAnimation({Key? key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: false);

    final maxStrokeWidth = useMemoized(() => size * .85, [size]);

    final strokeWidth = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0, end: maxStrokeWidth), weight: 60),
        TweenSequenceItem(tween: Tween(begin: maxStrokeWidth, end: maxStrokeWidth), weight: 20),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
    );

    final opacity = useAnimation(TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: .5, end: 0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    )));

    final strokeWidth2 = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 0, end: maxStrokeWidth), weight: 40),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
    );

    final opacity2 = useAnimation(TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: .5, end: 0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    )));

    // final scale = useAnimation(TweenSequence<double>([
    //   TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 20),
    //   TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    //   TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    // ]).animate(CurvedAnimation(
    //   parent: animationController,
    //   curve: Curves.easeInOut,
    // )));

    // useEffect(() {
    //   var t = Timer.periodic(Duration(seconds: 2), (timer) {
    //     animationController.reset();
    //     animationController.forward();
    //   });
    //   return t.cancel;
    // }, []);

    return ClipRect(
        child: OverflowBox(
            minWidth: 0.0,
            minHeight: 0.0,
            maxWidth: double.infinity,
            // Allows the child to be any width
            maxHeight: double.infinity,
            // Allows the child to be any height
            child: Stack(
              children: [
                InPrayerOutlinedAnimated(size: size, strokeWidth: strokeWidth, opacity: opacity),
                InPrayerOutlinedAnimated(size: size, strokeWidth: strokeWidth2, opacity: opacity2),
                // Outline version
                // Text(String.fromCharCode(PlusPrayer.praying_hands.codePoint),
                //     style: TextStyle(
                //       fontSize: size,
                //       fontFamily: PlusPrayer.praying_hands.fontFamily,
                //       package: PlusPrayer.praying_hands.fontPackage,
                //       foreground: Paint()
                //         ..style = PaintingStyle.stroke
                //         ..strokeWidth = strokeWidth
                //         ..color = Colors.amber.withValues(alpha:opacity),
                //     )),
                // Text(String.fromCharCode(PlusPrayer.praying_hands.codePoint),
                //     style: TextStyle(
                //       fontSize: size,
                //       fontFamily: PlusPrayer.praying_hands.fontFamily,
                //       package: PlusPrayer.praying_hands.fontPackage,
                //       foreground: Paint()
                //         ..style = PaintingStyle.stroke
                //         ..strokeWidth = strokeWidth2
                //         ..color = Colors.amber.withValues(alpha:opacity2),
                //     )),
                // Filled icon
                Text(
                  String.fromCharCode(PlusPrayer.praying_hands.codePoint),
                  style: TextStyle(
                    fontSize: size,
                    fontFamily: PlusPrayer.praying_hands.fontFamily,
                    package: PlusPrayer.praying_hands.fontPackage,
                    color: Colors.amber,
                  ),
                ),
              ],
            )));
  }
}

class InPrayerOutlinedAnimated extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double opacity;

  const InPrayerOutlinedAnimated(
      {super.key, required this.size, required this.strokeWidth, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Text(String.fromCharCode(PlusPrayer.praying_hands.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: PlusPrayer.praying_hands.fontFamily,
          package: PlusPrayer.praying_hands.fontPackage,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = Colors.amber.withValues(alpha:opacity),
        ));
  }
}

class InPrayerPrayingHandsAnimation2 extends HookWidget {
  final Color? color;
  final double size;

  const InPrayerPrayingHandsAnimation2({Key? key, this.color, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: false);

    final iconSize = useMemoized(() => size / 2, [size, 1]);
    final maxStrokeWidth = useMemoized(() => size, [size, 1]);
    final minPulsingCircleDiameter = useMemoized(() => size * 0.7, [size, 2]);
    final maxPulsingCircleDiameter = useMemoized(() => size * 0.85, [size, 2]);
    final color = useMemoized(() => this.color ?? Colors.amber, [this.color]);

    final diameter = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0, end: maxStrokeWidth), weight: 60),
        TweenSequenceItem(tween: Tween(begin: maxStrokeWidth, end: maxStrokeWidth), weight: 20),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
    );

    final opacity = useAnimation(TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    )));

    final diameter2 = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 0, end: maxStrokeWidth), weight: 40),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      )),
    );

    final opacity2 = useAnimation(TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    )));

    final pulsingCircleDiameter = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: minPulsingCircleDiameter, end: maxPulsingCircleDiameter), weight: 50),
        // TweenSequenceItem(tween: Tween(begin: maxPulsingCircleDiameter, end: minPulsingCircleDiameter), weight: 25),
        // TweenSequenceItem(tween: Tween(begin: minPulsingCircleDiameter, end: maxPulsingCircleDiameter), weight: 25),
        TweenSequenceItem(tween: Tween(begin: maxPulsingCircleDiameter, end: minPulsingCircleDiameter), weight: 50),
      ]).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      )),
    );

    // final scale = useAnimation(TweenSequence<double>([
    //   TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 20),
    //   TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    //   TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    // ]).animate(CurvedAnimation(
    //   parent: animationController,
    //   curve: Curves.easeInOut,
    // )));

    // useEffect(() {
    //   var t = Timer.periodic(Duration(seconds: 2), (timer) {
    //     animationController.reset();
    //     animationController.forward();
    //   });
    //   return t.cancel;
    // }, []);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
        ),
        Container(
          width: pulsingCircleDiameter,
          height: pulsingCircleDiameter,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha:.3), width: 1),
            shape: BoxShape.circle,
          ),
        ),
        // Transform.rotate(angle: pi / 2, child: Container(
        //   width: size * 1.5,
        //   height: size * 1.5,
        //   decoration: BoxDecoration(
        //     border: Border.all(color: Colors.amber.withValues(alpha:.5), width: pulsingCircleDiameter * .015),
        //   ),
        // )),
        InPrayerOutlinedAnimated2(color: color, size: size, diameter: diameter, opacity: opacity),
        InPrayerOutlinedAnimated2(color: color, size: size, diameter: diameter2, opacity: opacity2),
        // Outline version
        // Text(String.fromCharCode(PlusPrayer.praying_hands.codePoint),
        //     style: TextStyle(
        //       fontSize: size,
        //       fontFamily: PlusPrayer.praying_hands.fontFamily,
        //       package: PlusPrayer.praying_hands.fontPackage,
        //       foreground: Paint()
        //         ..style = PaintingStyle.stroke
        //         ..strokeWidth = strokeWidth
        //         ..color = Colors.amber.withValues(alpha:opacity),
        //     )),
        // Text(String.fromCharCode(PlusPrayer.praying_hands.codePoint),
        //     style: TextStyle(
        //       fontSize: size,
        //       fontFamily: PlusPrayer.praying_hands.fontFamily,
        //       package: PlusPrayer.praying_hands.fontPackage,
        //       foreground: Paint()
        //         ..style = PaintingStyle.stroke
        //         ..strokeWidth = strokeWidth2
        //         ..color = Colors.amber.withValues(alpha:opacity2),
        //     )),
        // Filled icon
        Text(
          String.fromCharCode(PlusPrayer.praying_hands.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: PlusPrayer.praying_hands.fontFamily,
            package: PlusPrayer.praying_hands.fontPackage,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha:.5),
                offset: const Offset(0, 0),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InPrayerOutlinedAnimated2 extends StatelessWidget {
  final Color color;
  final double size;
  final double diameter;
  final double opacity;

  const InPrayerOutlinedAnimated2(
      {super.key, required this.color, required this.size, required this.diameter, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color.withValues(alpha:opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
