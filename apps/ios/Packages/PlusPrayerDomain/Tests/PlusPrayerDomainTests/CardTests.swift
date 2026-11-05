import Testing
@testable import PlusPrayerDomain

struct PresenceTests {
    @Test func liveWhenEnoughArePrayingNow() {
        #expect(presenceLine(prayingNow: 239, prayedLastHour: 640, prayedToday: 4113, threshold: 10)
                == PresenceLine(window: .now, count: 239))
    }

    @Test func fallsBackToTheLastHourThenToday() {
        #expect(presenceLine(prayingNow: 9, prayedLastHour: 640, prayedToday: 4113, threshold: 10)
                == PresenceLine(window: .lastHour, count: 640))
        #expect(presenceLine(prayingNow: 3, prayedLastHour: 9, prayedToday: 4113, threshold: 10)
                == PresenceLine(window: .today, count: 4113))
    }

    @Test func hiddenBelowTheThresholdNeverZero() {
        #expect(presenceLine(prayingNow: 0, prayedLastHour: 0, prayedToday: 9, threshold: 10) == nil)
    }

    @Test func theThresholdIsInclusive() {
        #expect(presenceLine(prayingNow: 10, prayedLastHour: 0, prayedToday: 0, threshold: 10)?.window == .now)
    }
}

struct TomorrowStatusTests {
    @Test func coveredWinsOverEverything() {
        #expect(tomorrowStatus(nextListCovered: true, prayedWithListToday: true) == .covered)
        #expect(tomorrowStatus(nextListCovered: true, prayedWithListToday: false) == .covered)
    }

    @Test func prayedTodayButFlippedSince() {
        #expect(tomorrowStatus(nextListCovered: false, prayedWithListToday: true) == .nextPrayerCarries)
    }

    @Test func otherwisePrayToCarry() {
        #expect(tomorrowStatus(nextListCovered: false, prayedWithListToday: false) == .prayToCarry)
    }

    @Test func onlyCoveredIsDone() {
        #expect(!TomorrowStatus.covered.isActionable)
        #expect(TomorrowStatus.prayToCarry.isActionable)
        #expect(TomorrowStatus.nextPrayerCarries.isActionable)
    }
}

/// Same cases as the Flutter build's card_test.dart.
struct AvatarRowTests {
    @Test func countsOverlappingDiscsThatFit() {
        #expect(discCapacity(width: 80, size: 24, step: 16.8) == 4)
    }

    @Test func zeroWhenNotEvenOneFits() {
        #expect(discCapacity(width: 20, size: 24, step: 16.8) == 0)
    }

    @Test func everyoneFitsNoOverflowDisc() {
        #expect(fillRow(people: 10, capacity: 10) == (10, 0))
        #expect(fillRow(people: 3, capacity: 10) == (3, 0))
    }

    @Test func oneMoreThanFitsTheLastSlotBecomesTheDisc() {
        #expect(fillRow(people: 11, capacity: 10) == (9, 2))
    }

    @Test func noRoomAtAll() {
        #expect(fillRow(people: 4, capacity: 0) == (0, 4))
    }
}
