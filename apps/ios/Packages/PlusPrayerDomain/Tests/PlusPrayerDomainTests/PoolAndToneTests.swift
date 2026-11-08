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

    @Test func theMeterSaysWhatsLeftWhicheverWayTheToggleIs() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(10), now: now)
        #expect(carryMeter(offer, kind: .soul, isOn: true) == .left(6))
        #expect(carryMeter(offer, kind: .soul, isOn: false) == .left(6))
        let bea = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(10), now: now)
        #expect(carryMeter(bea, kind: .intention, isOn: true) == .left(6), "the cost is the Also line's job")
    }

    @Test func onWithOneLeftItTakesTheLastPlace() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(5), now: now)
        #expect(carryMeter(offer, kind: .soul, isOn: true) == .usesLast(1))
        #expect(carryMeter(offer, kind: .soul, isOn: false) == .left(1))
    }

    @Test func onAndTakingEverythingLeftSaysTheLastPlaces() {
        // Bea costs 3 (her, her flagged intention, the new one): 3 left of 7.
        let all = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(7), now: now)
        #expect(carryMeter(all, kind: .intention, isOn: true) == .usesLast(3))
        #expect(carryMeter(all, kind: .intention, isOn: false) == .left(3))
        let some = carryOffer(kind: .intention, parentId: "bea", in: tree, user: member(8), now: now)
        #expect(carryMeter(some, kind: .intention, isOn: true) == .left(4))
    }

    @Test func fullSaysAllInUse() {
        let offer = carryOffer(kind: .soul, parentId: nil, in: tree, user: member(4), now: now)
        #expect(carryMeter(offer, kind: .soul, isOn: false) == .allInUse(pool: 4))
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

/// A name's carry row on its page.
struct NameCarryOfferTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // carried beyond Me: self-1, dad, dad-1, mom → 4; Bea off, bea-1 flagged
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))

    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }

    @Test func aCarriedNameIsOnAndLeftOutOfWhatsUsed() {
        // Dad and dad-1 are his: 2 of the 4.
        let offer = nameCarryOffer(nameId: "dad", in: tree, user: member(10), now: now)
        #expect(offer.startsOn && offer.hasRoom)
        #expect(offer.used == 2 && offer.cost == 2)
        #expect(carryMeter(offer, kind: .soul, isOn: true) == .left(8))
    }

    @Test func reCarryingANameCountsItsFlaggedIntentions() {
        let roomy = nameCarryOffer(nameId: "bea", in: tree, user: member(6), now: now)
        #expect(!roomy.startsOn && roomy.hasRoom)
        #expect(roomy.cost == 2, "Bea and bea-1")
        #expect(carryMeter(roomy, kind: .soul, isOn: false) == .left(2))
        let tight = nameCarryOffer(nameId: "bea", in: tree, user: member(5), now: now)
        #expect(!tight.hasRoom, "1 left, Bea costs 2")
    }

    @Test func aCarriedNameCanStayOnOverThePoolAndTurnOff() {
        let offer = nameCarryOffer(nameId: "dad", in: tree, user: free, now: now)
        #expect(offer.hasRoom, "on already: nothing to fit")
        #expect(carryMeter(offer, kind: .soul, isOn: true) == .freeYouAndOneIntention)
    }

    @Test func theFreePoolNeverFitsAName() {
        let offer = nameCarryOffer(nameId: "bea", in: tree, user: free, now: now)
        #expect(!offer.hasRoom)
        #expect(offer.isOverPool, "Dad and Mom are still carried")
        #expect(nameCarryMeter(offer) == .allInUse(pool: 1), "over the free pool: never the free line")
    }

    @Test func withinTheFreePoolTheFreeLineShows() {
        // Me, Me's one carried intention, and Bea (off): within the free pool.
        let me = Fixture.subjects.first { $0.isSelf }!
        let mine = Fixture.subjects.first { $0.parentId == me.id && $0.isCarried && !$0.isResolved }!
        let bea = Fixture.name("bea", "Bea", order: 5, carried: false)
        let small = SubjectTree([me, mine, bea])
        let offer = nameCarryOffer(nameId: "bea", in: small, user: free, now: now)
        #expect(!offer.isOverPool && !offer.hasRoom)
        #expect(nameCarryMeter(offer) == .freeYouAndOneIntention)
    }

    @Test func aLapsedTrialOverTheFreePoolSeesWhatACarriedNameUses() {
        // Trial ended with Dad (and dad-1) and Mom still carried.
        let dad = nameCarryOffer(nameId: "dad", in: tree, user: free, now: now)
        #expect(dad.isFree && dad.isOverPool && dad.startsOn && dad.hasRoom, "on, and free to turn off")
        #expect(nameCarryMeter(dad) == .usesNoneLeft(cost: 2))
        #expect(nameCarryMeter(nameCarryOffer(nameId: "mom", in: tree, user: free, now: now))
                == .usesNoneLeft(cost: 1), "an answered intention doesn't count")
    }

    @Test func carriedTheMeterSaysWhatItUsesAndWhatsFreeOverall() {
        // 4 carried of 10: Dad uses 2 (him and dad-1), 6 left.
        #expect(nameCarryMeter(nameCarryOffer(nameId: "dad", in: tree, user: member(10), now: now))
                == .uses(cost: 2, left: 6))
        #expect(nameCarryMeter(nameCarryOffer(nameId: "mom", in: tree, user: member(10), now: now))
                == .uses(cost: 1, left: 6), "an answered intention doesn't count")
        #expect(nameCarryMeter(nameCarryOffer(nameId: "dad", in: tree, user: member(3), now: now))
                == .usesNoneLeft(cost: 2), "over the pool (a lapsed trial): never below 0")
    }

    @Test func carriedWithNoneFreeSaysNoneLeft() {
        // Exactly full: 4 of 4.
        let full = nameCarryOffer(nameId: "dad", in: tree, user: member(4), now: now)
        #expect(nameCarryMeter(full) == .usesNoneLeft(cost: 2))
        #expect(full.hasRoom, "turning it off is never blocked")
        // Over the pool: 4 of 1, still none (not -3) and still free to turn off.
        let over = nameCarryOffer(nameId: "mom", in: tree, user: member(1), now: now)
        #expect(nameCarryMeter(over) == .usesNoneLeft(cost: 1))
        #expect(over.hasRoom)
    }

    @Test func someRoomButNotEnoughWouldUseAndIsDisabled() {
        // 4 of 5: 1 left, Bea would use 2 (her and bea-1).
        let offer = nameCarryOffer(nameId: "bea", in: tree, user: member(5), now: now)
        #expect(nameCarryMeter(offer) == .wouldUse(cost: 2, left: 1))
        #expect(!offer.hasRoom && !offer.startsOn)
    }

    @Test func usesAndWouldUseNeverCountAnsweredIntentions() {
        // Ruth (off) with one open intention flagged and one Answered flagged.
        let ruth = Fixture.name("ruth", "Ruth", order: 9, carried: false)
        let open = Fixture.intention("ruth-1", "ruth", "Work", order: 1)
        let answered = Fixture.intention("ruth-2", "ruth", "A job", order: 2, answered: true)
        let withRuth = SubjectTree(Fixture.subjects + [ruth, open, answered])
        #expect(nameCarryMeter(nameCarryOffer(nameId: "ruth", in: withRuth, user: member(10), now: now))
                == .wouldUse(cost: 2, left: 6))
        var carried = ruth
        carried.isCarried = true
        let on = SubjectTree(Fixture.subjects + [carried, open, answered])
        #expect(nameCarryMeter(nameCarryOffer(nameId: "ruth", in: on, user: member(10), now: now))
                == .uses(cost: 2, left: 4))
    }

    @Test func notCarriedTheMeterSaysWhatCarryingWouldCost() {
        // Bea would bring back bea-1: 2 places.
        #expect(nameCarryMeter(nameCarryOffer(nameId: "bea", in: tree, user: member(10), now: now))
                == .wouldUse(cost: 2, left: 6))
        #expect(nameCarryMeter(nameCarryOffer(nameId: "bea", in: tree, user: member(6), now: now)) == .usesLast(2))
        #expect(nameCarryMeter(nameCarryOffer(nameId: "bea", in: tree, user: member(4), now: now))
                == .allInUse(pool: 4))
        let ruth = Fixture.name("ruth", "Ruth", order: 9, carried: false)
        let withRuth = SubjectTree(Fixture.subjects + [ruth])
        #expect(nameCarryMeter(nameCarryOffer(nameId: "ruth", in: withRuth, user: member(10), now: now)) == .left(6))
        #expect(nameCarryMeter(nameCarryOffer(nameId: "ruth", in: withRuth, user: member(5), now: now)) == .usesLast(1))
    }
}

