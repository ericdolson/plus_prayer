import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// First run over the mock (auth-onboarding.md, "Flow (redesigned
/// 2026-11-09, second pass)"): resume by state, the steps, the
/// alias-or-name label, the save sequence (the person carried, then the
/// intention as their chosen one), and the line under Me after the first
/// prayer. The fresh seed (`-PPMockFresh`) has no self name and no people,
/// never prayed: the pre-trial pool.
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

    /// A name → the moment.
    private func throughTheName(_ model: OnboardingModel, _ name: String = "Eric Olson") async {
        model.name = name
        await model.submitName()
    }

    /// A name → the moment → someone.
    private func toSomeone(_ model: OnboardingModel) async {
        await throughTheName(model)
        model.continueFromMoment()
    }

    // MARK: Resume

    @Test func aFreshAccountNeedsOnboardingAndTheNameEndsIt() async {
        defer { running.cancel() }
        #expect(home.needsSelfName, "no self name: onboarding")
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        await waitUntil { !home.needsSelfName }
        #expect(!home.needsSelfName, "a name exists: a later launch opens Home")
        #expect(model.step == .moment, "this run stays on the stage")
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

    @Test func theNameSavesTheFullNameWithTheAvatarTheMomentShows() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        #expect(model.step == .name)
        #expect(!model.canContinueName, "Continue is unlit while empty")
        #expect(model.nameInitials.isEmpty)
        model.name = "  Sarah Beth   Parker "
        #expect(model.nameInitials == "SP")
        #expect(model.displayName == "Sarah Beth Parker", "the full name, never split")
        await model.submitName()
        #expect(model.step == .moment)
        let me = backend.subjects.value.first(where: \.isSelf)
        #expect(me?.publicName == "Sarah Beth Parker")
        #expect(me?.tone == model.selfTone, "the self keeps the moment's color")
        await waitUntil { home.listContext != nil }
        #expect(model.nextListNumber == (home.listContext?.listNumber ?? 0) + 1, "the paper line: tomorrow's list")
    }

    @Test func nameErrorsUseTheExistingLinesAndKeepTheText() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        model.name = "call 555-123-4567"
        await model.submitName()
        #expect(model.nameProblem == .contact)
        #expect(model.step == .name)
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
        #expect(model.step == .moment)
    }

    @Test func backToTheNameAndContinueUnchangedDoesNotSaveAgain() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        #expect(model.canGoBack)
        model.back()
        #expect(model.step == .name)
        #expect(model.name == "Eric Olson", "the text is kept")
        backend.online = false // a second setSelfName would fail
        await model.submitName()
        #expect(model.step == .moment)
        #expect(model.nameProblem == nil)
    }

    // MARK: The steps

    @Test func backGoesOneStepAndNeverFromTheName() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        #expect(!model.canGoBack, "no ‹ on the first step")
        await toSomeone(model)
        #expect(model.step == .someone)
        model.personName = "Julie Olson"
        model.continueToIntention()
        #expect(model.step == .intention)
        model.back()
        #expect(model.step == .someone)
        #expect(model.personName == "Julie Olson")
        model.back()
        #expect(model.step == .moment)
        model.back()
        #expect(model.step == .name)
    }

    @Test func notNowGoesToHomeWithNoOne() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        model.personName = "typed, then not now"
        model.notNow()
        #expect(model.step == .handoff)
        #expect(model.addedPersonId == nil)
        #expect(backend.subjects.value.count == 1, "only Me")
        #expect(!model.isFinished, "the hand-off plays first")
        model.finish()
        #expect(model.isFinished)
    }

    @Test func thePersonsToneIsntYours() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        #expect(model.personTone != model.selfTone, "picked among the least used, yours counted")
    }

    // MARK: Someone you pray for

    @Test func theLabelIsWhatYouCallThemElseTheName() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        #expect(!model.hasPerson && !model.canContinuePerson, "their avatar forms with the first letter")
        model.personName = "Julie Olson"
        #expect(model.personLabel == "Julie Olson" && model.personInitials == "JO")
        #expect(model.hasPerson && model.canContinuePerson)
        model.personAlias = "Mom"
        #expect(model.personLabel == "Mom" && model.personInitials == "M")
        #expect(L10n.Onboarding.intentionTitle(model.personLabel) == "What are you praying for, for Mom?")
        model.personAlias = " "
        #expect(model.personLabel == "Julie Olson")
    }

    @Test func addSavesThePersonCarriedThenTheirChosenIntention() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        model.personName = "Julie Olson"
        model.personAlias = "Mom"
        model.continueToIntention()
        #expect(model.step == .intention)
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
        #expect(model.step == .handoff, "then Home")
        #expect(model.addedPersonId == mom?.id, "the hand-off takes her avatar into her row")
    }

    @Test func skipSavesThePersonWithoutAnIntention() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        model.personName = "Gary Olson"
        model.continueToIntention()
        model.intention = "typed, then skipped"
        await model.save(withIntention: false)
        #expect(subject(named: "Gary Olson")?.isCarried == true)
        #expect(subject(named: "typed, then skipped") == nil)
        #expect(backend.subjects.value.filter { $0.kind == .intention }.isEmpty)
        #expect(model.step == .handoff)
    }

    @Test func aFailedSaveKeepsWhatTheyTypedAndStays() async {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await toSomeone(model)
        model.personName = "Julie Olson"
        model.personAlias = "Mom"
        model.continueToIntention()
        model.intention = "Healing after surgery"
        backend.failsAdds = true
        await model.save(withIntention: true)
        #expect(model.addProblem == .failed)
        #expect(model.step == .intention)
        #expect(model.personName == "Julie Olson" && model.intention == "Healing after surgery")
        #expect(subject(named: "Julie Olson") == nil)
        #expect(!model.personLocked && model.canGoBack, "nothing saved: ‹ stays")

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
        await toSomeone(model)
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
        #expect(model.personLocked && !model.canGoBack, "‹ goes: their fields can't change from here")
        #expect(model.step == .intention)
        #expect(model.intention == "Healing after surgery", "what they typed stays")

        backend.subjects.update { $0.removeAll { $0.id.hasPrefix("filler-") } }
        model.textChanged()
        await model.save(withIntention: true)
        #expect(backend.subjects.value.filter { $0.publicName == "Julie Olson" }.count == 1, "never twice")
        #expect(subject(named: "Healing after surgery")?.isCarried == true)
        #expect(model.step == .handoff)
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

    // MARK: After the first Amen

    @Test func theLineUnderMeComesAfterTheFirstPrayer() async throws {
        defer { running.cancel() }
        let model = OnboardingModel(home: home)
        await throughTheName(model)
        await waitUntil { home.meId != nil }
        #expect(!home.hasPrayed)
        #expect(!home.showsSelfIntentionPrompt(dismissed: false), "the first Home has only Pray lit")
        let prayer = NewPrayer(id: UUID().uuidString, startedAt: .now.addingTimeInterval(-60), prayedAt: .now,
                               localDate: LocalDate(.now), timezone: "UTC", communityListId: nil,
                               listContextNumber: 52, subjectIds: [])
        await home.log(prayer)
        await waitUntil { home.hasPrayed }
        #expect(home.showsSelfIntentionPrompt(dismissed: false))
        #expect(!home.showsSelfIntentionPrompt(dismissed: true), "dismissed for good")
        let me = try #require(home.meId)
        _ = try await home.addSubject(NewSubject(kind: .intention, publicName: "Patience", parentId: me))
        await waitUntil { !home.showsSelfIntentionPrompt(dismissed: false) }
        #expect(!home.showsSelfIntentionPrompt(dismissed: false), "used: an intention on Me")
    }
}
