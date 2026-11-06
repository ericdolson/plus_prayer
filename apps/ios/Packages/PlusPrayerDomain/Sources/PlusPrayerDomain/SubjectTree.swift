import Foundation

// Home's personal list as a two-level tree (subjects.md): names as rows, each
// name's intentions beneath it. Order is manual (`sortOrder`, then creation);
// the self ("Me") is pinned to the top.

public struct SubjectTree: Sendable, Equatable {
    /// Names in display order, self first.
    public let names: [Subject]
    private let intentionsByName: [String: [Subject]]
    private let byId: [String: Subject]

    public init(_ subjects: [Subject]) {
        var byId: [String: Subject] = [:]
        for subject in subjects { byId[subject.id] = subject }
        func ordered(_ a: Subject, _ b: Subject) -> Bool {
            a.sortOrder != b.sortOrder ? a.sortOrder < b.sortOrder : a.createdAt < b.createdAt
        }
        names = subjects.filter(\.isName).sorted { a, b in
            a.isSelf != b.isSelf ? a.isSelf : ordered(a, b)
        }
        var intentions: [String: [Subject]] = [:]
        // An intention whose name isn't loaded (archived, purged) isn't shown.
        for subject in subjects where subject.isIntention {
            guard let parentId = subject.parentId, byId[parentId] != nil else { continue }
            intentions[parentId, default: []].append(subject)
        }
        intentionsByName = intentions.mapValues { $0.sorted(by: ordered) }
        self.byId = byId
    }

    public subscript(id: String) -> Subject? { byId[id] }

    public var all: some Collection<Subject> { byId.values }

    public var me: Subject? { names.first.flatMap { $0.isSelf ? $0 : nil } }

    public func intentions(of nameId: String) -> [Subject] { intentionsByName[nameId] ?? [] }

    public func parent(of id: String) -> Subject? { byId[id]?.parentId.flatMap { byId[$0] } }

    /// The shape the selection rules need (`Selection.swift`).
    public var graph: SubjectGraph {
        SubjectGraph(intentionsByName: Dictionary(uniqueKeysWithValues: names.map {
            ($0.id, intentions(of: $0.id).map(\.id))
        }))
    }
}
