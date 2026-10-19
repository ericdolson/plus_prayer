// The streak counts local days prayed WITH THE LIST (streaks-reminders.md).
// Stored on User and updated by the server; between prayers the app shows an
// EFFECTIVE streak from the stored fields + today, so a break shows before the
// next write. Grace is consumed lazily at the next list prayer.

import '../models/local_date.dart';
import '../models/user_header.dart';

/// "Prayed with the list today" (badge, list row, local last-call cancel).
bool prayedWithListToday(UserHeader user, LocalDate today) => user.lastListLocalDate == today;

/// Missed whole days between the last list day and today (today itself isn't
/// missed yet).
int _missedDays(LocalDate last, LocalDate today) => today.daysSince(last) - 1;

/// The streak to display: the stored streak while missed days ≤ grace days
/// held; otherwise 0.
int effectiveStreak(UserHeader user, LocalDate today) {
  final last = user.lastListLocalDate;
  if (last == null || user.currentStreak <= 0) return 0;
  if (!today.isAfter(last)) return user.currentStreak;
  return _missedDays(last, today) <= user.graceDays ? user.currentStreak : 0;
}

/// The stored fields after a list prayer on [day], as the server's
/// onPrayerLogged will compute them — used to show the result optimistically
/// (e.g. offline) until the server's values arrive.
UserHeader afterListPrayer(UserHeader user, LocalDate day) {
  final last = user.lastListLocalDate;
  if (last != null && !day.isAfter(last)) return user; // already counted (or a late sync)
  var streak = 1;
  var grace = user.graceDays;
  if (last != null && user.currentStreak > 0) {
    final missed = _missedDays(last, day);
    if (missed <= grace) {
      streak = user.currentStreak + 1;
      grace -= missed;
    }
  }
  return user.copyWith(
    currentStreak: streak,
    bestStreak: streak > user.bestStreak ? streak : user.bestStreak,
    lastListLocalDate: day,
    graceDays: grace,
  );
}

enum StreakBadgeState {
  /// Prayed with the list today: seal in today's wax + N.
  sealedToday,

  /// Streak alive, not yet today: muted seal + N.
  alive,

  /// Zero: muted seal, no number. Never "0".
  none,
}

StreakBadgeState streakBadgeState(UserHeader user, LocalDate today) {
  if (prayedWithListToday(user, today)) return StreakBadgeState.sealedToday;
  return effectiveStreak(user, today) > 0 ? StreakBadgeState.alive : StreakBadgeState.none;
}
