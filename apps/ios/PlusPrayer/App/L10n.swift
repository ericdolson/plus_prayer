import Foundation
import PlusPrayerDomain

/// Every user-facing string, by key, from `Resources/Localizable.xcstrings`
/// (apps/ios/CLAUDE.md, "Copy and localization"). Views never hold literals.
nonisolated enum L10n {
    enum Home {
        static var history: String { NSLocalizedString("home.bar.history", comment: "") }
        static var search: String { NSLocalizedString("home.bar.search", comment: "") }
        static var add: String { NSLocalizedString("home.bar.add", comment: "") }
        static var pray: String { NSLocalizedString("home.bar.pray", comment: "") }
        static var you: String { NSLocalizedString("home.header.you", comment: "") }
        /// A name row's long-press menu: opens the intention form for them.
        static var addIntention: String { NSLocalizedString("home.row.addIntention", comment: "") }
        static var filter: String { NSLocalizedString("home.filter", comment: "") }
        static var clearFilter: String { NSLocalizedString("home.filter.clear", comment: "") }

        /// "6 days with the world"; 0 → "Days with the world".
        static func streak(_ days: Int) -> String {
            String.localizedStringWithFormat(NSLocalizedString("home.header.streak", comment: ""), days)
        }
    }

    enum Card {
        private static func f(_ key: String, _ args: CVarArg...) -> String {
            String(format: NSLocalizedString(key, comment: ""), locale: .current, arguments: args)
        }
        private static func plural(_ key: String, _ n: Int) -> String {
            String.localizedStringWithFormat(NSLocalizedString(key, comment: ""), n)
        }

        static func title(_ list: Int) -> String { f("card.list.title", list) }
        static func sealed(_ list: Int) -> String { f("card.list.sealed", list) }
        static func beingFilmed(_ list: Int) -> String { f("card.list.beingFilmed", list) }
        static func people(_ n: Int) -> String { plural("card.people", n) }
        static func prayers(_ n: Int) -> String { plural("card.prayers", n) }
        static func prayingNow(_ n: Int) -> String { f("card.presence.now", n) }
        static func prayedLastHour(_ n: Int) -> String { f("card.presence.lastHour", n) }
        static func prayedLastHourSpoken(_ n: Int) -> String { f("card.presence.lastHour.spoken", n) }
        static func prayedToday(_ n: Int) -> String { f("card.presence.today", n) }
        static func overflow(_ n: Int) -> String { f("card.overflow", n) }
        static var you: String { NSLocalizedString("card.you", comment: "") }

        /// The status line under your carried people. `next` = the list they go onto.
        static func status(_ status: TomorrowStatus, next: Int, aboutYouOnly: Bool) -> String {
            switch (status, aboutYouOnly) {
            case (.covered, false): f("card.status.covered", next)
            case (.covered, true): f("card.status.coveredYou", next)
            case (.nextPrayerCarries, false): f("card.status.nextPrayer", next)
            case (.nextPrayerCarries, true): f("card.status.nextPrayerYou", next)
            case (.prayToCarry, false): f("card.status.prayToCarry", next)
            case (.prayToCarry, true): f("card.status.prayToBe", next)
            }
        }

        /// Replaces the status line near the cutoff.
        static func closesSoon(list: Int, minutes: Int, next: Int, aboutYouOnly: Bool) -> String {
            aboutYouOnly ? f("card.closesSoonYou", list, minutes, next) : f("card.closesSoon", list, minutes)
        }
    }

    enum Prayer {
        static var amen: String { NSLocalizedString("prayer.amen", comment: "") }
        static var cancel: String { NSLocalizedString("prayer.cancel", comment: "") }
        static var discardQuestion: String { NSLocalizedString("prayer.discardQuestion", comment: "") }
        static var discard: String { NSLocalizedString("prayer.discard", comment: "") }
        static var keepPraying: String { NSLocalizedString("prayer.keepPraying", comment: "") }
        static func with(_ n: Int) -> String {
            String(format: NSLocalizedString("prayer.with", comment: ""), locale: .current, n)
        }
        static func withSpoken(_ n: Int) -> String {
            String.localizedStringWithFormat(NSLocalizedString("prayer.withSpoken", comment: ""), n)
        }
        static func time(_ elapsed: String) -> String {
            String(format: NSLocalizedString("prayer.time", comment: ""), elapsed)
        }
    }

    enum Cluster {
        static func two(_ a: String, _ b: String) -> String {
            String(format: NSLocalizedString("cluster.two", comment: ""), a, b)
        }
        static func counted(_ a: String, _ b: String, _ n: Int) -> String {
            String(format: NSLocalizedString("cluster.counted", comment: ""), locale: .current, a, b, n)
        }
        static func andOthers(_ a: String, _ b: String) -> String {
            String(format: NSLocalizedString("cluster.andOthers", comment: ""), a, b)
        }
        static func sentence(_ names: String, _ trailing: String) -> String {
            String(format: NSLocalizedString("cluster.sentence", comment: ""), names, trailing)
        }
    }

    enum Invitation {
        private static func f(_ key: String, _ args: CVarArg...) -> String {
            String(format: NSLocalizedString(key, comment: ""), locale: .current, arguments: args)
        }
        /// "will be on List 53": `next` is the list they go onto.
        static func willBe(_ next: Int) -> String { f("invitation.willBe", next) }
        static func hold(people: Int, list: Int) -> String { f("invitation.hold", people, list) }
        static func holding(people: Int, list: Int) -> String { f("invitation.holding", people, list) }
    }

    enum Closing {
        static func carried(_ next: Int) -> String {
            String(format: NSLocalizedString("closing.carried", comment: ""), locale: .current, next)
        }
        /// "Add to journal" (history.md "Words"; schema keeps `note`).
        static var addToJournal: String { NSLocalizedString("closing.addToJournal", comment: "") }
        static var noteHint: String { NSLocalizedString("closing.noteHint", comment: "") }
    }

    enum Search {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }
        static var placeholder: String { L10n.Home.search }
        static var close: String { t("search.close") }
        static var add: String { t("search.add") }
        static var show: String { t("search.show") }
        /// "No matches for “Robe”": callers split it around the query so only
        /// the query truncates.
        static func noMatches(_ query: String) -> String { String(format: t("search.noMatches"), query) }
        static func matchesInAll(_ n: Int) -> String {
            String.localizedStringWithFormat(t("search.matchesInAll"), n)
        }
        static func showSpoken(_ n: Int) -> String {
            String.localizedStringWithFormat(t("search.showSpoken"), n)
        }
    }

    enum Add {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }
        static var tabName: String { t("add.tab.name") }
        static var tabIntention: String { t("add.tab.intention") }
        static var nameLabel: String { t("add.name.label") }
        static var namePlaceholder: String { t("add.name.placeholder") }
        static var aliasLabel: String { t("add.alias.label") }
        static var aliasPlaceholder: String { t("add.alias.placeholder") }
        static var aliasCaption: String { t("add.alias.caption") }
        static var intentionLabel: String { t("add.intention.label") }
        static var intentionPlaceholder: String { t("add.intention.placeholder") }
        static var forLabel: String { t("add.for") }
        static var change: String { t("add.for.change") }
        static var whoIsThisFor: String { t("add.for.title") }
        static func noMatches(_ query: String) -> String { String(format: t("add.for.noMatches"), query) }
        static var add: String { t("add.add") }
        static var cancel: String { t("add.cancel") }
        static var contactError: String { t("add.error.contact") }
        static var offline: String { t("add.offline") }
        static var failed: String { t("add.failed") }
        static var carryTitle: String { t("add.carry.title") }
        static var makeRoomHint: String { t("add.carry.makeRoom.hint") }
        static var notCarried: String { t("add.carry.notCarried") }

        /// "Print with Dad ✱" (Q32): an intention's carry toggle; under Me,
        /// "Print with your name".
        static func printWith(_ name: String, isSelf: Bool) -> String {
            isSelf ? t("add.carry.printWith.self") : String(format: t("add.carry.printWith"), name)
        }
        /// "Instead of “Healing after his surgery”": on is a swap.
        static func insteadOf(_ chosen: String) -> String { String(format: t("add.carry.insteadOf"), chosen) }
        /// "Also carries Dad · 3 places left": on also carries the person.
        static func alsoCarries(_ name: String, left: Int) -> String {
            String.localizedStringWithFormat(t("add.carry.alsoCarries"), name, left)
        }
        static func counter(_ count: Int, _ cap: Int) -> String {
            String(format: t("add.counter"), locale: .current, count, cap)
        }
        static func capReached(_ cap: Int) -> String {
            String(format: t("add.capReached"), locale: .current, cap)
        }
    }

    /// A name's or an intention's page (detail-page.md).
    enum Page {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }
        private static func f(_ key: String, _ args: CVarArg...) -> String {
            String(format: t(key), locale: .current, arguments: args)
        }
        enum Subject {
            case person(String)
            case me
            case intention
        }

        /// The carry card's footer (detail-page.md "Status line", 2026-11-08).
        static func status(_ status: CarryStatus, about subject: Subject, person: String = "") -> String {
            switch (status, subject) {
            case (.privateOnly, _): t("page.status.private")
            case (.privateWhilePersonOff, _): f("page.status.privateWhileOff", person)
            case (.closing(let list, let minutes, _), .person(let name)): f("page.closesSoon", list, minutes, name)
            case (.closing(let list, let minutes, let next), .me): f("page.closesSoon.self", list, minutes, next)
            case (.closing(let list, let minutes, _), .intention): f("page.closesSoon.intention", list, minutes)
            case (.list(let tomorrow, let next), .person(let name)): f(listKey(tomorrow, "page.status"), name, next)
            case (.list(let tomorrow, let next), .me): f(listKey(tomorrow, "page.status.self"), next)
            case (.list(let tomorrow, let next), .intention): f(listKey(tomorrow, "page.status.intention"), next)
            }
        }

        private static func listKey(_ tomorrow: TomorrowStatus, _ prefix: String) -> String {
            switch (tomorrow, prefix == "page.status.self") {
            case (.covered, _): "\(prefix).covered"
            case (.nextPrayerCarries, _): "\(prefix).nextPrayer"
            case (.prayToCarry, true): "\(prefix).prayToBe"
            case (.prayToCarry, false): "\(prefix).prayToCarry"
            }
        }
        /// The pray capsule (detail-page.md "Pray button label"): "Pray for
        /// Dad" on a name's page; "Pray" on the self page and an intention's.
        static func pray(for name: String?) -> String {
            name.map { String(format: t("page.pray.for"), $0) } ?? t("page.pray")
        }
        /// Praying in place: the quiet link back to Home, still praying.
        static var prayForOthers: String { t("page.prayForOthers") }
        static var intentions: String { t("page.intentions") }
        static var history: String { t("page.history") }
        static func addIntention(for name: String, isSelf: Bool) -> String {
            isSelf ? t("page.addIntention.self") : String(format: t("page.addIntention.for"), name)
        }
        static func firstIntention(for name: String, isSelf: Bool) -> String {
            isSelf ? t("page.firstIntention.self") : String(format: t("page.firstIntention"), name)
        }
        /// "Make room for Dad": the page's toggle and the add sheet's carry
        /// row when full (inert until Membership / Your portion exist).
        static func makeRoom(for name: String) -> String { String(format: t("page.carry.makeRoom"), name) }
        /// The person toggle's subtitle (one place = one person).
        static func carryMeter(_ meter: NameCarryMeter) -> String {
            switch meter {
            case .left(let left): String.localizedStringWithFormat(t("page.carry.left"), left)
            case .usesLast: t("page.carry.usesLast")
            case .allInUse(1): t("page.carry.allInUse.one")
            case .allInUse(let pool): String.localizedStringWithFormat(t("page.carry.allInUse"), pool)
            case .free: t("page.carry.free")
            }
        }
        /// Under the toggle after it flipped back: the pool filled from
        /// another device.
        static func filledUp(pool: Int) -> String { String.localizedStringWithFormat(t("page.carry.filledUp"), pool) }
        static var carryFailed: String { t("page.carry.failed") }
        static var carryOffline: String { t("page.carry.offline") }

        /// "Prints with": the row's title and the pushed list's.
        static var printsWith: String { t("page.printsWith") }
        static var nameOnly: String { t("page.printsWith.nameOnly") }
        /// The row's value: the chosen intention(s), else "Name only".
        static func printsWithValue(_ chosen: [String]) -> String {
            chosen.isEmpty ? nameOnly : chosen.formatted(.list(type: .and))
        }

    }

    /// History (history.md) and a page's preview (detail-page.md).
    enum History {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }
        private static func plural(_ key: String, _ n: Int) -> String { String.localizedStringWithFormat(t(key), n) }
        private static func join(_ parts: [String]) -> String {
            parts.dropFirst().reduce(parts.first ?? "") { String(format: t("history.summary"), $0, $1) }
        }

        static var title: String { t("history.title") }
        static var tabsLabel: String { t("history.tabs.label") }
        static var tabAll: String { t("history.tab.all") }
        static var tabHeld: String { t("history.tab.held") }
        static var tabLists: String { t("history.tab.lists") }
        static var tabJournal: String { t("history.tab.journal") }
        static var tabAnswered: String { t("history.tab.answered") }
        static var people: String { t("history.people.title") }
        static var seeAll: String { t("history.seeAll") }
        static var today: String { t("history.today") }
        static var yesterday: String { t("history.yesterday") }
        static var noActivity: String { t("history.gap.spoken") }
        static var journalEntry: String { t("history.journalEntry") }
        /// A tab with nothing in it (history.md "Empty tabs"); Answered has none.
        static var emptyHeld: String { t("history.empty.held") }
        static var emptyLists: String { t("history.empty.lists") }
        static var emptyJournal: String { t("history.empty.journal") }

        /// "You prayed once" / "You prayed 6 times".
        static func prayed(_ n: Int) -> String { plural("history.prayed", n) }
        /// "On 9 lists".
        static func lists(_ n: Int) -> String { plural("history.lists", n) }
        /// "You prayed 12 times · On 30 lists"; either half left out at 0.
        static func prayedAndLists(prayers: Int, lists: Int) -> String? {
            let parts = [prayers > 0 ? prayed(prayers) : nil, lists > 0 ? self.lists(lists) : nil].compactMap { $0 }
            return parts.isEmpty ? nil : join(parts)
        }
        /// An older period's right column: "2 prayers · 6 lists · ✎ 1".
        static func periodSummary(_ s: PeriodSummary) -> String {
            join([s.prayers > 0 ? plural("history.row.prayers", s.prayers) : nil,
                  s.lists > 0 ? plural("history.row.lists", s.lists) : nil,
                  s.notes > 0 ? String(format: t("history.notes"), locale: .current, s.notes) : nil].compactMap { $0 })
        }
        static func periodSummarySpoken(_ s: PeriodSummary) -> String {
            join([s.prayers > 0 ? plural("history.row.prayers", s.prayers) : nil,
                  s.lists > 0 ? plural("history.row.lists", s.lists) : nil,
                  s.notes > 0 ? plural("history.notes.spoken", s.notes) : nil].compactMap { $0 })
        }
        /// "6 days with the world" (the badge's own words).
        static func streak(_ days: Int) -> String { L10n.Home.streak(days) }
        /// "Time in prayer · 2h 14m this week · 61h 5m all time".
        static func time(_ time: PrayerTime) -> String {
            String(format: t("history.time"), duration(time.thisWeek), duration(time.allTime))
        }
        private static func duration(_ seconds: Int) -> String {
            Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
        }
        /// "Begun · Sep 12" this year; "Begun · Sep 12, 2025" before.
        static func begun(_ date: LocalDate, today: LocalDate) -> String {
            String(format: t("history.begun"), shortDate(date, today: today))
        }
        /// "Nov 3"; with the year before this year.
        static func shortDate(_ date: LocalDate, today: LocalDate) -> String {
            let day = date.start()
            return date.year == today.year
                ? day.formatted(.dateTime.month(.abbreviated).day())
                : day.formatted(.dateTime.month(.abbreviated).day().year())
        }
        /// "November" this year; "December 2025" otherwise; a year row "2025".
        static func period(_ period: HistoryPeriod, today: LocalDate) -> String {
            switch period {
            case .year(let year): String(year)
            case .month(let year, let month): monthName(year: year, month: month, withYear: year != today.year)
            }
        }
        static func monthName(year: Int, month: Int, withYear: Bool) -> String {
            let day = LocalDate(year: year, month: month, day: 1).start()
            return withYear ? day.formatted(.dateTime.month(.wide).year()) : day.formatted(.dateTime.month(.wide))
        }
        /// The month tab: "Nov".
        static func monthTab(year: Int, month: Int) -> String {
            LocalDate(year: year, month: month, day: 1).start().formatted(.dateTime.month(.abbreviated))
        }
        /// Day headings: "Today", "Yesterday", "Thursday, Nov 5" (with the
        /// year before this year).
        static func dayHeading(_ date: LocalDate, today: LocalDate) -> String {
            if date == today { return self.today }
            if date == today.adding(days: -1) { return yesterday }
            let day = date.start()
            return date.year == today.year
                ? day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
                : day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
        }
        /// The day sheet's title: "Thursday, November 5".
        static func longDate(_ date: LocalDate, today: LocalDate) -> String {
            let day = date.start()
            return date.year == today.year
                ? day.formatted(.dateTime.weekday(.wide).month(.wide).day())
                : day.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        }
        /// A node, for VoiceOver: "Thursday, November 5. On List 49. You
        /// prayed. Journal entry."
        static func node(_ node: StrandNode, lists: [Int], today: LocalDate) -> String {
            var parts = [String(format: t("history.spoken.sentence"), longDate(node.date, today: today))]
            if node.isToday { parts.insert(String(format: t("history.spoken.sentence"), self.today), at: 0) }
            parts += lists.map { String(format: t("history.node.onList"), locale: .current, $0) }
            if node.prayed { parts.append(t("history.node.prayed")) }
            if node.journal { parts.append(t("history.node.journal")) }
            if node.answered { parts.append(t("history.node.answered")) }
            return parts.joined(separator: " ")
        }
        /// "On List 46 · 3,475 prayers".
        static func onList(_ list: Int, prayers: Int) -> String {
            String.localizedStringWithFormat(t("history.day.onList"), list, prayers)
        }
        /// "Answered · Healing after his surgery".
        static func answered(_ text: String) -> String { String(format: t("history.day.answered"), text) }
        /// "Answered Nov 3".
        static func answeredOn(_ date: LocalDate, today: LocalDate) -> String {
            String(format: t("history.answered.on"), shortDate(date, today: today))
        }
        /// "7:42 AM · 12 min"; auto-saved "~38 min".
        static func prayerLine(startedAt: Date, seconds: Int, autoSaved: Bool) -> String {
            let minutes = max(1, Int((Double(seconds) / 60).rounded()))
            let length = String(format: t(autoSaved ? "history.prayer.lengthAuto" : "history.prayer.length"),
                                locale: .current, minutes)
            return join([startedAt.formatted(date: .omitted, time: .shortened), length])
        }
        /// The Lists tab: "Sat, Nov 7".
        static func listDate(_ date: LocalDate, today: LocalDate) -> String {
            let day = date.start()
            return date.year == today.year
                ? day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
                : day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
        }
        static func listTitle(_ number: Int) -> String { L10n.Card.title(number) }
        static func listPrayers(_ n: Int) -> String { L10n.Card.prayers(n) }

        // Tiles: the number, then its words.
        // (Separate keys for one and other: the words don't hold the number.)
        static func tilePrayers(_ n: Int) -> String { t(n == 1 ? "history.tile.prayers.one" : "history.tile.prayers.other") }
        static func tileLists(_ n: Int) -> String { t(n == 1 ? "history.tile.lists.one" : "history.tile.lists.other") }
        static var tileJournal: String { t("history.tile.journal") }
        static var tileAnswered: String { t("history.tile.answered") }
    }

    enum Common {
        static var save: String { NSLocalizedString("common.save", comment: "") }
        static var done: String { NSLocalizedString("common.done", comment: "") }
    }

    enum Row {
        /// "Answered · Oct 19"
        static func answered(_ date: Date) -> String {
            String(format: NSLocalizedString("row.status.answered", comment: ""),
                   date.formatted(.dateTime.month(.abbreviated).day()))
        }
        static func carried(_ name: String) -> String {
            String(format: NSLocalizedString("row.carried", comment: ""), name)
        }
        static var heldToday: String { NSLocalizedString("row.heldToday", comment: "") }
        static var held: String { NSLocalizedString("row.check.held", comment: "") }
        static var partial: String { NSLocalizedString("row.check.partial", comment: "") }
        static var notHeld: String { NSLocalizedString("row.check.none", comment: "") }
    }

    enum Filter {
        static var all: String { NSLocalizedString("home.filter.all", comment: "") }
        static var stillToHold: String { NSLocalizedString("home.filter.stillToHold", comment: "") }
        static var carried: String { NSLocalizedString("home.filter.carried", comment: "") }
        static var allHeld: String { NSLocalizedString("home.filter.allHeld", comment: "") }
        static var carriedMeaning: String { NSLocalizedString("home.carried.meaning", comment: "") }
        static var carriedKeep: String { NSLocalizedString("home.carried.keep", comment: "") }

        /// "Still to hold · 3". Callers never pass 0 (the count is dropped).
        static func withCount(_ label: String, _ count: Int) -> String {
            String.localizedStringWithFormat(NSLocalizedString("home.filter.withCount", comment: ""), label, count)
        }
    }
}
