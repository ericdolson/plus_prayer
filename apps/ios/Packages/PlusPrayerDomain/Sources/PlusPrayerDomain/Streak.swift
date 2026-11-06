import Foundation

// The streak counts local days prayed WITH THE LIST (streaks-reminders.md).
// Stored on User and updated by the server; between prayers the app shows an
// EFFECTIVE streak from the stored fields and today, so a break shows before
// the next write. Grace is consumed lazily at the next list prayer.

/// "Prayed with the list today": the badge, the card's gold border, the
/// local last-call cancel. Cleared at local midnight, never by the flip.
public func prayedWithListToday(_ user: UserHeader, today: LocalDate) -> Bool {
    user.lastListLocalDate == today
}

/// Missed whole days between the last list day and `today` (today itself
/// isn't missed yet).
private func missedDays(since last: LocalDate, to today: LocalDate) -> Int {
    today.days(since: last) - 1
}

/// The streak to show: the stored streak while missed days ≤ grace days held;
/// otherwise 0.
public func effectiveStreak(_ user: UserHeader, today: LocalDate) -> Int {
    guard let last = user.lastListLocalDate, user.currentStreak > 0 else { return 0 }
    if today <= last { return user.currentStreak }
    return missedDays(since: last, to: today) <= user.graceDays ? user.currentStreak : 0
}

/// The stored fields after a list prayer on `day`, as the server's
/// onPrayerLogged computes them: shown optimistically (offline too) until the
/// server's values arrive.
public func afterListPrayer(_ user: UserHeader, on day: LocalDate) -> UserHeader {
    if let last = user.lastListLocalDate, day <= last { return user } // already counted, or a late sync
    var streak = 1
    var grace = user.graceDays
    if let last = user.lastListLocalDate, user.currentStreak > 0 {
        let missed = missedDays(since: last, to: day)
        if missed <= grace {
            streak = user.currentStreak + 1
            grace -= missed
        }
    }
    var next = user
    next.currentStreak = streak
    next.bestStreak = max(streak, user.bestStreak)
    next.lastListLocalDate = day
    next.graceDays = grace
    return next
}

public enum StreakBadgeState: Sendable, Equatable {
    /// Prayed with the list today: the number in ink.
    case sealedToday
    /// Alive, not yet today: the number in inkMuted, the seal one step dimmer.
    case alive
    /// Zero: a dim seal, no number. Never "0".
    case none
}

public func streakBadgeState(_ user: UserHeader, today: LocalDate) -> StreakBadgeState {
    if prayedWithListToday(user, today: today) { return .sealedToday }
    return effectiveStreak(user, today: today) > 0 ? .alive : .none
}
