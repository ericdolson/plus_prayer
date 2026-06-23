import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/models/metrics.dart';
import 'package:plusprayer/services/firebase.dart';


HistoricalMetrics useHistoricalMetrics() {
  final historicalPrayerRollMetrics = useState(HistoricalMetrics());

  useEffect(() {
    final unsubscribe = PPFirebase.subscribeToHistoricalMetrics((metrics) {
      historicalPrayerRollMetrics.value = metrics;
    });

    return unsubscribe;
  }, []);

  return historicalPrayerRollMetrics.value;
}
