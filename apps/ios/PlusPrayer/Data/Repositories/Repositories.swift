import Foundation
import PlusPrayerDomain

// The seam between the UI and the backend (apps/ios/CLAUDE.md,
// "Repositories"). Models only ever see these protocols; the mock (Data/Mock)
// and the real implementations (Data/SQLConnect, Data/RTDB; build step 4)
// both satisfy them. What the UI watches is an AsyncStream that yields the
// current value first; commands are async.
//
// Each protocol carries what's built so far; the rest of each surface
// (addSubject, reorder, settings, the draft, …) lands with its feature.

/// getMySubjects + the subject callables.
protocol SubjectRepository {
    /// ACTIVE subjects (answered intentions stay until archived), with each
    /// one's `lastPrayed` local date.
    func subjects() -> AsyncStream<[Subject]>
}

/// getCurrentListMeta + RTDB `/lists/current` (live count, closesAt), and
/// getMyListStatus.
protocol ListRepository {
    func currentList() -> AsyncStream<CurrentList?>
    /// getMyListStatus for the current list; re-read when it flips or after a
    /// list prayer. nil until the current list is known.
    func myStatus() -> AsyncStream<MyListStatus?>
}

/// getMyHeader (later: reminders, updateMySettings).
protocol UserRepository {
    /// nil while the account isn't ready yet.
    func header() -> AsyncStream<UserHeader?>
}

/// logPrayer / updatePrayerNote, through the offline queue.
protocol PrayerRepository {
    /// Records the prayer on the device before returning, then sends it when
    /// it can. A prayer never fails for want of signal.
    func logPrayer(_ prayer: NewPrayer) async
    /// The note, the only part of a prayer that changes (note-only edits).
    /// Queued after its prayer, so it never overtakes it. nil clears it.
    func updateNote(prayerId: String, note: String?) async
    /// Prayers logged on this device that the server may not reflect yet:
    /// folded into Home so the result shows at once, offline too.
    func localPrayers() -> AsyncStream<[NewPrayer]>
}

/// RTDB: `/stats/live`, `/config` (later: the presence node and draft).
protocol LiveRepository {
    func stats() -> AsyncStream<LiveStats>
    /// `/config` over the compiled-in defaults.
    func config() -> AsyncStream<AppConfig>
}

/// The repositories one environment provides.
struct Repositories {
    let subjects: any SubjectRepository
    let lists: any ListRepository
    let user: any UserRepository
    let prayers: any PrayerRepository
    let live: any LiveRepository
}

/// A value that streams to any number of watchers: each new stream yields the
/// current value, then every change. Main-actor state for the mock and for
/// repositories that keep a local cache.
@MainActor
final class Watched<Value: Sendable> {
    private(set) var value: Value
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    init(_ value: Value) {
        self.value = value
    }

    func send(_ next: Value) {
        value = next
        for continuation in continuations.values { continuation.yield(next) }
    }

    func update(_ change: (inout Value) -> Void) {
        var next = value
        change(&next)
        send(next)
    }

    func stream() -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuation.yield(value)
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.continuations[id] = nil }
        }
        return stream
    }
}
