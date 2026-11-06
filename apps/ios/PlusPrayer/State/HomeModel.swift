import Foundation
import Observation
import PlusPrayerDomain

/// Home's view state (screens.md, design-direction §3–§6): the rows under the
/// filter, the filter's counts, the header, and the community card. Watches
/// the repositories (`run()`, from the view's `.task`), folds in prayers
/// still on the device, and derives everything through PlusPrayerDomain.
///
/// Linger then fold (design-direction §4): under Still to hold, what a prayer
/// just held stays `PP.duration.linger` after Amen with its gold, then leaves
/// (the view animates the fold). The card does the same when the list was
/// held.
@MainActor @Observable
final class HomeModel {
    // MARK: Inputs (from the repositories)

    private(set) var subjects: [Subject]?
    private(set) var header: UserHeader?
    private(set) var list: CurrentList?
    private(set) var myStatus: MyListStatus?
    private(set) var stats = LiveStats.empty
    private(set) var config = AppConfig.defaults
    private(set) var localPrayers: [NewPrayer] = []
    /// The local day; the gold and "prayed with the list today" clear when it changes.
    private(set) var today: LocalDate

    var filter: HomeFilter = .all

    /// Ids kept past the filter while they linger (`cardKey` for the card).
    private(set) var lingering: Set<String> = []
    private var lingerBatch: [String: Int] = [:]
    private var batches = 0
    static let cardKey = "community-card"

    private let repositories: Repositories
    private let clock: () -> Date

    init(repositories: Repositories, clock: @escaping () -> Date = Date.init) {
        self.repositories = repositories
        self.clock = clock
        today = LocalDate(clock())
    }

    convenience init(environment: AppEnvironment) {
        self.init(repositories: environment.repositories, clock: environment.clock)
    }

    // MARK: Watching

    /// Consumes every stream Home needs until cancelled (the view's `.task`).
    func run() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.watchSubjects() }
            group.addTask { await self.watchHeader() }
            group.addTask { await self.watchList() }
            group.addTask { await self.watchMyStatus() }
            group.addTask { await self.watchStats() }
            group.addTask { await self.watchConfig() }
            group.addTask { await self.watchLocalPrayers() }
            group.addTask { await self.followTheDay() }
        }
    }

    private func watchSubjects() async {
        for await value in repositories.subjects.subjects() { subjects = value }
    }
    private func watchHeader() async {
        for await value in repositories.user.header() { header = value }
    }
    private func watchList() async {
        for await value in repositories.lists.currentList() { list = value }
    }
    private func watchMyStatus() async {
        for await value in repositories.lists.myStatus() { myStatus = value }
    }
    private func watchStats() async {
        for await value in repositories.live.stats() { stats = value }
    }
    private func watchConfig() async {
        for await value in repositories.live.config() { config = value }
    }
    private func watchLocalPrayers() async {
        for await value in repositories.prayers.localPrayers() { localPrayers = value }
    }

    /// Re-reads the local day (at midnight, and when the app comes back).
    func refreshToday() {
        let now = LocalDate(clock())
        if now != today { today = now }
    }

    private func followTheDay() async {
        while !Task.isCancelled {
            let calendar = Calendar.current
            let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: clock())!)
            try? await Task.sleep(for: .seconds(max(1, midnight.timeIntervalSince(clock()) + 1)))
            refreshToday()
        }
    }

    // MARK: Derived

    /// Subjects with this device's unsent prayers folded in.
    var tree: SubjectTree {
        SubjectTree(subjectsWithLocalPrayers(subjects ?? [], localPrayers))
    }

    var graph: SubjectGraph { tree.graph }

    private var effectiveHeader: UserHeader? {
        header.map { headerWithLocalPrayers($0, localPrayers) }
    }

    var prayedWithListToday: Bool {
        effectiveHeader.map { PlusPrayerDomain.prayedWithListToday($0, today: today) } ?? false
    }

    var isLoaded: Bool { subjects != nil }

    /// The groups under the filter, as the rows show them.
    var groups: [NameGroup] {
        let tree = tree
        return visibleGroups(tree, today: today, filter: filter, keep: lingering).map { group in
            NameGroup(name: item(group.name, tree: tree),
                      intentions: group.intentions.map { item($0, tree: tree) })
        }
    }

    var counts: HomeFilterCounts {
        let tree = tree
        return HomeFilterCounts(all: filterCount(tree, .all, today: today),
                                stillToHold: filterCount(tree, .stillToHold, today: today),
                                carried: filterCount(tree, .carried, today: today))
    }

    /// Under Still to hold with nothing left, the list included.
    var allHeldShown: Bool {
        isLoaded && filter == .stillToHold && groups.isEmpty && !cardShown
    }

    /// Under Carried, when it holds only you: what Carried means.
    var carriedHelperShown: Bool {
        isLoaded && filter == .carried
            && carriedShowsOnlyYou(visibleGroups(tree, today: today, filter: .carried))
    }

    // MARK: Header

    var me: HeaderValues? {
        guard let me = tree.me else { return nil }
        let header = effectiveHeader
        return HeaderValues(initials: monogram(me), tone: me.tone,
                            streakState: header.map { streakBadgeState($0, today: today) } ?? .none,
                            streakDays: header.map { effectiveStreak($0, today: today) } ?? 0)
    }

    // MARK: The community card

    var cardShown: Bool {
        list != nil && communityCardShown(filter: filter, query: "", prayedWithListToday: prayedWithListToday,
                                          lingering: lingering.contains(Self.cardKey))
    }

    var card: CardValues? {
        guard let list else { return nil }
        let tree = tree
        let people = carriedNames(tree).map {
            CarriedPerson(id: $0.id, initials: monogram($0),
                          tone: $0.tone, spokenName: $0.isSelf ? L10n.Card.you : $0.label, isSelf: $0.isSelf)
        }
        return CardValues(
            listNumber: list.listNumber, sealVariant: list.sealVariant,
            people: list.soulCount, prayers: list.prayerCount,
            presence: presenceLine(stats, threshold: config.presenceDisplayThreshold),
            carried: people,
            status: tomorrowStatus(list: list, status: myStatus, local: localPrayers, header: effectiveHeader,
                                   today: today),
            closingMinutes: closingSoonMinutes(closesAt: list.closesAt, now: clock(),
                                               prayedWithListToday: prayedWithListToday),
            heldToday: prayedWithListToday)
    }

    /// The list a prayer started now is for.
    var listContext: ListContext? {
        list.map { ListContext(listId: $0.id, listNumber: $0.listNumber) }
    }

    /// Others praying now, for the prayer bar; nil under the threshold.
    var prayingWith: Int? { othersInPrayer(stats, threshold: config.presenceDisplayThreshold) }

    // MARK: Commands

    /// The committing Amen: the prayer goes to the device first (so the gold
    /// shows at once, offline too); under Still to hold what it held lingers.
    func log(_ prayer: NewPrayer) async {
        if filter == .stillToHold {
            let tree = tree
            var ids = Set(prayer.subjectIds)
            ids.formUnion(prayer.subjectIds.compactMap { tree.parent(of: $0)?.id })
            if prayer.includesList { ids.insert(Self.cardKey) }
            linger(ids)
        }
        await repositories.prayers.logPrayer(prayer)
    }

    private func linger(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        batches += 1
        let batch = batches
        for id in ids { lingerBatch[id] = batch }
        lingering.formUnion(ids)
        Task {
            try? await Task.sleep(for: .seconds(PP.duration.linger))
            // A later prayer that held the same row again keeps it longer.
            let done = ids.filter { lingerBatch[$0] == batch }
            for id in done { lingerBatch[id] = nil }
            lingering.subtract(done)
        }
    }

    // MARK: Row values

    private func item(_ row: HomeRow, tree: SubjectTree) -> RowItem {
        let s = row.subject
        let carried = showsCarriedMark(s, in: tree)
        let secondary: RowItem.Secondary? = switch rowStatus(s) {
        case .answered(let on): .init(text: L10n.Row.answered(on), answered: true)
        case .notCarriedPoolFull(let limit): .init(text: L10n.Row.notCarriedFull(limit), answered: false)
        case nil: nil
        }
        let named = s.label != s.publicName ? "\(s.label), \(s.publicName)" : s.publicName
        return RowItem(id: s.id, label: s.label, initials: monogram(s),
                       tone: s.tone, carried: carried, heldToday: isHeldToday(s, today: today),
                       secondary: secondary, isContext: row.isContext,
                       spoken: [carried ? L10n.Row.carried(named) : named, secondary?.text]
                           .compactMap { $0 }.joined(separator: ". "))
    }
}

