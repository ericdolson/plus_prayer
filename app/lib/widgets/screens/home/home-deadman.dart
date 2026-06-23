import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum AlertState { safe, ready, alerting }

var random = Random();
const logoSize = 160.0;
const dragCircleSize = 100.0;
const gradientDuration = Duration(milliseconds: 300);
const gradientDurationSlow = Duration(seconds: 2);

Offset dragAnchorStrategy(Draggable<Object> d, BuildContext context, Offset point) {
  return Offset(d.feedbackOffset.dx + dragCircleSize / 2, d.feedbackOffset.dy + dragCircleSize / 2);
}

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState(AlertState.safe);
    final isDragging = useState(false);
    final inAlertArea = useState(false);
    final inAlertAreaDelayed = useState(false);
    final width = useMemoized(() => MediaQuery.of(context).size.width, []);
    final height = useMemoized(() => MediaQuery.of(context).size.height, []);
    final initialPosition = useMemoized(
        () => Offset(width / 2 - dragCircleSize / 2, height - width / 2 + dragCircleSize / 2 + 10), [2]);
    final position = useState(initialPosition);
    // position.value = initialPosition;
    final List<Color> gradientColors = useMemoized(() {
      switch (state.value) {
        case AlertState.ready:
          return [Color.fromRGBO(236, 192, 80, 1.0), Color.fromRGBO(237, 106, 80, 1.0)];
          return [Color.fromRGBO(120, 133, 181, 1.0), Color.fromRGBO(31, 32, 37, 1.0)];
          return [Color.fromRGBO(236, 192, 80, 1.0), Color.fromRGBO(237, 106, 80, 1.0)];
          return [Color.fromRGBO(237, 106, 80, 1.0), Color.fromRGBO(245, 181, 77, 1.0)];
        case AlertState.alerting:
          // return [Color.fromRGBO(237, 106, 80, 1.0), Color.fromRGBO(140, 5, 71, 1.0)];
          return [Color.fromRGBO(237, 76, 114, 1.0), Color.fromRGBO(141, 5, 53, 1.0)];
          return [Color.fromRGBO(225, 55, 166, 1.0), Color.fromRGBO(114, 29, 42, 1.0)];
        case AlertState.safe:
        default:
          return [Color.fromRGBO(244, 246, 251, 1.0), Color.fromRGBO(244, 246, 251, 1.0)];
          return [Color.fromRGBO(120, 133, 181, 1.0), Color.fromRGBO(120, 133, 181, 1.0)];
          return [Color.fromRGBO(40, 208, 188, 1.0), Color.fromRGBO(55, 140, 225, 1.0)];
      }
    }, [state.value]);

    useEffect(() {
      HapticFeedback.mediumImpact();
      return null;
    }, [inAlertArea.value]);

    useEffect(() {
      if (state.value == AlertState.alerting) {
        HapticFeedback.vibrate();
      }

      return null;
    }, [state.value]);

    useEffect(() {
      Timer? timer;

      if (inAlertArea.value) {
        timer = Timer(gradientDuration, () {
          inAlertAreaDelayed.value = true;
        });
      } else {
        inAlertAreaDelayed.value = false;
      }

      return () => timer?.cancel();
    }, [inAlertArea.value]);

    return Stack(
      children: [
        Positioned.fill(
            child: AnimatedContainer(
          duration: inAlertAreaDelayed.value ? gradientDurationSlow : gradientDuration,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topRight, end: Alignment.bottomCenter, colors: gradientColors)),
        )),
        // Column(children: [
        //   Expanded(flex: 1, child: SizedBox.shrink()),
        //   Container(height: 200, color: Colors.white)
        // ]),
        // Positioned(
        //     left: width / 2 - logoSize / 2,
        //     top: 270,
        //     child: AnimatedOpacity(
        //         duration: Duration(milliseconds: 300),
        //         opacity: state.value == AlertState.alerting ? .3 : .1,
        //         child: Image(
        //             alignment: Alignment.center,
        //             image: AssetImage('assets/splash_image.png'),
        //             width: logoSize))),
        Positioned(
            bottom: -230,
            child: Container(
                alignment: Alignment.topLeft,
                clipBehavior: Clip.antiAlias,
                width: width,
                height: width,
                decoration: BoxDecoration(shape: BoxShape.rectangle),
                child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: width * 3,
                    maxWidth: width * 3,
                    minHeight: width * 3,
                    maxHeight: width * 3,
                    child: Opacity(
                        opacity: state.value == AlertState.alerting ? 1 : 1,
                        child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.center,
                                    colors: [
                                      // Color.fromRGBO(0, 0, 0, .1),
                                      // Color.fromRGBO(0, 0, 0, .1),
                                      Colors.white,
                                      Colors.white,
                                    ]),
                                shape: BoxShape.circle)))))),
        Column(children: [
          Expanded(
              flex: 1,
              child: AnimatedScale(
                  duration: Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  scale: state.value == AlertState.alerting ? 1.2 : 1,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: state.value == AlertState.alerting ? .6 : .15,
                    child: Text('Stuff'),
                    // child: Image(
                    //     alignment: Alignment.center,
                    //     image: AssetImage('assets/splash_image.png'),
                    //     width: logoSize)
                  ))),
          SizedBox(
            // duration: Duration(milliseconds: 500),
            // curve: state.value == AlertState.alerting ? Curves.easeIn : Curves.easeIn,
            width: width,
            height: state.value == AlertState.alerting ? 0 : width / 2,
            child: state.value == AlertState.alerting
                ? null
                : Center(
                    child: Text(
                    'RELEASE TO ALERT\nDRAG HERE TO CANCEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.black.withValues(alpha:.4),
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                        .animate(target: inAlertArea.value ? 1 : 0)
                        .fade(delay: 300.ms, duration: 300.ms)
                        .slideY(begin: .3)
                        .scale(begin: const Offset(.9, .9))),
          ),
          SizedBox(
              // duration: Duration(milliseconds: 500),
              // curve: state.value == AlertState.alerting ? Curves.easeIn : Curves.easeIn,
              width: width,
              height: state.value == AlertState.alerting ? width / 2 : 0,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_rounded, color: Colors.black.withValues(alpha:.6), size: 30),
                  SizedBox(width: 3),
                  Text(
                    'ALERTING!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.black.withValues(alpha:.6),
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                ]),
                MaterialButton(
                  onPressed: () {
                    state.value = AlertState.safe;
                    position.value = initialPosition;
                  },
                  shape: RoundedRectangleBorder(),
                  color: Colors.red,
                  child: Text('Manage'),
                )
              ])
                  .animate(target: state.value == AlertState.alerting ? 1 : 0)
                  .fade(delay: 500.ms, duration: 300.ms)
                  .slideY(begin: .3)
                  .scale(begin: const Offset(.9, .9))),
        ]),
        AnimatedPositioned(
          duration: isDragging.value ? Duration.zero : Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          left: position.value.dx,
          top: position.value.dy,
          child: Draggable(
            maxSimultaneousDrags: 1,
            feedback: DragCircle(isDragging: true),
            childWhenDragging: SizedBox.shrink(),
            onDragStarted: () {
              isDragging.value = true;
            },
            onDragEnd: (details) {
              position.value = details.offset;

              if (inAlertArea.value) {
                state.value = AlertState.alerting;
              } else {
                state.value = AlertState.safe;
              }

              inAlertArea.value = false;

              Future.delayed(Duration(milliseconds: 30), () {
                isDragging.value = false;
                position.value = initialPosition;
              });
            },
            onDragUpdate: (details) {
              // print(details.globalPosition);
              // isDragging.value = true;

              final isInAlertArea = details.globalPosition.dy < height - 160;

              if (isInAlertArea) {
                inAlertArea.value = true;
                state.value = AlertState.ready;
              } else {
                inAlertArea.value = false;
                state.value = AlertState.safe;
              }
            },
            dragAnchorStrategy: dragAnchorStrategy,
            child: Opacity(
                opacity: state.value == AlertState.alerting ? 0 : 1,
                child: DragCircle(isDragging: isDragging.value)),
          ),
        )
      ],
    );
  }
}

class DragCircle extends StatelessWidget {
  final bool isDragging;

  const DragCircle({super.key, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    // print('isDragging $isDragging');

    return AnimatedScale(
        scale: isDragging ? 1.2 : 1,
        duration: Duration(milliseconds: 300),
        child: Container(
          width: dragCircleSize,
          height: dragCircleSize,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:.1), blurRadius: 3, offset: Offset(0, 3))
              ]),
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: isDragging ? 0 : 1,
              child: Icon(Icons.swipe_up_rounded, size: 30, color: Colors.black.withValues(alpha:.25))),
        ));
  }
}
