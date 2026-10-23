// A row's second line (design-direction.md §5): only for exceptional states.
// Rows mark presence, never absence, so there's no "Prayed today" or "Last
// prayed N days ago" — being held today is the gold ring; history lives on the
// detail page.

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

/// Saved for private prayer because the pool is full (monetization.md
/// "Auto-carry"): "Not on the list · all 15 places in use".
class NotCarriedPoolFullStatus extends RowStatus {
  const NotCarriedPoolFullStatus(this.limit);
  final int limit;
}

RowStatus? rowStatus(Subject s, {bool justAddedNotCarried = false, int poolLimit = 0}) {
  if (s.resolution == Resolution.answered && s.resolvedAt != null) return AnsweredStatus(s.resolvedAt!);
  if (justAddedNotCarried) return NotCarriedPoolFullStatus(poolLimit);
  return null;
}

/// Held today: prayed for on this local day. The gold ring (names) or dot
/// (intentions) stays until local midnight.
bool prayedToday(Subject s, LocalDate today) => s.lastPrayed != null && !today.isAfter(s.lastPrayed!);
