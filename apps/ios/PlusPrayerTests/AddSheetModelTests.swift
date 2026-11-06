import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// The add sheet's flow over the mock (screens.md, Add sheet, revised
/// 2026-11-06). The seed carries 7 of the trial's 10 places; Aunt Bea is
/// left uncarried.
@MainActor
struct AddSheetModelTests {
    let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
    let home: HomeModel
    private let running: Task<Void, Never>

    init() async {
        let environment = AppEnvironment.mock(backend)
        let home = HomeModel(repositories: environment.repositories, clock: environment.clock)
        self.home = home
        running = Task { await home.run() }
        for _ in 0..<200 where !(home.isLoaded && home.header != nil) { try? await Task.sleep(for: .milliseconds(5)) }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(5)) }
    }

    /// Ends the trial: the free pool (1) is full, so anything new is private.
    private func makeFree() async {
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
        await waitUntil { home.carryOffer(kind: .soul, parentId: nil).pool == 1 }
    }

    private func subject(_ id: String) -> Subject? { backend.subjects.value.first { $0.id == id } }

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

    @Test func aCarriedNameIsAddedThenOffersOneIntentionThenCloses() async throws {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(model.carryOffer(.name) == CarryOffer(hasRoom: true, startsOn: true, alsoCarriesParent: false,
                                                      used: 7, pool: 10, cost: 1, isFree: false))
        #expect(model.isCarrying(.name), "on by default with room")
        #expect(model.meter(.name) == .left(3), "what's left, before this one")
        model.setCarrying(.name, false)
        #expect(model.meter(.name) == .left(3), "the toggle doesn't change it")
        model.setCarrying(.name, true)
        model.name = "Gary Olson"
        model.alias = "Dad"
        await model.add()
        guard case .offer(let nameId) = model.step else { Issue.record("expected the offer"); return }
        #expect(model.offerName == "Dad")
        #expect(subject(nameId)?.avatarTone == model.tone)
        #expect(subject(nameId)?.isCarried == true)
        #expect(model.activeField == .offer, "the offer's field takes the keyboard")

        #expect(!model.canAdd, "empty")
        #expect(model.isCarrying(.offer))
        #expect(model.alsoCarries(.offer) == nil)
        #expect(model.meter(.offer) == .left(2), "Dad is counted now")
        #expect(model.notCarried == nil)
        model.offerText = "Healing"
        await model.add()
        #expect(model.isFinished)
        #expect(backend.subjects.value.contains { $0.parentId == nameId && $0.publicName == "Healing" && $0.isCarried })
    }

    @Test func withNoAliasTheOfferUsesTheName() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "  Ruth   Kim "
        await model.add()
        #expect(model.offerName == "Ruth Kim")
    }

    @Test func aNameTurnedOffIsKeptForYourOwnPrayersAndItsIntentionStartsOff() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        model.setCarrying(.name, false)
        #expect(!model.isCarrying(.name))
        await model.add()
        guard case .offer(let nameId) = model.step else { Issue.record("expected the offer, as always"); return }
        #expect(subject(nameId)?.isCarried == false)

        // Under a name left uncarried: off, but it can carry both.
        #expect(model.carryOffer(.offer).hasRoom)
        #expect(!model.isCarrying(.offer))
        #expect(model.alsoCarries(.offer) == nil)
        model.setCarrying(.offer, true)
        #expect(model.alsoCarries(.offer)?.name == "Ruth")
        #expect(model.alsoCarries(.offer)?.cost == 2, "the true cost: Ruth and the intention")
        #expect(model.meter(.offer) == .left(3))
        model.offerText = "Courage"
        await model.add()
        #expect(model.isFinished)
        #expect(subject(nameId)?.isCarried == true, "the name prints with its intention")
        #expect(backend.subjects.value.contains { $0.parentId == nameId && $0.publicName == "Courage" && $0.isCarried })
    }

    @Test func anIntentionSavesAndClosesCarriedOrNot() async {
        defer { running.cancel() }
        let carried = AddSheetModel(home: home, tab: .intention)
        carried.parentId = "mom"
        carried.intention = "Rest"
        await carried.add()
        #expect(carried.isFinished)
        #expect(backend.subjects.value.contains { $0.parentId == "mom" && $0.publicName == "Rest" && $0.isCarried })

        let kept = AddSheetModel(home: home, tab: .intention)
        kept.parentId = "mom"
        kept.setCarrying(.intention, false)
        kept.intention = "Sleep"
        await kept.add()
        #expect(kept.isFinished, "no step after an intention")
        #expect(backend.subjects.value.contains { $0.parentId == "mom" && $0.publicName == "Sleep" && !$0.isCarried })
    }

    @Test func underAnUncarriedNameTheIntentionStartsOffAndChangingTheNameResetsIt() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "bea"
        #expect(!model.isCarrying(.intention))
        #expect(model.carryOffer(.intention).alsoCarriesParent)
        model.setCarrying(.intention, true)
        #expect(model.alsoCarries(.intention)?.name == "Aunt Bea")
        #expect(model.alsoCarries(.intention)?.cost == 2)
        model.parentId = "mom"
        #expect(model.isCarrying(.intention), "back to Mom's default")
        model.setCarrying(.intention, false)
        model.parentId = "dad"
        #expect(model.isCarrying(.intention), "a new name, its default again")
    }

    @Test func aFullPoolIsOffAndDisabledAndTheNameIsStillAddedWithTheOffer() async {
        defer { running.cancel() }
        await makeFree()
        let model = AddSheetModel(home: home)
        let offer = model.carryOffer(.name)
        #expect(!offer.hasRoom)
        #expect(offer.pool == 1)
        #expect(model.meter(.name) == .freeYouAndOneIntention)
        model.setCarrying(.name, true)
        #expect(!model.isCarrying(.name), "disabled")
        model.name = "Ruth"
        await model.add()
        guard case .offer(let nameId) = model.step else { Issue.record("expected the offer"); return }
        #expect(model.offerName == "Ruth")
        #expect(subject(nameId)?.isCarried == false)
        #expect(!model.carryOffer(.offer).hasRoom)
        #expect(model.meter(.offer) == .allInUse(pool: 1), "7 carried on a pool of 1: never \"7 of 1\"")
        #expect(model.notCarried == nil, "the toggle was off: nothing to report")
        model.offerText = "Courage"
        #expect(model.canAdd, "the keyboard and Add stay, pool full or not")
        await model.add()
        #expect(model.isFinished)
    }

    @Test func whoIsThisForSearchesEveryoneAndPickingReturnsToTheIntention() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, tab: .intention)
        model.openChooser()
        #expect(model.step == .choosing)
        #expect(model.activeField == .search)
        #expect(!model.canAdd)
        #expect(model.chooserNames.first?.label == "Me")
        #expect(model.chooserNames.count == home.pickerNames().count, "everyone, no strip")
        model.chooserQuery = "mo"
        #expect(model.chooserNames.map(\.label) == ["Mom", "Aunt Bea"], "name + alias, Home order")
        model.choose("bea")
        #expect(model.step == .form)
        #expect(model.parent?.label == "Aunt Bea")
        #expect(model.activeField == .intention)

        model.openChooser()
        #expect(model.chooserQuery.isEmpty, "a fresh search each time")
        model.choose(nil)
        #expect(model.parent?.label == "Aunt Bea", "back keeps the name")
    }

    @Test func theUnitGoesThroughOneFormatter() {
        defer { running.cancel() }
        #expect(L10n.Add.carryMeter(.left(3)) == "3 places left")
        #expect(L10n.Add.carryMeter(.left(1)) == "1 place left")
        #expect(L10n.Add.carryMeter(.usesLast(1)) == "This uses your last place")
        #expect(L10n.Add.carryMeter(.usesLast(3)) == "This uses your last 3 places")
        #expect(L10n.Add.alsoCarries("Dad", cost: nil) == "Also carries Dad")
        #expect(L10n.Add.carryMeter(.allInUse(pool: 10)) == "All 10 places in use")
        #expect(L10n.Add.carryMeter(.allInUse(pool: 1)) == "Your one place is in use")
        #expect(L10n.Add.carryMeter(.freeYouAndOneIntention) == "Free carries you and one intention of your own")
        #expect(L10n.Add.alsoCarries("Dad", cost: 2) == "Also carries Dad · uses 2 places")
    }

    /// Fills the pool on the server before Home hears of it (another
    /// device), so the toggle still says on.
    private func fillThePoolElsewhere() {
        backend.subjects.update { subjects in
            for i in 0..<3 {
                subjects.append(Subject(id: "elsewhere\(i)", kind: .soul, publicName: "E\(i)", isCarried: true,
                                        sortOrder: 100 + i, createdAt: .now))
            }
        }
    }

    @Test func whenTheServerDoesntCarryANameTheOfferSaysSo() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        #expect(model.isCarrying(.name))
        fillThePoolElsewhere()
        await model.add()
        guard case .offer(let nameId) = model.step else { Issue.record("expected the offer"); return }
        #expect(subject(nameId)?.isCarried == false)
        #expect(model.notCarried == .name, "under the header")
        model.offerText = "Courage"
        #expect(model.canAdd, "the offer still works")
    }

    @Test func whenTheServerDoesntCarryAnIntentionItWaitsForDone() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "mom"
        model.intention = "Rest"
        #expect(model.isCarrying(.intention))
        fillThePoolElsewhere()
        await model.add()
        #expect(model.notCarried == .intention)
        #expect(!model.isFinished, "doesn't close silently")
        #expect(model.isSettled)
        #expect(!model.canAdd, "saved; Done only")
        #expect(backend.subjects.value.contains { $0.publicName == "Rest" && !$0.isCarried })
        model.finish()
        #expect(model.isFinished)
    }

    @Test func reCarryingANameCountsItsFlaggedIntentionsAsTheServerDoes() async {
        defer { running.cancel() }
        // Aunt Bea isn't carried; give her an intention still flagged carried.
        backend.subjects.update {
            $0.append(Subject(id: "bea-1", kind: .intention, parentId: "bea", publicName: "Her new home",
                              isCarried: true, sortOrder: 1, createdAt: .now))
        }
        await waitUntil { home.tree["bea-1"] != nil }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "bea"
        model.setCarrying(.intention, true)
        #expect(model.meter(.intention) == .usesLast(3), "Bea, her flagged intention and this one: all 3 left")
        #expect(model.alsoCarries(.intention)?.name == "Aunt Bea")
        #expect(model.alsoCarries(.intention)?.cost == nil, "the meter already says it")
        model.intention = "Rest"
        await model.add()
        #expect(model.isFinished, "the server's check agrees: all three fit")
        let tree = SubjectTree(backend.subjects.value)
        #expect(effectiveCarried(tree).count == 10)
    }

    @Test func anIntentionUnderANameUncarriedElsewhereIsNotCarried() async {
        defer { running.cancel() }
        // The sheet saw Dad carried; another device has since uncarried him.
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "dad"
        #expect(model.isCarrying(.intention) && !model.carryOffer(.intention).alsoCarriesParent)
        backend.subjects.update { subjects in
            if let i = subjects.firstIndex(where: { $0.id == "dad" }) { subjects[i].isCarried = false }
        }
        model.intention = "Rest"
        await model.add()
        #expect(model.notCarried == .intention, "flagged, but it doesn't print: effectivelyCarried decides")
    }

    @Test func noMatchesSaysSo() {
        defer { running.cancel() }
        #expect(L10n.Add.noMatches("Zed") == "Nothing matches “Zed”.")
        let model = AddSheetModel(home: home, tab: .intention)
        model.openChooser()
        model.chooserQuery = "Zed"
        #expect(model.chooserNames.isEmpty)
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
