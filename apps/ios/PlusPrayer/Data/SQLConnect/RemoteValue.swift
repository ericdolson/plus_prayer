import FirebaseDataConnect
import Foundation
import OSLog
import PlusPrayerDomain

/// A value read from the server that streams to watchers: nothing until the
/// first read lands (so a screen's "loaded" means loaded), then every change.
/// `refresh()` re-reads; concurrent refreshes share one read.
@MainActor
final class RemoteValue<Value: Sendable> {
    private let store = Watched<Value?>(nil)
    private let read: @MainActor () async throws -> Value
    private var inFlight: Task<Void, Never>?
    private var started = false
    private let log = Logger(subsystem: "dev.hammock.plusprayer", category: "remote")
    let name: String

    init(_ name: String, read: @escaping @MainActor () async throws -> Value) {
        self.name = name
        self.read = read
    }

    var value: Value? { store.value }

    /// The value as it arrives; the first watcher starts the first read.
    func stream() -> AsyncStream<Value> {
        if !started {
            started = true
            Task { await refresh() }
        }
        let source = store.stream()
        return AsyncStream { continuation in
            let task = Task {
                for await value in source {
                    if let value { continuation.yield(value) }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Re-reads (only once anyone watches; until then the first watcher reads).
    func refresh() async {
        guard started else { return }
        // A read already under way may have started before a write: let it
        // land, then read again.
        if let running = inFlight { await running.value }
        let task = Task { @MainActor in
            do {
                store.send(try await read())
            } catch {
                log.error("\(self.name, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
        inFlight = task
        await task.value
        if inFlight == task { inFlight = nil }
    }

    /// Sets the value locally (a write's known result, before the re-read).
    func set(_ value: Value) { store.send(value) }
}

/// Online, a query goes to the server (and refreshes the device cache);
/// when that fails (no signal, the emulators down) the cached result is
/// used, so screens open offline (apps/ios/CLAUDE.md, "Offline reads").
@MainActor
func serverThenCache<Data>(_ run: @MainActor (QueryFetchPolicy) async throws -> OperationResult<Data>) async throws -> Data {
    do {
        if let data = try await run(.serverOnly).data { return data }
    } catch {
        if let data = try? await run(.cacheOnly).data { return data }
        throw error
    }
    throw RemoteReadError.empty
}

enum RemoteReadError: Error {
    case empty
}

/// Generated scalar types ↔ the app's own (generated types never leave
/// Data/SQLConnect and Data/Queue).
nonisolated enum RemoteScalars {
    static func date(_ local: FirebaseDataConnect.LocalDate) -> PlusPrayerDomain.LocalDate? {
        PlusPrayerDomain.LocalDate(string: local.description)
    }

    static func local(_ date: PlusPrayerDomain.LocalDate) throws -> FirebaseDataConnect.LocalDate {
        try FirebaseDataConnect.LocalDate(localDateString: date.description)
    }
}
