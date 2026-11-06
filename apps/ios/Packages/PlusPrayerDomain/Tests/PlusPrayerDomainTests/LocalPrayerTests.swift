import Foundation
import Testing
@testable import PlusPrayerDomain

struct LocalPrayerTests {
    let today = Fixture.today
    let list = CurrentList(id: "list-52", listNumber: 52, listDate: Fixture.today, isPublished: true,
                           soulCount: 4345, intentionCount: 1212, prayerCount: 3880)

    func prayer(_ ids: [String], list: Bool = false, startedAt: Date = Fixture.epoch) -> NewPrayer {
        NewPrayer(id: UUID().uuidString, startedAt: startedAt, prayedAt: startedAt.addingTimeInterval(60),
                  localDate: today, timezone: "America/Denver", communityListId: list ? "list-52" : nil,
                  listContextNumber: 52, subjectIds: ids)
    }

    @Test func aHeldIntentionHoldsItsNameToday() {
        let folded = SubjectTree(subjectsWithLocalPrayers(Fixture.subjects, [prayer(["bea-1"])]))
        #expect(isHeldToday(folded["bea-1"]!, today: today))
        #expect(isHeldToday(folded["bea"]!, today: today))
        #expect(!isHeldToday(folded["self"]!, today: today))
    }

    @Test func foldingIsIdempotentAndNeverGoesBack() {
        var subjects = Fixture.subjects
        subjects[0].lastPrayed = today.adding(days: 1)
        let folded = subjectsWithLocalPrayers(subjects, [prayer(["dad"])])
        #expect(folded[0].lastPrayed == today.adding(days: 1))
    }

    @Test func aListPrayerSealsTodayInTheHeader() {
        let header = UserHeader(id: "u", currentStreak: 6, lastListLocalDate: today.adding(days: -1))
        let folded = headerWithLocalPrayers(header, [prayer([], list: true)])
        #expect(prayedWithListToday(folded, today: today))
        #expect(folded.currentStreak == 7)
        #expect(headerWithLocalPrayers(header, [prayer(["dad"])]) == header)
    }

    @Test func coveredByTheServerOrALocalPrayerBeforeTheCutoff() {
        #expect(nextListCovered(list, status: MyListStatus(listId: "list-52", prayersWithList: 1), local: []))
        #expect(!nextListCovered(list, status: MyListStatus(listId: "list-52"), local: []))
        #expect(nextListCovered(list, status: nil, local: [prayer([], list: true)]))
        var closed = list
        closed.closesAt = Fixture.epoch
        #expect(!nextListCovered(closed, status: nil, local: [prayer([], list: true)]))
    }

    @Test func newPrayerFromASelection() {
        let selection = PrayerSelection(held: ["dad", "dad-1"], listIncluded: true)
        let started = Fixture.epoch
        let p = newPrayer(id: "p1", selection: selection, startedAt: started, endedAt: started.addingTimeInterval(42.7),
                          list: ListContext(listId: "list-52", listNumber: 52))
        #expect(p.subjectIds == ["dad", "dad-1"])
        #expect(p.communityListId == "list-52")
        #expect(p.durationSeconds == 42)
        let personal = newPrayer(id: "p2", selection: selection.withList(false), startedAt: started,
                                 endedAt: started.addingTimeInterval(10), list: ListContext(listId: "list-52", listNumber: 52))
        #expect(personal.communityListId == nil)
        #expect(personal.listContextNumber == 52)
    }
}

struct ClosingAndPresenceTests {
    let now = Fixture.epoch

    @Test func closingNoticeInTheLastFiveMinutes() {
        #expect(closingSoonMinutes(closesAt: now.addingTimeInterval(4 * 60 + 1), now: now, prayedWithListToday: false) == 5)
        #expect(closingSoonMinutes(closesAt: now.addingTimeInterval(10), now: now, prayedWithListToday: false) == 1)
        #expect(closingSoonMinutes(closesAt: now.addingTimeInterval(6 * 60), now: now, prayedWithListToday: false) == nil)
        #expect(closingSoonMinutes(closesAt: now.addingTimeInterval(-1), now: now, prayedWithListToday: false) == nil)
        #expect(closingSoonMinutes(closesAt: now.addingTimeInterval(60), now: now, prayedWithListToday: true) == nil)
    }

    @Test func othersInPrayerLeavesYouOut() {
        #expect(othersInPrayer(LiveStats(prayingNow: 213, prayedLastHour: 0, prayedToday: 0), threshold: 10) == 212)
        #expect(othersInPrayer(LiveStats(prayingNow: 9, prayedLastHour: 0, prayedToday: 0), threshold: 10) == nil)
    }
}
