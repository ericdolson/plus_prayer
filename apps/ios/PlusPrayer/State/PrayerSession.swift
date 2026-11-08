import Foundation
import Observation
import PlusPrayerDomain

/// One prayer, from the pray button to the closing sheet (prayer-flow.md).
/// Prayer mode is Home in a different state, not a screen: rows become
/// checkable, the halo frames the screen, the bar becomes the prayer bar.
///
///     idle ──start──▶ praying ──Amen──▶ (invitation) ──Amen──▶ closing ──close──▶ idle
///                        │                    │
///                        └─────── cancel ─────┘  (nothing is logged)
///
/// - Amen is available after the minimum (~5 s); before it only Cancel exits.
/// - Amen without the list, when you haven't prayed with it today, opens the
///   invitation. Tapping it holds the list and runs the same ring; it extends
///   the same prayer: one Prayer, written once, at the final Amen. Amen
///   before tapping finishes without the list.
/// - The list current at the START is the one the prayer counts for.
/// - Closing: the prayer is written (returned by the committing Amen, for
///   Home to log); the sheet offers a private note, then you leave.
///
/// Praying in place (detail-page.md): a prayer started on a name's or an
/// intention's page stays there (`page`). That subject is checked at the
/// start and can be unchecked. "Pray for others" (or back) leaves the page
/// for Home with the checks kept (`leavePage`); a draft restored at launch
/// would resume on Home, since `page` isn't kept.
///
/// The session holds only this prayer. What's held today comes from the data
/// (`HomeModel`). The selection stays through closing, so held rings don't
/// blink before the logged prayer arrives from the repository.
@MainActor @Observable
final class PrayerSession {
    struct Prayer: Equatable {
        /// Client UUID, chosen at the start.
        let id: String
        let startedAt: Date
        /// The list current at the start; nil only before Home has loaded.
        let list: ListContext?
    }

    enum Phase: Equatable {
        case idle
        case praying(Prayer)
        /// Amen was said without the list. `holdingSince`: when the user
        /// tapped to hold it (the invitation's ring runs from there).
        case invitation(Prayer, holdingSince: Date?)
        /// Written; the closing sheet is up.
        case closing(NewPrayer)
    }

    private(set) var phase: Phase = .idle
    private(set) var selection = PrayerSelection.empty
    /// The subject whose page the prayer is being said on; nil on Home. Set
    /// from the start through the closing sheet (the page stays stripped
    /// until it goes). In memory only.
    private(set) var page: String?
    /// Bumps on each committing Amen: the halo's flare.
    private(set) var amenCount = 0
    /// Bumps each time something is checked (not unchecked): the light haptic.
    private(set) var checkCount = 0

    /// Which names have which intentions, as Home shows them now.
    private let graph: () -> SubjectGraph
    private let clock: () -> Date
    private let makeID: () -> String

    /// The pray button's minimum before Amen (prayer-flow.md, ~5 s).
    static let minimum: TimeInterval = PP.duration.prayHold
    /// Past this, Cancel asks "Discard this prayer?" (design-direction §4, ~30 s).
    static let confirmDiscardAfter: TimeInterval = 30

    init(graph: @escaping () -> SubjectGraph, clock: @escaping () -> Date = Date.init,
         makeID: @escaping () -> String = { UUID().uuidString }) {
        self.graph = graph
        self.clock = clock
        self.makeID = makeID
    }

    // MARK: State

    private var prayer: Prayer? {
        switch phase {
        case .praying(let prayer), .invitation(let prayer, _): prayer
        case .idle, .closing: nil
        }
    }

    /// In prayer, the invitation included: the halo, checks, the prayer bar.
    var isPraying: Bool { prayer != nil }

    var startedAt: Date? { prayer?.startedAt }

    var isInvited: Bool {
        if case .invitation = phase { return true }
        return false
    }

    /// When the user tapped the invitation; nil before.
    var holdingListSince: Date? {
        if case .invitation(_, let since) = phase { return since }
        return nil
    }

