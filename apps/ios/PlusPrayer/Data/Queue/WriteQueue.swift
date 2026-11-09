import Foundation
import OSLog
import PlusPrayerDomain

/// One client write waiting to reach the server (apps/ios/CLAUDE.md,
/// "Offline prayer queue"). `logPrayer` carries its client-generated id, so
/// a resend is a no-op on the server; a note edit is note-only.
nonisolated enum PendingWrite: Codable, Sendable, Equatable {
    case logPrayer(NewPrayer)
    case updateNote(prayerId: String, note: String?)

    var prayer: NewPrayer? {
        if case .logPrayer(let prayer) = self { prayer } else { nil }
    }
}

nonisolated struct QueuedWrite: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let write: PendingWrite
    var attempts = 0
}

/// What sending one write came to.
nonisolated enum SendOutcome: Sendable, Equatable {
    case sent
    /// Transient (no connection, the server unavailable): kept, retried
    /// with backoff, and nothing after it goes first.
    case retry
    /// The server refused it (invalid input, a failed check): dropped and
    /// reported, so it can't block the writes behind it.
    case drop(reason: String)
}

/// Where the queue lives between launches.
nonisolated protocol QueueStore: Sendable {
    func load() throws -> [QueuedWrite]
    func save(_ writes: [QueuedWrite]) throws
}

/// A JSON file in Application Support (never Caches, which iOS may purge),
/// written atomically and excluded from iCloud backup.
nonisolated struct FileQueueStore: QueueStore {
    let url: URL

    static func standard() -> FileQueueStore {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return FileQueueStore(url: base.appendingPathComponent("PlusPrayer", isDirectory: true)
            .appendingPathComponent("write-queue.json"))
    }

    func load() throws -> [QueuedWrite] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([QueuedWrite].self, from: Data(contentsOf: url))
    }

    func save(_ writes: [QueuedWrite]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(writes).write(to: url, options: .atomic)
        var exclude = URLResourceValues()
        exclude.isExcludedFromBackup = true
        var excluded = url
        try? excluded.setResourceValues(exclude)
    }
}

/// The offline write queue: persists each write **before** the caller moves
/// on, sends FIFO (a note never overtakes its prayer), retries transient
/// failures with backoff, and drops and reports permanent ones. Flushes on
/// enqueue and whenever `flush()` is called (launch, the scene becoming
/// active, reconnect).
actor WriteQueue {
    typealias Sender = @Sendable (PendingWrite) async -> SendOutcome

    private let store: any QueueStore
    private let send: Sender
    private let onChange: @Sendable ([QueuedWrite]) async -> Void
    private let onSent: @Sendable (PendingWrite) async -> Void
    private let backoff: @Sendable (Int) -> Duration
    private var writes: [QueuedWrite]
    private var flushing = false
    private var retryTask: Task<Void, Never>?
    private let log = Logger(subsystem: "dev.hammock.plusprayer", category: "queue")

    init(store: any QueueStore, send: @escaping Sender,
         onChange: @escaping @Sendable ([QueuedWrite]) async -> Void = { _ in },
         onSent: @escaping @Sendable (PendingWrite) async -> Void = { _ in },
         backoff: @escaping @Sendable (Int) -> Duration = { .seconds(min(60, 1 << min($0, 6))) }) {
        self.store = store
        self.send = send
        self.onChange = onChange
        self.onSent = onSent
        self.backoff = backoff
        writes = (try? store.load()) ?? []
    }

    var pending: [QueuedWrite] { writes }

    /// Persists the write, then sends what it can.
    func enqueue(_ write: PendingWrite) async {
        writes.append(QueuedWrite(id: UUID(), write: write))
        persist()
        await onChange(writes)
        await flush()
    }

    /// Sends FIFO until the queue is empty or a write must wait.
    func flush() async {
        guard !flushing else { return }
        flushing = true
        defer { flushing = false }
        while let next = writes.first {
            switch await send(next.write) {
            case .sent:
                writes.removeFirst()
                persist()
                await onChange(writes)
                await onSent(next.write)
            case .drop(let reason):
                log.error("Dropped a queued write the server refused: \(reason, privacy: .public)")
                writes.removeFirst()
                persist()
                await onChange(writes)
            case .retry:
                writes[0].attempts += 1
                persist()
                scheduleRetry(after: backoff(writes[0].attempts))
                return
            }
        }
    }

    private func scheduleRetry(after delay: Duration) {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    private func persist() {
        do {
            try store.save(writes)
        } catch {
            log.error("Couldn't save the write queue: \(error.localizedDescription, privacy: .public)")
        }
    }
}
