import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/models/metrics.dart';
import 'package:plusprayer/services/firebase.dart';
import 'package:plusprayer/utils/date_utils.dart';


CurrentMetrics useCurrentMetrics() {
  final currentPrayerRollMetrics = useState(CurrentMetrics(date: currentDateKey(), currentRollId: -1));

  useEffect(() {
    final unsubscribe = PPFirebase.subscribeToCurrentMetrics((metrics) {
      currentPrayerRollMetrics.value = metrics;
    });

    return unsubscribe;
  }, []);

  return currentPrayerRollMetrics.value;
}