    /// The prayer just written, while the closing sheet is up.
    var closing: NewPrayer? {
        if case .closing(let prayer) = phase { return prayer }
        return nil
    }

    func elapsed(at now: Date) -> TimeInterval {
        startedAt.map { now.timeIntervalSince($0) } ?? 0
    }

    func canAmen(at now: Date) -> Bool {
        if case .praying = phase { return elapsed(at: now) >= Self.minimum }
        return false
    }

    func needsDiscardConfirmation(at now: Date) -> Bool { elapsed(at: now) > Self.confirmDiscardAfter }

    // MARK: Row state

    /// The check a row shows in prayer.
    func check(_ id: String) -> HoldState { selection.state(of: id, in: graph()) }

    /// Held in this prayer (the row's gold, live).
    func isHeld(_ id: String) -> Bool { selection.isHeld(id) }

    // MARK: Commands

    /// Starts a prayer: on Home, or on a subject's page (`page`), which
    /// starts checked (an intention's name with it, by the selection rules).
    /// The pre-check is no tap: no haptic.
    func start(list: ListContext?, on page: String? = nil) {
        guard phase == .idle else { return }
        let now = clock()
        selection = page.map { PrayerSelection.empty.holding($0, in: graph()).stamped(at: now) } ?? .empty
        self.page = page
        phase = .praying(Prayer(id: makeID(), startedAt: now, list: list))
    }

    /// Prayed in place, a page's way back to Home ("Pray for others", back,
    /// swipe-back): still praying, the checks kept.
    func leavePage() {
        guard isPraying else { return }
        page = nil
    }

    func toggle(_ id: String) {
        guard isPraying else { return }
        let graph = graph()
        let willHold = !selection.isHeld(id)
        // On an intention's own page its name is plain text: it follows the intention.
        let next = page == id && graph.parent(of: id) != nil
            ? selection.releasingWithItsName(id, in: graph)
            : selection.toggling(id, in: graph)
        selection = next.stamped(at: clock())
        if willHold { checkCount += 1 }
    }

    func toggleList() {
        guard isPraying, prayer?.list != nil else { return }
        let willHold = !selection.listIncluded
        selection = selection.withList(willHold)
        if willHold { checkCount += 1 }
    }

    /// The pray button's Amen. Opens the invitation (nothing written yet) or
    /// commits: then it returns the prayer to log.
    func amen(prayedWithListToday: Bool) -> NewPrayer? {
        let now = clock()
        guard canAmen(at: now), case .praying(let prayer) = phase else { return nil }
        if invitesToList(selection, listKnown: prayer.list != nil, prayedWithListToday: prayedWithListToday) {
            phase = .invitation(prayer, holdingSince: nil)
            return nil
        }
        return finish(prayer, at: now)
    }

    /// The invitation's tap: hold the list too; its ring runs from now.
    func holdList() {
        guard case .invitation(let prayer, nil) = phase else { return }
        selection = selection.withList(true)
        phase = .invitation(prayer, holdingSince: clock())
        checkCount += 1
    }

    /// The invitation's Amen: with the list once its ring has run, or
    /// without it if the user didn't tap. Returns the prayer to log.
    func amenFromInvitation() -> NewPrayer? {
        let now = clock()
        guard case .invitation(let prayer, let since) = phase else { return nil }
        if let since, now.timeIntervalSince(since) < Self.minimum { return nil }
        return finish(prayer, at: now)
    }

    /// Discard: nothing is logged.
    func cancel() {
        guard isPraying else { return }
        selection = .empty
        page = nil
        phase = .idle
    }

    /// The closing sheet is gone.
    func close() {
        guard closing != nil else { return }
        selection = .empty
        page = nil
        phase = .idle
    }

    private func finish(_ prayer: Prayer, at end: Date) -> NewPrayer? {
        guard let list = prayer.list else {
            // No list known (Home hadn't loaded): nothing to record it against.
            cancel()
            return nil
        }
        let written = newPrayer(id: prayer.id, selection: selection, startedAt: prayer.startedAt, endedAt: end,
                                list: list)
        amenCount += 1
        phase = .closing(written)
        return written
    }
}
