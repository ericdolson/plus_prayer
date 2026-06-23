import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plusprayer/utils/number_utils.dart';

class HistoricalMetrics {
  late Map<String, int> prayerCountByDate;
  late Map<String, int> prayerCountByRoll;
  late Map<String, int> prayerDurationByRoll;

  HistoricalMetrics({
    Map<String, int>? prayerCountByDate,
    Map<String, int>? prayerCountByRoll,
    Map<String, int>? prayerDurationByRoll,
  }) {
    this.prayerCountByDate = prayerCountByDate ?? {};
    this.prayerCountByRoll = prayerCountByRoll ?? {};
    this.prayerDurationByRoll = prayerDurationByRoll ?? {};
  }

  factory HistoricalMetrics.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final Map<String, dynamic> prayerCountByDate = data['prayerCountByDate'] ?? {};
    final Map<String, dynamic> prayerCountByRoll = data['prayerCountByRoll'] ?? {};
    final Map<String, dynamic> prayerDurationByRoll = data['prayerDurationByRoll'] ?? {};

    return HistoricalMetrics(
      prayerCountByDate: prayerCountByDate.map((key, value) => MapEntry(key, value as int)),
      prayerCountByRoll: prayerCountByRoll.map((key, value) => MapEntry(key, value as int)),
      prayerDurationByRoll: prayerDurationByRoll.map((key, value) => MapEntry(key, value as int)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prayerCountByDate': prayerCountByDate,
      'prayerCountByRoll': prayerCountByRoll,
      'prayerDurationByRoll': prayerDurationByRoll,
    };
  }

  int get totalPrayers {
    return prayerCountByRoll.values.fold(0, (int sum, int count) => sum + count);
  }

  int get totalDuration {
    return prayerDurationByRoll.values.fold(0, (int sum, int count) => sum + count);
  }

  int totalPrayersByRolls(List<int> rolls) {
    return rolls.fold(0, (int sum, int roll) => sum + (prayerCountByRoll[roll] ?? 0));
  }

  int totalDurationByRolls(List<int> rolls) {
    return rolls.fold(0, (int sum, int roll) => sum + (prayerDurationByRoll[roll] ?? 0));
  }

  String abbreviatedTotalPrayersByDates(List<int> dates) {
    return abbreviatedNumber(totalPrayersByRolls(dates));
  }
}

class CurrentMetrics {
  int currentRollId;
  String date;
  DateTime? nextRollStartingAt;
  late Map<String, int> prayerCounts;
  late Map<String, int> prayerDurations;

  CurrentMetrics({
    required this.currentRollId,
    required this.date,
    this.nextRollStartingAt,
    Map<String, int>? prayerCounts,
    // Map<String, int>? prayerDurations,
  }) {
    this.prayerCounts = prayerCounts ?? {};
    // this.prayerDurations = prayerDurations ?? {};
  }

  int get prayerCount {
    return prayerCounts['$currentRollId'] ?? 0;
  }

  // int get prayerDuration {
  //   return prayerDurations['$currentRollId'] ?? 0;
  // }

  set prayerCount(int count) {
    prayerCounts['$currentRollId'] = count;
  }

  // set prayerDuration(int count) {
  //   prayerDurations['$currentRollId'] = count;
  // }

  factory CurrentMetrics.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final Map<String, int> prayerCounts = Map<String, int>.from(data['prayerCounts'] ?? {});
    // final Map<String, int> prayerDurations = Map<String, int>.from(data['prayerDurations'] ?? {});

    return CurrentMetrics(
      date: data['date'],
      currentRollId: data['currentRollId'],
      nextRollStartingAt: data['nextRollStartingAt']?.toDate(),
      prayerCounts: prayerCounts,
      // prayerDurations: prayerDurations,
    );
  }
}
