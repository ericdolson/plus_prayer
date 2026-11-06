import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// The add sheet's flow over the mock (screens.md, Add sheet → Details).
@MainActor
struct AddSheetModelTests {
    let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
    let defaults: UserDefaults
    let home: HomeModel
    private let running: Task<Void, Never>

    init() async {
        defaults = UserDefaults(suiteName: "AddSheetModelTests.\(UUID().uuidString)")!
        let environment = AppEnvironment.mock(backend)
        let home = HomeModel(repositories: environment.repositories, clock: environment.clock, defaults: defaults)
        self.home = home
        running = Task { await home.run() }
        for _ in 0..<200 where !(home.isLoaded && home.header != nil) { try? await Task.sleep(for: .milliseconds(5)) }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(5)) }
    }

    /// Ends the trial: the free pool (1) is full, so anything new is private.
    private func makeFree() {
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
    }

    @Test func opensOnNameWithAnUnusedToneAndMeAsTheParent() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(model.tab == .name)
        #expect(!home.groups.map(\.name.tone).contains(model.tone))
        #expect(model.parent?.label == "Me")
    }

    @Test func thePreviewFollowsHomesInitialsRuleLive() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(model.previewInitials == "")
        model.name = "Gary Olson"
        #expect(model.previewInitials == "GO")
        model.alias = "Dad"
        #expect(model.previewInitials == "D")
        model.alias = "  "
        #expect(model.previewInitials == "GO")
    }

    @Test func addIsDisabledWhileEmptyOrWhileAContactMessageShows() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(!model.canAdd)
        model.name = "Ana 555-123-4567"
        #expect(model.canAdd, "enabled until the message shows (after the pause)")
        #expect(model.hasContactIssue(.name))
        model.showContactIssue(.name, true)
        #expect(!model.canAdd)
        model.name = "Ana"
        model.showContactIssue(.name, model.hasContactIssue(.name))
        #expect(model.canAdd)
    }

    @Test func aliasesAreNeverCheckedForContactInfo() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.alias = "Bea www.bea.com"
        #expect(!model.hasContactIssue(.alias))
    }

    @Test func aCarriedNameOffersOneIntentionThenCloses() async throws {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "Gary Olson"
        model.alias = "Dad"
        await model.add()
        guard case .offer(let nameId) = model.step else { Issue.record("expected the offer"); return }
        #expect(model.offerName == "Dad")
        #expect(backend.subjects.value.first { $0.id == nameId }?.avatarTone == model.tone)

        #expect(!model.canAdd, "empty")
        model.offerText = "Healing"
        await model.add()
        #expect(model.isFinished)
        #expect(backend.subjects.value.contains { $0.parentId == nameId && $0.publicName == "Healing" })
    }

    @Test func withNoAliasTheOfferUsesTheName() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "  Ruth   Kim "
        await model.add()
        #expect(model.offerName == "Ruth Kim")
    }

    @Test func aCarriedIntentionClosesWithNoOffer() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "mom"
        model.intention = "Rest"
        await model.add()
        #expect(model.isFinished)
        #expect(backend.subjects.value.contains { $0.parentId == "mom" && $0.publicName == "Rest" })
    }

    @Test func poolFullNameIsSavedPrivatelyWithTheOfferStillBelow() async {
        defer { running.cancel() }
        makeFree()
        await waitUntil { home.poolLimit == 1 }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        await model.add()
        guard case .savedPrivately(_, .soul, let invitation) = model.step else {
            Issue.record("expected saved privately"); return
        }
        #expect(invitation == .portionLink, "membership stays hidden until it exists")
        #expect(model.isFreePool)
        model.offerText = "Courage"
        #expect(model.canAdd)
        await model.add()
        #expect(model.isFinished, "the offered intention closes with no further message")
    }

    @Test func hiddenMembershipDoesntSpendTodaysInvitation() async {
        defer { running.cancel() }
        makeFree()
        await waitUntil { home.poolLimit == 1 }
        let hidden = AddSheetModel(home: home)
        hidden.name = "Ruth"
        await hidden.add()

        // Once Membership exists: the first full-pool add of the day invites…
        let first = AddSheetModel(home: home, membershipAvailable: true)
        first.name = "Sam"
        await first.add()
        #expect(first.step.invitation == .membership(premiumPool: 10))
        // …later adds that day get only the link.
        let second = AddSheetModel(home: home, membershipAvailable: true)
        second.name = "Ana"
        await second.add()
        #expect(second.step.invitation == .portionLink)
    }

    @Test func anyOtherFailureSaysSoKeepsTheTextAndLetsYouTryAgain() async {
        defer { running.cancel() }
        backend.failsAdds = true
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        await model.add()
        #expect(model.failedGenerically)
        #expect(model.step == .form)
        #expect(model.name == "Ruth")
        #expect(model.canAdd, "try again")

        backend.failsAdds = false
        await model.add()
        #expect(!model.failedGenerically)
        guard case .offer = model.step else { Issue.record("expected the offer"); return }
    }

    @Test func atTheCapTheLineShowsAndAddIsDisabled() async {
        defer { running.cancel() }
        backend.subjects.update { subjects in
            for i in subjects.count..<subjectCap {
                subjects.append(Subject(id: "x\(i)", kind: .soul, publicName: "N\(i)", sortOrder: 100 + i,
                                        createdAt: .now))
            }
        }
        await waitUntil { home.subjectCount == subjectCap }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        #expect(model.isAtCap)
        #expect(!model.canAdd)
        #expect(model.name == "Ruth")
    }

    @Test func poolFullIntentionGetsOnlyDone() async {
        defer { running.cancel() }
        makeFree()
        await waitUntil { home.poolLimit == 1 }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "dad"
        model.intention = "Rest"
        await model.add()
        guard case .savedPrivately(_, .intention, _) = model.step else { Issue.record("expected saved privately"); return }
        #expect(!model.canAdd)
        #expect(!model.isFinished)
    }

    @Test func onTheTopPoolNoUpsell() async {
        defer { running.cancel() }
        // The trial's 10 places: 7 used; fill the rest.
        for name in ["A", "B", "C"] { _ = try? await home.addSubject(NewSubject(kind: .soul, publicName: name)) }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        await model.add()
        #expect(model.step.invitation == .portionLink)
    }

    @Test func offlineDisablesAddAndKeepsTheText() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        backend.online = false
        await waitUntil { !home.isOnline }
        #expect(model.isOffline)
        #expect(!model.canAdd)
        #expect(model.name == "Ruth")
        backend.online = true
        await waitUntil { home.isOnline }
        #expect(model.canAdd)
    }
}

private extension AddSheetModel.Step {
    var invitation: PoolFullInvitation? {
        if case .savedPrivately(_, _, let invitation) = self { return invitation }
        return nil
    }
}
