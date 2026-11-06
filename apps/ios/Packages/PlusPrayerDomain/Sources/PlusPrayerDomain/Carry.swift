import Foundation

// What goes on the printed list (monetization.md, subjects.md). Mirrors the
// server's backend/functions/src/pool.ts so the app shows what the next list
// will print.
//
// - Effective carry: an intention is carried only if it and its name are
//   (or its name is the self). The self name is always carried and isn't
//   part of the pool.
// - Resolved items are never list-eligible.

/// Is `subject` effectively carried (beyond the self name)?
public func isEffectivelyCarried(_ subject: Subject, in tree: SubjectTree) -> Bool {
    if subject.isSelf || !subject.isCarried || subject.isResolved { return false }
    if subject.isName { return true }
    guard let parent = tree.parent(of: subject.id) else { return false }
    return parent.isSelf || parent.isCarried
}

/// Whether the row shows the carried mark (design-direction §5): the same
/// set the Carried filter shows. The self is always carried.
public func showsCarriedMark(_ subject: Subject, in tree: SubjectTree) -> Bool {
    subject.isSelf || isEffectivelyCarried(subject, in: tree)
}

/// The people on the community card's avatar row (and the invitation): you
/// first, then your effectively carried names in your order. Intentions have
/// no avatars.
public func carriedNames(_ tree: SubjectTree) -> [Subject] {
    (tree.me.map { [$0] } ?? []) + tree.names.filter { isEffectivelyCarried($0, in: tree) }
}
