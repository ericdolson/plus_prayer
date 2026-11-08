import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// The add sheet's flow over the mock (screens.md, Add sheet, revised
/// 2026-11-07; Q32 2026-11-08). The seed carries 5 people of the trial's 10
/// places (Dad, Mom, Daniel, Our parish, Ukraine); Aunt Bea is left
/// uncarried. Dad prints with "Healing after his surgery"; Mom's only
/// intention is Answered.
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

    /// Ends the trial: the free pool (0 people) is full, so a new name is private.
    private func makeFree() async {
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
        await waitUntil { home.nameCarryOffer("bea").isFree }
    }

    private func subject(_ id: String) -> Subject? { backend.subjects.value.first { $0.id == id } }

    @Test func opensOnNameWithAnUnusedToneAndMeAsTheParent() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(model.tab == .name)
        #expect(!home.groups.map(\.name.tone).contains(model.tone))
        #expect(model.parent?.label == "Me")
    }

    @Test func theAvatarFollowsTheDisplayName() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        #expect(model.previewInitials.isEmpty, "empty: the person glyph")
        model.name = "Gary Olson"
        #expect(model.previewInitials == "GO")
        model.alias = "Dad"
        #expect(model.previewInitials == "D", "the alias once it has text")
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

    @Test func aNameIsAddedAutoCarriedAndTheSheetCloses() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.name = "Gary Olson"
        model.alias = "Dad"
        await model.add()
        #expect(model.isFinished, "closes onto the person's page")
        let added = backend.subjects.value.first { $0.publicName == "Gary Olson" && $0.id != "dad" }
        #expect(model.addedNameId == added?.id)
        #expect(added?.alias == "Dad")
        #expect(added?.avatarTone == model.tone)
        #expect(added?.isCarried == true, "auto-carried: there's room")
    }

    @Test func aNameThatDoesntFitIsSavedUncarriedAndClosesOntoItsPage() async {
        defer { running.cancel() }
        await makeFree()
        let model = AddSheetModel(home: home)
        model.name = "Ruth"
        #expect(model.canAdd, "no carry row: nothing to stop it")
        await model.add()
        let ruth = backend.subjects.value.first { $0.publicName == "Ruth" }
        #expect(ruth?.isCarried == false)
        #expect(model.isFinished, "its page says \"Private · in your prayers only\"")
        #expect(model.addedNameId == ruth?.id)
    }

    @Test func theAddIntentionFormForAPersonHasNoForRow() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, intentionFor: "mom")
        guard case .person("mom") = model.step else { Issue.record("expected the person form"); return }
        #expect(model.isFromName)
        #expect(model.person?.label == "Mom")
        #expect(model.person?.initials == "M")
        #expect(model.activeField == .person, "its field has the keyboard on open")
        #expect(model.isCarrying(.person), "Mom is carried and has no chosen intention")
        #expect(model.carryTitle(.person) == "Print with Mom")
        #expect(model.carrySubtitle(.person).isEmpty)
        #expect(!model.canAdd, "empty")
        model.personText = "Strength for the week"
        await model.add()
        #expect(model.isFinished)
        #expect(backend.subjects.value.contains {
            $0.parentId == "mom" && $0.publicName == "Strength for the week" && $0.isCarried
        })
    }

    @Test func whatIsTypedAsTheSheetOpensReachesTheFirstField() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home)
        model.typeAhead("G")
        model.typeAhead("a")
        model.typeAhead("x")
        model.typeAhead("")
        #expect(model.name == "Ga", "typed before SwiftUI focused it, a delete included")
        let fromName = AddSheetModel(home: home, intentionFor: "dad")
        fromName.typeAhead("R")
        #expect(fromName.personText == "R")
    }





    @Test func forAnUncarriedPersonTheToggleStartsOffAndCanCarryBoth() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, intentionFor: "bea")
        #expect(model.carryOffer(.person).hasRoom)
        #expect(!model.isCarrying(.person), "never spends a place by default")
        #expect(model.carrySubtitle(.person) == ["Also carries Aunt Bea · 5 places left"])
        model.setCarrying(.person, true)
        model.personText = "Courage"
        await model.add()
        #expect(model.isFinished)
        #expect(subject("bea")?.isCarried == true, "the name prints with its intention")
        #expect(backend.subjects.value.contains { $0.parentId == "bea" && $0.publicName == "Courage" && $0.isCarried })
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
        #expect(model.carryOffer(.intention).alsoCarriesPerson)
        model.setCarrying(.intention, true)
        #expect(model.isCarrying(.intention))
        model.parentId = "mom"
        #expect(model.isCarrying(.intention), "back to Mom's default")
        model.setCarrying(.intention, false)
        model.parentId = "dad"
        #expect(!model.isCarrying(.intention), "Dad's default: he already prints with one")
        #expect(model.carrySubtitle(.intention) == ["Instead of “Healing after his surgery”"])
    }

    @Test func aFullPoolIsOffAndDisabledAndTheIntentionIsStillAdded() async {
        defer { running.cancel() }
        await makeFree()
        // Choosing costs nothing: under Dad (carried, a lapsed trial) it's still a swap.
        #expect(AddSheetModel(home: home, intentionFor: "dad").carryOffer(.person).hasRoom)
        // Aunt Bea would need a place: none on the free tier.
        let model = AddSheetModel(home: home, intentionFor: "bea")
        let offer = model.carryOffer(.person)
        #expect(!offer.hasRoom)
        #expect(offer.pool == 0)
        #expect(model.carrySubtitle(.person) == ["Free carries you and your intention"])
        model.setCarrying(.person, true)
        #expect(!model.isCarrying(.person), "disabled")
        model.personText = "Courage"
        #expect(model.canAdd, "the keyboard and Add stay, pool full or not")
        await model.add()
        #expect(model.isFinished)
        #expect(!model.isSettled, "the toggle was off: nothing to report")
        #expect(backend.subjects.value.contains { $0.parentId == "bea" && $0.publicName == "Courage" && !$0.isCarried })
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

    @Test func theCarryRowsCopy() {
        defer { running.cancel() }
        #expect(L10n.Add.printWith("Dad", isSelf: false) == "Print with Dad")
        #expect(L10n.Add.printWith("Me", isSelf: true) == "Print with your name")
        #expect(L10n.Add.insteadOf("Rest for his heart") == "Instead of “Rest for his heart”")
        #expect(L10n.Add.alsoCarries("Dad", left: 3) == "Also carries Dad · 3 places left")
        #expect(L10n.Add.alsoCarries("Dad", left: 1) == "Also carries Dad · 1 place left")
        #expect(L10n.Page.makeRoom(for: "Dad") == "Make room for Dad")
    }

    @Test func atTheCapOnSwapsTheNewIntentionIn() async {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "dad"
        #expect(!model.isCarrying(.intention))
        model.setCarrying(.intention, true)
        model.intention = "Rest"
        await model.add()
        #expect(model.isFinished)
        #expect(backend.subjects.value.contains { $0.parentId == "dad" && $0.publicName == "Rest" && $0.isCarried })
        #expect(subject("dad-1")?.isCarried == false, "Instead of “Healing after his surgery”")
    }

    /// Fills the pool on the server before Home hears of it (another
    /// device), so the toggle still says on.
    private func fillThePoolElsewhere() {
        backend.subjects.update { subjects in
            for i in 0..<5 {
                subjects.append(Subject(id: "elsewhere\(i)", kind: .soul, publicName: "E\(i)", isCarried: true,
                                        sortOrder: 100 + i, createdAt: .now))
            }
        }
    }



    @Test func whenTheServerDoesntCarryAnIntentionItWaitsForDone() async {
        defer { running.cancel() }
        // Carrying Aunt Bea needs a place; another device takes the last ones.
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "bea"
        model.setCarrying(.intention, true)
        model.intention = "Rest"
        #expect(model.isCarrying(.intention))
        fillThePoolElsewhere()
        await model.add()
        #expect(model.notCarried)
        #expect(!model.isFinished, "doesn't close silently")
        #expect(model.isSettled)
        #expect(!model.canAdd, "saved; Done only")
        #expect(backend.subjects.value.contains { $0.publicName == "Rest" && !$0.isCarried })
        #expect(subject("bea")?.isCarried == false, "all or nothing")
        model.finish()
        #expect(model.isFinished)
    }

    @Test func anIntentionUnderANameUncarriedElsewhereIsNotCarried() async {
        defer { running.cancel() }
        // The sheet saw Mom carried; another device has since uncarried her.
        let model = AddSheetModel(home: home, tab: .intention)
        model.parentId = "mom"
        #expect(model.isCarrying(.intention) && !model.carryOffer(.intention).alsoCarriesPerson)
        backend.subjects.update { subjects in
            if let i = subjects.firstIndex(where: { $0.id == "mom" }) { subjects[i].isCarried = false }
        }
        model.intention = "Rest"
        await model.add()
        #expect(model.notCarried, "chosen, but it doesn't print: effectivelyCarried decides")
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
        #expect(model.isFinished)
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
