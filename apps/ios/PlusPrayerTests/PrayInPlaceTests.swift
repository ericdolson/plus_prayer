import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// Praying on a page, in place (detail-page.md): a session started from a
/// name's or an intention's page, over the mock's standard seed (Dad with
/// "Healing after his surgery" and "Rest for his heart").
@MainActor
struct PrayInPlaceTests {
    let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
    let home: HomeModel
    let session: PrayerSession
    let clock = TestClock()
    private let running: Task<Void, Never>

    init() async {
        let home = HomeModel(environment: .mock(backend))
        self.home = home
        let clock = clock
        session = PrayerSession(graph: { home.graph }, clock: { clock.now })
        running = Task { await home.run() }
        for _ in 0..<200 where !(home.isLoaded && home.card != nil && home.historyLog != nil) {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(5)) }
    }

    /// Past the minimum, then Amen; through the invitation without the list
    /// if it opens.
    private func finish() -> NewPrayer? {
        clock.advance(6)
        return session.amen(prayedWithListToday: home.prayedWithListToday) ?? session.amenFromInvitation()
    }

    @Test func aNamesPageStartsWithTheNameChecked() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad")
        #expect(session.page == "dad")
        #expect(session.isPraying)
        #expect(session.check("dad") == .held)
        #expect(session.check("dad-1") == .none && session.check("dad-2") == .none,
                "checking a name doesn't check its intentions")
        #expect(session.checkCount == 0, "the pre-check is no tap: no haptic")
        #expect(session.selection.checkedAt["dad"] == clock.now)
    }

    @Test func homesRulesApplyOnThePage() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad")
        session.toggle("dad-1")
        #expect(session.check("dad") == .partial, "only some of his intentions")
        session.toggle("dad-2")
        #expect(session.check("dad") == .held)
        session.toggle("dad")
        #expect(session.selection.held.isEmpty, "the subject can be unchecked; its intentions go with it")
        session.toggle("dad-2")
        #expect(session.check("dad") == .partial, "an intention holds its name again")
    }

    @Test func amenCreditsTheSubjectAndOnlyTheCheckedIntentions() async {
        defer { running.cancel() }
        let before = try! #require(home.historyPreview("dad")).totals.prayers
        session.start(list: home.listContext, on: "dad")
        session.toggle("dad-2")
        let prayer = try! #require(finish())
        #expect(prayer.subjectIds == ["dad", "dad-2"])
        #expect(session.page == "dad", "the page stays stripped through the closing sheet")
        await home.log(prayer)
        await waitUntil { home.historyPreview("dad")?.totals.prayers == before + 1 }
        #expect(home.historyPreview("dad")?.totals.prayers == before + 1, "the tile's count, once it fades back")
        session.close()
        #expect(session.page == nil && session.phase == .idle)
    }

    @Test func untouchedTheSubjectIsStillCredited() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "daniel")
        #expect(finish()?.subjectIds == ["daniel"])
    }

    @Test func uncheckedNothingIsAPrayerWithNoSubjects() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "daniel")
        session.toggle("daniel")
        let prayer = finish()
        #expect(prayer != nil)
        #expect(prayer?.subjectIds == [])
    }

    @Test func anIntentionsPageChecksItAndItsName() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad-1")
        #expect(session.check("dad-1") == .held)
        #expect(session.isHeld("dad"), "the name is credited whenever the intention is")
        #expect(finish()?.subjectIds == ["dad", "dad-1"])
    }

    @Test func onAnIntentionsPageItsNameFollowsIt() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad-1")
        session.toggle("dad-1")
        #expect(session.selection.held.isEmpty, "the name isn't a check there, so it goes with the intention")
        session.toggle("dad-1")
        #expect(session.selection.held == ["dad", "dad-1"])
    }

    @Test func anAnsweredIntentionCanBePrayedFor() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "mom-1")
        #expect(finish()?.subjectIds == ["mom", "mom-1"])
    }

    @Test func prayForOthersKeepsTheChecks() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad")
        session.toggle("dad-1")
        session.leavePage()
        #expect(session.page == nil)
        #expect(session.isPraying, "still praying, now on Home")
        #expect(session.check("dad") == .partial && session.isHeld("dad-1"))
        // On Home, Home's rules: letting the intention go leaves the name held.
        session.toggle("dad-1")
        #expect(session.selection.held == ["dad"])
        session.toggle("mom")
        #expect(finish()?.subjectIds == ["dad", "mom"])
    }

    @Test func leavingTheIntentionsPageGivesHomesRulesBack() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad-1")
        session.leavePage()
        session.toggle("dad-1")
        #expect(session.selection.held == ["dad"], "Home's rule: unchecking an intention leaves its name held")
    }

    @Test func cancelOnThePageLeavesNothing() {
        defer { running.cancel() }
        session.start(list: home.listContext, on: "dad")
        session.cancel()
        #expect(session.page == nil && session.phase == .idle && session.selection.isEmpty)
        // A new prayer from Home starts empty, not on the page.
        session.start(list: home.listContext)
        #expect(session.page == nil && session.selection.isEmpty)
    }

    @Test func theCapsulesLabels() {
        defer { running.cancel() }
        #expect(L10n.Page.pray(for: "Dad") == "Pray for Dad")
        #expect(L10n.Page.pray(for: nil) == "Pray")
        #expect(L10n.Page.prayForOthers == "Pray for others")
    }
}
