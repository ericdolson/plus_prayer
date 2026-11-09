import Foundation
import Testing
@testable import PlusPrayerDomain

/// auth-onboarding.md: resume by state, the alias-or-name label, the full
/// name in the greeting, and the pre-trial pool (2026-11-09).
struct OnboardingTests {
    let now = Fixture.epoch

    @Test func resumeIsStateBased() {
        #expect(launchDestination(nil) == .waiting)
        #expect(launchDestination(UserHeader(id: "u")) == .onboarding, "no self name: Welcome")
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

    @Test func theGreetingIsTheFullName() {
        #expect(greetingName(UserHeader(id: "u", displayName: "Sarah Beth Parker", selfSubjectId: "s"))
                == "Sarah Beth Parker")
        #expect(greetingName(UserHeader(id: "u")) == nil)
        #expect(greetingName(nil) == nil)
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
