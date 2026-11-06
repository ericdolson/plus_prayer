import Foundation

// The optimistic view: prayers logged on this device that the server may not
// reflect yet (queued offline, or sent but not re-read) fold into what Home
// shows, so held rings, the card's border and the streak update the moment
// Amen is said, with or without signal. Folding is idempotent: a prayer the
// server already counted changes nothing.

public func subjectsWithLocalPrayers(_ subjects: [Subject], _ local: [NewPrayer]) -> [Subject] {
    guard !local.isEmpty else { return subjects }
    var parentOf: [String: String] = [:]
    for subject in subjects { parentOf[subject.id] = subject.parentId }
    var latest: [String: LocalDate] = [:]
    for prayer in local {
        // Holding an intention also links its name (the server does the same).
        let ids = Set(prayer.subjectIds + prayer.subjectIds.compactMap { parentOf[$0] })
        for id in ids where latest[id].map({ prayer.localDate > $0 }) ?? true {
            latest[id] = prayer.localDate
        }
    }
    return subjects.map { subject in
        guard let day = latest[subject.id], subject.lastPrayed.map({ day > $0 }) ?? true else { return subject }
        var next = subject
        next.lastPrayed = day
        return next
    }
}

public func headerWithLocalPrayers(_ header: UserHeader, _ local: [NewPrayer]) -> UserHeader {
    local.filter(\.includesList)
        .sorted { $0.localDate < $1.localDate }
        .reduce(header) { afterListPrayer($0, on: $1.localDate) }
}

/// True when the next list is already earned (list-lifecycle.md, the gate):
/// the server has a prayer with `list`, or this device has one waiting that
/// started before the cutoff.
public func nextListCovered(_ list: CurrentList, status: MyListStatus?, local: [NewPrayer]) -> Bool {
    if let status, status.listId == list.id, status.prayersWithList > 0 { return true }
    return local.contains { prayer in
        prayer.communityListId == list.id && list.closesAt.map { prayer.startedAt < $0 } ?? true
    }
}

/// The card's status line for the next list.
public func tomorrowStatus(list: CurrentList, status: MyListStatus?, local: [NewPrayer],
                           header: UserHeader?, today: LocalDate) -> TomorrowStatus {
    tomorrowStatus(nextListCovered: nextListCovered(list, status: status, local: local),
                   prayedWithListToday: header.map { prayedWithListToday($0, today: today) } ?? false)
}
