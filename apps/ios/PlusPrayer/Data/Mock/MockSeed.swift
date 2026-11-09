import Foundation
import PlusPrayerDomain

/// Seed data for the mock backend, matching the reference screenshots
/// (docs/product/reference/home-default-dark.png): a user a week into the
/// reverse trial, a 6-day streak that last counted yesterday, List 52 sealed
/// and current, not yet prayed with today. Dates are relative to `now`, so
/// "held today" and "Answered · Oct 19" read naturally whenever it runs.
/// Names and journal entries are illustrative. History (`MockHistory`) has
/// every state: Dad carried with near-daily lists, prayers and entries; Aunt
/// Bea private, with prayer days and gaps; Mom's answered intention; Lena
/// added today.
struct MockSeed {
    var subjects: [Subject]
    var header: UserHeader
    var list: CurrentList
    var myStatus: MyListStatus
    var stats: LiveStats
    var history: HistoryLog

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
            // Added today: nothing yet but today.
            name("lena", "Lena Park", order: 7, tone: 3, carried: false, createdAgo: 0),
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
                        stats: LiveStats(prayingNow: 213, prayedLastHour: 640, prayedToday: 4113),
                        history: MockHistory.seeded(subjects, today: today, now: now, currentList: list, calendar: calendar))
    }

    /// A first run (launch argument `-PPMockFresh`): an account with no self
    /// name and no people, never prayed (pre-trial), so onboarding opens.
    /// The list and live counts are the standard seed's.
    static func fresh(now: Date, calendar: Calendar = .current) -> MockSeed {
        let standard = standard(now: now, calendar: calendar)
        return MockSeed(subjects: [], header: UserHeader(id: "mock-user"), list: standard.list,
                        myStatus: MyListStatus(listId: standard.list.id), stats: standard.stats,
                        history: HistoryLog())
    }
}

/// The History log in the mock (getMyPrayerHistory + your subjects' list
/// entries), seeded with a believable past, then grown by every prayer the
/// backend takes and every flip. List N's date is N days before today's
/// List 52. Deterministic: a small hash of a key and the day decides.
enum MockHistory {
    /// Illustrative journal entries (user content, not product copy).
    static let journal = [
        "Dad sounded stronger on the phone tonight.",
        "A quiet morning. Thought of Mom most of the time.",
        "Hard to focus today. Stayed anyway.",
        "Daniel starts treatment next week.",
        "Prayed on the walk to work.",
    ]
    /// The day Mom's intention was answered gets its own entry.
    static let answeredEntry = "Ruth's baby is here. Both well."

    static func seeded(_ subjects: [Subject], today: LocalDate, now: Date, currentList: CurrentList,
                       calendar: Calendar = .current) -> HistoryLog {
        let tree = SubjectTree(subjects)
        func roll(_ key: String, _ day: Int, _ mod: Int = 7) -> Int {
            (key.unicodeScalars.reduce(day &* 31) { ($0 &* 33 &+ Int($1.value)) & 0x7fff_ffff }) % mod
        }
        func age(_ s: Subject) -> Int { today.days(since: LocalDate(s.createdAt, calendar: calendar)) }
        func prayedAgo(_ s: Subject) -> Int? { s.lastPrayed.map { today.days(since: $0) } }
        func answeredAgo(_ s: Subject) -> Int? {
            s.resolution == .answered ? s.resolvedAt.map { today.days(since: LocalDate($0, calendar: calendar)) } : nil
        }
        let span = tree.me.map(age) ?? 0
        var log = HistoryLog()

        // Lists: you were on most (a few missed; the last week unbroken, as
        // the streak says), and so was everything you carried then. An
        // answered intention printed until it was answered.
        func printed(_ s: Subject, back: Int) -> Bool {
            guard age(s) > back else { return false }
            if s.isSelf { return true }
            if s.isName { return s.isCarried }
            guard s.isCarried, let parent = tree.parent(of: s.id), parent.isSelf || parent.isCarried else { return false }
            return answeredAgo(s).map { back > $0 } ?? (s.resolution == nil)
        }
        for back in stride(from: span - 1, through: 0, by: -1) where back <= 7 || roll("list", back) != 0 {
            let date = today.adding(days: -back)
            let number = currentList.listNumber - back
            let record = back == 0
                ? ListRecord(listId: currentList.id, listNumber: number, listDate: currentList.listDate,
                             prayerCount: currentList.prayerCount, sealVariant: currentList.sealVariant)
                : ListRecord(listId: "list-\(number)", listNumber: number, listDate: date,
                             prayerCount: 3000 + (number * 37) % 900, sealVariant: date.weekdayFromSunday)
            for subject in subjects where printed(subject, back: back) {
                log.entries.append(LoggedEntry(subjectId: subject.id, list: record))
            }
        }

        // Prayers: most days one (some days two) holding several people.
        // Nobody is held after their `lastPrayed` and everyone is held on it,
        // so Home's gold matches. Dad nearly every day; Aunt Bea now and then.
        func rolled(_ s: Subject, _ back: Int) -> Bool {
            let r = roll(s.id, back)
            switch s.id {
            case "dad": return r != 0
            case "bea": return r == 2 || r == 5
            default: return s.isName ? [1, 2, 4].contains(r) : [1, 4].contains(r)
            }
        }
        for back in stride(from: span, through: 0, by: -1) {
            let date = today.adding(days: -back)
            let eligible = subjects.filter { s in
                guard let last = prayedAgo(s), age(s) >= back else { return false }
                return back >= last
            }
            let must = eligible.filter { prayedAgo($0) == back }
            if must.isEmpty && roll("you", back) == 3 { continue } // a day off
            var held = Set(must.map(\.id) + eligible.filter { rolled($0, back) }.map(\.id))
            let answeredThatDay = subjects.first { answeredAgo($0) == back }
            if let answeredThatDay { held.insert(answeredThatDay.id) }
            held.formUnion(held.compactMap { tree.parent(of: $0)?.id })
            guard !held.isEmpty else { continue }

            // Some days split into a morning and an evening prayer, by person.
            let people = tree.names.filter { held.contains($0.id) }
            let parts: [[Subject]] = people.count >= 4 && roll("split", back, 3) == 1
                ? [Array(people.prefix(people.count / 2)), Array(people.dropFirst(people.count / 2))]
                : [people]
            for (index, part) in parts.enumerated() {
                let ids = Set(part.flatMap { [$0.id] + tree.intentions(of: $0.id).map(\.id) }).intersection(held)
                let hour = index == 0 && parts.count == 1 ? (roll("am", back, 2) == 0 ? 7 : 21) : (index == 0 ? 7 : 21)
                let minute = (roll("min", back, 12) * 5)
                var start = date.start(in: calendar).addingTimeInterval(Double(hour * 3600 + minute * 60))
                // Today's prayer was earlier today, not later.
                if back == 0 { start = max(date.start(in: calendar), min(start, now.addingTimeInterval(-3600))) }
                let autoSaved = back == 9 && index == 0
                let note: String? = if answeredThatDay != nil && index == parts.count - 1 {
                    answeredEntry
                } else if roll("note", back * 2 + index, 5) == 2 {
                    journal[(back + index) % journal.count]
                } else {
                    nil
                }
                log.prayers.append(LoggedPrayer(
                    id: "seed-\(back)-\(index)", startedAt: start, localDate: date,
                    durationSeconds: autoSaved ? 38 * 60 : (4 + roll("len", back + index, 20)) * 60,
                    autoSaved: autoSaved, note: note, held: ids))
            }
        }
        return log
    }
}
