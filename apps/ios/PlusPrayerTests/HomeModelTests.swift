import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// HomeModel over the mock backend (the standard seed): what Home shows, the
/// filter, and a prayer from start to Amen, online and off.
/// A clock a test moves by hand.
@MainActor
final class TestClock {
    var now = Date.now
    func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
}

@MainActor
struct HomeModelTests {
    let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
    let home: HomeModel
    let session: PrayerSession
    let clock = TestClock()
    private let running: Task<Void, Never>

    init() async {
        let environment = AppEnvironment.mock(backend)
        let home = HomeModel(environment: environment)
        self.home = home
        let clock = clock
        session = PrayerSession(graph: { home.graph }, clock: { clock.now })
        running = Task { await home.run() }
        await waitUntil { home.isLoaded && home.card != nil }
    }

    /// Polls the main actor until `condition` holds (streams deliver on later turns).
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(5)) }
    }

    /// Past the minimum, then Amen; through the invitation without the list
    /// if it opens.
    private func finish() -> NewPrayer? {
        clock.advance(6)
        return session.amen(prayedWithListToday: home.prayedWithListToday) ?? session.amenFromInvitation()
    }

    private func ids(_ groups: [NameGroup]) -> [String] {
        groups.flatMap { [$0.id] + $0.intentions.map(\.id) }
    }

    @Test func showsTheSeedAsTheScreenshotsDo() {
        defer { running.cancel() }
        #expect(home.groups.map(\.name.label)
                == ["Me", "Dad", "Mom", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea", "Lena Park"])
        #expect(home.groups[0].name.initials == "EO")
        #expect(home.groups[1].name.heldToday)
        let card = home.card!
        #expect(card.listNumber == 52)
        #expect(card.carried.map(\.initials) == ["EO", "D", "M", "DK", "OP", "U"])
        #expect(card.status == .prayToCarry)
        #expect(card.presence == PresenceLine(window: .now, count: 213))
        #expect(home.me?.streakState == .alive)
        #expect(home.me?.streakDays == 6)
    }

    @Test func filterCounts() {
        defer { running.cancel() }
        #expect(home.counts == HomeFilterCounts(all: 12, stillToHold: 9, carried: 8))
    }

    @Test func stillToHoldDimsAHeldNameKeptForItsIntention() {
        defer { running.cancel() }
        home.filter = .stillToHold
        let dad = home.groups.first { $0.id == "dad" }!
        #expect(dad.name.isContext)
        #expect(dad.intentions.map(\.id) == ["dad-2"])
        #expect(home.cardShown)
    }

    @Test func carriedShowsTheCarriedSet() {
        defer { running.cancel() }
        home.filter = .carried
        #expect(ids(home.groups) == ["self", "self-1", "dad", "dad-1", "mom", "daniel", "parish", "ukraine"])
        #expect(!home.carriedHelperShown)
    }

    @Test func amenWithTheListCarriesYouOn() async {
        defer { running.cancel() }
        session.start(list: home.listContext)
        session.toggleList()
        session.toggle("bea")
        let prayer = try! #require(finish())
        await home.log(prayer)

        // From the device first (the stream's next turn): gold, the card's
        // border, the gate, the streak.
        await waitUntil { !home.localPrayers.isEmpty }
        #expect(home.groups.first { $0.id == "bea" }!.name.heldToday)
        #expect(home.card?.heldToday == true)
        #expect(home.card?.status == .covered)
        #expect(home.me?.streakState == .sealedToday)
        #expect(home.me?.streakDays == 7)

        // Then the backend has it, and the device holds nothing back.
        await waitUntil { home.localPrayers.isEmpty && home.card?.prayers == 3881 }
        #expect(home.localPrayers.isEmpty)
        #expect(backend.myStatus.value?.prayersWithList == 1)
        #expect(home.card?.prayers == 3881)
        #expect(home.card?.status == .covered)
    }

    @Test func offlineThePrayerWaitsOnTheDevice() async {
        defer { running.cancel() }
        backend.online = false
        session.start(list: home.listContext)
        session.toggle("parish")
        await home.log(try! #require(finish()))
        try? await Task.sleep(for: .milliseconds(30))

        #expect(home.groups.first { $0.id == "parish" }!.name.heldToday)
        #expect(home.localPrayers.count == 1)
        #expect(backend.subjects.value.first { $0.id == "parish" }?.lastPrayed == nil)

        backend.online = true
        await waitUntil { home.localPrayers.isEmpty }
        #expect(backend.subjects.value.first { $0.id == "parish" }?.lastPrayed == home.today)
    }

    @Test func underStillToHoldHeldRowsLingerThenLeave() async {
        defer { running.cancel() }
        home.filter = .stillToHold
        session.start(list: home.listContext)
        session.toggle("parish")
        session.toggleList()
        await home.log(try! #require(finish()))

        #expect(home.groups.contains { $0.id == "parish" }, "lingers")
        #expect(home.cardShown, "the card lingers too")
        await waitUntil { !home.groups.contains { $0.id == "parish" } }
        #expect(!home.groups.contains { $0.id == "parish" }, "then folds away")
        #expect(!home.cardShown)
    }

    @Test func theNoteFollowsItsPrayerOffline() async {
        defer { running.cancel() }
        backend.online = false
        session.start(list: home.listContext)
        session.toggleList()
        let prayer = try! #require(finish())
        await home.log(prayer)
        await home.saveNote("  A quiet morning.\n", prayerId: prayer.id)
        await home.saveNote("   ", prayerId: prayer.id) // blank: nothing to save

        backend.online = true
        await waitUntil { backend.notes[prayer.id] != nil }
        #expect(backend.notes[prayer.id] == "A quiet morning.")
    }

    // MARK: Search

    @Test func searchMatchesAliasAndPrintedNameAndHidesTheCard() {
        defer { running.cancel() }
        home.openSearch()
        #expect(home.cardShown, "no text yet: Home as it was")
        home.query = "gary"
        #expect(ids(home.groups) == ["dad", "dad-1", "dad-2"])
        #expect(!home.cardShown, "results only")
        home.query = "Dad"
        #expect(ids(home.groups) == ["dad", "dad-1", "dad-2"])
    }

    @Test func aMatchingIntentionKeepsItsNameAsContext() {
        defer { running.cancel() }
        home.query = "ruth"
        #expect(ids(home.groups) == ["mom", "mom-1"])
        #expect(home.groups[0].name.isContext)
    }

    @Test func noMatchesAndWhatTheFilterHides() {
        defer { running.cancel() }
        home.query = "zzz"
        #expect(home.noMatches)
        #expect(home.matchesHiddenByFilter == nil)

        home.filter = .stillToHold
        home.query = "surgery" // held today: hidden by Still to hold
        #expect(home.noMatches)
        #expect(home.matchesHiddenByFilter == 1)
        #expect(!home.allHeldShown, "search has its own empty state")
        home.showAllMatches()
        #expect(home.filter == .all)
        #expect(home.query == "surgery", "the query is kept")
        #expect(!home.noMatches)
    }

    @Test func closingSearchClearsIt() {
        defer { running.cancel() }
        home.openSearch()
        home.query = "dad"
        home.closeSearch()
        #expect(!home.isSearching)
        #expect(home.query.isEmpty)
        #expect(home.groups.count == 8)
    }

    @Test func noMatchesPrefillsTheAddSheet() {
        defer { running.cancel() }
        let model = AddSheetModel(home: home, name: "  Robe ")
        #expect(model.name == "Robe")
        #expect(model.previewInitials == "R")
    }

    // MARK: Adding

    @Test func aNewNameGoesToTheBottomCarriedWithItsTone() async throws {
        defer { running.cancel() }
        let tone = home.toneForNewName()
        let added = try await home.addSubject(NewSubject(kind: .soul, publicName: "  Ruth   Kim ",
                                                         alias: "Ruthie", avatarTone: tone))
        await waitUntil { home.groups.last?.id == added.id }
        let row = try #require(home.groups.last?.name)
        #expect(row.label == "Ruthie")
        #expect(row.initials == "R")
        #expect(row.tone == tone)
        #expect(row.carried)
        #expect(backend.subjects.value.last?.publicName == "Ruth Kim")
    }

    @Test func anIntentionGoesUnderItsName() async throws {
        defer { running.cancel() }
        let added = try await home.addSubject(NewSubject(kind: .intention, publicName: "Rest", parentId: "dad"))
        await waitUntil { home.groups.first { $0.id == "dad" }?.intentions.last?.id == added.id }
        #expect(home.groups.first { $0.id == "dad" }?.intentions.map(\.id) == ["dad-1", "dad-2", added.id])
    }

    @Test func theNewTonesAreTheLeastUsed() {
        defer { running.cancel() }
        let used = Set(home.groups.map(\.name.tone)) // 7, 0, 8, 10, 13, 14, 6
        for _ in 0..<20 { #expect(!used.contains(home.toneForNewName())) }
    }

    @Test func printedTextCantCarryContactInfo() async {
        defer { running.cancel() }
        await #expect(throws: AddSubjectError.input(.contactInfo)) {
            try await home.addSubject(NewSubject(kind: .soul, publicName: "Ana 555-123-4567"))
        }
    }

    @Test func addingNeedsAConnection() async {
        defer { running.cancel() }
        backend.online = false
        await #expect(throws: AddSubjectError.offline) {
            try await home.addSubject(NewSubject(kind: .soul, publicName: "Ruth"))
        }
    }

    @Test func whenThePoolIsFullItsSavedPrivatelyAndHomeShowsNoMark() async throws {
        defer { running.cancel() }
        // 5 of 10 people carried: five more fit, the sixth doesn't.
        for name in ["A", "B", "C", "E", "F"] {
            #expect(try await home.addSubject(NewSubject(kind: .soul, publicName: name)).isCarried)
        }
        let fourth = try await home.addSubject(NewSubject(kind: .soul, publicName: "D"))
        #expect(!fourth.isCarried)
        await waitUntil { home.groups.contains { $0.id == fourth.id } }
        let row = try #require(home.groups.first { $0.id == fourth.id }?.name)
        #expect(!row.carried)
        #expect(row.secondary == nil, "absence is never marked; the add sheet says it")
    }

    @Test func thePickerIsHomeOrderMeFirst() {
        defer { running.cancel() }
        #expect(home.pickerNames().map(\.label)
                == ["Me", "Dad", "Mom", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea", "Lena Park"])
        #expect(home.pickerNames().first?.initials == "EO")
    }

    @Test func theFlipNeedsAFreshPrayer() async {
        defer { running.cancel() }
        session.start(list: home.listContext)
        session.toggleList()
        await home.log(try! #require(finish()))
        await waitUntil { backend.myStatus.value?.prayersWithList == 1 && home.localPrayers.isEmpty }

        backend.flipList()
        await waitUntil { home.card?.listNumber == 53 }
        #expect(home.card?.status == .nextPrayerCarries)
        #expect(home.card?.sealVariant == nil, "being filmed")
        #expect(home.card?.heldToday == true, "the border stays until local midnight")
    }

    // MARK: A name's page (detail-page.md; Q32: 5 people carried of 10)

    @Test func aNamePageHasTheAliasThePrintedNameAndHomesIntentions() {
        defer { running.cancel() }
        let page = home.page("dad")
        #expect(page?.label == "Dad")
        #expect(page?.printedName == "Gary Olson", "the printed name under the alias")
        #expect(page?.isSelf == false)
        #expect(page?.intentions.map(\.id) == home.groups.first { $0.id == "dad" }?.intentions.map(\.id),
                "Home's rows, in Home's order")
        if case .list = page?.status {} else { Issue.record("a carried name has the list status") }
        #expect(page?.printsWith == ["Healing after his surgery"])
    }

    @Test func theStatusLineReadsAsTheSpecSays() {
        defer { running.cancel() }
        let nb = "\u{00A0}"
        #expect(L10n.Page.status(.list(.covered, next: 53), about: .person("Dad")) == "Dad will be on List\(nb)53")
        #expect(L10n.Page.status(.list(.nextPrayerCarries, next: 54), about: .person("Dad"))
                == "Your next prayer with the list carries Dad onto List\(nb)54")
        #expect(L10n.Page.status(.list(.prayToCarry, next: 53), about: .person("Dad"))
                == "Pray with today's list to carry Dad onto List\(nb)53")
        #expect(L10n.Page.status(.list(.covered, next: 53), about: .me) == "You'll be on List\(nb)53")
        #expect(L10n.Page.status(.list(.nextPrayerCarries, next: 54), about: .me)
                == "Your next prayer with the list puts you on List\(nb)54")
        #expect(L10n.Page.status(.list(.prayToCarry, next: 53), about: .me) == "Pray with today's list to be on List\(nb)53")
        #expect(L10n.Page.status(.list(.covered, next: 53), about: .intention) == "It'll be on List\(nb)53")
        #expect(L10n.Page.status(.list(.nextPrayerCarries, next: 54), about: .intention)
                == "Your next prayer with the list carries it onto List\(nb)54")
        #expect(L10n.Page.status(.list(.prayToCarry, next: 53), about: .intention)
                == "Pray with today's list to carry it onto List\(nb)53")
        #expect(L10n.Page.status(.privateOnly, about: .person("Aunt Bea")) == "Private · in your prayers only")
        #expect(L10n.Page.status(.privateWhilePersonOff, about: .intention, person: "Aunt Bea")
                == "Private while Aunt Bea isn't carried")
        #expect(L10n.Page.status(.closing(list: 52, minutes: 5, next: 53), about: .person("Dad"))
                == "List\(nb)52 closes in 5 min · pray with the list to carry Dad")
        #expect(L10n.Page.status(.closing(list: 52, minutes: 5, next: 53), about: .me)
                == "List\(nb)52 closes in 5 min · pray with the list to be on List\(nb)53")
        #expect(L10n.Page.status(.closing(list: 52, minutes: 5, next: 53), about: .intention)
                == "List\(nb)52 closes in 5 min · pray with the list to carry this")
    }

    @Test func withoutAnAliasNothingRepeatsAndTheSelfIsMe() {
        defer { running.cancel() }
        #expect(home.page("daniel")?.label == "Daniel Kim")
        #expect(home.page("daniel")?.printedName == nil)
        #expect(home.page("daniel")?.printsWith == nil, "no open intentions: no row")
        let me = home.page("self")
        #expect(me?.label == "Me")
        #expect(me?.printedName == "Eric Olson")
        #expect(me?.printsWith == nil, "the self page's card holds only the status")
        #expect(L10n.Page.addIntention(for: "Me", isSelf: true) == "Add intention")
        #expect(L10n.Page.addIntention(for: "Dad", isSelf: false) == "Add intention for Dad")
        #expect(L10n.Page.firstIntention(for: "Dad", isSelf: false) == "Add a first intention for Dad",
                "no possessive built from the alias")
        #expect(L10n.Page.firstIntention(for: "Me", isSelf: true) == "Add your first intention")
    }

    @Test func anUncarriedNameIsPrivateAndCanBeCarriedFromItsPage() async throws {
        defer { running.cancel() }
        #expect(home.page("bea")?.status == .privateOnly)
        #expect(home.page("bea")?.printsWith == nil, "hidden while not carried")
        let offer = home.nameCarryOffer("bea")
        #expect(!offer.startsOn && offer.hasRoom)
        #expect(L10n.Page.carryMeter(nameCarryMeter(offer)) == "5 places left", "5 of 10 people carried")
        #expect(L10n.Page.carryMeter(nameCarryMeter(home.nameCarryOffer("dad"))) == "5 places left")
        try await home.setCarried("bea", true)
        await waitUntil { home.nameCarryOffer("bea").startsOn }
        if case .list = home.page("bea")?.status {} else { Issue.record("carried: the list status") }
        try await home.setCarried("bea", false)
        await waitUntil { !home.nameCarryOffer("bea").startsOn }
        #expect(home.page("bea")?.status == .privateOnly)
        #expect(backend.subjects.value.first { $0.id == "dad" }?.isCarried == true, "the others are kept")
    }

    @Test func theMeterCopy() {
        defer { running.cancel() }
        #expect(L10n.Page.carryMeter(.left(3)) == "3 places left")
        #expect(L10n.Page.carryMeter(.left(1)) == "1 place left")
        #expect(L10n.Page.carryMeter(.usesLast) == "This uses your last place")
        #expect(L10n.Page.carryMeter(.allInUse(pool: 10)) == "All 10 places in use")
        #expect(L10n.Page.carryMeter(.allInUse(pool: 1)) == "Your one place is in use")
        #expect(L10n.Page.carryMeter(.free) == "Free carries you and your intention")
        #expect(L10n.Page.filledUp(pool: 10) == "All 10 places filled up.")
        #expect(L10n.Page.carryFailed == "Couldn't change this. Try again.")
        #expect(L10n.Page.carryOffline == "Needs a connection.")
        #expect(L10n.Page.printsWithValue([]) == "Name only")
        #expect(L10n.Page.printsWithValue(["Rest"]) == "Rest")
    }

    @Test func theLastPlaceAndAFullPool() async {
        defer { running.cancel() }
        backend.header.update { $0?.includeLimit = 6 }
        await waitUntil { home.nameCarryOffer("bea").pool == 6 }
        #expect(nameCarryMeter(home.nameCarryOffer("bea")) == .usesLast)
        backend.header.update { $0?.includeLimit = 5 }
        await waitUntil { home.nameCarryOffer("bea").pool == 5 }
        #expect(!home.nameCarryOffer("bea").hasRoom)
        #expect(nameCarryMeter(home.nameCarryOffer("bea")) == .allInUse(pool: 5))
        #expect(nameCarryMeter(home.nameCarryOffer("dad")) == .allInUse(pool: 5), "carried, none left")
        backend.header.update { $0?.includeLimit = 3 }
        await waitUntil { home.nameCarryOffer("dad").pool == 3 }
        #expect(nameCarryMeter(home.nameCarryOffer("dad")) == .allInUse(pool: 3), "over the pool: never negative")
    }

    @Test func carryingANameThatDoesntFitIsRefused() async {
        defer { running.cancel() }
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
        await waitUntil { home.nameCarryOffer("bea").isFree }
        #expect(!home.nameCarryOffer("bea").hasRoom)
        #expect(nameCarryMeter(home.nameCarryOffer("bea")) == .free)
        await #expect(throws: SetCarriedError.overLimit) { try await home.setCarried("bea", true) }
    }

    @Test func overThePoolTurningANameOffAlwaysWorks() async throws {
        defer { running.cancel() }
        // A lapsed trial: the free pool, with names still carried.
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
        await waitUntil { home.nameCarryOffer("dad").isFree }
        let dad = home.nameCarryOffer("dad")
        #expect(dad.startsOn && dad.hasRoom, "on, and free to turn off")
        try await home.setCarried("dad", false)
        await waitUntil { !home.nameCarryOffer("dad").startsOn }
        #expect(backend.subjects.value.first { $0.id == "dad" }?.isCarried == false)
        #expect(backend.subjects.value.first { $0.id == "dad-1" }?.isCarried == true, "his choice is kept")
        #expect(backend.subjects.value.first { $0.id == "mom" }?.isCarried == true, "the others are kept")
        // Still over the pool: adding back is still refused.
        await #expect(throws: SetCarriedError.overLimit) { try await home.setCarried("dad", true) }
    }

    @Test func printsWithMovesTheCheckEvenOverThePool() async throws {
        defer { running.cancel() }
        // A swap is never pool-checked: a lapsed trial can still choose.
        backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) }
        await waitUntil { home.nameCarryOffer("dad").isFree }
        let options = home.printsWithOptions("dad")
        #expect(options.options.map(\.id) == ["dad-1", "dad-2"])
        #expect(options.options.map(\.checked) == [true, false])
        try await home.setPrintsWith("dad", "dad-2")
        await waitUntil { home.page("dad")?.printsWith == ["Rest for his heart"] }
        #expect(backend.subjects.value.first { $0.id == "dad-1" }?.isCarried == false)
        try await home.setPrintsWith("dad", nil)
        await waitUntil { home.page("dad")?.printsWith == [] }
        #expect(home.printsWithOptions("dad").nameOnly)
    }

    @Test func theCapIsEnforcedByTheServer() async {
        defer { running.cancel() }
        var ids = carriedIds(home.tree)
        ids.insert("dad-2")
        await #expect(throws: SetCarriedError.overCap) { try await backend.setCarriedItems(Array(ids)) }
    }

    @Test func homesCarriedMarkIsChosenAndPersonCarried() async throws {
        defer { running.cancel() }
        let dadRow = { home.groups.first { $0.id == "dad" }?.intentions.first { $0.id == "dad-1" } }
        #expect(dadRow()?.carried == true)
        try await home.setCarried("dad", false)
        await waitUntil { !home.nameCarryOffer("dad").startsOn }
        #expect(dadRow()?.carried == false, "chosen, but Dad isn't carried")
    }

    @Test func anIntentionPageChoosesAndCarriesItsPerson() async throws {
        defer { running.cancel() }
        backend.subjects.update {
            $0.append(Subject(id: "bea-1", kind: .intention, parentId: "bea", publicName: "Her new home",
                              isCarried: false, sortOrder: 1, createdAt: .now))
        }
        await waitUntil { home.intentionPage("bea-1") != nil }
        #expect(home.intentionPage("bea-1")?.status == .privateOnly)
        let offer = home.intentionCarryOffer(personId: "bea", intentionId: "bea-1")
        #expect(!offer.startsOn && offer.alsoCarriesPerson && offer.hasRoom)
        try await home.choose("bea-1", true)
        await waitUntil { home.nameCarryOffer("bea").startsOn }
        if case .list = home.intentionPage("bea-1")?.status {} else { Issue.record("prints now") }
        // Bea off again: the choice stays, and the page says why it doesn't print.
        try await home.setCarried("bea", false)
        await waitUntil { !home.nameCarryOffer("bea").startsOn }
        #expect(home.intentionPage("bea-1")?.status == .privateWhilePersonOff)
        #expect(home.intentionCarryOffer(personId: "bea", intentionId: "bea-1").startsOn)
        // Swapping on Dad's page.
        try await home.choose("dad-2", true)
        await waitUntil { home.page("dad")?.printsWith == ["Rest for his heart"] }
        #expect(home.intentionPage("mom-1")?.answered != nil, "Answered: no carry card")
        #expect(home.intentionPage("mom-1")?.status == nil)
    }

    @Test func restoreComesBackUncarriedOverThePoolAndUnchosenAtTheCap() async throws {
        defer { running.cancel() }
        let now = Date.now
        let ann = Subject(id: "ann", kind: .soul, publicName: "Ann", isCarried: true, sortOrder: 99, createdAt: now)
        let work = Subject(id: "ann-1", kind: .intention, parentId: "ann", publicName: "Work", isCarried: true,
                           sortOrder: 1, createdAt: now)
        backend.header.update { $0?.includeLimit = 6 }
        await waitUntil { home.nameCarryOffer("dad").pool == 6 }
        // 5 of 6 carried: Ann fits.
        #expect(try await backend.restoreSubject(ann, intentions: [work]))
        await waitUntil { home.nameCarryOffer("ann").startsOn }
        // 6 of 6: Bo comes back off; his intention keeps its choice.
        let bo = Subject(id: "bo", kind: .soul, publicName: "Bo", isCarried: true, sortOrder: 100, createdAt: now)
        let boWork = Subject(id: "bo-1", kind: .intention, parentId: "bo", publicName: "Rest", isCarried: true,
                             sortOrder: 1, createdAt: now)
        #expect(try await backend.restoreSubject(bo, intentions: [boWork]) == false)
        await waitUntil { home.page("bo") != nil }
        #expect(backend.subjects.value.first { $0.id == "bo-1" }?.isCarried == true)
        #expect(home.page("bo")?.status == .privateOnly)
        // An intention restored to Dad (at the cap) comes back unchosen.
        let dad3 = Subject(id: "dad-3", kind: .intention, parentId: "dad", publicName: "Sleep", isCarried: true,
                           sortOrder: 3, createdAt: now)
        #expect(try await backend.restoreSubject(dad3) == false)
    }

    // MARK: History (history.md) and the pages' preview

    private func waitForHistory() async {
        await waitUntil { home.historyLog != nil }
    }

    private func node(_ item: StrandItem?) -> StrandNode? {
        if case .node(let node) = item { node } else { nil }
    }

    @Test func dadIsCarriedWithNearDailyListsPrayersAndEntries() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let preview = try #require(home.historyPreview("dad"))
        let today = try #require(node(preview.recent.first))
        #expect(today.isToday && today.prayed && today.listNumbers == [52], "held today, on List 52")
        #expect(preview.totals.prayers > 20 && preview.totals.lists > 20 && preview.totals.journal > 0)
        #expect(preview.totals.worldPrayers > 0)
        #expect(preview.totals.answered == 0)
        #expect(preview.recent.count > 7, "enough for a full row")
    }

    @Test func beaIsPrivateWithPrayerDaysAndGaps() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let preview = try #require(home.historyPreview("bea"))
        #expect(preview.totals.lists == 0, "never carried, never on a list")
        #expect(preview.totals.prayers > 0)
        let strand = try #require(home.historyScreen(.subject("bea"))).strand
        #expect(strand.items.contains { if case .gap = $0 { true } else { false } })
        #expect(strand.items.compactMap(node).allSatisfy { !$0.onList })
    }

    @Test func lenaWasAddedTodayAndHasOnlyToday() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let preview = try #require(home.historyPreview("lena"))
        #expect(preview.recent == [.node(StrandNode(date: home.today, isToday: true))])
        #expect(preview.totals == HistoryTotals(prayers: 0, lists: 0, worldPrayers: 0, journal: 0, answered: 0),
                "every tile hidden")
        let strand = try #require(home.historyScreen(.subject("lena"))).strand
        #expect(strand.begun == home.today)
        #expect(strand.older.isEmpty)
    }

    @Test func momsAnsweredIntentionHasATileATabAndAMark() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let mom = try #require(home.historyPreview("mom"))
        #expect(mom.totals.answered == 1 && mom.showsAnswered)
        #expect(home.historyPreview("mom-1")?.showsAnswered == false, "an intention's page has no Answered tile")
        let screen = try #require(home.historyScreen(.everyone))
        let row = try #require(screen.answered.first)
        #expect(row.text == "A safe delivery for Ruth" && row.personLabel == "Mom")
        #expect(row.prayers > 0 && row.lists > 0)
        let answered = try #require(screen.strand.items.compactMap(node).first { $0.answered })
        let sheet = try #require(home.historyDaySheet(answered.date, scope: .everyone))
        #expect(sheet.answered == ["A safe delivery for Ruth"])
        #expect(sheet.prayers.contains { $0.note == MockHistory.answeredEntry })
    }

    @Test func everyoneIsYourDaysWithPrayersThatHoldSeveralPeople() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let screen = try #require(home.historyScreen(.everyone))
        #expect(screen.streakDays == 6)
        #expect((screen.time?.allTime ?? 0) > 0)
        #expect(screen.lists.first?.listNumber == 52)
        #expect(screen.lists.first?.prayerCount == backend.list.value?.prayerCount, "the live count")
        #expect(screen.held.flatMap(\.items).contains { ($0.people?.count ?? 0) >= 3 })
        #expect(!screen.journal.isEmpty)
        #expect(screen.held.flatMap(\.items).contains { $0.autoSaved })
        let nodes = screen.strand.items.compactMap(node)
        #expect(nodes.contains { $0.onList && $0.prayed && $0.journal })
        #expect(nodes.contains { $0.onList && !$0.prayed }, "a list day without a prayer")
        #expect(screen.strand.items.contains { if case .month = $0 { true } else { false } })
        // Filtered: nothing about you, no clusters.
        let dad = try #require(home.historyScreen(.subject("dad")))
        #expect(dad.streakDays == nil && dad.time == nil)
        #expect(dad.held.flatMap(\.items).allSatisfy { $0.people == nil })
        #expect(home.historyChip(.subject("dad")) == "Dad")
        #expect(home.historyChip(.subject("dad-1")) == "Healing after his surgery")
        #expect(home.historyChip(.everyone) == nil)
    }

    @Test func aDayWithNoPrayerShowsOnlyWhatHappened() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let screen = try #require(home.historyScreen(.everyone))
        let listOnly = try #require(screen.strand.items.compactMap(node).first { $0.onList && !$0.prayed })
        let sheet = try #require(home.historyDaySheet(listOnly.date, scope: .everyone))
        #expect(sheet.prayers.isEmpty && sheet.lists.count == 1)
    }

    @Test func aPrayerShowsAtOnceFoldedInFromTheDevice() async throws {
        defer { running.cancel() }
        await waitForHistory()
        let before = try #require(home.historyPreview("mom")).totals.prayers
        backend.online = false
        let prayer = NewPrayer(id: "p-new", startedAt: .now.addingTimeInterval(-60), prayedAt: .now,
                               localDate: home.today, timezone: "UTC", communityListId: nil, listContextNumber: 52,
                               subjectIds: ["mom-1"])
        await home.log(prayer)
        await waitUntil { home.historyPreview("mom")?.totals.prayers == before + 1 }
        #expect(home.historyPreview("mom")?.totals.prayers == before + 1, "an intention's prayer holds its name too")
        #expect(node(home.historyPreview("mom")?.recent.first)?.prayed == true)
        backend.online = true
    }

    @Test func theHistoryCopy() {
        defer { running.cancel() }
        let start = Date.now
        #expect(L10n.History.prayerLine(startedAt: start, seconds: 38 * 60, autoSaved: true)
                .hasSuffix(" · ~38 min"))
        #expect(L10n.History.prayerLine(startedAt: start, seconds: 12 * 60 + 10, autoSaved: false)
                .hasSuffix(" · 12 min"))
        #expect(L10n.History.onList(46, prayers: 3475) == "On List\u{00A0}46 · 3,475 prayers")
        #expect(L10n.History.answered("Rest") == "Answered · Rest")
        #expect(L10n.History.tilePrayers(1) == "your prayer" && L10n.History.tilePrayers(14) == "your prayers")
        #expect(L10n.History.tileLists(40) == "lists")
        #expect(L10n.History.tileJournal == "in your journal" && L10n.History.tileAnswered == "answered")
        #expect(L10n.History.periodSummary(PeriodSummary(prayers: 2, lists: 6, notes: 1)) == "2 prayers · 6 lists · ✎ 1")
        #expect(L10n.History.periodSummary(PeriodSummary(prayers: 0, lists: 1, notes: 0)) == "1 list")
        #expect(L10n.History.prayedAndLists(prayers: 12, lists: 30) == "You prayed 12 times · On 30 lists")
        #expect(L10n.History.prayedAndLists(prayers: 1, lists: 0) == "You prayed once")
        let day = LocalDate(year: 2026, month: 11, day: 5)
        let spoken = L10n.History.node(StrandNode(date: day, listNumbers: [49], prayed: true, journal: true),
                                       lists: [49], today: LocalDate(year: 2026, month: 11, day: 8))
        #expect(spoken == "Thursday, November 5. On List\u{00A0}49. You prayed. Journal entry.")
        #expect(L10n.History.dayHeading(day, today: day) == "Today")
        #expect(L10n.History.dayHeading(day, today: day.adding(days: 1)) == "Yesterday")
        #expect(L10n.History.dayHeading(day, today: day.adding(days: 3)) == "Thursday, Nov 5")
        #expect(L10n.History.noActivity == "No activity")
        #expect(L10n.Closing.addToJournal == "Add to journal")
    }
}

