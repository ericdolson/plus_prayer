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
                == ["Me", "Dad", "Mom", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea"])
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
        #expect(home.counts == HomeFilterCounts(all: 11, stillToHold: 8, carried: 8))
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
        #expect(home.groups.count == 7)
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
        // 7 of 10 places carried: three more fit, the fourth doesn't.
        for name in ["A", "B", "C"] {
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
        #expect(home.pickerNames.map(\.label) == ["Me", "Dad", "Mom", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea"])
        #expect(home.pickerNames.first?.initials == "EO")
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
