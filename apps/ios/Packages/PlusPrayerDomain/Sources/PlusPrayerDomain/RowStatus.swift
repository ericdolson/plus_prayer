import Foundation

// A row's second line (design-direction §5): only for exceptional states.
// Rows mark presence, never absence, so there's no "Prayed today" or "Last
// prayed N days ago": being held today is the gold ring; history lives on
// the detail page.

public enum RowStatus: Sendable, Equatable {
    /// "Answered · Oct 3"
    case answered(on: Date)
    /// Added while the pool was full, so saved for private prayer
    /// (monetization.md, auto-carry): "Not on the list · all 15 places in use".
    case notCarriedPoolFull(limit: Int)
}

public func rowStatus(_ subject: Subject, justAddedNotCarried: Bool = false, poolLimit: Int = 0) -> RowStatus? {
    if subject.resolution == .answered, let on = subject.resolvedAt { return .answered(on: on) }
    if justAddedNotCarried { return .notCarriedPoolFull(limit: poolLimit) }
    return nil
}
