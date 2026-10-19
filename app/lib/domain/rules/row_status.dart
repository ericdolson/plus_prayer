// A row's one secondary line (prayer-flow.md "Main screen rows", app-brief §3
// Home), the same in nav and prayer modes. No metrics on rows, and no ledger
// of absences: a row that has never been prayed for shows nothing.

import '../models/local_date.dart';
import '../models/subject.dart';

sealed class RowStatus {
  const RowStatus();
}

/// "Answered · Oct 3"
class AnsweredStatus extends RowStatus {
  const AnsweredStatus(this.on);
  final DateTime on;
}

/// "Prayed today"
class PrayedTodayStatus extends RowStatus {
  const PrayedTodayStatus();
}

/// "Last prayed 3 days ago"
class LastPrayedStatus extends RowStatus {
  const LastPrayedStatus(this.daysAgo);
  final int daysAgo;
}

/// Saved for private prayer because the pool is full (monetization.md
/// "Auto-carry"): "Not on the list · all 15 places in use".
class NotCarriedPoolFullStatus extends RowStatus {
  const NotCarriedPoolFullStatus(this.limit);
  final int limit;
}

RowStatus? rowStatus(
  Subject s,
  LocalDate today, {
  bool justAddedNotCarried = false,
  int poolLimit = 0,
}) {
  if (s.resolution == Resolution.answered && s.resolvedAt != null) return AnsweredStatus(s.resolvedAt!);
  if (justAddedNotCarried) return NotCarriedPoolFullStatus(poolLimit);
  final last = s.lastPrayed;
  if (last == null) return null;
  if (!today.isAfter(last)) return const PrayedTodayStatus();
  return LastPrayedStatus(today.daysSince(last));
}

bool prayedToday(Subject s, LocalDate today) => s.lastPrayed != null && !today.isAfter(s.lastPrayed!);
