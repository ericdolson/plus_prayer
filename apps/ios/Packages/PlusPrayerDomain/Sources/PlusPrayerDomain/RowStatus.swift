import Foundation

// A row's second line (design-direction §5): only for exceptional states.
// Rows mark presence, never absence, so there's no "Prayed today" or "Last
// prayed N days ago": being held today is the gold ring; history lives on
// the detail page.

public enum RowStatus: Sendable, Equatable {
    /// "Answered · Oct 3"
    case answered(on: Date)
}

/// A full pool is said in the add sheet, never on Home (screens.md, add
/// sheet; design-direction §5: absence is never marked).
public func rowStatus(_ subject: Subject) -> RowStatus? {
    if subject.resolution == .answered, let on = subject.resolvedAt { return .answered(on: on) }
    return nil
}
