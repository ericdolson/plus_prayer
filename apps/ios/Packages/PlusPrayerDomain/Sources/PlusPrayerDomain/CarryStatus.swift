import Foundation

// The status line in a page's carry card footer (detail-page.md "Status
// line", 2026-11-08): what carries someone is praying WITH THE LIST.

public enum CarryStatus: Sendable, Equatable {
    /// From the list gate: "{alias} will be on List 53" / "Your next prayer
    /// with the list carries {alias} onto List 54" / "Pray with today's list
    /// to carry {alias} onto List 53" (the self and an intention have their
    /// own wording). `next` is the list they go onto.
    case list(TomorrowStatus, next: Int)
    /// Near the cutoff, while carried and not prayed with the list today:
    /// "List 52 closes in 5 min · pray with the list to carry {alias}".
    case closing(list: Int, minutes: Int, next: Int)
    /// Not carried (a name), or not chosen (an intention): "Private · in
    /// your prayers only".
    case privateOnly
    /// An intention chosen whose person isn't carried: "Private while
    /// {alias} isn't carried".
    case privateWhilePersonOff

    /// Weight follows state, as on the community card: what's still to do
    /// in ink; covered and private in inkMuted.
    public var isActionable: Bool {
        switch self {
        case .list(let tomorrow, _): tomorrow.isActionable
        case .closing: true
        case .privateOnly, .privateWhilePersonOff: false
        }
    }
}

/// The footer for `subject`'s page (a name, the self, or an open
/// intention). nil while the current list isn't known yet.
/// - Parameters:
///   - list: the current list's number.
///   - tomorrow: the gate's status for the next list.
///   - closingMinutes: `closingSoonMinutes(…)` (nil outside the last minutes
///     or once prayed with the list today).
public func carryStatus(_ subject: Subject, in tree: SubjectTree, list: Int?, tomorrow: TomorrowStatus?,
                        closingMinutes: Int?) -> CarryStatus? {
    if subject.isIntention {
        guard subject.isCarried, !subject.isResolved else { return .privateOnly }
        if let person = tree.parent(of: subject.id), !person.isSelf, !person.isCarried {
            return .privateWhilePersonOff
        }
    } else if !subject.isSelf && !subject.isCarried {
        return .privateOnly
    }
    guard let list else { return nil }
    if let closingMinutes { return .closing(list: list, minutes: closingMinutes, next: list + 1) }
    guard let tomorrow else { return nil }
    return .list(tomorrow, next: list + 1)
}
