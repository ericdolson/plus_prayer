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
    private(set) var isOnline = true
    /// The local day; the gold and "prayed with the list today" clear when it changes.
    private(set) var today: LocalDate

    var filter: HomeFilter = .all

    /// Search (design-direction §4): the field docked above the keyboard is
    /// open, and what's typed in it. Both persist across nav and prayer.
    private(set) var isSearching = false
    var query = ""

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
            group.addTask { await self.watchNetwork() }
            group.addTask { await self.watchHistory() }
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
    private func watchNetwork() async {
        for await value in repositories.network.online() { isOnline = value }
    }
    private func watchHistory() async {
        for await value in repositories.subjects.history() { historyLog = value }
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
        return visibleGroups(tree, today: today, query: query, filter: filter, keep: lingering).map { group in
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
        isLoaded && !hasQuery && filter == .stillToHold && groups.isEmpty && !cardShown
    }

    /// Search has text: results only (no card, no empty states of the filter).
    var hasQuery: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Search found nothing under the filter: "No matches for “Robe”".
    var noMatches: Bool { isLoaded && hasQuery && groups.isEmpty }

    /// With a filter active, how many items the query matches under All
    /// ("1 match in All · Show →"); nil without a filter or nothing to show.
    var matchesHiddenByFilter: Int? {
        guard filter != .all, hasQuery else { return nil }
        let count = matchesInAll(tree, query: query, today: today)
        return count > 0 ? count : nil
    }

    /// Under Carried, when it holds only you: what Carried means.
    var carriedHelperShown: Bool {
        isLoaded && !hasQuery && filter == .carried
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
        list != nil && communityCardShown(filter: filter, query: query, prayedWithListToday: prayedWithListToday,
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

    // MARK: Search

    func openSearch() { isSearching = true }

    /// The row's ×: clears the query and closes the row.
    func closeSearch() {
        query = ""
        isSearching = false
    }

    /// "Show →" under no matches: back to All, the query kept.
    func showAllMatches() { filter = .all }

    /// The closing sheet's note (private; note-only edits). Queued after its
    /// prayer, so it never overtakes it.
    func saveNote(_ text: String, prayerId: String) async {
        guard let note = cleanNote(text) else { return }
        await repositories.prayers.updateNote(prayerId: prayerId, note: note)
    }

    /// The addSubject callable (online only). The add sheet's carry row
    /// already said whether it's carried.
    func addSubject(_ input: NewSubject) async throws -> AddedSubject {
        try await repositories.subjects.addSubject(input)
    }

    /// A new name's tone (design-direction §1b): one of the least used among
    /// the avatars on Home, Me included, by the tone you see. Picked when the
    /// add sheet opens; nothing is kept if it's cancelled.
    func toneForNewName() -> Int {
        var generator = SystemRandomNumberGenerator()
        return pickTone(tree.names.map(\.tone), using: &generator)
    }

    /// "Who is this for?": your names in Home order, Me first, matching the
    /// query on name + alias as Home search does (everyone when it's empty).
    func pickerNames(matching query: String = "") -> [PickerName] {
        tree.names.filter { matchesQuery($0, query) }
            .map { PickerName(id: $0.id, label: $0.label, initials: monogram($0), tone: $0.tone) }
    }

    /// "Print with {alias} ✱" (Q32): the add sheet's carry row for a new
    /// intention under `personId` (`intentionId` nil), or an intention's page.
    func intentionCarryOffer(personId: String, intentionId: String? = nil) -> IntentionCarryOffer {
        let user = header ?? UserHeader(id: "")
        return PlusPrayerDomain.intentionCarryOffer(personId: personId, intentionId: intentionId, in: tree, user: user,
                                                    now: clock(), cap: config.intentionsPerPerson)
    }

    // MARK: A name's page (detail-page.md)

    /// What a name's page shows, from the same rules as Home; nil until the
    /// name is here (a name just added arrives with the next stream value).
    func page(_ id: String) -> PersonPageValues? {
        let tree = tree
        guard let subject = tree[id], subject.isName else { return nil }
        // Home's rows under All, in Home's order.
        let group = visibleGroups(tree, today: today).first { $0.id == id }
        let intentions = (group?.intentions ?? []).map { item($0, tree: tree) }
        let open = openIntentions(of: id, in: tree)
        let printsWith: [String]? = subject.isSelf || !subject.isCarried || open.isEmpty ? nil
            : chosenIntentions(of: id, in: tree).map(\.publicName)
        return PersonPageValues(
            id: id, initials: monogram(subject), tone: subject.tone, isSelf: subject.isSelf,
            label: subject.label, printedName: subject.label != subject.publicName ? subject.publicName : nil,
            heldToday: isHeldToday(subject, today: today), status: status(of: subject, tree: tree),
            printsWith: printsWith, intentions: intentions)
    }

    /// The carry card's footer (detail-page.md "Status line").
    private func status(of subject: Subject, tree: SubjectTree) -> CarryStatus? {
        carryStatus(subject, in: tree, list: list?.listNumber,
                    tomorrow: list.map { tomorrowStatus(list: $0, status: myStatus, local: localPrayers,
                                                        header: effectiveHeader, today: today) },
                    closingMinutes: list.flatMap { closingSoonMinutes(closesAt: $0.closesAt, now: clock(),
                                                                      prayedWithListToday: prayedWithListToday) })
    }

    /// A name's carry toggle: its flag, and whether turning it on fits.
    func nameCarryOffer(_ id: String) -> CarryOffer {
        guard let header else {
            return CarryOffer(hasRoom: false, startsOn: tree[id]?.isCarried ?? false, used: 0, pool: freeCarryLimit,
                              isFree: true)
        }
        return PlusPrayerDomain.nameCarryOffer(nameId: id, in: tree, user: header, now: clock())
    }

    /// Carries the person `id` or stops carrying them (their chosen
    /// intentions keep their choice) through setCarriedItems: what's carried
    /// now, with this one changed. Throws `SetCarriedError`.
    func setCarried(_ id: String, _ carried: Bool) async throws {
        var ids = carriedIds(tree)
        if carried { ids.insert(id) } else { ids.remove(id) }
        try await repositories.subjects.setCarriedItems(Array(ids))
    }

    /// "Prints with": the person's open intentions with the check on the
    /// chosen ones (Name only when none).
    func printsWithOptions(_ personId: String) -> PrintsWithValues {
        let tree = tree
        let chosen = Set(chosenIntentions(of: personId, in: tree).map(\.id))
        let cap = config.intentionsPerPerson
        return PrintsWithValues(
            cap: cap,
            options: openIntentions(of: personId, in: tree).map {
                PrintsWithValues.Option(id: $0.id, text: $0.publicName, checked: chosen.contains($0.id),
                                        enabled: cap <= 1 || chosen.contains($0.id) || chosen.count < cap)
            })
    }

    /// A tap in "Prints with" (`intentionId` nil = Name only): a swap,
    /// never pool-checked. Throws `SetCarriedError`.
    func setPrintsWith(_ personId: String, _ intentionId: String?) async throws {
        let ids = printsWith(intentionId, for: personId, in: tree, cap: config.intentionsPerPerson)
        try await repositories.subjects.setCarriedItems(Array(ids))
    }

    /// An intention's "Print with {alias} ✱": on chooses it (a swap at the
    /// cap) and carries its person when they aren't; off unchooses it.
    func choose(_ intentionId: String, _ on: Bool) async throws {
        let tree = tree
        let person = tree.parent(of: intentionId)
        let ids = choosing(intentionId, on, in: tree, cap: config.intentionsPerPerson,
                           carryPerson: on && !(person?.isSelf ?? true) && !(person?.isCarried ?? true))
        try await repositories.subjects.setCarriedItems(Array(ids))
    }

    // MARK: An intention's page (detail-page.md "Intention page")

    func intentionPage(_ id: String) -> IntentionPageValues? {
        let tree = tree
        guard let subject = tree[id], subject.isIntention, let person = tree.parent(of: id) else { return nil }
        return IntentionPageValues(
            id: id, text: subject.publicName, personId: person.id, personLabel: person.label,
            personIsSelf: person.isSelf, heldToday: isHeldToday(subject, today: today),
            answered: subject.resolvedAt.map { L10n.Row.answered($0) },
            status: subject.isResolved ? nil : status(of: subject, tree: tree))
    }

    // MARK: History (history.md; HomeModel+History.swift)

    /// The History log as it streams in; nil until it arrives.
    private(set) var historyLog: HistoryLog?

    /// Active names and intentions; at the ~500 cap the add sheet says so.
    var subjectCount: Int { subjects?.count ?? 0 }

    /// A subject's label ("Dad"), for the offer step and the picker.
    func label(of id: String) -> String? { tree[id]?.label }

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

/// A name's page: the person, the carry card and their intentions (the
/// History preview comes from `historyPreview`).
struct PersonPageValues: Equatable {
    let id: String
    let initials: String
    let tone: Int
    let isSelf: Bool
    /// The alias ("Dad", "Me"), else the name: the title.
    let label: String
    /// The printed name, under an alias; nil without one.
    let printedName: String?
    let heldToday: Bool
    /// The carry card's footer; nil until the current list has arrived.
    let status: CarryStatus?
    /// "Prints with": the chosen intentions' text (empty = "Name only");
    /// nil hides the row (not carried, no open intentions, or the self).
    let printsWith: [String]?
    /// As on Home, in Home's order.
    let intentions: [RowItem]
}

/// "Prints with": Name only, then the person's open intentions.
struct PrintsWithValues: Equatable {
    struct Option: Identifiable, Equatable {
        let id: String
        let text: String
        let checked: Bool
        /// With a cap above 1, an unchecked row is disabled at the cap.
        let enabled: Bool
    }

    let cap: Int
    let options: [Option]
    var nameOnly: Bool { !options.contains(where: \.checked) }
}

/// An intention's page.
struct IntentionPageValues: Equatable {
    let id: String
    let text: String
    let personId: String
    /// The person's alias, else their name (the link above the title).
    let personLabel: String
    let personIsSelf: Bool
    let heldToday: Bool
    /// "Answered · Oct 19": no carry card.
    let answered: String?
    /// The carry card's footer; nil when answered or before the list loads.
    let status: CarryStatus?
}

/// One name in the add sheet's For row and "Who is this for?".
struct PickerName: Identifiable, Equatable {
    let id: String
    let label: String
    let initials: String
    let tone: Int
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
