import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// First run over the mock (auth-onboarding.md, "Flow (revised
/// 2026-11-09)"): resume by state, the screens' path, the alias-or-name
/// label, and the guided add's save sequence (the person carried, then the
/// intention as their chosen one). The fresh seed (`-PPMockFresh`) has no
/// self name and no people, never prayed: the pre-trial pool.
@MainActor
struct OnboardingModelTests {
    let backend = MockBackend(seed: .fresh(now: .now), latency: .milliseconds(1), liveDrift: false)
    let home: HomeModel
    private let running: Task<Void, Never>

    init() async {
        let environment = AppEnvironment.mock(backend)
        let home = HomeModel(repositories: environment.repositories, clock: environment.clock)
        self.home = home
        running = Task { await home.run() }
        for _ in 0..<200 where home.header == nil { try? await Task.sleep(for: .milliseconds(5)) }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<400 where !condition() { try? await Task.sleep(for: .milliseconds(5)) }
    }

    private func subject(named name: String) -> Subject? { backend.subjects.value.first { $0.publicName == name } }

    /// Begin → a name → Welcome back.
    private func throughTheName(_ model: OnboardingModel, _ name: String = "Eric Olson") async {
        model.begin()
        model.name = name
        await model.submitName()
    }

    // MARK: Resume

    @Test func aFreshAccountNeedsOnboardingAndTheNameEndsIt() async {
        defer { running.cancel() }
        #expect(home.needsSelfName, "no self name: Welcome")
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        await waitUntil { !home.needsSelfName }
        #expect(!home.needsSelfName, "a name exists: a later launch opens Home")
        #expect(model.path == [.name, .welcomeBack], "this run stays on Welcome back")
        #expect(!model.isFinished)
    }

    @Test func theSeededMockOpensHome() async {
        let home = HomeModel(environment: .mock(MockBackend(latency: .milliseconds(1), liveDrift: false)))
        let running = Task { await home.run() }
        defer { running.cancel(); self.running.cancel() }
        for _ in 0..<200 where !home.isLoaded { try? await Task.sleep(for: .milliseconds(5)) }
        #expect(!home.needsSelfName)
    }

    // MARK: The name

