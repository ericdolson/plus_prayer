import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Time since [since], rebuilding while it runs: every frame when [smooth]
/// (a ring sweeping), once a second otherwise (timers, reduced motion — and
/// no per-frame work during a long prayer). Stops rebuilding after [until]
/// when given. Returns [Duration.zero] when [since] is null.
Duration useElapsed(
  DateTime? since, {
  bool smooth = false,
  Duration? until,
  DateTime Function() clock = DateTime.now,
}) {
  final tick = useState(0);
  useEffect(() {
    if (since == null) return null;
    bool done() => until != null && clock().difference(since) >= until;
    if (smooth) {
      late final Ticker ticker;
      ticker = Ticker((_) {
        tick.value++;
        if (done()) ticker.stop();
      })
        ..start();
      return ticker.dispose;
    }
    final timer = Timer.periodic(const Duration(seconds: 1), (t) {
      tick.value++;
      if (done()) t.cancel();
    });
    return timer.cancel;
  }, [since, smooth, until]);
  return since == null ? Duration.zero : clock().difference(since);
}
