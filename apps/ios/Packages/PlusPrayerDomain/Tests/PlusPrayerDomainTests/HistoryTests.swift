import Foundation
import Testing
@testable import PlusPrayerDomain

/// History (history.md, 2026-11-08): scoping the log, the strand (nodes,
/// folds, month tabs), older periods, the tiles, and the tabs' lists.
struct HistoryTests {
    // Thursday 5 Nov 2026.
    let today = Fixture.today
    var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func d(_ m: Int, _ day: Int, _ y: Int = 2026) -> LocalDate { LocalDate(year: y, month: m, day: day) }
    func list(_ n: Int, _ date: LocalDate, count: Int = 100) -> ListRecord {
        ListRecord(listId: "l\(n)", listNumber: n, listDate: date, prayerCount: count, sealVariant: date.weekdayFromSunday)
    }
    func entry(_ subject: String, _ n: Int, _ date: LocalDate, count: Int = 100) -> LoggedEntry {
        LoggedEntry(subjectId: subject, list: list(n, date, count: count))
    }
    func prayer(_ id: String, _ date: LocalDate, hour: Int = 8, minutes: Int = 10, note: String? = nil,
                held: Set<String>) -> LoggedPrayer {
        let start = date.start(in: utc).addingTimeInterval(Double(hour) * 3600)
        return LoggedPrayer(id: id, startedAt: start, localDate: date, durationSeconds: minutes * 60, note: note,
                            held: held)
    }
    func scoped(_ log: HistoryLog, _ scope: HistoryScope, tree: SubjectTree = Fixture.tree) -> ScopedHistory {
        scopedHistory(log, scope: scope, tree: tree, calendar: utc)
    }
    func nodes(_ items: [StrandItem]) -> [StrandNode] {
        items.compactMap { if case .node(let n) = $0 { n } else { nil } }
    }

    // MARK: Scope

