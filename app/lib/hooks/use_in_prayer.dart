import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/models/inPrayer.dart';
import 'package:plusprayer/models/prayer.dart';
import 'package:plusprayer/utils/date_utils.dart';

import '../models/name.dart';
import '../services/firebase.dart';

final heartbeatInterval = 5.minutes;
final paddingForTTL = 10.seconds;

InPrayerState useInPrayer() {
  // useEffect(() {
  //   return () => Future.delayed(1.ms, () => inPrayerState.endPrayer());
  // }, []);

  // useEffect(() {
  //   final unsubscribe = PPFirebase.subscribeToInPrayer((inPrayer) {
  //     if (inPrayer != null && !inPrayerState.isInPrayer) {
  //       inPrayerState.startPrayer(startedAt: inPrayer.startedAt);
  //     } else if (inPrayer == null && inPrayerState.isInPrayer) {
  //       inPrayerState.endPrayer();
  //     }
  //   });
  //
  //   return unsubscribe;
  // }, []);

  useListenable(inPrayerState);
  return inPrayerState;
}

class InPrayerState extends ChangeNotifier {
  Timer? _cancelTimer;
  int _inPrayerCount = -1;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _inPrayerCountSubscription;
  bool _isInPrayer = false;
  DateTime? _startedAt;
  Stopwatch _stopwatch = Stopwatch();
  Map<String, int> _prayedForWithTime = {};

  // constructor
  InPrayerState() {
    PPFirebase.subscribeToInPrayer((inPrayer) {
      if (inPrayer != null && !isInPrayer) {
        // If the user has an inPrayer document, but the app is not aware of it, we will "start"
        // the prayer for the ui to update.
        startPrayer(inPrayer: inPrayer);
      } else if (inPrayer == null && isInPrayer) {
        // It is possible that the prayer ended from another device, so we will make sure this
        // device is also aware of the end of the prayer so the ui can update. If it was this
        // device that ended the prayer, this will be a no-op as endPrayer() will have already
        // been called.
        _endPrayerCleanup();
      }
    });
  }

  int get inPrayerCount {
    // If we're in prayer, we want to show at least 1 person in prayer
    return isInPrayer ? max(1, _inPrayerCount) : _inPrayerCount;
  }

  set inPrayerCount(int value) {
    _inPrayerCount = value;
    notifyListeners();
  }

  bool get inPrayerCountLoading {
    return _inPrayerCount < 0;
  }

  bool get isInPrayer {
    return _isInPrayer;
  }

  set isInPrayer(bool value) {
    _isInPrayer = value;

    if (value) {
      print('clearing prayedForWithTime');
      _prayedForWithTime.clear();
    }
    try {
      notifyListeners();
    } catch (e) {
      // ignore (probably disposed)
    }
  }

  get startedAt {
    return _startedAt;
  }

  void addPrayedFor(String nameId) {
    _prayedForWithTime[nameId] = 1;
    notifyListeners();
  }

  void clearPrayedFor(String nameId) {
    _prayedForWithTime.remove(nameId);
    notifyListeners();
  }

  void togglePrayedFor(String nameId) {
    if (_prayedForWithTime.containsKey(nameId)) {
      clearPrayedFor(nameId);
    } else {
      addPrayedFor(nameId);
    }
    notifyListeners();
  }

  bool hasPrayedFor(String nameId) {
    return _prayedForWithTime.containsKey(nameId);
  }

  void startPrayer({InPrayer? inPrayer, Name? name}) async {
    if (isInPrayer) return;

    isInPrayer = true;
    _startedAt = inPrayer?.startedAt ?? DateTime.now();
    _cancelTimer = Timer.periodic(heartbeatInterval, (timer) {
      _updateOrCreateInPrayer();
    });

    _inPrayerCountSubscription = FirebaseFirestore.instance
        .collection(Collections.metrics.name)
        .doc('inPrayerMetrics')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      final int count = data?['inPrayerCount'] ?? 0;
      inPrayerCount = count;
    });

    await _updateOrCreateInPrayer(startedAt: inPrayer == null ? _startedAt : null);
  }

  void _endPrayerCleanup() {
    print('ending prayer');
    if (!isInPrayer) return;

    isInPrayer = false;
    inPrayerCount = -1;
    _inPrayerCountSubscription?.cancel();
    _cancelTimer?.cancel();
    // _prayedForWithTime.clear(); // We will clear this when starting so the animation for ending the prayer won't remove the checks
  }

  void completePrayer() async {
    if (!isInPrayer) return;

    final dateKey = currentDateKey();
    final nameIds = _prayedForWithTime.keys.toList();

    final prayer = Prayer(
      createdAt: DateTime.now(),
      date: dateKey,
      duration: 10,
      forGroups: false,
      forNames: nameIds.isNotEmpty,
      forPrayerRoll: true,
      groupIds: [],
      nameIds: nameIds,
      prayerRollId: null,
      timezone: currentTimezone(),
    );

    final firestoreFutures = [
      prayer.savePrayer(),
      ..._prayedForWithTime.keys.map((nameId) =>
          FirebaseFirestore.instance.collection(Collections.names.name).doc(nameId).update({
            'ppCounts.$dateKey': FieldValue.increment(1),
            'lastPrayerDate': dateKey,
          }))
    ];

    await Future.wait(firestoreFutures);

    _endPrayerCleanup();

    // todo: commit prayer to database

    await FirebaseFirestore.instance
        .collection(Collections.inPrayer.name)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();

    await endPrayer();
  }

  Future<void> endPrayer() async {
    if (!isInPrayer) return;

    _endPrayerCleanup();

    // todo: commit prayer to database

    await FirebaseFirestore.instance
        .collection(Collections.inPrayer.name)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();
  }

  _updateOrCreateInPrayer({DateTime? startedAt}) async {
    await FirebaseFirestore.instance
        .collection(Collections.inPrayer.name)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'expiresAt': DateTime.now().add(heartbeatInterval).add(paddingForTTL),
      if (startedAt != null) 'startedAt': startedAt,
    }, SetOptions(merge: true));
  }
}

final inPrayerState = InPrayerState();
