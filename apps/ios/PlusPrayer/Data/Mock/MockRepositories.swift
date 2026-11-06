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
                     live: MockLiveRepository(backend: backend))
    }
}

final class MockSubjectRepository: SubjectRepository {
    let backend: MockBackend
    init(backend: MockBackend) { self.backend = backend }

    func subjects() -> AsyncStream<[Subject]> { backend.subjects.stream() }
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
}

/// Holds prayers on the device until the mock backend takes them: FIFO,
/// after the simulated latency, and only while online (flushed again on
/// reconnect). A stand-in for the offline queue (Data/Queue, next), which
/// will also persist them to disk.
final class MockPrayerRepository: PrayerRepository {
    let backend: MockBackend
    private let pending = Watched<[NewPrayer]>([])
    private var flushing = false

    init(backend: MockBackend) {
        self.backend = backend
        backend.onReconnect { [weak self] in self?.flush() }
    }

    func logPrayer(_ prayer: NewPrayer) async {
        pending.update { $0.append(prayer) }
        flush()
    }

    func localPrayers() -> AsyncStream<[NewPrayer]> { pending.stream() }

    private func flush() {
        guard !flushing else { return }
        flushing = true
        Task {
            defer { flushing = false }
            while backend.online, let next = pending.value.first {
                try? await Task.sleep(for: backend.latency)
                guard backend.online else { return }
                // Same turn: the backend's rows and the pending list change
                // together, so Home never flickers between them.
                backend.applyPrayer(next)
                pending.update { $0.removeAll { $0.id == next.id } }
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