/// Restore is pool-aware (mirrors the server's restoreSubject).
struct RestoreCarryTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // 4 carried beyond Me
    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))
    let ann = Fixture.name("ann", "Ann", order: 9)
    let annWork = Fixture.intention("ann-1", "ann", "Work", order: 1)

    @Test func underThePoolRestoreKeepsCarrying() {
        #expect(restoredCarryFlag(ann, intentions: [annWork], into: tree, user: member(6), now: now))
    }

    @Test func overThePoolANameComesBackUncarried() {
        // 4 + Ann + her intention = 6 > 5.
        #expect(!restoredCarryFlag(ann, intentions: [annWork], into: tree, user: member(5), now: now))
        #expect(!restoredCarryFlag(ann, into: tree, user: free, now: now), "a lapsed trial")
    }

    @Test func overThePoolAnIntentionComesBackUncarried() {
        let dad3 = Fixture.intention("dad-3", "dad", "Sleep", order: 3)
        #expect(!restoredCarryFlag(dad3, into: tree, user: member(4), now: now))
        #expect(restoredCarryFlag(dad3, into: tree, user: member(5), now: now))
    }

    @Test func aRestoreThatAddsNothingKeepsItsFlag() {
        // Under Bea (not carried): doesn't print, so nothing to fit.
        let bea2 = Fixture.intention("bea-2", "bea", "Peace", order: 2)
        #expect(restoredCarryFlag(bea2, into: tree, user: free, now: now))
        let answered = Fixture.intention("dad-4", "dad", "Results", order: 4, answered: true)
        #expect(restoredCarryFlag(answered, into: tree, user: member(1), now: now))
        var off = ann
        off.isCarried = false
        #expect(!restoredCarryFlag(off, into: tree, user: member(10), now: now), "an uncarried item stays off")
    }
}
