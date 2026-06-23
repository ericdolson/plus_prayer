import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

List<Object> useDelayed({required List<Object> values, Duration delay = Duration.zero}) {
  final currentValues = useState(values);

  useEffect(() {
    var delayed = Timer(delay, () {
      currentValues.value = values;
    });

    return delayed.cancel;
  }, values);

  return currentValues.value;
}
