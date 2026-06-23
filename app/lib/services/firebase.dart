import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:plusprayer/models/inPrayer.dart';
import 'package:plusprayer/models/prayer.dart';
import 'package:plusprayer/models/user.dart';
import 'package:plusprayer/utils/const.dart';

import '../models/metrics.dart';
import '../models/name.dart';
import '../utils/date_utils.dart';

enum Collections {
  inPrayer,
  metrics,
  names,
  prayers,
  users,
}

Future<int> fetchPrayerCount(String date) async {
  final res = await FirebaseFirestore.instance
      .collection(Collections.prayers.name)
      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .where('date', isEqualTo: date)
      .count()
      .get();

  return res.count ?? 0;
}

class _Firebase {
  CurrentMetrics _currentMetrics = CurrentMetrics(date: currentDateKey(), currentRollId: -1);
  HistoricalMetrics _historicalMetrics = HistoricalMetrics();
  InPrayer? _inPrayer;
  bool _isInitialized = false;
  PPUser _ppUser = PPUser();
  List<Name> _names = [];
  Prayer? _userLastCommunityPrayer;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subCurrentMetrics;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subHistoricalMetrics;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subInPrayer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subNames;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subUser;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subUserLastCommunityPrayer;

  final List<Function(CurrentMetrics)> _subCurrentMetricsCallbacks = [];
  final List<Function(HistoricalMetrics)> _subHistoricalMetricsCallbacks = [];
  final List<Function(InPrayer?)> _subInPrayerCallbacks = [];
  final List<Function(List<Name>)> _subNamesCallbacks = [];
  final List<Function(PPUser)> _subUserCallbacks = [];
  final List<Function(Prayer?)> _subUserLastCommunityPrayerCallbacks = [];

  bool isInitialized() {
    return _isInitialized;
  }