// MARK: View values

/// One row's plain values (the row components take these apart).
struct RowItem: Identifiable, Equatable {
    struct Secondary: Equatable {
        let text: String
        /// "Answered · Oct 19" (gold) rather than a muted notice.
        let answered: Bool
    }

    let id: String
    /// The alias if there is one ("Dad", "Me"), else the name.
    let label: String
    let initials: String
    let tone: Int
    let carried: Bool
    /// Prayed for on this local day: the gold ring or dot.
    let heldToday: Bool
    let secondary: Secondary?
    /// A name shown only for an intention under it that passes the filter.
    let isContext: Bool
    /// VoiceOver's sentence, without the held part (`accessibilityLabel(held:)`).
    let spoken: String

    func accessibilityLabel(heldOutsidePrayer: Bool) -> String {
        heldOutsidePrayer ? "\(spoken). \(L10n.Row.heldToday)" : spoken
    }
}

struct NameGroup: Identifiable, Equatable {
    let name: RowItem
    let intentions: [RowItem]
    var id: String { name.id }
}

struct HeaderValues: Equatable {
    let initials: String
    let tone: Int
    let streakState: StreakBadgeState
    let streakDays: Int
}

struct CarriedPerson: Identifiable, Equatable {
    let id: String
    let initials: String
    let tone: Int
    /// What VoiceOver reads ("You" for the self).
    let spokenName: String
    let isSelf: Bool
}

struct CardValues: Equatable {
    let listNumber: Int
    let sealVariant: Int?
    let people: Int
    let prayers: Int
    let presence: PresenceLine?
    /// You first, then your carried names in your order.
    let carried: [CarriedPerson]
    let status: TomorrowStatus
    let closingMinutes: Int?
    /// Prayed with the list today: the card's gold border until local midnight.
    let heldToday: Bool
}
