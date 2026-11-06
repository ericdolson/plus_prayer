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

struct CarryOfferTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // carried beyond Me: self-1, dad, dad-1, mom → 4
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))

    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }

    @Test func onByDefaultWhileThereIsRoom() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(5), now: now)
        #expect(offer == CarryOffer(hasRoom: true, startsOn: true, alsoCarriesParent: false, used: 4, pool: 5,
                                    cost: 1, isFree: false))
        let intention = carryOffer(kind: .intention, parentId: "dad", in: tree, user: member(5), now: now)
        #expect(intention.hasRoom && intention.startsOn && !intention.alsoCarriesParent)
    }

    @Test func aFullPoolIsOffAndDisabled() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(4), now: now)
        #expect(!offer.hasRoom && !offer.startsOn)
        #expect(offer.used == 4 && offer.pool == 4)
    }

    @Test func underMeAnIntentionNeverCarriesItsName() {
        let offer = carryOffer(kind: .intention, parentId: "self", in: tree, user: member(5), now: now)
        #expect(offer.hasRoom && offer.startsOn && !offer.alsoCarriesParent)
    }

    @Test func underAnUncarriedNameItStartsOffAndCarriesTheNameToo() {
        // Bea isn't carried; her intention bea-1 still is, so carrying her
        // costs Bea + bea-1 + the new one: 4 + 3 = 7.
        let roomy = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(7), now: now)
        #expect(roomy == CarryOffer(hasRoom: true, startsOn: false, alsoCarriesParent: true, used: 4, pool: 7,
                                    cost: 3, isFree: false))
        let tight = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(6), now: now)
        #expect(!tight.hasRoom && tight.alsoCarriesParent)
    }

    @Test func theFreePoolCarriesOneIntentionUnderMeOnly() {
        let mine = SubjectTree([Fixture.subjects[3]])
        #expect(carryOffer(kind: .intention, parentId: "self", in: mine, user: free, now: now).hasRoom)
        #expect(!carryOffer(kind: .soul, parentId: nil, in: mine, user: free, now: now).hasRoom)
        let offer = carryOffer(kind: .soul, parentId: nil, in: mine, user: free, now: now)
        #expect(offer.used == 0 && offer.pool == 1)
    }

    @Test func thePoolIsTheEffectiveEntitlement() {
        #expect(effectivePoolLimit(free, now: now) == 1)
        #expect(effectivePoolLimit(member(10), now: now) == 10)
    }

    @Test func theMeterPreviewsTheResult() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(10), now: now)
        #expect(carryMeter(offer, kind: .soul, isOn: true) == .used(5, pool: 10))
        #expect(carryMeter(offer, kind: .soul, isOn: false) == .used(4, pool: 10))
        let bea = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(10), now: now)
        #expect(carryMeter(bea, kind: .intention, isOn: true) == .used(7, pool: 10), "the true cost")
    }

    @Test func overThePoolSaysAllInUse() {
        // A lapsed trial: 4 carried against the free pool of 1.
        let intention = carryOffer(kind: .intention, parentId: "self", in: tree, user: free, now: now)
        #expect(carryMeter(intention, kind: .intention, isOn: false) == .allInUse(pool: 1))
    }

    @Test func theFreePoolsNameTabExplainsInstead() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: SubjectTree([Fixture.subjects[3]]), user: free, now: now)
        #expect(offer.isFree && !offer.hasRoom)
        #expect(carryMeter(offer, kind: .soul, isOn: false) == .freeYouAndOneIntention)
        // Over the pool too: still the explanation on the Name tab.
        let lapsed = carryOffer(kind: .soul, parentId: nil, in: tree, user: free, now: now)
        #expect(carryMeter(lapsed, kind: .soul, isOn: false) == .freeYouAndOneIntention)
    }
}
