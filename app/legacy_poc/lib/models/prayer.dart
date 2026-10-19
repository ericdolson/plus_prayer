import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plusprayer/utils/date_utils.dart';

import '../services/firebase.dart';

class Prayer {
  late FieldValue _t;
  late String id;
  late DateTime createdAt;
  late String date;
  late int duration; // seconds
  late bool forGroups;
  late bool forNames;
  late bool forPrayerRoll;
  List<String>? groupIds;
  GeoPoint? location;
  List<String>? nameIds;
  int? prayerRollId;
  late String timezone;
  late String userId;

  Prayer({
    String? id,
    DateTime? createdAt,
    String? date,
    int duration = 0, // default to 0 if not provided
    bool? forGroups,
    bool? forNames,
    bool? forPrayerRoll,
    this.groupIds,
    this.location,
    this.nameIds,
    this.prayerRollId,
    String? timezone,
    String? userId,
  }) {
    _t = FieldValue.serverTimestamp();
    this.id = id ?? '';
    this.forGroups = forGroups ?? false;
    this.forNames = forNames ?? false;
    this.forPrayerRoll = forPrayerRoll ?? false;
    this.createdAt = createdAt ?? DateTime.now();
    this.date = date ?? makeDateKey(this.createdAt); // set after timestamp in case we use timestamp
    this.timezone = timezone ?? currentTimezone();
    this.userId = userId ?? FirebaseAuth.instance.currentUser!.uid;
  }

  factory Prayer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<dynamic> groupIds = data['groupIds'] ?? [];
    final List<dynamic> nameIds = data['nameIds'] ?? [];

    return Prayer(
      id: doc.id,
      createdAt: data['createdAt'].toDate(),
      date: data['date'],
      duration: data['duration'],
      forGroups: data['forGroups'] ?? false,
      forNames: data['forNames'] ?? false,
      forPrayerRoll: data['forPrayerRoll'] ?? false,
      groupIds: groupIds.map((e) => e as String).toList(),
      location: data['location'],
      nameIds: nameIds.map((e) => e as String).toList(),
      prayerRollId: data['prayerRollId'],
      timezone: data['timezone'],
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      '_t': _t,
      'createdAt': createdAt,
      'date': date,
      'duration': duration,
      if (forGroups) 'forGroups': forGroups,
      if (forNames) 'forNames': forNames,
      if (forPrayerRoll) 'forPrayerRoll': forPrayerRoll,
      if (groupIds != null) 'groupIds': groupIds,
      if (location != null) 'location': location,
      if (nameIds != null) 'nameIds': nameIds,
      if (prayerRollId != null) 'prayerRollId': prayerRollId,
      'timezone': timezone,
      'userId': userId,
    };
  }

  static void logCommunityPrayer(int currentPrayerRoll) async {
    FirebaseFirestore.instance
        .collection(Collections.prayers.name)
        .add(Prayer(prayerRollId: currentPrayerRoll, forPrayerRoll: true).toFirestore());
  }

  Future<void> savePrayer() async {
    print(userId);
    duration = 0;
    FirebaseFirestore.instance.collection(Collections.prayers.name).add(toFirestore());
  }
}
