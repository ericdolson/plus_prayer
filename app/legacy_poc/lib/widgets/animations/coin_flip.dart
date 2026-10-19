import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

class CoinFlipAnimation extends HookWidget {
  final double size;

  const CoinFlipAnimation({Key? key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    useEffect(() {
      var t = Timer.periodic(Duration(seconds: 2), (timer) {
        animationController.reset();
        animationController.forward();
      });
      return t.cancel;
    }, []);

    return ClipRect(
            child: OverflowBox(
      minWidth: 0.0,
      minHeight: 0.0,
      maxWidth: double.infinity,
      // Allows the child to be any width
      maxHeight: double.infinity,
      // Allows the child to be any height
      child: Lottie.asset(
        'assets/animations/coin_flip.json',
        controller: animationController,
        options: LottieOptions(enableApplyingOpacityToLayers: true),
        width: size,
        height: size,
        fit: BoxFit.cover,
        repeat: false,
      ),
    ));
  }
}
