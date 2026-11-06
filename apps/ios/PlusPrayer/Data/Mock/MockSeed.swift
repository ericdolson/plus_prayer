import Foundation
import PlusPrayerDomain

/// Seed data for the mock backend, matching the reference screenshots
/// (docs/product/reference/home-default-dark.png): a user a week into the
/// reverse trial, a 6-day streak that last counted yesterday, List 52 sealed
/// and current, not yet prayed with today. Dates are relative to `now`, so
/// "held today" and "Answered · Oct 19" read naturally whenever it runs.
/// Names are illustrative.
struct MockSeed {
    var subjects: [Subject]
    var header: UserHeader
    var list: CurrentList
    var myStatus: MyListStatus
    var stats: LiveStats

    static func standard(now: Date, calendar: Calendar = .current) -> MockSeed {
        let today = LocalDate(now, calendar: calendar)
        func daysAgo(_ n: Int) -> LocalDate { today.adding(days: -n) }
        func created(_ n: Int) -> Date { now.addingTimeInterval(-Double(n) * 86_400) }

        // Short mock ids collide in the tone hash (real ids are UUIDs), so
        // tones are set as if the user picked them: the screenshots' mix.
        func name(_ id: String, _ publicName: String, alias: String? = nil, order: Int, tone: Int,
                  carried: Bool = true, isSelf: Bool = false, prayed: Int? = nil, createdAgo: Int) -> Subject {
            Subject(id: id, kind: .soul, publicName: publicName, alias: alias, isSelf: isSelf, isCarried: carried,
                    sortOrder: order, avatarTone: tone, createdAt: created(createdAgo), lastPrayed: prayed.map(daysAgo))
        }
        func intention(_ id: String, _ parent: String, _ text: String, order: Int, carried: Bool = true,
                       prayed: Int? = nil, answeredAgo: Int? = nil, createdAgo: Int) -> Subject {
            Subject(id: id, kind: .intention, parentId: parent, publicName: text, isCarried: carried,
                    sortOrder: order, resolution: answeredAgo == nil ? nil : .answered,
                    resolvedAt: answeredAgo.map(created), createdAt: created(createdAgo),
                    lastPrayed: prayed.map(daysAgo))
        }

        let subjects = [
            name("self", "Eric Olson", alias: "Me", order: 0, tone: 7, isSelf: true, prayed: 1, createdAgo: 52),
            intention("self-1", "self", "Patience with the new job", order: 1, prayed: 3, createdAgo: 35),
            name("dad", "Gary Olson", alias: "Dad", order: 1, tone: 0, prayed: 0, createdAgo: 45),
            intention("dad-1", "dad", "Healing after his surgery", order: 1, prayed: 0, createdAgo: 40),
            intention("dad-2", "dad", "Rest for his heart", order: 2, carried: false, prayed: 4, createdAgo: 25),
            name("mom", "Margaret Olson", alias: "Mom", order: 2, tone: 8, prayed: 2, createdAgo: 40),
            intention("mom-1", "mom", "A safe delivery for Ruth", order: 1, prayed: 2, answeredAgo: 17, createdAgo: 39),
            name("daniel", "Daniel Kim", order: 3, tone: 10, prayed: 8, createdAgo: 30),
            name("parish", "Our parish", order: 4, tone: 13, createdAgo: 15),
            name("ukraine", "Ukraine", order: 5, tone: 14, prayed: 0, createdAgo: 2),
            name("bea", "Beatrice Moreno", alias: "Aunt Bea", order: 6, tone: 6, carried: false, prayed: 1, createdAgo: 25),
        ]

        let header = UserHeader(id: "mock-user", displayName: "Eric Olson", selfSubjectId: "self",
                                currentStreak: 6, bestStreak: 11, lastListLocalDate: daysAgo(1), graceDays: 1,
                                includeLimit: 10, trialStartedAt: created(5),
                                entitlementExpiresAt: now.addingTimeInterval(9 * 86_400))

        let list = CurrentList(id: "list-52", listNumber: 52, listDate: today, isPublished: true,
                               soulCount: 4345, intentionCount: 1212, prayerCount: 3880,
                               currentFrom: now.addingTimeInterval(-3 * 3600),
                               sealVariant: today.weekdayFromSunday)

        // Prayed with List 51 yesterday, so these were printed on List 52.
        let tree = SubjectTree(subjects)
        let printed = carriedNames(tree).flatMap { name in
            [name] + tree.intentions(of: name.id).filter { isEffectivelyCarried($0, in: tree) }
        }
        let myStatus = MyListStatus(listId: list.id, entries: printed.map {
            ListEntry(subjectId: $0.id, publicName: $0.publicName, isName: $0.isName, isSelf: $0.isSelf)
        })

        return MockSeed(subjects: subjects, header: header, list: list, myStatus: myStatus,
                        stats: LiveStats(prayingNow: 213, prayedLastHour: 640, prayedToday: 4113))
    }
}
