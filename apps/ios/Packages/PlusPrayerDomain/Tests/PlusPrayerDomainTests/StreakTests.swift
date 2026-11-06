import Testing
@testable import PlusPrayerDomain

struct StreakTests {
    let today = Fixture.today

    func user(streak: Int, lastDaysAgo: Int?, grace: Int = 0) -> UserHeader {
        UserHeader(id: "u", currentStreak: streak, bestStreak: streak,
                   lastListLocalDate: lastDaysAgo.map { today.adding(days: -$0) }, graceDays: grace)
    }

    @Test func aliveThroughYesterday() {
        #expect(effectiveStreak(user(streak: 6, lastDaysAgo: 1), today: today) == 6)
        #expect(streakBadgeState(user(streak: 6, lastDaysAgo: 1), today: today) == .alive)
    }

    @Test func sealedToday() {
        #expect(streakBadgeState(user(streak: 6, lastDaysAgo: 0), today: today) == .sealedToday)
    }

    @Test func graceCoversMissedDays() {
        #expect(effectiveStreak(user(streak: 6, lastDaysAgo: 2, grace: 1), today: today) == 6)
        #expect(effectiveStreak(user(streak: 6, lastDaysAgo: 3, grace: 1), today: today) == 0)
        #expect(streakBadgeState(user(streak: 6, lastDaysAgo: 3, grace: 1), today: today) == .none)
    }

    @Test func listPrayerExtendsTheStreak() {
        let next = afterListPrayer(user(streak: 6, lastDaysAgo: 1), on: today)
        #expect(next.currentStreak == 7)
        #expect(next.bestStreak == 7)
        #expect(next.lastListLocalDate == today)
    }

    @Test func listPrayerSpendsGrace() {
        let next = afterListPrayer(user(streak: 6, lastDaysAgo: 2, grace: 2), on: today)
        #expect(next.currentStreak == 7)
        #expect(next.graceDays == 1)
    }

    @Test func aBrokenStreakRestartsAtOne() {
        #expect(afterListPrayer(user(streak: 6, lastDaysAgo: 3), on: today).currentStreak == 1)
    }

    @Test func aSecondPrayerTheSameDayChangesNothing() {
        let once = afterListPrayer(user(streak: 6, lastDaysAgo: 1), on: today)
        #expect(afterListPrayer(once, on: today) == once)
    }
}

struct LocalDateTests {
    @Test func dayArithmeticCrossesMonths() {
        let d = LocalDate(year: 2026, month: 11, day: 1)
        #expect(d.adding(days: -1) == LocalDate(year: 2026, month: 10, day: 31))
        #expect(d.days(since: LocalDate(year: 2026, month: 10, day: 25)) == 7)
    }

    @Test func weekdayFromSunday() {
        #expect(LocalDate(year: 2026, month: 11, day: 1).weekdayFromSunday == 0) // a Sunday
        #expect(Fixture.today.weekdayFromSunday == 4)
    }

    @Test func roundTripsAsAString() {
        #expect(LocalDate(string: "2026-03-07")?.description == "2026-03-07")
        #expect(LocalDate(string: "nope") == nil)
    }
}
