import Foundation

// A name's or an intention's History (detail-page.md "History (calendar,
// 2026-11-08)", stats-history.md): month calendars for the current and the
// previous month, every older period as a text row, then "Begun".
//
// Gold ring = you held them (on the LOCAL date you prayed); bloom = on a
// printed list (on the LIST's date). They can sit a day apart around the
// flip. Future days and days before Begun are blank (no today marker); a
// list entry that exists still shows its bloom on its date.

/// What GetSubjectDetail gives one page (the repository maps it here).
public struct SubjectDetail: Sendable, Equatable {
    public let subjectId: String
    /// The lists it printed on (not EXCLUDED; server-side), any order.
    public var entries: [DetailListEntry]
    /// Your prayers that held it, any order.
    public var prayers: [DetailPrayer]

    public init(subjectId: String, entries: [DetailListEntry] = [], prayers: [DetailPrayer] = []) {
        self.subjectId = subjectId
        self.entries = entries
        self.prayers = prayers
    }
}

public struct DetailListEntry: Sendable, Hashable {
    public let listId: String
    public let listNumber: Int
    /// The list's date (Mountain date at assembly).
    public let listDate: LocalDate
    /// Settled count for a closed list; for the current list, the stored
    /// value (the live one comes from RTDB, stitched by the caller).
    public let prayerCount: Int

    public init(listId: String, listNumber: Int, listDate: LocalDate, prayerCount: Int) {
        self.listId = listId
        self.listNumber = listNumber
        self.listDate = listDate
        self.prayerCount = prayerCount
    }
}

public struct DetailPrayer: Sendable, Hashable {
    public let id: String
    /// The device's local date at the start.
    public let localDate: LocalDate
    /// A synced note (✎ counts reflect synced notes only).
    public let hasNote: Bool

    public init(id: String, localDate: LocalDate, hasNote: Bool = false) {
        self.id = id
        self.localDate = localDate
        self.hasNote = hasNote
    }
}

// MARK: Counts (detail-page.md "Counts")

public struct DetailCounts: Sendable, Equatable {
    /// "Held by you · N prayers" (always shown).
    public let heldByYou: Int
    /// "Carried by the world · N prayers · N lists": nil until ever carried
    /// (never "0 lists").
    public let world: World?

    public struct World: Sendable, Equatable {
        public let prayers: Int
        public let lists: Int
    }
}

/// Tier 1 and tier 3 (backend/CLAUDE.md "Counts"): the world count is the
/// settled counts of closed lists plus the live count of the current list
/// when it's among them.
public func detailCounts(_ detail: SubjectDetail, currentListId: String?, livePrayerCount: Int?) -> DetailCounts {
    let lists = Set(detail.entries.map(\.listId)).count
    var prayers = 0
    for entry in detail.entries {
        prayers += entry.listId == currentListId ? (livePrayerCount ?? entry.prayerCount) : entry.prayerCount
    }
    return DetailCounts(heldByYou: Set(detail.prayers.map(\.id)).count,
                        world: lists > 0 ? .init(prayers: prayers, lists: lists) : nil)
}

// MARK: The calendar

public enum HistoryDay: Sendable, Equatable {
    /// Before Begun or in the future (and not on a list): nothing drawn.
    case blank
    /// Nothing that day: the ~4 pt `thread` dot (the calendar's shape).
    case empty
    /// On a printed list: the bloom.
    case onList
    /// You held them: the gold ring.
    case held
    /// Both: the bloom inside the ring.
    case heldOnList
}

/// A period's line: "You prayed N times · On N lists". Either half is left
/// out when it's 0.
public struct PeriodSummary: Sendable, Equatable {
    public let prayers: Int
    public let lists: Int
    /// Prayers with a synced note: "✎ N" (0 = no mark).
    public let notes: Int
    /// The period the intention was answered in (shown on its own page only).
    public let answered: Bool

    public var isEmpty: Bool { prayers == 0 && lists == 0 }
}

public struct MonthGrid: Sendable, Equatable {
    public let year: Int
    public let month: Int
    /// Weeks of seven, starting on the locale's first weekday; nil pads the
    /// first and last weeks outside the month.
    public let weeks: [[DayCell?]]
    public let summary: PeriodSummary
}

public struct DayCell: Sendable, Equatable {
    public let date: LocalDate
    public let state: HistoryDay
}

