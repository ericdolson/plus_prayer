import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/hooks/use_timer.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/widgets/animations/in_prayer_praying_hands.dart';

import '../../hooks/use_in_prayer.dart';
import '../animations/coin_flip.dart';

final Duration intentTime = 10.seconds;

void showPrayerModal({
  required BuildContext context,
  required Function onPrayerAdded,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: Duration(milliseconds: 500),
    ),
    // showDragHandle: true,
    enableDrag: false,
    isDismissible: false,
    barrierColor: Theme.of(context).colorScheme.primary,
    clipBehavior: Clip.hardEdge,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return PrayerModal(onPrayerAdded: onPrayerAdded);
    },
  );
}

class PrayerModal extends HookWidget {
  const PrayerModal({Key? key, required this.onPrayerAdded}) : super(key: key);

  final Function onPrayerAdded;

  @override
  Widget build(BuildContext context) {
    final inPrayer = useInPrayer();
    final screenSize = useScreenSize();
    final timer = useTimer(10, start: true);

    return SizedBox(
        // height: screenSize.height / 2,
        child: Stack(
      children: [
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: RadialGradient(
        //       center: Alignment.topLeft,
        //       radius: 2,
        //       colors: [Colors.blue.withValues(alpha:0.1), Colors.transparent],
        //       stops: [0.0, 1.0],
        //     ),
        //   ),
        // ),
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: RadialGradient(
        //       center: Alignment.topRight,
        //       radius: 2,
        //       colors: [Colors.green.withValues(alpha:0.1), Colors.transparent],
        //       stops: [0.0, 1.0],
        //     ),
        //   ),
        // ),
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: RadialGradient(
        //       center: Alignment.bottomLeft,
        //       radius: 2,
        //       colors: [Colors.orange.withValues(alpha:0.1), Colors.transparent],
        //       stops: [0.0, 1.0],
        //     ),
        //   ),
        // ),
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: RadialGradient(
        //       center: Alignment.bottomRight,
        //       radius: 2,
        //       colors: [Colors.red.withValues(alpha:0.1), Colors.transparent],
        //       stops: [0.0, 1.0],
        //     ),
        //   ),
        // ),
        SafeArea(
            child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // CoinFlipAnimation(),
                        // FancyText('${timer.secondsRemaining}',
                        //     style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                          InPrayerPrayingHandsAnimation2(size: 60),
                          SizedBox(height: 8),
                          FancyText('In prayer',
                              style: TextStyle(color: Colors.amber, fontSize: 24)),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // inPrayer.isInPrayer ? inPrayer.endPrayer() : inPrayer.startPrayer();
                            },
                            child: Text(inPrayer.isInPrayer ? 'End Prayer' : 'Start Prayer')),
                        Text('In prayer with ${inPrayer.inPrayerCount - 1} other people'),
                        Expanded(
                            flex: 1,
                            child: Center(child: SizedBox.shrink())),
                        TweenAnimationBuilder<double>(
                            duration: 10.seconds,
                            curve: Curves.linear,
                            onEnd: () {
                              // onPrayerAdded();
                              // Navigator.of(context).pop();
                            },
                            tween: Tween<double>(
                              begin: 1,
                              end: 0,
                            ),
                            builder: (context, value, _) => FancyText('${timer.secondsRemaining}',
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900))),
                      ],
                    ))))
      ],
    ));
  }
}
