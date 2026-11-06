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

    /// The addSubject callable: appended to the bottom of its level, carried
    /// when asked and while the pool has room, `avatarTone` stored. Online
    /// only (it needs the server's id and carry decision). Throws
    /// `AddSubjectError`.
    func addSubject(_ input: NewSubject) async throws -> AddedSubject
}

struct NewSubject: Equatable {
    let kind: SubjectKind
    let publicName: String
    /// Required for an intention: its name.
    var parentId: String? = nil
    /// Names only; blank = none.
    var alias: String? = nil
    /// Names only: picked when the add sheet opened.
    var avatarTone: Int? = nil
    /// The add sheet's carry row. false = kept for your own prayers. (The
    /// server still saves it privately if the pool has no room.)
    /// schema-brief.md, "addSubject carry inputs": coming to the callable;
    /// the mock has it now.
    var carry = true
    /// Intentions only: also carry the name it's under ("Also carries Dad"),
    /// which re-carries its intentions still flagged.
    var carryParent = false
}

/// schema-brief.md, "addSubject carry inputs": one all-or-nothing pool
/// check in the same call.
struct AddedSubject: Equatable {
    let id: String
    /// The stored flag: false when it wasn't asked to be carried or the pool
    /// had no room.
    let isCarried: Bool
    /// An intention's name's stored flag after the call; nil for a name.
    var parentCarried: Bool? = nil
    /// Prints: its own flag and its name's (a name: its own flag).
    let effectivelyCarried: Bool

    /// The server's result differs from what the carry row asked for (the
    /// pool filled from another device): the sheet says "Saved, but not
    /// carried…". All or nothing, so `effectivelyCarried` is the whole answer.
    func differs(from input: NewSubject) -> Bool {
        input.carry && !effectivelyCarried
    }
}

/// From the addSubject callable's codes (backend/functions/src/subjects.ts):
/// invalid-argument → `.input`, resource-exhausted → `.cap`, no connection →
/// `.offline`, anything else (failed-precondition for the hard cap, internal,
/// …) → `.failed`.
enum AddSubjectError: Error, Equatable {
    /// The server rejected the text (the same rules as PlusPrayerDomain).
    case input(TextIssue)
    /// No connection.
    case offline
    /// The ~500 cap on what's on Home. Not a paywall.
    case cap
    /// Anything else (the quiet ~5,000 hard cap, an unexpected server
    /// error): "Couldn't add this right now. Try again in a little while."
    case failed
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

/// Whether the device can reach the backend (NWPathMonitor for real; the
/// mock's toggle). Online-only commands (addSubject) read it to disable
/// themselves and say "Adding needs a connection."
protocol NetworkRepository {
    func online() -> AsyncStream<Bool>
}

/// The repositories one environment provides.
struct Repositories {
    let subjects: any SubjectRepository
    let lists: any ListRepository
    let user: any UserRepository
    let prayers: any PrayerRepository
    let live: any LiveRepository
    let network: any NetworkRepository
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
