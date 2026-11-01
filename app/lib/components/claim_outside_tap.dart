import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Wraps a menu's anchor so that, while [open], a tap outside the menu only
/// closes it, while a drag still scrolls what's beneath in the same motion,
/// as iOS menus do. (The menus' own `consumeOutsideTaps` swallows drags too.)
///
/// [groupId] is the menu's tap region group (its root [MenuController]), so
/// taps on the anchor and the menu itself count as inside. Closing is left
/// to the menu.
class ClaimOutsideTap extends StatelessWidget {
  const ClaimOutsideTap({super.key, required this.groupId, required this.open, required this.child});

  final Object groupId;
  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) => TapRegion(
        groupId: groupId,
        enabled: open,
        onTapOutside: (event) => _OutsideTapClaimer().addPointer(event),
        child: child,
      );
}

/// Joins the pointer's gesture arena and wins it on release, or on a hold,
/// so nothing beneath sees a tap or a long press. Steps aside once the
/// pointer moves past the slop, so a scroll beneath takes it.
class _OutsideTapClaimer extends OneSequenceGestureRecognizer {
  // Under the long press's timeout, so a hold never turns into one.
  static const _hold = Duration(milliseconds: 400);

  Offset? _start;
  double _slop = kTouchSlop;
  Timer? _timer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _start = event.position;
    _slop = computeHitSlop(event.kind, gestureSettings);
    _timer = Timer(_hold, () => resolve(GestureDisposition.accepted));
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && (event.position - _start!).distance > _slop) {
      resolve(GestureDisposition.rejected);
    } else if (event is PointerUpEvent) {
      // Before the arena's sweep would hand the tap to what's beneath.
      resolve(GestureDisposition.accepted);
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _timer?.cancel();
    // Single use: nothing else holds it.
    scheduleMicrotask(dispose);
  }

  @override
  String get debugDescription => 'outside tap claimer';
}
