import Foundation

// The community card's rules (design-direction §6, presence-live.md,
// list-lifecycle.md). Pure functions; the app turns their answers into copy.

// MARK: Presence

/// Which presence rung the card shows. Count only, never who.
public enum PresenceWindow: Sendable, Equatable {
    /// "● 239 praying now" (the only rung with the live dot).
    case now
    /// "640 prayed this hour".
    case lastHour
    /// "4,113 prayed today".
    case today
}

public struct PresenceLine: Sendable, Equatable {
    public let window: PresenceWindow
    public let count: Int

    public init(window: PresenceWindow, count: Int) {
        self.window = window
        self.count = count
    }
}

/// The presence ladder: praying now ≥ threshold → now; else the last hour;
/// else today; else hidden. Never 0.
public func presenceLine(prayingNow: Int, prayedLastHour: Int, prayedToday: Int, threshold: Int) -> PresenceLine? {
    if prayingNow >= threshold { return PresenceLine(window: .now, count: prayingNow) }
    if prayedLastHour >= threshold { return PresenceLine(window: .lastHour, count: prayedLastHour) }
    if prayedToday >= threshold { return PresenceLine(window: .today, count: prayedToday) }
    return nil
}

// MARK: The you block

/// The status line under your carried people, from the list gate: a prayer
/// with the current list, started before its cutoff, carries you and your
/// carried names onto the next list.
public enum TomorrowStatus: Sendable, Equatable {
    /// A qualifying prayer for the next list exists: "They'll be on List 53".
    case covered
    /// Prayed with the list today, but it has flipped since:
    /// "Your next prayer carries them onto List 54".
    case nextPrayerCarries
    /// "Pray to carry them onto List 53".
    case prayToCarry

    /// The one actionable thing (ink); otherwise done (inkMuted).
    public var isActionable: Bool { self != .covered }
}

public func tomorrowStatus(nextListCovered: Bool, prayedWithListToday: Bool) -> TomorrowStatus {
    if nextListCovered { return .covered }
    if prayedWithListToday { return .nextPrayerCarries }
    return .prayToCarry
}

// MARK: The avatar row

/// How many overlapping discs of `size`, each `step` after the last, fit in `width`.
public func discCapacity(width: Double, size: Double, step: Double) -> Int {
    guard width >= size, step > 0 else { return width >= size ? 1 : 0 }
    return Int(((width - size) / step).rounded(.down)) + 1
}

/// The card's full-width fill: everyone when they fit; otherwise as many as
/// fit less one, then a "+N" disc for the rest. Measured, never a fixed cap.
public func fillRow(people: Int, capacity: Int) -> (shown: Int, overflow: Int) {
    if people <= capacity { return (people, 0) }
    let shown = max(capacity - 1, 0)
    return (shown, people - shown)
}

public func presenceLine(_ stats: LiveStats, threshold: Int) -> PresenceLine? {
    presenceLine(prayingNow: stats.prayingNow, prayedLastHour: stats.prayedLastHour,
                 prayedToday: stats.prayedToday, threshold: threshold)
}

/// Others in prayer alongside you, for the prayer bar ("with 212"); nil when
/// the live count is under the display threshold. Your own presence is part
/// of `prayingNow` once it has synced.
public func othersInPrayer(_ stats: LiveStats, threshold: Int) -> Int? {
    stats.prayingNow < threshold ? nil : stats.prayingNow - 1
}

// MARK: The closing notice

/// Minutes until the list closes, during the last 5 minutes, for someone who
/// hasn't prayed with it today (the notice replaces the status line); nil
/// otherwise. Rounded up, 1…5.
public func closingSoonMinutes(closesAt: Date?, now: Date, prayedWithListToday: Bool) -> Int? {
    guard let closesAt, !prayedWithListToday else { return nil }
    let left = closesAt.timeIntervalSince(now)
    guard left >= 0, left <= 5 * 60 else { return nil }
    return min(5, max(1, Int((left / 60).rounded(.up))))
}