  Future<bool> init() async {
    print('initing...');
    if (!_isInitialized) {
      await Firebase.initializeApp();
    }

    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    _isInitialized = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      // Save the token to the database
      await FirebaseFirestore.instance
          .collection(Collections.users.name)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _subCurrentMetrics?.cancel();
      _subHistoricalMetrics?.cancel();
      _subInPrayer?.cancel();
      _subNames?.cancel();
      _subUser?.cancel();
      _subUserLastCommunityPrayer?.cancel();

      if (user == null) {
        _ppUser = PPUser();
        for (var cb in _subUserCallbacks) {
          cb(_ppUser);
        }
        return;
      }

      _subCurrentMetrics = FirebaseFirestore.instance
          .collection(Collections.metrics.name)
          .doc('currentPrayerRollMetrics')
          .snapshots()
          .listen((doc) async {
        if (!doc.exists) {
          return;
        }

        _currentMetrics = CurrentMetrics.fromFirestore(doc);

        for (var cb in _subCurrentMetricsCallbacks) {
          cb(_currentMetrics);
        }
      });

      _subHistoricalMetrics = FirebaseFirestore.instance
          .collection(Collections.metrics.name)
          .doc('historicalPrayerRollMetrics')
          .snapshots()
          .listen((doc) async {
        if (!doc.exists) {
          return;
        }

        _historicalMetrics = HistoricalMetrics.fromFirestore(doc);

        for (var cb in _subHistoricalMetricsCallbacks) {
          cb(_historicalMetrics);
        }
      });

      _subInPrayer = FirebaseFirestore.instance
          .collection(Collections.inPrayer.name)
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        _inPrayer = doc.exists ? InPrayer.fromFirestore(doc) : null;

        for (var cb in _subInPrayerCallbacks) {
          cb(_inPrayer);
        }
      });

      _subNames = FirebaseFirestore.instance
          .collection(Collections.names.name)
          .where('userId', isEqualTo: user.uid)
          .orderBy('sortIndex')
          .snapshots()
          .listen((querySnapshot) {
        _names = querySnapshot.docs.map((doc) => Name.fromFirestore(doc)).toList();

        for (var cb in _subNamesCallbacks) {
          cb(_names);
        }
      });

      // todo: What happens if the user is not found? We should have def set the user, but what if
      // the user node never existed somehow? We user the createUserNode method to create a user node
      // when the user signs in, but what if that fails? Perhaps the firebase function for auth
      // should create the user node but with no `v` and when we get here, if a user node coming
      // in delayed from createUserNode does not show up after some time, we should create
      // the user node here because we know the user is signed in but a node is not found.
      _subUser = FirebaseFirestore.instance
          .collection(Collections.users.name)
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        if (doc.exists) {
          // if (userVersion < currentUserVersion) {
          //   _updateUser(authUser: user, currentUserDoc: doc, from: userVersion);
          // }

          _ppUser = PPUser(
              authUser: user,
              familyName: doc.data()?['familyName'],
              givenName: doc.data()?['givenName'],
              email: doc.data()?['email'],
              isPremium: doc.data()?['isPremium'] ?? false,
              v: doc.data()?['v'] ?? currentUserVersion);
        }

        for (var cb in _subUserCallbacks) {
          cb(_ppUser);
        }
      });

      _subUserLastCommunityPrayer = FirebaseFirestore.instance
          .collection(Collections.prayers.name)
          .where('userId', isEqualTo: user.uid)
          .where('prayerRollId', isGreaterThan: 0)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((querySnapshot) {
        _userLastCommunityPrayer =
            querySnapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList().firstOrNull;

        // User just sent community prayer. Increment prayer count on current metrics so the feedback is immediate.
        if (querySnapshot.metadata.hasPendingWrites) {
          _currentMetrics.prayerCount++;

          for (var cb in _subCurrentMetricsCallbacks) {
            cb(_currentMetrics);
          }
        }

        for (var cb in _subUserLastCommunityPrayerCallbacks) {
          cb(_userLastCommunityPrayer);
        }
      });
    });

    return _isInitialized;
  }

  VoidCallback subscribeToCurrentMetrics(Function(CurrentMetrics) callback) {
    _subCurrentMetricsCallbacks.add(callback);
    callback(_currentMetrics);

    return () {
      _subCurrentMetricsCallbacks.remove(callback);
    };
  }

  VoidCallback subscribeToHistoricalMetrics(Function(HistoricalMetrics) callback) {
    _subHistoricalMetricsCallbacks.add(callback);
    callback(_historicalMetrics);

    return () {
      _subHistoricalMetricsCallbacks.remove(callback);
    };
  }

  VoidCallback subscribeToInPrayer(Function(InPrayer?) callback) {
    _subInPrayerCallbacks.add(callback);
    callback(_inPrayer);

    return () {
      _subInPrayerCallbacks.remove(callback);
    };
  }

  VoidCallback subscribeToNames(Function(List<Name>) callback) {
    _subNamesCallbacks.add(callback);
    callback(_names);

    return () {
      _subNamesCallbacks.remove(callback);
    };
  }

  VoidCallback subscribeToUser(Function(PPUser) callback) {
    _subUserCallbacks.add(callback);
    callback(_ppUser);

    return () {
      _subUserCallbacks.remove(callback);
    };
  }

  VoidCallback subscribeToUserLastCommunityPrayer(Function(Prayer?) callback) {
    _subUserLastCommunityPrayerCallbacks.add(callback);
    callback(_userLastCommunityPrayer);

    return () {
      _subUserLastCommunityPrayerCallbacks.remove(callback);
    };
  }

  Future<int> getPrayerCountForDate(String date) async {
    final res = await FirebaseFirestore.instance
        .collection(Collections.prayers.name)
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('date', isEqualTo: date)
        .count()
        .get();

    return res.count ?? 0;
  }

  // StreamSubscription subscribeToDate(DateTime dateTime, Function(Routine) callback) =>
  //     FirebaseFirestore.instance
  //         .collection(Collections.completedRoutines.name)
  //         .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
  //         .where('date', isEqualTo: routineDateString(dateTime))
  //         .snapshots()
  //         .listen((event) {
  //       if (event.docs.isNotEmpty) {
  //         callback(Routine.fromFirestore(event.docs[0]));
  //       } else {
  //         callback(makeRoutine(dateTime: dateTime));
  //       }
  //     });

  createUserNode({required User authUser, required NewUserData newUserData}) async {
    var db = FirebaseFirestore.instance;
    var userRef = db.collection(Collections.users.name).doc(authUser.uid);

    await userRef.set({
      'v': currentUserVersion,
      if (newUserData.givenName != null) 'givenName': newUserData.givenName,
      if (newUserData.familyName != null) 'familyName': newUserData.familyName,
      if (newUserData.email != null) 'email': newUserData.email,
    });
  }

  /// Removes the current FCM token from Firebase and the user's document
  Future<void> removeCurrentFCMToken() async {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();

    if (token != null && FirebaseAuth.instance.currentUser != null) {
      Future.wait([
        // Deactivates the token from Firebase (including all topics subscribed)
        messaging.deleteToken(),

        // Removes the token from the user's document
        FirebaseFirestore.instance
            .collection(Collections.users.name)
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({
          'fcmTokens': FieldValue.arrayRemove([token])
        }, SetOptions(merge: true)),
      ]);
    }
  }
}

final PPFirebase = _Firebase();