    @Test func everyoneIsAllYourPrayersAndTheListsYouWereOn() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 3), held: ["dad", "dad-1"]),
                                       prayer("b", d(11, 4), held: ["bea"])],
                             entries: [entry("self", 50, d(11, 3)), entry("dad", 50, d(11, 3)),
                                       entry("dad", 49, d(11, 2))])
        let h = scoped(log, .everyone)
        #expect(h.prayers.map(\.id) == ["b", "a"], "newest first")
        #expect(h.lists.map(\.listNumber) == [50], "only the self's entries: you were on that list")
        #expect(h.begun == d(11, 3), "everyone begins at your first prayer")
        #expect(h.answered.map(\.intentionId) == ["mom-1"])
    }

    @Test func aPersonIncludesTheirIntentionsAndBeginsAtTheirCreation() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 3), held: ["dad-2"]),
                                       prayer("b", d(11, 4), held: ["mom"])],
                             entries: [entry("dad", 50, d(11, 3)), entry("dad-1", 50, d(11, 3))])
        let dad = scoped(log, .subject("dad"))
        #expect(dad.prayers.map(\.id) == ["a"], "a prayer for one of his intentions holds him")
        #expect(dad.lists.map(\.listNumber) == [50])
        #expect(dad.begun == LocalDate(Fixture.epoch, calendar: utc))
        let intention = scoped(log, .subject("dad-1"))
        #expect(intention.prayers.isEmpty)
        #expect(intention.lists.map(\.listNumber) == [50])
        #expect(scoped(log, .subject("mom")).answered.map(\.intentionId) == ["mom-1"])
        #expect(scoped(log, .subject("mom-1")).answered.count == 1)
        #expect(scoped(log, .subject("dad")).answered.isEmpty)
    }

    @Test func releasedIntentionsNeverAppear() {
        var subjects = Fixture.subjects
        let i = subjects.firstIndex { $0.id == "mom-1" }!
        subjects[i].resolution = .released
        let h = scoped(HistoryLog(), .everyone, tree: SubjectTree(subjects))
        #expect(h.answered.isEmpty)
    }

    @Test func localPrayersFoldInOnceWithTheirNames() {
        let local = NewPrayer(id: "n1", startedAt: Fixture.epoch, prayedAt: Fixture.epoch.addingTimeInterval(600),
                              localDate: today, timezone: "UTC", communityListId: nil, listContextNumber: 52,
                              subjectIds: ["dad-1"])
        let log = historyLogWithLocalPrayers(HistoryLog(), [local], tree: Fixture.tree)
        #expect(log.prayers.first?.held == ["dad", "dad-1"])
        #expect(log.prayers.first?.durationSeconds == 600)
        #expect(historyLogWithLocalPrayers(log, [local], tree: Fixture.tree).prayers.count == 1, "idempotent")
    }

    // MARK: The strand

    @Test func theStrandStartsAtTodayAndMarksEachDay() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 4), note: "Quiet morning.", held: ["dad"]),
                                       prayer("b", d(11, 3), held: ["dad"])],
                             entries: [entry("dad", 51, d(11, 4)), entry("dad", 50, d(11, 2))])
        let items = strand(scoped(log, .subject("dad")), today: today).items
        #expect(items.prefix(4) == [
            .node(StrandNode(date: d(11, 5), isToday: true)),
            .node(StrandNode(date: d(11, 4), listNumbers: [51], prayed: true, journal: true)),
            .node(StrandNode(date: d(11, 3), prayed: true)),
            .node(StrandNode(date: d(11, 2), listNumbers: [50])),
        ], "today's node exists before anything happened")
    }

    @Test func emptyRunsFoldToOneGapWhateverTheLength() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 4), held: ["dad"]), prayer("b", d(11, 1), held: ["dad"])])
        let items = strand(scoped(log, .subject("dad")), today: today).items
        #expect(Array(items.prefix(4)) == [.node(StrandNode(date: d(11, 5), isToday: true)),
                                           .node(StrandNode(date: d(11, 4), prayed: true)),
                                           .gap(d(11, 3)),
                                           .node(StrandNode(date: d(11, 1), prayed: true))])
        // October is empty: one tab, then one fold for the whole month.
        #expect(Array(items.dropFirst(4)) == [.month(year: 2026, month: 10), .gap(d(10, 31))])
    }

    @Test func aMonthTabSitsWhereTheMonthTurnsAndSplitsAFold() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 3), held: ["dad"]), prayer("b", d(10, 29), held: ["dad"])])
        let items = strand(scoped(log, .subject("dad")), today: today).items
        #expect(items == [.node(StrandNode(date: d(11, 5), isToday: true)),
                          .gap(d(11, 4)),
                          .node(StrandNode(date: d(11, 3), prayed: true)),
                          .gap(d(11, 2)),
                          .month(year: 2026, month: 10),
                          .gap(d(10, 31)),
                          .node(StrandNode(date: d(10, 29), prayed: true)),
                          .gap(d(10, 28))])
    }

    @Test func theStrandStopsAtBegun() {
        let tree = SubjectTree([Subject(id: "self", kind: .soul, publicName: "Eric", alias: "Me", isSelf: true,
                                        isCarried: true, sortOrder: 0, createdAt: d(11, 3).start(in: utc))])
        let log = HistoryLog(prayers: [prayer("a", d(11, 3), held: ["self"])])
        let s = strand(scoped(log, .subject("self"), tree: tree), today: today)
        #expect(s.items == [.node(StrandNode(date: d(11, 5), isToday: true)), .gap(d(11, 4)),
                            .node(StrandNode(date: d(11, 3), prayed: true))])
        #expect(s.older.isEmpty)
        #expect(s.begun == d(11, 3))
    }

    @Test func anAnsweredDayGetsItsMark() {
        var subjects = Fixture.subjects
        let i = subjects.firstIndex { $0.id == "mom-1" }!
        subjects[i].resolvedAt = d(11, 2).start(in: utc).addingTimeInterval(3600)
        let items = strand(scoped(HistoryLog(), .subject("mom"), tree: SubjectTree(subjects)), today: today).items
        #expect(nodes(items).contains(StrandNode(date: d(11, 2), answered: true)))
    }

    @Test func daysAfterTodayArentDrawn() {
        let log = HistoryLog(entries: [entry("dad", 53, d(11, 6))])
        let items = strand(scoped(log, .subject("dad")), today: today).items
        #expect(!nodes(items).contains { $0.date > today })
    }

    @Test func olderPeriodsAreMonthsThenYearsNewestFirstAndEmptyOnesLeftOut() {
        let tree = SubjectTree([Subject(id: "self", kind: .soul, publicName: "Eric", alias: "Me", isSelf: true,
                                        isCarried: true, sortOrder: 0, createdAt: d(12, 1, 2024).start(in: utc))])
        let log = HistoryLog(prayers: [prayer("a", d(8, 1), note: "x", held: ["self"]),
                                       prayer("b", d(12, 1, 2024), held: ["self"])],
                             entries: [entry("self", 10, d(9, 20)), entry("self", 5, d(3, 2, 2025))])
        let s = strand(scoped(log, .subject("self"), tree: tree), today: today)
        #expect(s.older.map(\.period) == [.month(year: 2026, month: 9), .month(year: 2026, month: 8),
                                          .year(2025), .year(2024)])
        #expect(s.older[0].summary == PeriodSummary(prayers: 0, lists: 1, notes: 0))
        #expect(s.older[1].summary == PeriodSummary(prayers: 1, lists: 0, notes: 1))
        #expect(s.begun == d(12, 1, 2024))
    }

    @Test func inJanuaryLastYearsRowLeavesOutDecembersStrand() {
        let jan = LocalDate(year: 2027, month: 1, day: 10)
        let tree = SubjectTree([Subject(id: "self", kind: .soul, publicName: "Eric", alias: "Me", isSelf: true,
                                        isCarried: true, sortOrder: 0, createdAt: d(1, 1).start(in: utc))])
        let log = HistoryLog(prayers: [prayer("a", d(12, 3), held: ["self"]), prayer("b", d(6, 3), held: ["self"])])
        let s = strand(scoped(log, .subject("self"), tree: tree), today: jan)
        #expect(s.items.contains(.month(year: 2026, month: 12)))
        #expect(s.older == [HistoryRow(period: .year(2026), summary: PeriodSummary(prayers: 1, lists: 0, notes: 0))])
    }

    @Test func thePreviewRowHasNoMonthTabsAndNoTrailingFold() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 3), held: ["dad"]), prayer("b", d(10, 29), held: ["dad"])])
        let row = recentStrand(scoped(log, .subject("dad")), today: today, limit: 5)
        #expect(row == [.node(StrandNode(date: d(11, 5), isToday: true)), .gap(d(11, 4)),
                        .node(StrandNode(date: d(11, 3), prayed: true)), .gap(d(11, 2)),
                        .node(StrandNode(date: d(10, 29), prayed: true))], "the folds either side of a tab merge")
        #expect(recentStrand(scoped(log, .subject("dad")), today: today, limit: 4).last
                == .node(StrandNode(date: d(11, 3), prayed: true)), "no fold at the end")
        #expect(recentStrand(scoped(HistoryLog(), .subject("dad")), today: today)
                == [.node(StrandNode(date: d(11, 5), isToday: true))], "a new person: today only")
    }

    // MARK: The day sheet, the tiles, the tabs

    @Test func aDayHoldsItsListsPrayersAndAnswers() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 4), hour: 7, held: ["dad"]),
                                       prayer("b", d(11, 4), hour: 21, held: ["mom"])],
                             entries: [entry("self", 51, d(11, 4), count: 3475)])
        let day = historyDay(d(11, 4), in: scoped(log, .everyone))
        #expect(day.lists.map(\.listNumber) == [51])
        #expect(day.prayers.map(\.id) == ["b", "a"])
        #expect(historyDay(d(11, 1), in: scoped(log, .everyone)).isEmpty)
    }

    @Test func totalsCountTheTilesAndStitchTheLiveList() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 4), note: "x", held: ["dad"]),
                                       prayer("b", d(11, 5), note: "  ", held: ["dad-1"])],
                             entries: [entry("dad", 51, d(11, 4), count: 300), entry("dad", 52, d(11, 5), count: 10)])
        let totals = historyTotals(scoped(log, .subject("dad")), currentListId: "l52", livePrayerCount: 42)
        #expect(totals == HistoryTotals(prayers: 2, lists: 2, worldPrayers: 342, journal: 1, answered: 0),
                "a blank note isn't a journal entry")
        #expect(historyTotals(scoped(log, .subject("mom")), currentListId: nil, livePrayerCount: nil).answered == 1)
    }

    @Test func heldAndJournalGroupByDayNewestFirst() {
        let log = HistoryLog(prayers: [prayer("a", d(11, 4), hour: 7, held: ["dad"]),
                                       prayer("b", d(11, 4), hour: 21, note: "Evening.", held: ["dad"]),
                                       prayer("c", d(11, 2), held: ["dad"])])
        let h = scoped(log, .everyone)
        #expect(heldByDay(h).map(\.date) == [d(11, 4), d(11, 2)])
        #expect(heldByDay(h)[0].items.map(\.id) == ["b", "a"])
        #expect(journalByDay(h).map { $0.items.map(\.id) } == [["b"]])
    }

    @Test func answeredRowsCountTheirOwnPrayersAndLists() {
        let log = HistoryLog(prayers: [prayer("a", d(10, 1), held: ["mom", "mom-1"]), prayer("b", d(10, 2), held: ["mom"])],
                             entries: [entry("mom-1", 20, d(10, 1)), entry("mom-1", 21, d(10, 2)),
                                       entry("mom", 21, d(10, 2))])
        let rows = answeredSummaries(scoped(log, .everyone), log: log)
        #expect(rows.map(\.prayers) == [1])
        #expect(rows.map(\.lists) == [2])
    }

    @Test func peopleHeldAreNamesInHomeOrder() {
        let p = prayer("a", today, held: ["mom", "dad-1", "dad", "self-1", "gone"])
        #expect(peopleHeld(p, in: Fixture.tree).map(\.id) == ["self", "dad", "mom"])
    }

    @Test func timeInPrayerThisWeekFollowsTheLocale() {
        // Sun 1 Nov … Thu 5 Nov; Mon 2 Nov starts a Monday week.
        let prayers = [prayer("a", d(11, 1), minutes: 10, held: []), prayer("b", d(11, 3), minutes: 20, held: []),
                       prayer("c", d(10, 30), minutes: 30, held: [])]
        #expect(prayerTime(prayers, today: today, firstWeekday: 1) == PrayerTime(thisWeek: 1800, allTime: 3600))
        #expect(prayerTime(prayers, today: today, firstWeekday: 2) == PrayerTime(thisWeek: 1200, allTime: 3600))
    }
}

