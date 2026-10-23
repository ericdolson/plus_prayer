import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';

/// [value], but each change arrives [delay] late (the POC's per-row stagger:
/// rows flip into prayer one after another). A zero delay passes through.
T useDelayed<T>(T value, Duration delay) {
  final delayed = useState(value);
  useEffect(() {
    if (delay == Duration.zero) {
      delayed.value = value;
      return null;
    }
    final timer = Timer(delay, () => delayed.value = value);
    return timer.cancel;
  }, [value, delay]);
  return delay == Duration.zero ? value : delayed.value;
}
