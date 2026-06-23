import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_currentMetrics.dart';
import 'package:plusprayer/hooks/use_userLastCommunityPrayer.dart';

bool usePrayedForCurrentRoll({Duration delay = Duration.zero}) {
  final currentMetrics = useCurrentMetrics();
  final lastCommunityPrayer = useLastCommunityPrayer();
  final prayedForCurrentRoll = useState(currentMetrics.currentRollId == lastCommunityPrayer?.prayerRollId);

  // print(lastCommunityPrayer?.toFirestore());

  useEffect(() {
    var delayed = Timer(delay, () {
      prayedForCurrentRoll.value = currentMetrics.currentRollId == lastCommunityPrayer?.prayerRollId;
    });

    return delayed.cancel;
  }, [currentMetrics.currentRollId, lastCommunityPrayer?.prayerRollId, delay.inMilliseconds]);

  return prayedForCurrentRoll.value;
}