@MainActor
struct PrayerSessionTests {
    @Test func amenBeforeTheMinimumDoesNothing() {
        let session = PrayerSession(graph: { SubjectGraph(intentionsByName: [:]) })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        #expect(session.amen(prayedWithListToday: true) == nil)
        #expect(session.isPraying)
    }

    @Test func amenReturnsWhatWasHeld() {
        let graph = SubjectGraph(intentionsByName: ["dad": ["dad-1"]])
        let clock = TestClock()
        let session = PrayerSession(graph: { graph }, clock: { clock.now })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        session.toggle("dad-1")
        clock.advance(6)
        let prayer = session.amen(prayedWithListToday: true)
        #expect(prayer?.subjectIds == ["dad", "dad-1"])
        #expect(prayer?.communityListId == nil)
        #expect(prayer?.listContextNumber == 52)
        #expect(!session.isPraying)
        #expect(session.closing == prayer)
        #expect(session.amenCount == 1)
        #expect(session.isHeld("dad-1"), "held until the closing sheet goes, so the gold doesn't blink")
        session.close()
        #expect(session.phase == .idle)
        #expect(!session.isHeld("dad-1"))
    }

    @Test func amenWithoutTheListInvitesFirst() {
        let clock = TestClock()
        let session = PrayerSession(graph: { SubjectGraph(intentionsByName: ["dad": []]) }, clock: { clock.now })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        session.toggle("dad")
        clock.advance(6)
        #expect(session.amen(prayedWithListToday: false) == nil, "nothing written yet")
        #expect(session.isInvited)
        #expect(session.isPraying, "the halo stays through the invitation")
        #expect(session.amenCount == 0)

        session.holdList()
        #expect(session.holdingListSince == clock.now)
        clock.advance(2)
        #expect(session.amenFromInvitation() == nil, "the ring is still running")
        clock.advance(3)
        let prayer = session.amenFromInvitation()
        #expect(prayer?.communityListId == "list-52")
        #expect(prayer?.subjectIds == ["dad"])
        #expect(prayer?.durationSeconds == 11, "one prayer: the invitation extends it")
        #expect(session.amenCount == 1)
    }

    @Test func amenOnTheInvitationWithoutTappingFinishesWithoutTheList() {
        let clock = TestClock()
        let session = PrayerSession(graph: { SubjectGraph(intentionsByName: [:]) }, clock: { clock.now })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        clock.advance(6)
        _ = session.amen(prayedWithListToday: false)
        let prayer = session.amenFromInvitation()
        #expect(prayer != nil)
        #expect(prayer?.communityListId == nil)
    }

    @Test func noInvitationOnceYouvePrayedWithTheList() {
        let clock = TestClock()
        let session = PrayerSession(graph: { SubjectGraph(intentionsByName: [:]) }, clock: { clock.now })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        clock.advance(6)
        #expect(session.amen(prayedWithListToday: true) != nil)
        #expect(!session.isInvited)
    }

    @Test func cancelFromTheInvitationLogsNothing() {
        let clock = TestClock()
        let session = PrayerSession(graph: { SubjectGraph(intentionsByName: [:]) }, clock: { clock.now })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        clock.advance(6)
        _ = session.amen(prayedWithListToday: false)
        session.cancel()
        #expect(session.phase == .idle)
        #expect(session.amenCount == 0)
    }
}
