import Foundation
import Testing
@testable import PlusPrayerDomain

/// Q32 (2026-11-08): the pool counts people; each person prints with up to
/// `intentionsPerPerson` chosen intentions.
struct PoolTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // carried people beyond Me: Dad, Mom → 2 (Bea off)

    func user(limit: Int, active: Bool) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit,
                   entitlementExpiresAt: now.addingTimeInterval(active ? 86_400 : -86_400))
    }

    @Test func thePoolCountsPeopleOnly() {
        #expect(carriedPeople(tree).map(\.id) == ["dad", "mom"])
        #expect(checkPool(tree, user: user(limit: 2, active: true), now: now).fits)
        #expect(!checkPool(tree, user: user(limit: 1, active: true), now: now).fits)
        #expect(checkPool(tree, user: user(limit: 2, active: true), now: now).carried == 2,
                "intentions never cost a place")
    }

    @Test func freeIsZeroPeople() {
        let free = checkPool(tree, user: user(limit: 10, active: false), now: now)
        #expect(!free.fits)
        #expect(free.isFree && free.limit == 0)
        // You, with your intention: fits.
        let onlyMine = SubjectTree([Fixture.subjects[3], Fixture.subjects[4]])
        #expect(checkPool(onlyMine, user: user(limit: 10, active: false), now: now).fits)
        #expect(effectivePoolLimit(user(limit: 10, active: false), now: now) == 0)
    }

    @Test func aNewNameIsCarriedWhileThereIsRoom() {
        let new = Fixture.name("new", "Ruth", order: 9)
        #expect(carriesNewSubject(new, in: tree, user: user(limit: 3, active: true), now: now))
        #expect(!carriesNewSubject(new, in: tree, user: user(limit: 2, active: true), now: now))
    }

    @Test func aNewIntentionIsChosenWhileItsPersonIsUnderTheCap() {
        let underDad = Fixture.intention("new", "dad", "Sleep", order: 9)
        #expect(!carriesNewSubject(underDad, in: tree, user: user(limit: 0, active: false), now: now),
                "Dad has one chosen: at the cap")
        #expect(carriesNewSubject(underDad, in: tree, user: user(limit: 0, active: false), now: now, cap: 2))
        let underMom = Fixture.intention("new", "mom", "Rest", order: 9)
        #expect(carriesNewSubject(underMom, in: tree, user: user(limit: 0, active: false), now: now),
                "Mom's only intention is Answered: it frees the choice")
    }

    @Test func chosenIntentionsAreOpenAndInOrder() {
        #expect(chosenIntentions(of: "dad", in: tree).map(\.id) == ["dad-1"])
        #expect(chosenIntentions(of: "mom", in: tree).isEmpty)
        #expect(openIntentions(of: "dad", in: tree).map(\.id) == ["dad-1", "dad-2"])
        #expect(openIntentions(of: "mom", in: tree).isEmpty, "Answered isn't offered")
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

/// A person's carry toggle and its meter (detail-page.md, Q32).
struct NameCarryOfferTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // Dad, Mom carried; Bea off
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))

    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }

    @Test func carriedSaysWhatsLeft() {
        let dad = nameCarryOffer(nameId: "dad", in: tree, user: member(5), now: now)
        #expect(dad.startsOn && dad.hasRoom && dad.left == 3)
        #expect(nameCarryMeter(dad) == .left(3))
    }

    @Test func carriedWithNoneFreeOrOverThePoolSaysAllInUse() {
        #expect(nameCarryMeter(nameCarryOffer(nameId: "dad", in: tree, user: member(2), now: now)) == .allInUse(pool: 2))
        let over = nameCarryOffer(nameId: "dad", in: tree, user: member(1), now: now)
        #expect(nameCarryMeter(over) == .allInUse(pool: 1), "never negative")
        #expect(over.hasRoom, "turning off is never blocked")
    }

    @Test func notCarriedSaysWhatsLeftOrTheLastPlace() {
        #expect(nameCarryMeter(nameCarryOffer(nameId: "bea", in: tree, user: member(5), now: now)) == .left(3))
        let last = nameCarryOffer(nameId: "bea", in: tree, user: member(3), now: now)
        #expect(last.hasRoom && nameCarryMeter(last) == .usesLast)
        let full = nameCarryOffer(nameId: "bea", in: tree, user: member(2), now: now)
        #expect(!full.hasRoom && nameCarryMeter(full) == .allInUse(pool: 2))
    }

    @Test func reCarryingCostsOnePlaceWhateverIsChosen() {
        // Bea has a chosen intention (bea-1): it comes back with her at no cost.
        #expect(nameCarryOffer(nameId: "bea", in: tree, user: member(3), now: now).hasRoom)
    }

    @Test func theFreeTierExplains() {
        let bea = nameCarryOffer(nameId: "bea", in: tree, user: free, now: now)
        #expect(!bea.hasRoom && nameCarryMeter(bea) == .free)
        let dad = nameCarryOffer(nameId: "dad", in: tree, user: free, now: now)
        #expect(dad.hasRoom && nameCarryMeter(dad) == .free, "a lapsed trial can still turn Dad off")
    }

    @Test func theSelfHasNoToggle() {
        #expect(!nameCarryOffer(nameId: "self", in: tree, user: member(5), now: now).hasRoom)
    }
}