public enum HistoryPeriod: Sendable, Equatable {
    case month(year: Int, month: Int)
    case year(Int)
}

public struct HistoryRow: Sendable, Equatable {
    public let period: HistoryPeriod
    public let summary: PeriodSummary
}

public struct History: Sendable, Equatable {
    /// The current month, then the previous one (only from Begun on).
    public let grids: [MonthGrid]
    /// Older periods, newest first: each earlier month of the current year,
    /// then each earlier year. Periods with neither prayers nor lists are
    /// left out.
    public let older: [HistoryRow]
    /// "Begun · Sep 12".
    public let begun: LocalDate
}

/// Buckets a page's history.
/// - Parameters:
///   - begun: the subject's first day (its creation, local).
///   - today: the device's local day.
///   - answeredOn: an intention's Answered day (its own page only), else nil.
///   - firstWeekday: the locale's (`Calendar.firstWeekday`: 1 = Sunday).
public func history(_ detail: SubjectDetail, begun: LocalDate, today: LocalDate, answeredOn: LocalDate? = nil,
                    firstWeekday: Int = 1) -> History {
    let listDays = Set(detail.entries.map(\.listDate))
    let prayers = Dictionary(grouping: Set(detail.prayers), by: \.localDate)
    // Lists counted by list, prayers by prayer.
    func summary(_ contains: (LocalDate) -> Bool) -> PeriodSummary {
        let lists = Set(detail.entries.filter { contains($0.listDate) }.map(\.listId)).count
        let held = prayers.filter { contains($0.key) }.flatMap(\.value)
        return PeriodSummary(prayers: held.count, lists: lists, notes: held.filter(\.hasNote).count,
                             answered: answeredOn.map(contains) ?? false)
    }

    let current = (year: today.year, month: today.month)
    let previous = current.month == 1 ? (year: current.year - 1, month: 12) : (year: current.year, month: current.month - 1)
    var gridMonths = [current]
    if begun < LocalDate(year: current.year, month: current.month, day: 1) { gridMonths.append(previous) }

    let grids = gridMonths.map { ym -> MonthGrid in
        let days = daysIn(year: ym.year, month: ym.month)
        let first = LocalDate(year: ym.year, month: ym.month, day: 1)
        // weekdayFromSunday is 0-based; firstWeekday is 1-based.
        let lead = (first.weekdayFromSunday - (firstWeekday - 1) + 7) % 7
        var cells: [DayCell?] = Array(repeating: nil, count: lead)
        for d in 1...days {
            let date = LocalDate(year: ym.year, month: ym.month, day: d)
            let onList = listDays.contains(date)
            let held = prayers[date] != nil && date >= begun && date <= today
            let state: HistoryDay
            if held && onList {
                state = .heldOnList
            } else if held {
                state = .held
            } else if onList {
                state = .onList
            } else if date < begun || date > today {
                state = .blank
            } else {
                state = .empty
            }
            cells.append(DayCell(date: date, state: state))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        let weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<($0 + 7)]) }
        return MonthGrid(year: ym.year, month: ym.month, weeks: weeks,
                         summary: summary { $0.year == ym.year && $0.month == ym.month })
    }

    let inGrid: (LocalDate) -> Bool = { date in gridMonths.contains { $0.year == date.year && $0.month == date.month } }
    var older: [HistoryRow] = []
    // Earlier months of the current year, newest first.
    let lastGridMonth = gridMonths.last!
    if lastGridMonth.year == current.year {
        for month in stride(from: lastGridMonth.month - 1, through: 1, by: -1)
        where LocalDate(year: current.year, month: month, day: daysIn(year: current.year, month: month)) >= begun {
            older.append(HistoryRow(period: .month(year: current.year, month: month),
                                    summary: summary { $0.year == current.year && $0.month == month }))
        }
    }
    // Earlier years (a year's row leaves out months already shown as grids).
    for year in stride(from: current.year - 1, through: begun.year, by: -1) {
        older.append(HistoryRow(period: .year(year), summary: summary { $0.year == year && !inGrid($0) }))
    }
    return History(grids: grids, older: older.filter { !$0.summary.isEmpty }, begun: begun)
}

/// Days in a month (Gregorian).
public func daysIn(year: Int, month: Int) -> Int {
    switch month {
    case 2: (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
    case 4, 6, 9, 11: 30
    default: 31
    }
}
