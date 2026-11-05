import Foundation
import Testing
@testable import PlusPrayerDomain

/// Same cases as the Flutter build's selection_test.dart.
struct SelectionTests {
    let graph = SubjectGraph(intentionsByName: [
        "me": ["me.work"],
        "dad": ["dad.surgery", "dad.sleep"],
        "mom": [],
    ])
    let none = PrayerSelection.empty

    // Checking
    @Test func anIntentionAlsoHoldsItsName() {
        #expect(none.toggling("dad.surgery", in: graph).held == ["dad.surgery", "dad"])
    }

    @Test func aNameDoesNotCheckItsIntentions() {
        #expect(none.toggling("dad", in: graph).held == ["dad"])
    }

    @Test func worksUnderTheSelfRowToo() {
        #expect(none.toggling("me.work", in: graph).held == ["me.work", "me"])
    }

    @Test func unknownIdsChangeNothing() {
        #expect(none.toggling("ghost", in: graph).held.isEmpty)
    }

    // Unchecking
    @Test func aNameUnchecksItsIntentions() {
        let s = none.toggling("dad.surgery", in: graph).toggling("dad", in: graph)
        #expect(s.held.isEmpty)
    }

    @Test func anIntentionLeavesItsNameHeld() {
        let s = none.toggling("dad.surgery", in: graph).toggling("dad.surgery", in: graph)
        #expect(s.held == ["dad"])
    }

    @Test func onlyThatNamesIntentionsOtherNamesUntouched() {
        let s = none.toggling("me.work", in: graph).toggling("dad.surgery", in: graph).toggling("dad", in: graph)
        #expect(s.held == ["me.work", "me"])
    }

    // State
    @Test func partialWhenOnlySomeIntentionsAreHeld() {
        let s = none.toggling("dad.surgery", in: graph)
        #expect(s.state(of: "dad", in: graph) == .partial)
        #expect(s.state(of: "dad.surgery", in: graph) == .held)
        #expect(s.state(of: "dad.sleep", in: graph) == .none)
    }

    @Test func heldWhenEveryIntentionIsHeld() {
        let s = none.toggling("dad.surgery", in: graph).toggling("dad.sleep", in: graph)
        #expect(s.state(of: "dad", in: graph) == .held)
    }

    @Test func heldWhenTheNameAloneIsHeld() {
        #expect(none.toggling("dad", in: graph).state(of: "dad", in: graph) == .held)
        #expect(none.toggling("mom", in: graph).state(of: "mom", in: graph) == .held)
    }

    @Test func aSingleHeldIntentionIsTheWholeSetNotPartial() {
        #expect(none.toggling("me.work", in: graph).state(of: "me", in: graph) == .held)
    }

    @Test func noneWhenNotHeld() {
        #expect(none.state(of: "dad", in: graph) == .none)
    }

    // The list
    @Test func theListIsItsOwnToggle() {
        let s = none.withList(true)
        #expect(s.listIncluded)
        #expect(s.held.isEmpty)
        #expect(!s.isEmpty)
    }

    // checkedAt
    @Test func stampsNewItemsAndKeepsEarlierOnes() {
        let t0 = Date(timeIntervalSince1970: 0), t1 = Date(timeIntervalSince1970: 60)
        let s = none.toggling("dad", in: graph).stamped(at: t0).toggling("mom", in: graph).stamped(at: t1)
        #expect(s.checkedAt == ["dad": t0, "mom": t1])
    }

    @Test func reCheckingKeepsTheLastCheck() {
        let t0 = Date(timeIntervalSince1970: 0), t1 = Date(timeIntervalSince1970: 60)
        let s = none.toggling("dad", in: graph).stamped(at: t0)
            .toggling("dad", in: graph).stamped(at: t0)
            .toggling("dad", in: graph).stamped(at: t1)
        #expect(s.checkedAt == ["dad": t1])
    }
}