/// "Print with {alias} ✱": the add sheet's carry row and an intention's page.
struct IntentionCarryOfferTests {
    let now = Fixture.epoch
    let tree = Fixture.tree
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))

    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }

    @Test func onByDefaultWhenThePersonHasNoChosenIntention() {
        let mom = intentionCarryOffer(personId: "mom", in: tree, user: member(5), now: now)
        #expect(mom.startsOn && mom.hasRoom && mom.replaces.isEmpty && !mom.alsoCarriesPerson)
        let mine = intentionCarryOffer(personId: "daniel", in: SubjectTree(Fixture.subjects + [Fixture.name("daniel", "Daniel", order: 9)]),
                                       user: free, now: now)
        #expect(mine.startsOn, "intentions cost nothing: free too")
    }

    @Test func atTheCapItStartsOffAndOnIsASwap() {
        let dad = intentionCarryOffer(personId: "dad", in: tree, user: member(5), now: now)
        #expect(!dad.startsOn && dad.hasRoom)
        #expect(dad.replaces.map(\.id) == ["dad-1"], "Instead of “Healing after his surgery”")
        let me = intentionCarryOffer(personId: "self", in: tree, user: free, now: now)
        #expect(me.isSelf && !me.startsOn && me.replaces.map(\.id) == ["self-1"])
    }

    @Test func aPersonNotCarriedIsCarriedTooAndNeedsAPlace() {
        let bea = intentionCarryOffer(personId: "bea", in: tree, user: member(5), now: now)
        #expect(bea.alsoCarriesPerson && bea.hasRoom && bea.left == 3)
        #expect(!bea.startsOn, "never spends a place by default")
        let full = intentionCarryOffer(personId: "bea", in: tree, user: member(2), now: now)
        #expect(!full.hasRoom, "Make room for Aunt Bea")
        #expect(!intentionCarryOffer(personId: "bea", in: tree, user: free, now: now).hasRoom)
    }

    @Test func onItsPageTheToggleIsItsOwnChoice() {
        let chosen = intentionCarryOffer(personId: "dad", intentionId: "dad-1", in: tree, user: member(5), now: now)
        #expect(chosen.startsOn && chosen.hasRoom && chosen.replaces.isEmpty)
        let other = intentionCarryOffer(personId: "dad", intentionId: "dad-2", in: tree, user: member(5), now: now)
        #expect(!other.startsOn && other.replaces.map(\.id) == ["dad-1"])
        // On, under a person who isn't carried (and the pool is full): still on, can turn off.
        let bea = intentionCarryOffer(personId: "bea", intentionId: "bea-1", in: tree, user: member(2), now: now)
        #expect(bea.startsOn && bea.hasRoom)
    }

    @Test func choosingAtTheCapSwaps() {
        let ids = choosing("dad-2", true, in: tree)
        #expect(ids.contains("dad-2") && !ids.contains("dad-1"))
        #expect(ids.contains("dad") && ids.contains("bea-1"), "nothing else changes")
        #expect(choosing("dad-2", true, in: tree, cap: 2).isSuperset(of: ["dad-1", "dad-2"]))
        #expect(!choosing("dad-1", false, in: tree).contains("dad-1"))
        let withBea = choosing("bea-1", true, in: tree, carryPerson: true)
        #expect(withBea.contains("bea"))
    }

    @Test func printsWithMovesTheCheckAtCapOne() {
        #expect(printsWith("dad-2", for: "dad", in: tree).intersection(["dad-1", "dad-2"]) == ["dad-2"])
        #expect(printsWith(nil, for: "dad", in: tree).intersection(["dad-1", "dad-2"]).isEmpty, "Name only")
        // A higher cap: taps toggle, up to the cap.
        #expect(printsWith("dad-2", for: "dad", in: tree, cap: 2).isSuperset(of: ["dad-1", "dad-2"]))
        #expect(!printsWith("dad-1", for: "dad", in: tree, cap: 2).contains("dad-1"))
    }

    @Test func carriedIdsLeaveOutTheSelfAndResolved() {
        #expect(carriedIds(tree) == ["dad", "dad-1", "self-1", "mom", "bea-1"])
    }
}

/// Restore never exceeds the pool or the cap (mirrors the server's restoreSubject).
struct RestoreCarryTests {
    let now = Fixture.epoch
    let tree = Fixture.tree // 2 people carried
    func member(_ limit: Int) -> UserHeader {
        UserHeader(id: "u", includeLimit: limit, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(86_400))
    }
    let free = UserHeader(id: "u", includeLimit: 10, entitlementExpiresAt: Fixture.epoch.addingTimeInterval(-1))
    let ann = Fixture.name("ann", "Ann", order: 9)
    let annWork = Fixture.intention("ann-1", "ann", "Work", order: 1)

    @Test func underThePoolANameKeepsCarrying() {
        #expect(restoredCarryFlag(ann, intentions: [annWork], into: tree, user: member(3), now: now))
    }

    @Test func overThePoolANameComesBackUncarried() {
        #expect(!restoredCarryFlag(ann, intentions: [annWork], into: tree, user: member(2), now: now))
        #expect(!restoredCarryFlag(ann, into: tree, user: free, now: now), "a lapsed trial")
    }

    @Test func anIntentionToAPersonAtTheCapComesBackUnchosen() {
        let dad3 = Fixture.intention("dad-3", "dad", "Sleep", order: 3)
        #expect(!restoredCarryFlag(dad3, into: tree, user: member(10), now: now))
        #expect(restoredCarryFlag(dad3, into: tree, user: member(10), now: now, cap: 2))
        let mom2 = Fixture.intention("mom-2", "mom", "Rest", order: 2)
        #expect(restoredCarryFlag(mom2, into: tree, user: free, now: now), "intentions never touch the pool")
    }

    @Test func anAnsweredOrUnchosenItemKeepsItsFlag() {
        let answered = Fixture.intention("dad-4", "dad", "Results", order: 4, answered: true)
        #expect(restoredCarryFlag(answered, into: tree, user: member(1), now: now))
        var off = ann
        off.isCarried = false
        #expect(!restoredCarryFlag(off, into: tree, user: member(10), now: now), "an uncarried item stays off")
    }
}
