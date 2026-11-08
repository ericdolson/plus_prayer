import Foundation
import Testing
@testable import PlusPrayerDomain

/// History (detail-page.md, 2026-11-08): month grids, older rows, Begun.
struct HistoryTests {
    // Thursday 5 Nov 2026.
    let today = LocalDate(year: 2026, month: 11, day: 5)

    func entry(_ n: Int, _ date: LocalDate, count: Int = 100) -> DetailListEntry {
        DetailListEntry(listId: "l\(n)", listNumber: n, listDate: date, prayerCount: count)
    }
    func d(_ m: Int, _ day: Int, _ y: Int = 2026) -> LocalDate { LocalDate(year: y, month: m, day: day) }

    @Test func gridsAreTheCurrentAndPreviousMonthFromBegun() {
        let detail = SubjectDetail(subjectId: "dad")
        let both = history(detail, begun: d(9, 12), today: today)
        #expect(both.grids.map(\.month) == [11, 10])
        let one = history(detail, begun: d(11, 2), today: today)
        #expect(one.grids.map(\.month) == [11], "begun this month: one grid")
    }

    @Test func daysAreBlankBeforeBegunAndAfterToday() {
        let detail = SubjectDetail(subjectId: "dad",
                                   entries: [entry(50, d(11, 3))],
                                   prayers: [DetailPrayer(id: "p1", localDate: d(11, 3)),
                                             DetailPrayer(id: "p2", localDate: d(11, 4))])
        let grid = history(detail, begun: d(11, 2), today: today).grids[0]
        let cells = grid.weeks.flatMap { $0 }.compactMap { $0 }
        func state(_ day: Int) -> HistoryDay { cells.first { $0.date.day == day }!.state }
        #expect(state(1) == .blank)
        #expect(state(2) == .empty)
        #expect(state(3) == .heldOnList)
        #expect(state(4) == .held)
        #expect(state(5) == .empty, "today, nothing yet")
        #expect(state(6) == .blank, "the future")
        #expect(cells.count == 30)
    }

    @Test func aListEntryShowsItsBloomOnItsDateEvenAhead() {
        let detail = SubjectDetail(subjectId: "dad", entries: [entry(53, d(11, 6))])
        let cells = history(detail, begun: d(10, 1), today: today).grids[0].weeks.flatMap { $0 }.compactMap { $0 }
        #expect(cells.first { $0.date.day == 6 }!.state == .onList)
    }

    @Test func weekStartFollowsTheLocale() {
        // 1 Nov 2026 is a Sunday.
        let sunday = history(SubjectDetail(subjectId: "x"), begun: d(11, 1), today: today, firstWeekday: 1)
        #expect(sunday.grids[0].weeks[0][0]?.date.day == 1)
        let monday = history(SubjectDetail(subjectId: "x"), begun: d(11, 1), today: today, firstWeekday: 2)
        #expect(monday.grids[0].weeks[0][0] == nil)
        #expect(monday.grids[0].weeks[0][6]?.date.day == 1)
        #expect(monday.grids[0].weeks.allSatisfy { $0.count == 7 })
    }

    @Test func summariesCountPrayersListsAndNotes() {
        let detail = SubjectDetail(subjectId: "dad",
                                   entries: [entry(49, d(11, 1)), entry(50, d(11, 2)), entry(20, d(10, 3))],
                                   prayers: [DetailPrayer(id: "a", localDate: d(11, 1), hasNote: true),
                                             DetailPrayer(id: "b", localDate: d(11, 1)),
                                             DetailPrayer(id: "c", localDate: d(10, 9), hasNote: true)])
        let h = history(detail, begun: d(9, 12), today: today)
        #expect(h.grids[0].summary == PeriodSummary(prayers: 2, lists: 2, notes: 1, answered: false))
        #expect(h.grids[1].summary == PeriodSummary(prayers: 1, lists: 1, notes: 1, answered: false))
    }

    @Test func olderPeriodsAreMonthsThenYearsNewestFirstAndEmptyOnesLeftOut() {
        let detail = SubjectDetail(subjectId: "dad",
                                   entries: [entry(10, d(9, 20)), entry(5, d(3, 2, 2025))],
                                   prayers: [DetailPrayer(id: "a", localDate: d(8, 1)),
                                             DetailPrayer(id: "b", localDate: d(12, 1, 2024))])
        let h = history(detail, begun: d(12, 1, 2024), today: today)
        #expect(h.older.map(\.period) == [.month(year: 2026, month: 9), .month(year: 2026, month: 8),
                                         .year(2025), .year(2024)])
        #expect(h.older[0].summary.lists == 1 && h.older[0].summary.prayers == 0, "only the list half")
        #expect(h.older[1].summary.prayers == 1 && h.older[1].summary.lists == 0, "only the prayer half")
        #expect(h.begun == d(12, 1, 2024))
    }

    @Test func inJanuaryLastYearsRowLeavesOutDecembersGrid() {
        let jan = LocalDate(year: 2027, month: 1, day: 10)
        let detail = SubjectDetail(subjectId: "dad", prayers: [DetailPrayer(id: "a", localDate: d(12, 3)),
                                                               DetailPrayer(id: "b", localDate: d(6, 3))])
        let h = history(detail, begun: d(1, 1), today: jan)
        #expect(h.grids.map(\.month) == [1, 12])
        #expect(h.older == [HistoryRow(period: .year(2026),
                                       summary: PeriodSummary(prayers: 1, lists: 0, notes: 0, answered: false))])
    }

    @Test func theAnsweredHintSitsOnItsPeriod() {
        let h = history(SubjectDetail(subjectId: "i", entries: [entry(9, d(8, 3))]), begun: d(7, 1), today: today,
                        answeredOn: d(8, 20))
        #expect(h.older.first { $0.period == .month(year: 2026, month: 8) }?.summary.answered == true)
        #expect(h.grids.allSatisfy { !$0.summary.answered })
    }

    @Test func countsStitchTheLiveCurrentList() {
        let detail = SubjectDetail(subjectId: "dad", entries: [entry(51, d(11, 4), count: 300), entry(52, d(11, 5), count: 10)],
                                   prayers: [DetailPrayer(id: "a", localDate: d(11, 4)), DetailPrayer(id: "a", localDate: d(11, 4))])
        let counts = detailCounts(detail, currentListId: "l52", livePrayerCount: 42)
        #expect(counts.heldByYou == 1)
        #expect(counts.world == .init(prayers: 342, lists: 2))
        #expect(detailCounts(SubjectDetail(subjectId: "x"), currentListId: nil, livePrayerCount: nil).world == nil,
                "never \"0 lists\"")
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
