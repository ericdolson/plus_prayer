import Foundation
import Testing
@testable import PlusPrayerDomain

/// Same cases as the Flutter build's avatar_cluster rules.
struct ClusterLayoutTests {
    @Test func upToFiveEveryAvatarAndTheTextCounts() {
        let layout = layoutCluster(["You", "Dad", "Mom", "Daniel", "Parish"])
        #expect(layout.avatars.count == 5)
        #expect(layout.overflow == 0)
        #expect(layout.named == ["You", "Dad"])
        #expect(layout.counted == 3)
    }

    @Test func moreThanFiveFourAvatarsADiscAndNoCount() {
        let layout = layoutCluster(["You", "Dad", "Mom", "Daniel", "Parish", "Ukraine"])
        #expect(layout.avatars == ["You", "Dad", "Mom", "Daniel"])
        #expect(layout.overflow == 2)
        #expect(layout.counted == 0)
    }

    @Test func twoOrOne() {
        #expect(layoutCluster(["You", "Dad"]).counted == 0)
        #expect(layoutCluster(["You"]).named == ["You"])
    }
}

struct InvitationTests {
    let none = PrayerSelection.empty

    @Test func amenWithoutTheListInvites() {
        #expect(invitesToList(none, listKnown: true, prayedWithListToday: false))
    }

    @Test func notWhenTheListWasHeld() {
        #expect(!invitesToList(none.withList(true), listKnown: true, prayedWithListToday: false))
    }

    @Test func notOnceYouvePrayedWithItToday() {
        #expect(!invitesToList(none, listKnown: true, prayedWithListToday: true))
    }

    @Test func notWithoutAList() {
        #expect(!invitesToList(none, listKnown: false, prayedWithListToday: false))
    }
}

struct DurationTests {
    let start = Fixture.epoch
    let list = ListContext(listId: "list-52", listNumber: 52)

    @Test func heldWithinTheMinimumAndTheCap() {
        func duration(_ seconds: TimeInterval) -> Int {
            newPrayer(id: "p", selection: .empty, startedAt: start, endedAt: start.addingTimeInterval(seconds),
                      list: list).durationSeconds
        }
        #expect(duration(3) == 5)
        #expect(duration(42.9) == 42)
        #expect(duration(5 * 3600) == 4 * 3600)
    }
}
