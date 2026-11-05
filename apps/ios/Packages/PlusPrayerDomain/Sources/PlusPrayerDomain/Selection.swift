import Foundation

// Selection rules in prayer (subjects.md, prayer-flow.md; decided 2026-10-17):
// - checking an intention also holds its name (the prayer counts toward it);
// - checking a name does NOT check its intentions;
// - unchecking a name unchecks its intentions;
// - unchecking an intention leaves its name held;
// - a name shows a partial state when only some of its intentions are held.
// The current list is a separate toggle (`listIncluded`).
// Each held item keeps when it was checked (`checkedAt`, schema-brief §12): a
// data seam sent per item with the prayer; no UI shows it.

/// What a row's check shows.
public enum HoldState: Sendable, Equatable {
    case none, held, partial
}

/// The shape the rules need: which names have which intentions.
public struct SubjectGraph: Sendable, Equatable {
    /// Name id → its intention ids, in order.
    public let intentionsByName: [String: [String]]
    private let parentByIntention: [String: String]

    public init(intentionsByName: [String: [String]]) {
        self.intentionsByName = intentionsByName
        var parents: [String: String] = [:]
        for (name, intentions) in intentionsByName {
            for intention in intentions { parents[intention] = name }
        }
        parentByIntention = parents
    }

    public func contains(_ id: String) -> Bool { isName(id) || parentByIntention[id] != nil }
    public func isName(_ id: String) -> Bool { intentionsByName[id] != nil }
    public func parent(of id: String) -> String? { parentByIntention[id] }
    public func intentions(of name: String) -> [String] { intentionsByName[name] ?? [] }
}

public struct PrayerSelection: Sendable, Equatable {
    /// Held subject ids (names and intentions).
    public private(set) var held: Set<String>
    public private(set) var listIncluded: Bool
    /// When each held item was checked; see `stamped(at:)`.
    public private(set) var checkedAt: [String: Date]

    public static let empty = PrayerSelection()

    public init(held: Set<String> = [], listIncluded: Bool = false, checkedAt: [String: Date] = [:]) {
        self.held = held
        self.listIncluded = listIncluded
        self.checkedAt = checkedAt
    }

    public var isEmpty: Bool { held.isEmpty && !listIncluded }
    public func isHeld(_ id: String) -> Bool { held.contains(id) }

    public func withList(_ included: Bool) -> PrayerSelection {
        var next = self
        next.listIncluded = included
        return next
    }

    /// Tap on a row in prayer: hold it, or let it go.
    public func toggling(_ id: String, in graph: SubjectGraph) -> PrayerSelection {
        isHeld(id) ? releasing(id, in: graph) : holding(id, in: graph)
    }

    public func holding(_ id: String, in graph: SubjectGraph) -> PrayerSelection {
        guard graph.contains(id) else { return self }
        var next = self
        next.held.insert(id)
        if let parent = graph.parent(of: id) { next.held.insert(parent) }
        return next
    }

    public func releasing(_ id: String, in graph: SubjectGraph) -> PrayerSelection {
        var next = self
        next.held.remove(id)
        if graph.isName(id) {
            for intention in graph.intentions(of: id) { next.held.remove(intention) }
        }
        return next
    }

    /// Records `at` for every held item not yet stamped (a name held along
    /// with its intention gets the same time) and forgets items let go, so an
    /// item checked, unchecked and checked again keeps the last check.
    public func stamped(at date: Date) -> PrayerSelection {
        var next = self
        next.checkedAt = Dictionary(uniqueKeysWithValues: held.map { ($0, checkedAt[$0] ?? date) })
        return next
    }

    public func state(of id: String, in graph: SubjectGraph) -> HoldState {
        guard isHeld(id) else { return .none }
        guard graph.isName(id) else { return .held }
        let intentions = graph.intentions(of: id)
        let heldCount = intentions.filter(isHeld).count
        return heldCount > 0 && heldCount < intentions.count ? .partial : .held
    }
}
