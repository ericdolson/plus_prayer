import Testing
@testable import PlusPrayerDomain

struct HomeFilterTests {
    let tree = Fixture.tree
    let today = Fixture.today

    private func ids(_ groups: [HomeGroup]) -> [String] {
        groups.flatMap { [$0.name.id] + $0.intentions.map(\.id) }
    }

    @Test func heldTodayIsTodayOnly() {
        #expect(isHeldToday(tree["dad"]!, today: today))
        #expect(!isHeldToday(tree["self"]!, today: today), "yesterday")
        #expect(!isHeldToday(tree["bea"]!, today: today), "never")
    }

    @Test func allShowsEverythingInOrder() {
        #expect(ids(visibleGroups(tree, today: today))
                == ["self", "self-1", "dad", "dad-1", "dad-2", "mom", "mom-1", "bea", "bea-1"])
    }

    @Test func stillToHoldKeepsAHeldNameAsContextForAnUnheldIntention() {
        let groups = visibleGroups(tree, today: today, filter: .stillToHold)
        #expect(ids(groups) == ["self", "self-1", "dad", "dad-2", "mom", "mom-1", "bea", "bea-1"])
        let dad = groups.first { $0.id == "dad" }!
        #expect(dad.name.isContext)
        #expect(!groups.first { $0.id == "mom" }!.name.isContext)
    }

    @Test func aHeldNameWithNothingLeftDisappears() {
        let held = SubjectTree([Fixture.name("a", "Ann", order: 0, prayed: 0)])
        #expect(visibleGroups(held, today: today, filter: .stillToHold).isEmpty)
    }

    @Test func keepHoldsLingeringRowsIn() {
        let groups = visibleGroups(tree, today: today, filter: .stillToHold, keep: ["dad", "dad-1"])
        #expect(ids(groups).contains("dad-1"))
        #expect(!groups.first { $0.id == "dad" }!.name.isContext)
    }

    @Test func carriedIsTheMarkedSet() {
        #expect(ids(visibleGroups(tree, today: today, filter: .carried))
                == ["self", "self-1", "dad", "dad-1", "mom"])
    }

    @Test func carriedIntentionUnderAnUncarriedNameIsNotShown() {
        #expect(!ids(visibleGroups(tree, today: today, filter: .carried)).contains("bea-1"))
    }

    @Test func countsAreItemsNamesAndIntentions() {
        #expect(filterCount(tree, .all, today: today) == 9)
        #expect(filterCount(tree, .stillToHold, today: today) == 7)
        #expect(filterCount(tree, .carried, today: today) == 5)
    }

    @Test func searchMatchesAliasAndPrintedName() {
        #expect(ids(visibleGroups(tree, today: today, query: "gary")) == ["dad", "dad-1", "dad-2"])
        #expect(ids(visibleGroups(tree, today: today, query: "Bea")) == ["bea", "bea-1"])
    }

    @Test func searchKeepsTheNameAsContextForAMatchingIntention() {
        let groups = visibleGroups(tree, today: today, query: "ruth")
        #expect(ids(groups) == ["mom", "mom-1"])
        #expect(groups[0].name.isContext)
    }

    @Test func matchesInAllCountsWhatAFilterHides() {
        #expect(matchesInAll(tree, query: "surgery", today: today) == 1)
    }

    @Test func carriedViewHoldingOnlyYou() {
        let onlyMe = SubjectTree([Fixture.subjects[3], Fixture.subjects[4]])
        #expect(carriedShowsOnlyYou(visibleGroups(onlyMe, today: today, filter: .carried)))
        #expect(!carriedShowsOnlyYou(visibleGroups(tree, today: today, filter: .carried)))
        #expect(carriedShowsOnlyYou([]))
    }

    @Test func cardUnderFilters() {
        #expect(communityCardShown(filter: .all, query: "", prayedWithListToday: true, lingering: false))
        #expect(communityCardShown(filter: .carried, query: "", prayedWithListToday: true, lingering: false))
        #expect(communityCardShown(filter: .stillToHold, query: "", prayedWithListToday: false, lingering: false))
        #expect(!communityCardShown(filter: .stillToHold, query: "", prayedWithListToday: true, lingering: false))
        #expect(communityCardShown(filter: .stillToHold, query: "", prayedWithListToday: true, lingering: true))
        #expect(!communityCardShown(filter: .all, query: "dad", prayedWithListToday: false, lingering: false))
    }
}
