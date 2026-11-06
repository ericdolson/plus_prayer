import Foundation
import Observation
import PlusPrayerDomain

/// One prayer, from the pray button to Amen (prayer-flow.md). Prayer mode is
/// Home in a different state, not a screen: rows become checkable, the halo
/// frames the screen, the bar becomes the prayer bar.
///
/// The session holds only what this prayer holds. What's held today comes
/// from the data (`HomeModel`); Amen hands back the `NewPrayer` to log. The
/// list invitation and the closing sheet come in the next slices.
@MainActor @Observable
final class PrayerSession {
    enum Phase: Equatable {
        case idle
        /// `list`: the list current at the start, which the prayer counts for.
        case praying(startedAt: Date, list: ListContext?)
    }

    private(set) var phase: Phase = .idle
    private(set) var selection = PrayerSelection.empty
    /// Bumps on each committing Amen: the halo's flare.
    private(set) var amenCount = 0
    /// Bumps each time something is checked (not unchecked): the light haptic.
    private(set) var checkCount = 0

    /// Which names have which intentions, as Home shows them now.
    private let graph: () -> SubjectGraph
    private let clock: () -> Date

    /// The pray button's minimum before Amen (prayer-flow.md, ~5 s).
    static let minimum: TimeInterval = PP.duration.prayHold
    /// Past this, Cancel asks "Discard this prayer?" (design-direction §4, ~30 s).
    static let confirmDiscardAfter: TimeInterval = 30

    init(graph: @escaping () -> SubjectGraph, clock: @escaping () -> Date = Date.init) {
        self.graph = graph
        self.clock = clock
    }

    var isPraying: Bool { phase != .idle }

    var startedAt: Date? {
        if case .praying(let startedAt, _) = phase { return startedAt }
        return nil
    }

    func elapsed(at now: Date) -> TimeInterval {
        startedAt.map { now.timeIntervalSince($0) } ?? 0
    }

    func canAmen(at now: Date) -> Bool { isPraying && elapsed(at: now) >= Self.minimum }

    func needsDiscardConfirmation(at now: Date) -> Bool { elapsed(at: now) > Self.confirmDiscardAfter }

    // MARK: Row state

    /// The check a row shows in prayer.
    func check(_ id: String) -> HoldState { selection.state(of: id, in: graph()) }

    /// Held in this prayer (the row's gold, live).
    func isHeld(_ id: String) -> Bool { selection.isHeld(id) }

    // MARK: Commands

    func start(list: ListContext?) {
        guard !isPraying else { return }
        selection = .empty
        phase = .praying(startedAt: clock(), list: list)
    }

    func toggle(_ id: String) {
        guard isPraying else { return }
        let willHold = !selection.isHeld(id)
        selection = selection.toggling(id, in: graph()).stamped(at: clock())
        if willHold { checkCount += 1 }
    }

    func toggleList() {
        guard isPraying else { return }
        let willHold = !selection.listIncluded
        selection = selection.withList(willHold)
        if willHold { checkCount += 1 }
    }

    /// The committing Amen: ends the prayer and returns it, to be logged.
    /// nil before the minimum (or with no list known, which can't happen once
    /// Home has loaded: every prayer records the list current at its start).
    func amen() -> NewPrayer? {
        let now = clock()
        guard canAmen(at: now), case .praying(let startedAt, let list) = phase else { return nil }
        let prayer = list.map {
            newPrayer(id: UUID().uuidString, selection: selection, startedAt: startedAt, endedAt: now, list: $0)
        }
        amenCount += 1
        selection = .empty
        phase = .idle
        return prayer
    }

    /// Discard: nothing is logged.
    func cancel() {
        selection = .empty
        phase = .idle
    }
}
