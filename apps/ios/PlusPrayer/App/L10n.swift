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
        static var makeRoomForIntention: String { t("add.carry.makeRoom.intention") }
        static var makeRoomHint: String { t("add.carry.makeRoom.hint") }
        static var notCarried: String { t("add.carry.notCarried") }
        // Everything with a `{unit}` goes through these, keyed by the unit
        // (open-questions Q32): "places" today.

        /// "Also carries Dad · uses 2 places"; "Also carries Dad" when the
        /// meter already says it takes the last places (cost nil).
        static func alsoCarries(_ name: String, cost: Int?, unit: PoolUnit = poolUnit) -> String {
            guard let cost else { return String(format: t("add.carry.alsoCarries"), name) }
            let key = switch unit {
            case .places: "add.carry.alsoCarries.places"
            }
            return String.localizedStringWithFormat(t(key), name, cost)
        }

        /// The carry row's meter: "3 places left", "This uses your last
        /// place" / "… last 2 places", "All 10 places in use", or the free
        /// pool's line.
        static func carryMeter(_ meter: CarryMeter, unit: PoolUnit = poolUnit) -> String {
            switch (meter, unit) {
            case (.left(let left), .places):
                String.localizedStringWithFormat(t("add.carry.left.places"), left)
            case (.usesLast(let left), .places):
                String.localizedStringWithFormat(t("add.carry.usesLast.places"), left)
            case (.allInUse(1), .places):
                t("add.carry.allInUse.one")
            case (.allInUse(let pool), .places):
                String.localizedStringWithFormat(t("add.carry.allInUse.places"), pool)
            case (.freeYouAndOneIntention, _):
                t("add.carry.freeNote")
            }
        }
        static func counter(_ count: Int, _ cap: Int) -> String {
            String(format: t("add.counter"), locale: .current, count, cap)
        }
        static func capReached(_ cap: Int) -> String {
            String(format: t("add.capReached"), locale: .current, cap)
        }
    }

    /// A name's page (detail-page.md).
    enum Page {
        private static func t(_ key: String) -> String { NSLocalizedString(key, comment: "") }

        /// The status line under the title; the self's reads as the card's
        /// own ("You'll be on List 53").
        static func status(_ status: PersonPageValues.Status, name: String, isSelf: Bool) -> String {
            switch status {
            case .notOnList:
                return t("page.status.notOnList")
            case .closing(let list, let minutes, let next):
                return isSelf ? Card.closesSoon(list: list, minutes: minutes, next: next, aboutYouOnly: true)
                    : String(format: t("page.closesSoon"), locale: .current, list, minutes, name)
            case .list(let tomorrow, let next):
                if isSelf { return Card.status(tomorrow, next: next, aboutYouOnly: true) }
                let key = switch tomorrow {
                case .covered: "page.status.covered"
                case .nextPrayerCarries: "page.status.nextPrayer"
                case .prayToCarry: "page.status.prayToCarry"
                }
                return String(format: t(key), locale: .current, name, next)
            }
        }
        static var intentions: String { t("page.intentions") }
        static func addIntention(for name: String, isSelf: Bool) -> String {
            isSelf ? t("page.addIntention.self") : String(format: t("page.addIntention.for"), name)
        }
        static func firstIntention(for name: String, isSelf: Bool) -> String {
            isSelf ? t("page.firstIntention.self") : String(format: t("page.firstIntention"), name)
        }
        static func makeRoom(for name: String) -> String { String(format: t("page.carry.makeRoom"), name) }
        /// The carry row's subtitle: what this name costs and what's free
        /// overall ("Uses 2 places · 3 left").
        static func carryMeter(_ meter: NameCarryMeter, unit: PoolUnit = poolUnit) -> String {
            switch (meter, unit) {
            case (.uses(let cost, let left), .places):
                String.localizedStringWithFormat(t("page.carry.uses"), cost, left)
            case (.usesNoneLeft(let cost), .places):
                String.localizedStringWithFormat(t("page.carry.usesNoneLeft"), cost)
            case (.wouldUse(let cost, let left), .places):
                String.localizedStringWithFormat(t("page.carry.wouldUse"), cost, left)
            case (.left(let left), _): Add.carryMeter(.left(left), unit: unit)
            case (.usesLast(let left), _): Add.carryMeter(.usesLast(left), unit: unit)
            case (.allInUse(let pool), _): Add.carryMeter(.allInUse(pool: pool), unit: unit)
            case (.freeYouAndOneIntention, _): Add.carryMeter(.freeYouAndOneIntention, unit: unit)
            }
        }
        /// Under the carry row after it flipped back: the pool filled from
        /// another device.
        static func filledUp(pool: Int) -> String { String.localizedStringWithFormat(t("page.carry.filledUp"), pool) }
        static var carryFailed: String { t("page.carry.failed") }
        static var carryOffline: String { t("page.carry.offline") }
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