    @Test func theNameScreenSavesTheFullNameWithTheAvatarItShowed() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        model.begin()
        #expect(model.path == [.name])
        #expect(!model.canContinueName, "Continue is disabled while empty")
        #expect(model.nameInitials.isEmpty, "the person glyph")
        model.name = "  Sarah Beth   Parker "
        #expect(model.nameInitials == "SP")
        await model.submitName()
        let me = backend.subjects.value.first(where: \.isSelf)
        #expect(me?.publicName == "Sarah Beth Parker")
        #expect(me?.tone == model.selfTone, "the self keeps the name screen's color")
        await waitUntil { home.header?.displayName != nil }
        #expect(model.greeting == "Sarah Beth Parker", "the full name, never split")
    }

    @Test func nameErrorsUseTheExistingLinesAndKeepTheText() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        model.begin()
        model.name = "call 555-123-4567"
        await model.submitName()
        #expect(model.nameProblem == .contact)
        #expect(model.path == [.name])
        model.name = "Ann"
        model.nameChanged()
        #expect(model.nameProblem == nil)
        backend.online = false
        await model.submitName()
        #expect(model.nameProblem == .offline)
        #expect(model.name == "Ann", "what they typed stays")
        backend.online = true
        backend.failsAdds = true
        await model.submitName()
        #expect(model.nameProblem == .failed)
        backend.failsAdds = false
        await model.submitName()
        #expect(model.path == [.name, .welcomeBack])
    }

    @Test func backToTheNameAndContinueUnchangedDoesNotSaveAgain() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.path = [.name]
        backend.online = false // a second setSelfName would fail
        await model.submitName()
        #expect(model.path == [.name, .welcomeBack])
        #expect(model.nameProblem == nil)
    }

    // MARK: The guided add

    @Test func theLabelIsWhatYouCallThemElseTheName() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.addSomeone()
        #expect(model.path.last == .someone)
        #expect(!model.showsCarriedLine && !model.canContinuePerson)
        model.personName = "Julie Olson"
        #expect(model.personLabel == "Julie Olson" && model.personInitials == "JO")
        #expect(model.showsCarriedLine)
        model.personAlias = "Mom"
        #expect(model.personLabel == "Mom" && model.personInitials == "M")
        #expect(L10n.Onboarding.carriedWithYou(model.personLabel) == "Mom will be carried on the list with you.")
        #expect(L10n.Onboarding.intentionTitle(model.personLabel) == "What are you praying for, for Mom?")
        model.personAlias = " "
        #expect(model.personLabel == "Julie Olson")
    }

    @Test func addSavesThePersonCarriedThenTheirChosenIntention() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.addSomeone()
        model.personName = "Julie Olson"
        model.personAlias = "Mom"
        model.continueToIntention()
        #expect(model.path == [.name, .welcomeBack, .someone, .intention])
        #expect(backend.subjects.value.count == 1, "nothing saved before Add or Skip")
        model.intention = "Healing after surgery"
        await model.save(withIntention: true)

        let mom = subject(named: "Julie Olson")
        #expect(mom?.alias == "Mom")
        #expect(mom?.isCarried == true, "carried by default: the pre-trial pool")
        #expect(mom?.tone == model.personTone)
        let intention = subject(named: "Healing after surgery")
        #expect(intention?.parentId == mom?.id)
        #expect(intention?.isCarried == true, "their chosen intention")
        #expect(model.path == [.name, .welcomeBack], "back to Welcome back")
        await waitUntil { !model.added.isEmpty }
        #expect(model.added.map(\.label) == ["Mom"], "only the people added, never you")
    }

    @Test func skipSavesThePersonWithoutAnIntention() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.addSomeone()
        model.personName = "Gary Olson"
        model.continueToIntention()
        model.intention = "typed, then skipped"
        await model.save(withIntention: false)
        #expect(subject(named: "Gary Olson")?.isCarried == true)
        #expect(subject(named: "typed, then skipped") == nil)
        #expect(backend.subjects.value.filter { $0.kind == .intention }.isEmpty)
        #expect(model.path == [.name, .welcomeBack])
    }

    @Test func aFailedSaveKeepsWhatTheyTypedAndStays() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.addSomeone()
        model.personName = "Julie Olson"
        model.personAlias = "Mom"
        model.continueToIntention()
        model.intention = "Healing after surgery"
        backend.failsAdds = true
        await model.save(withIntention: true)
        #expect(model.addProblem == .failed)
        #expect(model.path.last == .intention)
        #expect(model.personName == "Julie Olson" && model.intention == "Healing after surgery")
        #expect(subject(named: "Julie Olson") == nil)
        #expect(!model.personLocked, "nothing saved: ‹ stays")

        backend.online = false
        await waitUntil { model.isOffline }
        #expect(!model.canSave, "offline: Add and Skip wait for the connection")
        backend.online = true
        await waitUntil { !model.isOffline }
        backend.failsAdds = false
        model.textChanged()
        await model.save(withIntention: true)
        #expect(model.addProblem == nil)
        #expect(backend.subjects.value.filter { $0.publicName == "Julie Olson" }.count == 1)
    }

    @Test func ifOnlyTheIntentionFailsTheRetryAddsOnlyTheIntention() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        model.addSomeone()
        model.personName = "Julie Olson"
        model.continueToIntention()
        model.intention = "Healing after surgery"
        // One place left under the ~500 cap: the person fits, the intention doesn't.
        let filler = (0..<(subjectCap - 2)).map {
            Subject(id: "filler-\($0)", kind: .soul, publicName: "F\($0)", isCarried: false, sortOrder: 100 + $0,
                    createdAt: .now)
        }
        backend.subjects.update { $0 += filler }
        await model.save(withIntention: true)
        #expect(subject(named: "Julie Olson") != nil, "the person was saved")
        #expect(model.addProblem == .cap)
        #expect(model.personLocked, "‹ goes: their fields can't change from here")
        #expect(model.path.last == .intention)
        #expect(model.intention == "Healing after surgery", "what they typed stays")

        backend.subjects.update { $0.removeAll { $0.id.hasPrefix("filler-") } }
        model.textChanged()
        await model.save(withIntention: true)
        #expect(backend.subjects.value.filter { $0.publicName == "Julie Olson" }.count == 1, "never twice")
        #expect(subject(named: "Healing after surgery")?.isCarried == true)
        #expect(model.path == [.name, .welcomeBack])
        #expect(model.addedIds.count == 1)
    }

    @Test func peopleAddedThroughTheSheetJoinTheRow() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        let sheet = AddSheetModel(home: home)
        sheet.name = "Gary Olson"
        sheet.alias = "Dad"
        await sheet.add()
        model.addedFromSheet(sheet.addedNameId)
        model.addedFromSheet(sheet.addedNameId)
        model.addedFromSheet(nil)
        await waitUntil { !model.added.isEmpty }
        #expect(model.added.map(\.label) == ["Dad"])
        #expect(subject(named: "Gary Olson")?.isCarried == true, "the pre-trial pool carries it")
        model.finish()
        #expect(model.isFinished)
    }

    @Test func theFirstPrayerStartsTheTrial() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        #expect(backend.header.value?.trialStartedAt == nil)
        backend.applyPrayer(NewPrayer(id: UUID().uuidString, startedAt: .now.addingTimeInterval(-60), prayedAt: .now,
                                      localDate: LocalDate(.now), timezone: "UTC", communityListId: nil,
                                      listContextNumber: 52, subjectIds: []))
        #expect(backend.header.value?.trialStartedAt != nil)
        #expect(backend.header.value?.includeLimit == AppConfig.defaults.basePremiumPool)
    }
}
