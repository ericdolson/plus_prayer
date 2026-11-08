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
        static var addNote: String { NSLocalizedString("closing.addNote", comment: "") }
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

        /// "Held by you · 47 prayers".
        static func heldByYou(_ prayers: Int) -> String {
            String.localizedStringWithFormat(t("page.counts.heldByYou"), prayers)
        }
        /// "Carried by the world · 61,204 prayers · 19 lists".
        static func carriedByWorld(prayers: Int, lists: Int) -> String {
            String.localizedStringWithFormat(t("page.counts.world"), prayers, lists)
        }
    }

    /// The History section (detail-page.md "History (calendar)").
    enum History {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }

        /// "You prayed once" / "You prayed 6 times".
        static func prayed(_ n: Int) -> String { String.localizedStringWithFormat(t("history.prayed"), n) }
        /// "On 9 lists".
        static func lists(_ n: Int) -> String { String.localizedStringWithFormat(t("history.lists"), n) }
        /// "You prayed 6 times · On 9 lists"; either half left out at 0; nil when both are.
        static func summary(_ s: PeriodSummary) -> String? {
            switch (s.prayers, s.lists) {
            case (0, 0): nil
            case (let p, 0): prayed(p)
            case (0, let l): lists(l)
            case (let p, let l): String(format: t("history.summary"), prayed(p), lists(l))
            }
        }
        /// "✎ 2".
        static func notes(_ n: Int) -> String { String(format: t("history.notes"), locale: .current, n) }
        static func notesSpoken(_ n: Int) -> String { String.localizedStringWithFormat(t("history.notes.spoken"), n) }
        static var answered: String { t("history.answered") }
        /// "Begun · Sep 12" this year; "Begun · Sep 12, 2025" before.
        static func begun(_ date: LocalDate, today: LocalDate) -> String {
            let day = date.start()
            let text = date.year == today.year
                ? day.formatted(.dateTime.month(.abbreviated).day())
                : day.formatted(.dateTime.month(.abbreviated).day().year())
            return String(format: t("history.begun"), text)
        }
        /// "November" this year; "December 2025" otherwise; a year row "2025".
        static func period(_ period: HistoryPeriod, today: LocalDate) -> String {
            switch period {
            case .year(let year): String(year)
            case .month(let year, let month):
                monthName(year: year, month: month, withYear: year != today.year)
            }
        }
        static func monthName(year: Int, month: Int, withYear: Bool) -> String {
            let day = LocalDate(year: year, month: month, day: 1).start()
            return withYear ? day.formatted(.dateTime.month(.wide).year()) : day.formatted(.dateTime.month(.wide))
        }
        /// A grid as one VoiceOver element: "November. On 9 lists. You
        /// prayed 6 times."
        static func gridSpoken(month: String, _ s: PeriodSummary) -> String {
            let parts = [s.lists > 0 ? lists(s.lists) : nil, s.prayers > 0 ? prayed(s.prayers) : nil].compactMap { $0 }
            return ([month] + parts).map { String(format: t("history.spoken.sentence"), $0) }.joined(separator: " ")
        }
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
