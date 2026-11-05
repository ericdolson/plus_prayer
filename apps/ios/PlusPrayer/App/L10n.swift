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

    enum Row {
        static var held: String { NSLocalizedString("row.check.held", comment: "") }
        static var partial: String { NSLocalizedString("row.check.partial", comment: "") }
        static var notHeld: String { NSLocalizedString("row.check.none", comment: "") }
    }

    enum Filter {
        static var all: String { NSLocalizedString("home.filter.all", comment: "") }
        static var stillToHold: String { NSLocalizedString("home.filter.stillToHold", comment: "") }
        static var carried: String { NSLocalizedString("home.filter.carried", comment: "") }
        static var allHeld: String { NSLocalizedString("home.filter.allHeld", comment: "") }

        /// "Still to hold · 3". Callers never pass 0 (the count is dropped).
        static func withCount(_ label: String, _ count: Int) -> String {
            String.localizedStringWithFormat(NSLocalizedString("home.filter.withCount", comment: ""), label, count)
        }
    }
}
