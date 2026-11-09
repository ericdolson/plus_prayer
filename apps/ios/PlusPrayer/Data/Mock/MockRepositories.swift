import Foundation
import PlusPrayerDomain

// The repositories over MockBackend. The UI can't tell them from the real
// ones (build step 4).

extension Repositories {
    static func mock(_ backend: MockBackend) -> Repositories {
        Repositories(subjects: MockSubjectRepository(backend: backend),
                     lists: MockListRepository(backend: backend),
                     user: MockUserRepository(backend: backend),
                     prayers: MockPrayerRepository(backend: backend),
                     live: MockLiveRepository(backend: backend),
                     network: MockNetworkRepository(backend: backend))
    }
}

final class MockSubjectRepository: SubjectRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func subjects() -> AsyncStream<[Subject]> { backend.subjects.stream() }

    func addSubject(_ input: NewSubject) async throws -> AddedSubject {
        try await backend.addSubject(input)
    }

    func setCarriedItems(_ ids: [String]) async throws {
        try await backend.setCarriedItems(ids)
    }

    func history() -> AsyncStream<HistoryLog> { backend.history.stream() }

    /// The mock keeps no archive yet (`MockBackend.restoreSubject` restores
    /// an item handed to it), so an id can't be found.
    func restoreSubject(_ id: String) async throws -> Bool {
        throw SetCarriedError.failed
    }
}

final class MockListRepository: ListRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func currentList() -> AsyncStream<CurrentList?> { backend.list.stream() }
    func myStatus() -> AsyncStream<MyListStatus?> { backend.myStatus.stream() }
}

final class MockUserRepository: UserRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func header() -> AsyncStream<UserHeader?> { backend.header.stream() }

    func setSelfName(_ name: String, avatarTone: Int?) async throws {
        try await backend.setSelfName(name, avatarTone: avatarTone)
    }
}

/// Holds writes on the device until the mock backend takes them: FIFO (a
/// note never overtakes its prayer), after the simulated latency, and only
/// while online (flushed again on reconnect). A stand-in for the offline
/// queue (Data/Queue, next), which will also persist them to disk.
final class MockPrayerRepository: PrayerRepository {
    private enum Write {
        case prayer(NewPrayer)
        case note(prayerId: String, note: String?)
    }

    let backend: MockBackend
    private var queue: [Write] = [] {
        didSet {
            pending.send(queue.compactMap { if case .prayer(let p) = $0 { p } else { nil } })
        }
    }
    private let pending = Watched<[NewPrayer]>([])
    private var flushing = false

    init(backend: MockBackend) {
        self.backend = backend
        backend.onReconnect { [weak self] in self?.flush() }
    }

    func logPrayer(_ prayer: NewPrayer) async {
        queue.append(.prayer(prayer))
        flush()
    }

    func updateNote(prayerId: String, note: String?) async {
        queue.append(.note(prayerId: prayerId, note: note))
        flush()
    }

    func localPrayers() -> AsyncStream<[NewPrayer]> { pending.stream() }

    private func flush() {
        guard !flushing else { return }
        flushing = true
        Task {
            defer { flushing = false }
            while backend.online, !queue.isEmpty {
                try? await Task.sleep(for: backend.latency)
                guard backend.online else { return }
                // Apply, then let go: the backend's rows change before the
                // prayer leaves the device, so the gold never blinks.
                switch queue[0] {
                case .prayer(let prayer): backend.applyPrayer(prayer)
                case .note(let id, let note): backend.applyNote(prayerId: id, note: note)
                }
                queue.removeFirst()
            }
        }
    }
}

final class MockLiveRepository: LiveRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func stats() -> AsyncStream<LiveStats> {
        backend.startLiveDrift()
        return backend.stats.stream()
    }

    func config() -> AsyncStream<AppConfig> { backend.config.stream() }
}

final class MockNetworkRepository: NetworkRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func online() -> AsyncStream<Bool> { backend.connected.stream() }
}
