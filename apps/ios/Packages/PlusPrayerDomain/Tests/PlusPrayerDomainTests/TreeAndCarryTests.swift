import Foundation
import Testing
@testable import PlusPrayerDomain

struct SubjectTreeTests {
    @Test func selfFirstThenManualOrder() {
        #expect(Fixture.tree.names.map(\.id) == ["self", "dad", "mom", "bea"])
        #expect(Fixture.tree.me?.id == "self")
    }

    @Test func intentionsInOrderUnderTheirName() {
        #expect(Fixture.tree.intentions(of: "dad").map(\.id) == ["dad-1", "dad-2"])
        #expect(Fixture.tree.parent(of: "dad-2")?.id == "dad")
    }

    @Test func orphanedIntentionsAreDropped() {
        let tree = SubjectTree([Fixture.intention("x", "gone", "Lost", order: 0)])
        #expect(tree.names.isEmpty)
        #expect(tree.intentions(of: "gone").isEmpty)
    }

    @Test func graphMatchesTheTree() {
        let graph = Fixture.tree.graph
        #expect(graph.intentions(of: "dad") == ["dad-1", "dad-2"])
        #expect(graph.parent(of: "self-1") == "self")
    }

    @Test func labelPrefersANonBlankAlias() {
        #expect(Fixture.name("a", "Gary", order: 0, alias: "Dad").label == "Dad")
        #expect(Fixture.name("a", "Gary", order: 0, alias: "  ").label == "Gary")
    }
}

struct CarryTests {
    let tree = Fixture.tree

    @Test func selfIsMarkedButNotInThePool() {
        #expect(showsCarriedMark(tree["self"]!, in: tree))
        #expect(!isEffectivelyCarried(tree["self"]!, in: tree))
    }

    @Test func intentionNeedsItsNameCarried() {
        #expect(isEffectivelyCarried(tree["dad-1"]!, in: tree))
        #expect(!isEffectivelyCarried(tree["bea-1"]!, in: tree), "carried, but Bea isn't")
        #expect(!isEffectivelyCarried(tree["dad-2"]!, in: tree), "private")
    }

    @Test func intentionUnderTheSelfIsCarried() {
        #expect(isEffectivelyCarried(tree["self-1"]!, in: tree))
    }

    @Test func resolvedIsNeverCarried() {
        #expect(!isEffectivelyCarried(tree["mom-1"]!, in: tree))
    }

    @Test func cardRowIsYouThenCarriedNamesInOrder() {
        #expect(carriedNames(tree).map(\.id) == ["self", "dad", "mom"])
    }
}

struct RowStatusTests {
    @Test func answeredShowsItsDate() {
        #expect(rowStatus(Fixture.tree["mom-1"]!) == .answered(on: Fixture.epoch))
    }

    @Test func otherwiseNoSecondLine() {
        #expect(rowStatus(Fixture.tree["dad-1"]!) == nil)
    }
}
