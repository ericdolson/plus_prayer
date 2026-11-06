import Foundation
import Testing
@testable import PlusPrayerDomain

struct PoolTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // carried beyond Me: self-1, dad, dad-1, mom → 4

    func user(limit: Int, active: Bool) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit,
                   entitlementExpiresAt: now.addingTimeInterval(active ? 86_400 : -86_400))
    }

    @Test func activeEntitlementMeasuresAgainstTheLimit() {
        #expect(checkPool(tree, user: user(limit: 4, active: true), now: now).fits)
        #expect(!checkPool(tree, user: user(limit: 3, active: true), now: now).fits)
    }

    @Test func freeIsOneIntentionUnderMe() {
        let free = checkPool(tree, user: user(limit: 10, active: false), now: now)
        #expect(!free.fits)
        #expect(free.isFree)
        #expect(free.limit == 1)
        let onlyMine = SubjectTree([Fixture.subjects[3], Fixture.subjects[4]])
        #expect(checkPool(onlyMine, user: user(limit: 10, active: false), now: now).fits)
    }

    @Test func aNewSubjectIsCarriedWhileThereIsRoom() {
        let new = Fixture.name("new", "Ruth", order: 9)
        #expect(carriesNewSubject(new, in: tree, user: user(limit: 5, active: true), now: now))
        #expect(!carriesNewSubject(new, in: tree, user: user(limit: 4, active: true), now: now))
    }
}

struct ToneTests {
    @Test func leastUsedAreTheUnusedFirst() {
        let used = Array(0..<15) // only 15 is unused
        #expect(leastUsedTones(used) == [15])
    }

    @Test func tiesAreAllCandidates() {
        #expect(leastUsedTones([]) == Array(0..<16))
        #expect(leastUsedTones(Array(0..<16) + [3]) == Array(0..<16).filter { $0 != 3 })
    }

    @Test func pickIsAlwaysAmongTheLeastUsed() {
        var generator = SystemRandomNumberGenerator()
        let used = Array(0..<14)
        for _ in 0..<50 {
            #expect([14, 15].contains(pickTone(used, using: &generator)))
        }
    }
}

struct PoolFullInvitationTests {
    let now = Fixture.epoch
    let today = Fixture.today
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))
    let member = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))

    @Test func theFirstFullPoolAddOfTheDayInvites() {
        #expect(poolFullInvitation(user: free, now: now, today: today, premiumPool: 10, shownOn: nil)
                == .membership(premiumPool: 10))
        #expect(poolFullInvitation(user: free, now: now, today: today, premiumPool: 10,
                                   shownOn: today.adding(days: -1)) == .membership(premiumPool: 10))
    }

    @Test func laterThatDayOnlyTheLink() {
        #expect(poolFullInvitation(user: free, now: now, today: today, premiumPool: 10, shownOn: today) == .portionLink)
    }

    @Test func aCooldownOfAWeek() {
        #expect(poolFullInvitation(user: free, now: now, today: today, premiumPool: 10,
                                   shownOn: today.adding(days: -6), cooldownDays: 7) == .portionLink)
        #expect(poolFullInvitation(user: free, now: now, today: today, premiumPool: 10,
                                   shownOn: today.adding(days: -7), cooldownDays: 7) == .membership(premiumPool: 10))
    }

    @Test func onTheTopPoolNeverAnUpsell() {
        #expect(poolFullInvitation(user: member, now: now, today: today, premiumPool: 10, shownOn: nil) == .portionLink)
    }

    @Test func thePoolIsTheEffectiveEntitlement() {
        #expect(effectivePoolLimit(free, now: now) == 1)
        #expect(effectivePoolLimit(member, now: now) == 10)
    }
}
