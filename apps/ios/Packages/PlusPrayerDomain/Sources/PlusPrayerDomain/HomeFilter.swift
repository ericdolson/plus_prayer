import Foundation

// Home's filter and search (design-direction §4, §6): All · Still to hold ·
// Carried. Both persist across nav and prayer modes (it's the same view).
// Search matches the printed name and the alias.
//
// A name stays visible as context when any of its intentions pass; a name
// that passes brings its passing intentions with it. Counts (the filter menu
// only, never on Home) are items: names and intentions that pass, search
// aside.

public enum HomeFilter: Sendable, Hashable, CaseIterable {
    case all, stillToHold, carried
}

/// Held today: prayed for on this local day. The gold ring (names) or dot
/// (intentions) stays until local midnight.
public func isHeldToday(_ subject: Subject, today: LocalDate) -> Bool {
    guard let lastPrayed = subject.lastPrayed else { return false }
    return lastPrayed >= today
}

public func matchesQuery(_ subject: Subject, _ query: String) -> Bool {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if q.isEmpty { return true }
    return subject.publicName.localizedStandardContains(q) || (subject.alias?.localizedStandardContains(q) ?? false)
}

public func passesFilter(_ subject: Subject, _ filter: HomeFilter, tree: SubjectTree, today: LocalDate) -> Bool {
    switch filter {
    case .all: true
    case .stillToHold: !isHeldToday(subject, today: today)
    case .carried: showsCarriedMark(subject, in: tree)
    }
}

/// One visible row: a name or an intention.
public struct HomeRow: Sendable, Equatable, Identifiable {
    public let subject: Subject
    /// Shown only as the parent of an intention that passes: dimmed.
    public let isContext: Bool

    public var id: String { subject.id }
}

/// A name and the intentions shown under it.
public struct HomeGroup: Sendable, Equatable, Identifiable {
    public let name: HomeRow
    public let intentions: [HomeRow]

    public var id: String { name.id }
}

/// The groups Home shows. `keep`: ids that pass regardless (rows lingering
/// after Amen under Still to hold, before they fold away).
public func visibleGroups(_ tree: SubjectTree, today: LocalDate, query: String = "",
                          filter: HomeFilter = .all, keep: Set<String> = []) -> [HomeGroup] {
    func passes(_ s: Subject) -> Bool {
        keep.contains(s.id) || passesFilter(s, filter, tree: tree, today: today)
    }
    return tree.names.compactMap { name in
        let nameMatches = matchesQuery(name, query)
        let namePasses = nameMatches && passes(name)
        let intentions = tree.intentions(of: name.id).filter {
            (nameMatches || matchesQuery($0, query)) && passes($0)
        }
        guard namePasses || !intentions.isEmpty else { return nil }
        return HomeGroup(name: HomeRow(subject: name, isContext: !namePasses),
                         intentions: intentions.map { HomeRow(subject: $0, isContext: false) })
    }
}

/// How many items (names and intentions) `filter` keeps, search aside.
public func filterCount(_ tree: SubjectTree, _ filter: HomeFilter, today: LocalDate) -> Int {
    tree.names.reduce(0) { count, name in
        count + ([name] + tree.intentions(of: name.id)).filter {
            passesFilter($0, filter, tree: tree, today: today)
        }.count
    }
}

/// The Carried view holds only you (your name and your own intentions) or
/// nothing: Home then teaches what Carried means (design-direction §6).
public func carriedShowsOnlyYou(_ groups: [HomeGroup]) -> Bool {
    groups.allSatisfy { $0.name.subject.isSelf }
}

/// Items `query` matches under All (context rows aside): what clearing the
/// filter would reveal.
public func matchesInAll(_ tree: SubjectTree, query: String, today: LocalDate) -> Int {
    visibleGroups(tree, today: today, query: query).reduce(0) { count, group in
        count + (group.name.isContext ? 0 : 1) + group.intentions.count
    }
}

/// The community card under filters and search (design-direction §6):
/// shown under All and Carried; under Still to hold only until you've prayed
/// with the list today (or while it lingers after Amen); hidden while search
/// has text.
public func communityCardShown(filter: HomeFilter, query: String, prayedWithListToday: Bool,
                               lingering: Bool) -> Bool {
    if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
    if filter != .stillToHold { return true }
    return !prayedWithListToday || lingering
}
