import Foundation
import Observation
import PlusPrayerDomain

/// One prayer, from the pray button to Amen (prayer-flow.md). Prayer mode is
/// Home in a different state, not a screen: rows become checkable, the halo
/// frames the screen, the bar becomes the prayer bar.
///
/// Build step 1: no writes yet. Amen marks what was held as held today (the
/// gold that lasts until local midnight); logging, the list invitation and
/// the closing sheet come with the data layer and the next slices.
@MainActor @Observable
final class PrayerSession {
    enum Phase: Equatable {
        case idle
        case praying(startedAt: Date)
    }

    private(set) var phase: Phase = .idle
    private(set) var selection = PrayerSelection.empty
    /// Held today (until local midnight): names and intentions, and the list.
    private(set) var heldToday: Set<String>
    private(set) var listHeldToday: Bool
    /// Bumps on each committing Amen: the halo's flare.
    private(set) var amenCount = 0
    /// Bumps each time something is checked (not unchecked): the light haptic.
    private(set) var checkCount = 0

    let graph: SubjectGraph
    private let clock: () -> Date

    /// The pray button's minimum before Amen (prayer-flow.md, ~5 s).
    static let minimum: TimeInterval = PP.duration.prayHold
    /// Past this, Cancel asks "Discard this prayer?" (design-direction §4, ~30 s).
    static let confirmDiscardAfter: TimeInterval = 30

    init(graph: SubjectGraph, heldToday: Set<String> = [], listHeldToday: Bool = false,
         clock: @escaping () -> Date = Date.init) {
        self.graph = graph
        self.heldToday = heldToday
        self.listHeldToday = listHeldToday
        self.clock = clock
    }

    var isPraying: Bool { phase != .idle }

    var startedAt: Date? {
        if case .praying(let startedAt) = phase { return startedAt }
        return nil
    }

    func elapsed(at now: Date) -> TimeInterval {
        startedAt.map { now.timeIntervalSince($0) } ?? 0
    }

    func canAmen(at now: Date) -> Bool { isPraying && elapsed(at: now) >= Self.minimum }

    func needsDiscardConfirmation(at now: Date) -> Bool { elapsed(at: now) > Self.confirmDiscardAfter }

    // MARK: Row state

    /// The check a row shows in prayer.
    func check(_ id: String) -> HoldState { selection.state(of: id, in: graph) }

    /// The gold ring / dot: held today, or held live in this prayer.
    func isHeld(_ id: String) -> Bool { heldToday.contains(id) || selection.isHeld(id) }

    var listHeld: Bool { listHeldToday || selection.listIncluded }

    // MARK: Commands

    func start() {
        guard !isPraying else { return }
        selection = .empty
        phase = .praying(startedAt: clock())
    }

    func toggle(_ id: String) {
        guard isPraying else { return }
        let willHold = !selection.isHeld(id)
        selection = selection.toggling(id, in: graph).stamped(at: clock())
        if willHold { checkCount += 1 }
    }

    func toggleList() {
        guard isPraying else { return }
        let willHold = !selection.listIncluded
        selection = selection.withList(willHold)
        if willHold { checkCount += 1 }
    }

    /// The committing Amen.
    func amen() {
        guard canAmen(at: clock()) else { return }
        heldToday.formUnion(selection.held)
        listHeldToday = listHeldToday || selection.listIncluded
        amenCount += 1
        selection = .empty
        phase = .idle
    }

    /// Discard: nothing is logged.
    func cancel() {
        selection = .empty
        phase = .idle
    }
}