/// The carry card's footer (detail-page.md "Status line", 2026-11-08).
struct CarryStatusTests {
    let tree = Fixture.tree

    @Test func carriedFollowsTheGate() {
        let dad = tree["dad"]!
        #expect(carryStatus(dad, in: tree, list: 52, tomorrow: .prayToCarry, closingMinutes: nil)
                == .list(.prayToCarry, next: 53))
        #expect(carryStatus(dad, in: tree, list: 52, tomorrow: .covered, closingMinutes: nil)?.isActionable == false)
        #expect(carryStatus(dad, in: tree, list: 52, tomorrow: .prayToCarry, closingMinutes: 4)
                == .closing(list: 52, minutes: 4, next: 53))
        #expect(carryStatus(dad, in: tree, list: nil, tomorrow: nil, closingMinutes: nil) == nil)
    }

    @Test func notCarriedIsPrivate() {
        #expect(carryStatus(tree["bea"]!, in: tree, list: 52, tomorrow: .covered, closingMinutes: 3) == .privateOnly,
                "no closing notice while not carried")
        #expect(carryStatus(tree["dad-2"]!, in: tree, list: 52, tomorrow: .covered, closingMinutes: nil) == .privateOnly)
    }

    @Test func aChosenIntentionUnderAPersonOffIsPrivateWhileTheyreOff() {
        #expect(carryStatus(tree["bea-1"]!, in: tree, list: 52, tomorrow: .covered, closingMinutes: nil)
                == .privateWhilePersonOff)
        #expect(carryStatus(tree["dad-1"]!, in: tree, list: 52, tomorrow: .covered, closingMinutes: nil)
                == .list(.covered, next: 53))
        #expect(carryStatus(tree["self-1"]!, in: tree, list: 52, tomorrow: .nextPrayerCarries, closingMinutes: nil)
                == .list(.nextPrayerCarries, next: 53), "Me is always carried")
    }

    @Test func theSelfIsAlwaysCarried() {
        #expect(carryStatus(tree["self"]!, in: tree, list: 52, tomorrow: .covered, closingMinutes: nil)
                == .list(.covered, next: 53))
    }
}
