import Foundation

// History (history.md, 2026-11-08): one screen, everyone or one subject.
// The repository gives the account's log (your prayers, with what each held,
// and the list entries of your subjects); these functions scope it, turn it
// into the strand's nodes (newest first, empty runs folded, month tabs where
// the month turns), split off the older periods, and count the tiles.
//
// Gold ring = you prayed (on the LOCAL date you started); bloom = on a
// printed list (on the LIST's date). They can sit a day apart around the
// flip. Days after today aren't drawn.

// MARK: The log

/// What the History screen and a page's preview read: getMyPrayerHistory
/// (your prayers, newest first, with what each held) and the list entries of
/// your subjects (each entry: the subject and its list).
public struct HistoryLog: Sendable, Equatable {
    public var prayers: [LoggedPrayer]
    public var entries: [LoggedEntry]

    public init(prayers: [LoggedPrayer] = [], entries: [LoggedEntry] = []) {
        self.prayers = prayers
        self.entries = entries
    }
}

public struct LoggedPrayer: Sendable, Hashable, Identifiable {
    public let id: String
    public let startedAt: Date
    /// The device's local date at the start.
    public let localDate: LocalDate
    public let durationSeconds: Int
    /// Ended by the auto-save (`endedBy` AUTO): its length shows as "~38 min".
    public let autoSaved: Bool
    /// The journal entry (schema: `note`).
    public var note: String?
    /// What it held, with each held intention's name (the server links it).
    public let held: Set<String>

    public init(id: String, startedAt: Date, localDate: LocalDate, durationSeconds: Int, autoSaved: Bool = false,
                note: String? = nil, held: Set<String>) {
        self.id = id
        self.startedAt = startedAt
        self.localDate = localDate
        self.durationSeconds = durationSeconds
        self.autoSaved = autoSaved
        self.note = note
        self.held = held
    }

