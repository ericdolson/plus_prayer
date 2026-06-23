import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plusprayer/models/prayer.dart';
import 'package:plusprayer/utils/collection_uitls.dart';
import 'package:plusprayer/utils/date_utils.dart';
import 'package:plusprayer/utils/number_utils.dart';

import '../services/firebase.dart';

class Name {
  String? id;
  String? alias;
  Color? color;
  String? imageUrl;
  String? intention;
  String? lastPrayerDate;
  String name;
  late List<int> onRoll;
  late Map<String, int> ppCounts;
  late bool selected;
  double sortIndex;

  Name({
    this.id,
    this.alias,
    this.color,
    this.imageUrl,
    this.intention,
    this.lastPrayerDate,
    required this.name,
    List<int>? onRoll,
    Map<String, int>? ppCounts,
    bool? selected,
    required this.sortIndex,
  }) {
    this.onRoll = onRoll ?? [];
    this.ppCounts = ppCounts ?? {};
    this.selected = selected ?? false;
  }

  factory Name.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<dynamic> onRoll = data['onRoll'] ?? [];
    final Map<String, dynamic> ppCounts = data['ppCounts'] ?? {};

    return Name(
      id: doc.id,
      alias: data['alias'],
      color: data['color'] != null ? Color(data['color']) : null,
      imageUrl: data['imageUrl'],
      intention: data['intention'],
      lastPrayerDate: data['lastPrayerDate'],
      name: data['name'],
      onRoll: onRoll.map((e) => e as int).toList(),
      ppCounts: ppCounts.map((key, value) => MapEntry(key, value as int)),
      selected: data['selected'] ?? false,
      sortIndex: data['sortIndex'] * 1.0, // convert to double (cannot be cast)
    );
  }

  Map<String, dynamic> toFirestore() {
    return trimAndNullifyEmptyStrings({
      'alias': alias,
      'color': color?.value,
      'imageUrl': imageUrl,
      'intention': intention,
      'lastPrayerDate': lastPrayerDate,
      'name': name,
      'onRoll': onRoll,
      'ppCounts': ppCounts,
      'selected': selected,
      'sortIndex': sortIndex,
    });
  }

  get totalPPCount {
    return ppCounts.values.fold(0, (int sum, int count) => sum + count);
  }

  int totalPrayersByRolls(Map<String, int> metricsByRoll) {
    return metricsByRoll.values.fold(0, (int sum, int count) => sum + count);
  }

  String abbreviatedTotalPrayersByDates(Map<String, int> metricsByDate) {
    return abbreviatedNumber(totalPrayersByRolls(metricsByDate));
  }

  String get avatarLetter {
    return (alias ?? name)[0].toUpperCase();
  }

  // todo: use something that can update based on changing current date
  bool get isOnRoll {
    return onRoll.contains(currentDateKey());
  }

  void setSelected(bool value) {
    FirebaseFirestore.instance.collection(Collections.names.name).doc(id).update({
      'selected': value,
    });
  }

  void incrementPPCount() async {
    DateWrapper date = DateWrapper();

    // todo: ok to id!?
    await Future.wait([
      FirebaseFirestore.instance.collection(Collections.names.name).doc(id!).update({
        'ppCounts.${date.dateKey}': FieldValue.increment(1),
        'lastPrayerDate': date.dateKey,
      }),
      FirebaseFirestore.instance.collection(Collections.prayers.name).add(Prayer(
              date: date.dateKey,
              forNames: true,
              nameIds: [id!],
              createdAt: date.timestamp,
              timezone: date.timezoneName)
          .toFirestore()),
    ]);

    // Not using this batch code bc it requires the device to be online
    // final batch = FirebaseFirestore.instance.batch();
    //
    // // Update the `ppCounts` and `lastPrayerDate` in the "names" collection
    // final namesDocRef = FirebaseFirestore.instance.collection(Collections.names.name).doc(id!);
    // batch.update(namesDocRef, {
    //   'ppCounts.${date.dateKey}': FieldValue.increment(1),
    //   'lastPrayerDate': date.dateKey,
    // });
    //
    // // Add a new document in the "prayers" collection
    // final prayersDocRef = FirebaseFirestore.instance.collection(Collections.prayers.name).doc();
    // final prayerData = Prayer(
    //   date: date.dateKey,
    //   forNames: true,
    //   nameIds: [id!],
    //   timestamp: date.timestamp,
    //   timezone: date.timezoneName,
    // ).toFirestore();
    // batch.set(prayersDocRef, prayerData);
    //
    // // Commit the batch
    // await batch.commit();
  }

  Future<void> saveAsNewToDB() async {
    final firestoreData = toFirestore();
    firestoreData.putIfAbsent('userId', () => FirebaseAuth.instance.currentUser?.uid);
    await FirebaseFirestore.instance.collection(Collections.names.name).add(firestoreData);
  }

  Future<void> updateWith(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection(Collections.names.name).doc(id).update(data);
  }

  void setSortIndex(double newIndex) async {
    await FirebaseFirestore.instance.collection(Collections.names.name).doc(id).update({
      'sortIndex': newIndex,
    });
  }

  void delete() async {
    await FirebaseFirestore.instance.collection(Collections.names.name).doc(id).delete();
  }
}
