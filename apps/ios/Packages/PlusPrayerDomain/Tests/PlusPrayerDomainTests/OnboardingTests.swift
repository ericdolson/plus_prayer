import Foundation
import Testing
@testable import PlusPrayerDomain

/// auth-onboarding.md: resume by state, the alias-or-name label, the line
/// under Me after the first prayer, and the pre-trial pool (2026-11-09).
struct OnboardingTests {
    let now = Fixture.epoch

    @Test func resumeIsStateBased() {
        #expect(launchDestination(nil) == .waiting)
        #expect(launchDestination(UserHeader(id: "u")) == .onboarding, "no self name: onboarding")
        #expect(launchDestination(UserHeader(id: "u", displayName: "Eric Olson")) == .onboarding,
                "a display name without the self subject isn't done")
        #expect(launchDestination(UserHeader(id: "u", displayName: "Eric Olson", selfSubjectId: "s")) == .home)
    }

    @Test func theLabelIsTheAliasElseTheName() {
        #expect(personLabel(name: "Julie Olson", alias: "Mom") == "Mom")
        #expect(personLabel(name: "Julie Olson", alias: "  ") == "Julie Olson")
        #expect(personLabel(name: "  Julie   Olson ", alias: "") == "Julie Olson")
        #expect(personLabel(name: "", alias: "") == "")
        #expect(initials(personLabel(name: "Julie Olson", alias: "Mom")) == "M")
        #expect(initials(personLabel(name: "Julie Olson", alias: "")) == "JO")
    }
}

/// "After the first Amen" (auth-onboarding.md): the quiet line under Me,
/// "Add an intention for yourself", after the first prayer, while Me has no
/// open intention, until dismissed for good.
struct SelfIntentionPromptTests {
    let me = Fixture.name("self", "Eric Olson", order: 0, alias: "Me", isSelf: true)
    let user = UserHeader(id: "u", displayName: "Eric Olson", selfSubjectId: "self")

    @Test func prayedOnceMeansAnyTraceOfAPrayer() {
        let tree = SubjectTree([me, Fixture.name("mom", "Julie Olson", order: 1, alias: "Mom")])
        #expect(!hasPrayed(user, tree: tree, loggedPrayers: 0, localPrayers: 0), "a fresh account")
        #expect(!hasPrayed(nil, tree: SubjectTree([]), loggedPrayers: 0, localPrayers: 0))
        #expect(hasPrayed(user, tree: tree, loggedPrayers: 1, localPrayers: 0), "in the History log")
        #expect(hasPrayed(user, tree: tree, loggedPrayers: 0, localPrayers: 1), "still on the device")
        var withList = user
        withList.lastListLocalDate = Fixture.today
        #expect(hasPrayed(withList, tree: tree, loggedPrayers: 0, localPrayers: 0), "prayed with the list")
        let held = SubjectTree([me, Fixture.name("mom", "Julie Olson", order: 1, alias: "Mom", prayed: 3)])
        #expect(hasPrayed(user, tree: held, loggedPrayers: 0, localPrayers: 0), "a name held some day")
    }

    @Test func onlyAfterTheFirstPrayer() {
        let tree = SubjectTree([me])
        #expect(!showsSelfIntentionPrompt(hasPrayed: false, tree: tree, dismissed: false),
                "the first Home has only Pray lit")
        #expect(showsSelfIntentionPrompt(hasPrayed: true, tree: tree, dismissed: false))
    }

    @Test func goneOnceDismissedOrUsed() {
        #expect(!showsSelfIntentionPrompt(hasPrayed: true, tree: SubjectTree([me]), dismissed: true),
                "dismissed for good")
        let withOne = SubjectTree([me, Fixture.intention("i", "self", "Patience", order: 0)])
        #expect(!showsSelfIntentionPrompt(hasPrayed: true, tree: withOne, dismissed: false), "used")
        let notChosen = SubjectTree([me, Fixture.intention("i", "self", "Patience", order: 0, carried: false)])
        #expect(!showsSelfIntentionPrompt(hasPrayed: true, tree: notChosen, dismissed: false),
                "any open intention on Me, printed or not")
        let answered = SubjectTree([me, Fixture.intention("i", "self", "A new job", order: 0, answered: true)])
        #expect(showsSelfIntentionPrompt(hasPrayed: true, tree: answered, dismissed: false),
                "an answered one is no longer open")
    }

    @Test func neverBeforeMeExists() {
        #expect(!showsSelfIntentionPrompt(hasPrayed: true, tree: SubjectTree([]), dismissed: false))
        let others = SubjectTree([Fixture.name("mom", "Julie Olson", order: 1)])
        #expect(!showsSelfIntentionPrompt(hasPrayed: true, tree: others, dismissed: false))
    }
}

/// Before the first prayer (never prayed, never entitled) the user has the
/// trial's pool, so onboarding's adds are carried (2026-11-09; pool.ts).
struct PreTrialPoolTests {
    let now = Fixture.epoch
    let fresh = UserHeader(id: "u", displayName: "Eric Olson", selfSubjectId: "self")

    func names(_ n: Int) -> SubjectTree {
        SubjectTree([Fixture.name("self", "Eric Olson", order: 0, alias: "Me", isSelf: true)]
                    + (1...max(n, 1)).prefix(n).map { Fixture.name("p\($0)", "P\($0)", order: $0) })
    }

    @Test func aNeverPrayedUserHasTheTrialsPool() {
        #expect(isPreTrial(fresh))
        #expect(!isFreeTier(fresh, now: now))
        #expect(effectivePoolLimit(fresh, now: now) == AppConfig.defaults.basePremiumPool)
        #expect(effectivePoolLimit(fresh, now: now, prePool: 3) == 3, "from /config")
        let new = Fixture.name("new", "Julie Olson", order: 99)
        #expect(carriesNewSubject(new, in: names(0), user: fresh, now: now))
    }

    @Test func tenFitNotEleven() {
        #expect(checkPool(names(10), user: fresh, now: now).fits)
        let eleven = checkPool(names(11), user: fresh, now: now)
        #expect(!eleven.fits && eleven.limit == 10 && !eleven.isFree)
        #expect(placesLeft(names(9), user: fresh, now: now) == 1)
        let offer = nameCarryOffer(nameId: "p1", in: names(10), user: fresh, now: now)
        #expect(nameCarryMeter(offer) == .allInUse(pool: 10), "a meter, not the free line")
    }

    @Test func notPreTrialOnceTheTrialStartedOrAnEntitlementExisted() {
        var started = fresh
        started.trialStartedAt = now.addingTimeInterval(-86_400)
        started.entitlementExpiresAt = now.addingTimeInterval(13 * 86_400)
        started.includeLimit = 10
        #expect(!isPreTrial(started))
        #expect(effectivePoolLimit(started, now: now) == 10)

        var ended = started
        ended.entitlementExpiresAt = now.addingTimeInterval(-86_400)
        #expect(isFreeTier(ended, now: now))
        #expect(effectivePoolLimit(ended, now: now) == 0)

        var lapsedBeforePraying = fresh
        lapsedBeforePraying.entitlementExpiresAt = now.addingTimeInterval(-86_400)
        lapsedBeforePraying.includeLimit = 10
        #expect(!isPreTrial(lapsedBeforePraying))
        #expect(effectivePoolLimit(lapsedBeforePraying, now: now) == 0)
    }
}