    /// Has a journal entry.
    public var hasNote: Bool { !(note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
}

/// A printed list, as History shows it.
public struct ListRecord: Sendable, Hashable, Identifiable {
    public let listId: String
    public let listNumber: Int
    /// The list's date (Mountain date at assembly).
    public let listDate: LocalDate
    /// Settled for a closed list; for the current list the stored value (the
    /// caller stitches the live one).
    public let prayerCount: Int
    /// The wax (0 = Sunday … 6); nil = unsealed.
    public let sealVariant: Int?

    public init(listId: String, listNumber: Int, listDate: LocalDate, prayerCount: Int, sealVariant: Int? = nil) {
        self.listId = listId
        self.listNumber = listNumber
        self.listDate = listDate
        self.prayerCount = prayerCount
        self.sealVariant = sealVariant
    }

    public var id: String { listId }
}

/// One of your subjects printed on one list (not EXCLUDED; server-side).
public struct LoggedEntry: Sendable, Hashable {
    public let subjectId: String
    public var list: ListRecord

    public init(subjectId: String, list: ListRecord) {
        self.subjectId = subjectId
        self.list = list
    }
}

/// Prayers logged on this device that the server may not have yet, folded
/// in (idempotent by id). A held intention brings its name, as on the server.
public func historyLogWithLocalPrayers(_ log: HistoryLog, _ local: [NewPrayer], tree: SubjectTree) -> HistoryLog {
    let known = Set(log.prayers.map(\.id))
    var next = log
    for prayer in local where !known.contains(prayer.id) {
        let held = Set(prayer.subjectIds + prayer.subjectIds.compactMap { tree.parent(of: $0)?.id })
        next.prayers.append(LoggedPrayer(id: prayer.id, startedAt: prayer.startedAt, localDate: prayer.localDate,
                                         durationSeconds: prayer.durationSeconds, note: prayer.note, held: held))
    }
    return next
}

// MARK: Scope

/// Everyone (from Home's footer), or one subject: a person (with their
/// intentions) or one intention.
public enum HistoryScope: Sendable, Hashable {
    case everyone
    case subject(String)

    public var subjectId: String? {
        if case .subject(let id) = self { id } else { nil }
    }
}

/// An intention answered, on the local day of `resolvedAt`.
public struct AnsweredMoment: Sendable, Hashable, Identifiable {
    public let intentionId: String
    public let personId: String
    public let date: LocalDate

    public init(intentionId: String, personId: String, date: LocalDate) {
        self.intentionId = intentionId
        self.personId = personId
        self.date = date
    }

    public var id: String { intentionId }
}

/// A scope's history, newest first.
public struct ScopedHistory: Sendable, Equatable {
    public let scope: HistoryScope
    public let prayers: [LoggedPrayer]
    /// One per list.
    public let lists: [ListRecord]
    /// Answered only; Released never appears (history.md).
    public let answered: [AnsweredMoment]
    /// Scoped: the subject's creation; everyone: your first prayer (else the
    /// self's creation).
    public let begun: LocalDate
}

/// Scopes the log.
/// - Everyone: all your prayers; the lists *you* (the self) were on; every
///   answered intention.
/// - A person: the prayers that held them or one of their intentions; the
///   lists they were on; their answered intentions.
/// - An intention: the prayers that held it; its lists; itself if answered.
public func scopedHistory(_ log: HistoryLog, scope: HistoryScope, tree: SubjectTree,
                          calendar: Calendar = .current) -> ScopedHistory {
    func answered(_ intentions: [Subject]) -> [AnsweredMoment] {
        intentions.compactMap { i in
            guard i.resolution == .answered, let at = i.resolvedAt, let person = i.parentId else { return nil }
            return AnsweredMoment(intentionId: i.id, personId: person, date: LocalDate(at, calendar: calendar))
        }
    }
    let prayers: [LoggedPrayer]
    let listOwner: String?
    let moments: [AnsweredMoment]
    let begun: LocalDate?
    switch scope {
    case .everyone:
        prayers = log.prayers
        listOwner = tree.me?.id
        moments = answered(tree.names.flatMap { tree.intentions(of: $0.id) })
        begun = log.prayers.map(\.localDate).min() ?? tree.me.map { LocalDate($0.createdAt, calendar: calendar) }
    case .subject(let id):
        let subject = tree[id]
        let ids: Set<String> = subject?.isName == true ? Set([id] + tree.intentions(of: id).map(\.id)) : [id]
        prayers = log.prayers.filter { !$0.held.isDisjoint(with: ids) }
        listOwner = id
        if let subject {
            moments = answered(subject.isName ? tree.intentions(of: id) : [subject])
        } else {
            moments = []
        }
        begun = subject.map { LocalDate($0.createdAt, calendar: calendar) }
    }
    var seen: Set<String> = []
    let lists = log.entries.filter { $0.subjectId == listOwner }.map(\.list)
        .sorted { ($0.listDate, $0.listNumber) > ($1.listDate, $1.listNumber) }
        .filter { seen.insert($0.listId).inserted }
    let ordered = prayers.sorted { $0.startedAt > $1.startedAt }
    let first = [begun, ordered.last?.localDate, lists.last?.listDate].compactMap { $0 }.min()
    return ScopedHistory(scope: scope, prayers: ordered, lists: lists,
                         answered: moments.sorted { $0.date > $1.date },
                         begun: first ?? LocalDate(Date.now, calendar: calendar))
}

// MARK: Days

/// What happened on one day.
public struct HistoryDay: Sendable, Equatable {
    public let date: LocalDate
    public var lists: [ListRecord] = []
    /// Newest first.
    public var prayers: [LoggedPrayer] = []
    public var answered: [AnsweredMoment] = []

    public init(date: LocalDate) { self.date = date }

    /// The bloom: on a printed list.
    public var onList: Bool { !lists.isEmpty }
    /// The gold ring: you prayed.
    public var prayed: Bool { !prayers.isEmpty }
    /// The corner dot.
    public var journal: Bool { prayers.contains(where: \.hasNote) }
    /// The gold ✦.
    public var isAnswered: Bool { !answered.isEmpty }
    public var isEmpty: Bool { !onList && !prayed && !isAnswered }
}

/// Every day something happened, by date.
public func historyDays(_ h: ScopedHistory) -> [LocalDate: HistoryDay] {
    var days: [LocalDate: HistoryDay] = [:]
    func edit(_ date: LocalDate, _ change: (inout HistoryDay) -> Void) {
        var day = days[date] ?? HistoryDay(date: date)
        change(&day)
        days[date] = day
    }
    for list in h.lists { edit(list.listDate) { $0.lists.append(list) } }
    for prayer in h.prayers { edit(prayer.localDate) { $0.prayers.append(prayer) } }
    for moment in h.answered { edit(moment.date) { $0.answered.append(moment) } }
    return days
}

/// The day sheet's content for `date` (empty when nothing happened).
public func historyDay(_ date: LocalDate, in h: ScopedHistory) -> HistoryDay {
    historyDays(h)[date] ?? HistoryDay(date: date)
}

// MARK: The strand

/// A node's marks.
public struct StrandNode: Sendable, Hashable {
    public let date: LocalDate
    /// The lists it was on that day (usually one; VoiceOver says which).
    public let listNumbers: [Int]
    public let prayed: Bool
    public let journal: Bool
    public let answered: Bool
    public let isToday: Bool

    public init(date: LocalDate, listNumbers: [Int] = [], prayed: Bool = false, journal: Bool = false,
                answered: Bool = false, isToday: Bool = false) {
        self.date = date
        self.listNumbers = listNumbers
        self.prayed = prayed
        self.journal = journal
        self.answered = answered
        self.isToday = isToday
    }

    /// The bloom.
    public var onList: Bool { !listNumbers.isEmpty }
}

public enum StrandItem: Sendable, Hashable {
    case node(StrandNode)
    /// A run of empty days, any length: one `··`. Keyed by its newest day.
    case gap(LocalDate)
    /// The month turns: what follows is this month.
    case month(year: Int, month: Int)
}

/// An older period's line: "N prayers · N lists · ✎ N".
public struct PeriodSummary: Sendable, Equatable {
    public let prayers: Int
    public let lists: Int
    /// Prayers with a journal entry (0 = no mark).
    public let notes: Int

    public init(prayers: Int, lists: Int, notes: Int) {
        self.prayers = prayers
        self.lists = lists
        self.notes = notes
    }

    public var isEmpty: Bool { prayers == 0 && lists == 0 }
}

public enum HistoryPeriod: Sendable, Hashable {
    case month(year: Int, month: Int)
    case year(Int)
}

public struct HistoryRow: Sendable, Equatable {
    public let period: HistoryPeriod
    public let summary: PeriodSummary
}

public struct Strand: Sendable, Equatable {
    /// Today first, back to the first day of last month (or Begun).
    public let items: [StrandItem]
    /// Older periods, newest first: earlier months of this year, then
    /// earlier years. Periods with neither prayers nor lists are left out.
    public let older: [HistoryRow]
    public let begun: LocalDate
}

/// The All tab: the strand for this month and last, then the older rows.
/// Only days where something happened get a node, and today always does.
public func strand(_ h: ScopedHistory, today: LocalDate) -> Strand {
    let days = historyDays(h)
    let previous = today.month == 1 ? (year: today.year - 1, month: 12) : (year: today.year, month: today.month - 1)
    let windowStart = max(LocalDate(year: previous.year, month: previous.month, day: 1), min(h.begun, today))
    let items = strandItems(days, from: today, through: windowStart, today: today)

    let inWindow: (LocalDate) -> Bool = { $0 >= windowStart }
    func summary(_ contains: (LocalDate) -> Bool) -> PeriodSummary {
        let prayers = h.prayers.filter { contains($0.localDate) }
        return PeriodSummary(prayers: prayers.count, lists: h.lists.filter { contains($0.listDate) }.count,
                             notes: prayers.filter(\.hasNote).count)
    }
    var older: [HistoryRow] = []
    // Earlier months of this year, newest first.
    if windowStart.year == today.year {
        for month in stride(from: windowStart.month - 1, through: 1, by: -1) {
            older.append(HistoryRow(period: .month(year: today.year, month: month),
                                    summary: summary { $0.year == today.year && $0.month == month }))
        }
    }
    // Earlier years (a year's row leaves out what the strand already shows).
    if h.begun.year < today.year {
        for year in stride(from: today.year - 1, through: h.begun.year, by: -1) {
            older.append(HistoryRow(period: .year(year), summary: summary { $0.year == year && !inWindow($0) }))
        }
    }
    return Strand(items: items, older: older.filter { !$0.summary.isEmpty }, begun: h.begun)
}

/// A page's preview row: the strand's nodes and folds from today back, no
/// month tabs (the view shows as many as fit).
public func recentStrand(_ h: ScopedHistory, today: LocalDate, limit: Int = 14) -> [StrandItem] {
    // A year back is more than a row can hold.
    let start = max(min(h.begun, today), today.adding(days: -365))
    var items: [StrandItem] = []
    for item in strandItems(historyDays(h), from: today, through: start, today: today) {
        switch item {
        case .month: continue
        // Without the tab between them, two folds are one.
        case .gap: if case .gap = items.last { continue }
        case .node: break
        }
        items.append(item)
        if items.count == limit { break }
    }
    // Nothing after a last fold in the row: drop it.
    if case .gap = items.last { items.removeLast() }
    return items
}

/// Days from `from` back to `through`: a node per day with something (and
/// today), one gap per empty run within a month, a month tab where it turns.
func strandItems(_ days: [LocalDate: HistoryDay], from: LocalDate, through: LocalDate,
                 today: LocalDate) -> [StrandItem] {
    var items: [StrandItem] = []
    var pendingGap: LocalDate?
    var previous: LocalDate?
    var date = from
    while date >= through {
        if let previous, previous.month != date.month || previous.year != date.year {
            if let gap = pendingGap { items.append(.gap(gap)) }
            pendingGap = nil
            items.append(.month(year: date.year, month: date.month))
        }
        if let day = days[date], !day.isEmpty {
            if let gap = pendingGap { items.append(.gap(gap)) }
            pendingGap = nil
            items.append(.node(StrandNode(date: date, listNumbers: day.lists.map(\.listNumber), prayed: day.prayed,
                                          journal: day.journal,
                                          answered: day.isAnswered, isToday: date == today)))
        } else if date == today {
            items.append(.node(StrandNode(date: date, isToday: true)))
        } else if pendingGap == nil {
            pendingGap = date
        }
        previous = date
        date = date.adding(days: -1)
    }
    if let gap = pendingGap { items.append(.gap(gap)) }
    return items
}

// MARK: Totals (the tiles)

/// The tiles: "14 · your prayers", "40 · lists" + "138,994 prayers",
/// "3 · in your journal", "1 · answered". A tile at 0 is hidden.
public struct HistoryTotals: Sendable, Equatable {
    public let prayers: Int
    public let lists: Int
    /// What the world prayed those lists: settled counts plus the live count
    /// of the current list when it's among them (tier 3).
    public let worldPrayers: Int
    public let journal: Int
    public let answered: Int

    public init(prayers: Int, lists: Int, worldPrayers: Int, journal: Int, answered: Int) {
        self.prayers = prayers
        self.lists = lists
        self.worldPrayers = worldPrayers
        self.journal = journal
        self.answered = answered
    }
}

public func historyTotals(_ h: ScopedHistory, currentListId: String?, livePrayerCount: Int?) -> HistoryTotals {
    let world = h.lists.reduce(0) { sum, list in
        sum + (list.listId == currentListId ? (livePrayerCount ?? list.prayerCount) : list.prayerCount)
    }
    return HistoryTotals(prayers: h.prayers.count, lists: h.lists.count, worldPrayers: world,
                         journal: h.prayers.filter(\.hasNote).count, answered: h.answered.count)
}

// MARK: The lists behind the tabs

/// Items under day headings, newest day first.
public struct DayGroup<Item: Sendable & Equatable>: Sendable, Equatable {
    public let date: LocalDate
    public let items: [Item]

    public init(date: LocalDate, items: [Item]) {
        self.date = date
        self.items = items
    }
}

/// Groups newest-first items by day, keeping their order.
public func groupedByDay<Item: Sendable & Equatable>(_ items: [Item], day: (Item) -> LocalDate) -> [DayGroup<Item>] {
    var groups: [DayGroup<Item>] = []
    for item in items {
        let date = day(item)
        if let last = groups.last, last.date == date {
            groups[groups.count - 1] = DayGroup(date: date, items: last.items + [item])
        } else {
            groups.append(DayGroup(date: date, items: [item]))
        }
    }
    return groups
}

/// Held: your prayers by day.
public func heldByDay(_ h: ScopedHistory) -> [DayGroup<LoggedPrayer>] {
    groupedByDay(h.prayers, day: \.localDate)
}

/// Journal: the prayers with an entry, by day.
public func journalByDay(_ h: ScopedHistory) -> [DayGroup<LoggedPrayer>] {
    groupedByDay(h.prayers.filter(\.hasNote), day: \.localDate)
}

/// An Answered row's last line: "You prayed 12 times · On 30 lists".
public struct AnsweredSummary: Sendable, Equatable {
    public let moment: AnsweredMoment
    public let prayers: Int
    public let lists: Int
}

/// Answered, newest first, each with its own counts (the intention's, from
/// the whole log, whatever the scope).
public func answeredSummaries(_ h: ScopedHistory, log: HistoryLog) -> [AnsweredSummary] {
    h.answered.map { moment in
        AnsweredSummary(moment: moment,
                        prayers: log.prayers.filter { $0.held.contains(moment.intentionId) }.count,
                        lists: Set(log.entries.filter { $0.subjectId == moment.intentionId }.map(\.list.listId)).count)
    }
}

/// Who a prayer held, as people (an intention counts as its person), in
/// Home order, Me first. Subjects no longer here are left out.
public func peopleHeld(_ prayer: LoggedPrayer, in tree: SubjectTree) -> [Subject] {
    let ids = Set(prayer.held.compactMap { id -> String? in
        guard let subject = tree[id] else { return nil }
        return subject.isName ? id : subject.parentId
    })
    return tree.names.filter { ids.contains($0.id) }
}

// MARK: Time in prayer

/// "Time in prayer · 2h 14m this week · 61h all time" (seconds).
public struct PrayerTime: Sendable, Equatable {
    public let thisWeek: Int
    public let allTime: Int
}

/// The week starts on the locale's first weekday (1 = Sunday).
public func prayerTime(_ prayers: [LoggedPrayer], today: LocalDate, firstWeekday: Int = 1) -> PrayerTime {
    let back = (today.weekdayFromSunday - (firstWeekday - 1) + 7) % 7
    let weekStart = today.adding(days: -back)
    let week = prayers.filter { $0.localDate >= weekStart && $0.localDate <= today }
    return PrayerTime(thisWeek: week.reduce(0) { $0 + $1.durationSeconds },
                      allTime: prayers.reduce(0) { $0 + $1.durationSeconds })
}
