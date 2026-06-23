import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/widgets/animations/coin_flip.dart';

class CustomSwipeToDismissWithHooks extends HookWidget {
  final Widget background;
  final Widget child;
  final VoidCallback onDismissed;

  CustomSwipeToDismissWithHooks({
    required this.background,
    required this.child,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isDismissing = useState(false);

    // Animation controller for the entire swipe animation
    final controller = useAnimationController(duration: 300.ms);

    // Offset animation that either snaps back or dismisses based on swipe position
    final offsetAnimation =
        useMemoized(() => Tween<double>(begin: 0, end: -1.0).animate(controller));

    // Define the fling threshold (velocity in pixels per second) for a quick swipe
    const flingVelocityThreshold = -600.0;

    void handleSwipeEnd(double dragExtent, double velocity) {
      final screenWidth = MediaQuery.of(context).size.width;

      // Dismiss if dragged beyond threshold or flung with sufficient speed
      if (dragExtent.abs() > screenWidth * 0.4 || velocity.abs() > flingVelocityThreshold) {
        controller.animateTo(1.0).then((_) {
          isDismissing.value = true;
          onDismissed();
        });
      } else {
        // Snap back to original position if threshold and velocity are not met
        controller.reverse();
      }
    }

    return GestureDetector(
      onTap: () {
        controller.duration = 3000.ms;
        controller.animateTo(.05).then((_) {
          controller.animateTo(0);
          controller.duration = 300.ms;
        });
        // controller.animateTo(1.0).then((_) {
        //   isDismissing.value = true;
        //   onDismissed();
        // });
      },
      onHorizontalDragUpdate: (details) {
        if (!isDismissing.value) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dragAmount = details.primaryDelta ?? 0.0;
          final newExtent = controller.value + dragAmount / -screenWidth;

          // Set controller value within 0 to 1 bounds
          controller.value = newExtent.clamp(0.0, 1.0);
        }
      },
      onHorizontalDragEnd: (details) {
        // Determine if item should be dismissed or snapped back
        handleSwipeEnd(
            controller.value * MediaQuery.of(context).size.width, details.primaryVelocity ?? 0.0);
        final screenWidth = MediaQuery.of(context).size.width;
        final dragExtent = controller.value * screenWidth;
        final velocity = details.primaryVelocity ?? 0.0;

        // Dismiss if dragged beyond threshold or flung with sufficient speed
        if (dragExtent.abs() > screenWidth * 0.4 || velocity < flingVelocityThreshold) {
          controller.animateTo(1.0).then((_) {
            isDismissing.value = true;
            onDismissed();
          });
        } else {
          // Snap back to original position if threshold and velocity are not met
          controller.reverse();
        }
      },
      child: Stack(
        children: [
          // Background widget positioned behind the swiped item
          Positioned.fill(
              child: Container(
            // height: 90,
            color: Colors.transparent,
            // color: Theme.of(context).colorScheme.surfaceTint,
            // child: CoinFlipAnimation(size: 120,)
          )),
          // Main swipable child with an animated slide
          AnimatedBuilder(
            animation: offsetAnimation,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(offsetAnimation.value * MediaQuery.of(context).size.width, 0),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: isDismissing.value ? 300.ms : 100.ms,
                    height: isDismissing.value ? 0 : 60,
                    decoration: BoxDecoration(
                      // color: Theme.of(context).colorScheme.secondary,
                      color: Theme.of(context).colorScheme.surfaceDim,
                      // color: Colors.deepPurpleAccent,
                      // color: Colors.amber.withValues(alpha:1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(controller.value == 0 ? 0 : 20),
                        bottomRight: Radius.circular(controller.value == 0 ? 0 : 20),
                      ),
                    ),
                    // child: ListTile(
                    //   minTileHeight: 80,
                    //   // leading: Icon(Icons.question_mark_rounded, color: Colors.black.withValues(alpha:.5)),
                    //   title: Text('Eligible for next prayer roll?', style: TextStyle(color: Colors.black)),
                    //   subtitle: Text('Slide item to the left to dismiss', style: TextStyle(color: Colors.black.withValues(alpha:.5))),
                    //   trailing: Icon(Icons.swipe_left_rounded, color: Colors.black),
                    // ),
                    child: Padding(
                        padding: EdgeInsets.only(left: 16, right: 24),
                        child: Row(
                          children: [
                            Text('Unlock next prayer roll',
                                style: TextStyle(
                                    // color: Colors.black.withValues(alpha:.8),
                                    color: Theme.of(context).colorScheme.surface,
                                    fontWeight: FontWeight.w600)),
                            Expanded(
                              flex: 4,
                              child: SizedBox.shrink(),
                            ),
                            Icon(
                              Icons.chevron_left_rounded,
                              color: Theme.of(context).colorScheme.surface,
                              // color: Colors.black.withValues(alpha:.8)
                            ),
                            Icon(
                              Icons.swipe_left_rounded,
                              color: Theme.of(context).colorScheme.surface,
                              // color: Colors.black.withValues(alpha:.8)
                            ),
                          ],
                        )),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
