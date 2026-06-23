import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/services/firebase.dart';

import '../models/name.dart';
import '../models/prayer.dart';

Prayer? useLastCommunityPrayer() {
  final prayer = useState<Prayer?>(null);

  useEffect(() {
    final unsubscribe = PPFirebase.subscribeToUserLastCommunityPrayer((lastPrayer) {
      prayer.value = lastPrayer;
    });

    return unsubscribe;
  }, []);

  return prayer.value;
}
