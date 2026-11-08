import PlusPrayerDomain
import SwiftUI

/// Everything pushed over Home (apps/ios/CLAUDE.md, "Navigation").
enum Route: Hashable {
    /// A name's or an intention's page (`SubjectPage` picks by kind).
    case subject(String)
    /// The History screen (history.md), opened on a scope, a tab, and
    /// maybe a day's sheet.
    case history(HistoryRequest)
}

/// Where History opens: Home's footer → everyone on All; a page's tiles,
/// preview row and "See all" → that subject, on the matching tab (a node:
/// All, with that day's sheet).
struct HistoryRequest: Hashable {
    var scope: HistoryScope = .everyone
    var tab: HistoryTab = .all
    var day: LocalDate? = nil
}

/// History's tabs (history.md, 2026-11-08): each tab is the full list
/// behind one mark in the strand.
enum HistoryTab: Hashable, CaseIterable {
    case all, held, lists, journal, answered

    var title: String {
        switch self {
        case .all: L10n.History.tabAll
        case .held: L10n.History.tabHeld
        case .lists: L10n.History.tabLists
        case .journal: L10n.History.tabJournal
        case .answered: L10n.History.tabAnswered
        }
    }
}


extension View {
    /// Where each route goes; on the stack's root (Home, and previews).
    func routes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .subject(let id): SubjectPage(id: id)
            case .history(let request): HistoryScreen(request: request)
            }
        }
    }
}
