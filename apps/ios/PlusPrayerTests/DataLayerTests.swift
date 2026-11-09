import Foundation
import PlusPrayerDomain
import Testing
@testable import PlusPrayer

/// The offline write queue (with a fake file store), the environment choice,
/// ids at the boundary, `/config` parsing, and the name step on the mock.

/// An in-memory QueueStore that records every save.
final class MemoryQueueStore: QueueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [QueuedWrite]
    private(set) var saves: [[QueuedWrite]] = []

    init(_ writes: [QueuedWrite] = []) { stored = writes }

    func load() throws -> [QueuedWrite] { lock.withLock { stored } }
    func save(_ writes: [QueuedWrite]) throws {
        lock.withLock {
            stored = writes
            saves.append(writes)
        }
    }
    var current: [QueuedWrite] { lock.withLock { stored } }
}

/// A scripted server: answers each send with the next outcome (default sent).
actor FakeServer {
    private(set) var received: [PendingWrite] = []
    private var outcomes: [SendOutcome]
    private var store: MemoryQueueStore?

    init(_ outcomes: [SendOutcome] = []) { self.outcomes = outcomes }

    /// What the store held when each write was sent (persisted before sending?).
    private(set) var persistedAtSend: [Bool] = []
    func watch(_ store: MemoryQueueStore) { self.store = store }

    func send(_ write: PendingWrite) -> SendOutcome {
        received.append(write)
        persistedAtSend.append(store?.current.contains { $0.write == write } ?? false)
        return outcomes.isEmpty ? .sent : outcomes.removeFirst()
    }
}

private func prayer(_ id: String, note: String? = nil) -> NewPrayer {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    return NewPrayer(id: id, startedAt: start, prayedAt: start.addingTimeInterval(60),
                     localDate: LocalDate(year: 2026, month: 11, day: 8), timezone: "America/Denver",
                     communityListId: "list", listContextNumber: 70, subjectIds: ["a"], note: note)
}

struct WriteQueueTests {
    @Test func persistsBeforeSendingAndSendsInOrder() async {
        let store = MemoryQueueStore()
        let server = FakeServer()
        await server.watch(store)
        let queue = WriteQueue(store: store, send: { await server.send($0) })
        await queue.enqueue(.logPrayer(prayer("p1")))
        await queue.enqueue(.updateNote(prayerId: "p1", note: "A quiet morning."))
        #expect(await server.received == [.logPrayer(prayer("p1")), .updateNote(prayerId: "p1", note: "A quiet morning.")])
        #expect(await server.persistedAtSend == [true, true], "on disk before it's sent")
        #expect(store.current.isEmpty)
        #expect(await queue.pending.isEmpty)
    }

    @Test func aTransientFailureKeepsTheWriteAndEverythingBehindIt() async {
        let store = MemoryQueueStore()
        // Offline: the prayer fails, and again when the note's enqueue retries it.
        let server = FakeServer([.retry, .retry])
        let queue = WriteQueue(store: store, send: { await server.send($0) }, backoff: { _ in .seconds(3600) })
        await queue.enqueue(.logPrayer(prayer("p1")))
        await queue.enqueue(.updateNote(prayerId: "p1", note: "later"))
        // The note never overtook its prayer: only the prayer was tried.
        #expect(await server.received == [.logPrayer(prayer("p1")), .logPrayer(prayer("p1"))])
        #expect(store.current.map(\.write) == [.logPrayer(prayer("p1")), .updateNote(prayerId: "p1", note: "later")])
        #expect(store.current.first?.attempts == 2)

        // Reconnect: the flush sends both, in order.
        await queue.flush()
        #expect(await server.received.suffix(2) == [.logPrayer(prayer("p1")), .updateNote(prayerId: "p1", note: "later")])
        #expect(store.current.isEmpty)
    }

    @Test func aPermanentFailureIsDroppedSoItCantBlockTheQueue() async {
        let store = MemoryQueueStore()
        let server = FakeServer([.drop(reason: "invalid-argument")])
        let queue = WriteQueue(store: store, send: { await server.send($0) })
        await queue.enqueue(.logPrayer(prayer("bad")))
        await queue.enqueue(.logPrayer(prayer("good")))
        #expect(await server.received == [.logPrayer(prayer("bad")), .logPrayer(prayer("good"))])
        #expect(store.current.isEmpty)
    }

    @Test func whatAnEarlierLaunchLeftIsSentOnFlush() async {
        let left = [QueuedWrite(id: UUID(), write: .logPrayer(prayer("p0")))]
        let store = MemoryQueueStore(left)
        let server = FakeServer()
        let queue = WriteQueue(store: store, send: { await server.send($0) })
        #expect(await queue.pending == left)
        await queue.flush()
        #expect(await server.received == [.logPrayer(prayer("p0"))])
    }

    @Test func theFileStoreRoundTripsAndIsExcludedFromBackup() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true).appendingPathComponent("write-queue.json")
        let store = FileQueueStore(url: url)
        #expect(try store.load().isEmpty)
        let writes = [QueuedWrite(id: UUID(), write: .logPrayer(prayer("p1", note: "x"))),
                      QueuedWrite(id: UUID(), write: .updateNote(prayerId: "p1", note: nil), attempts: 2)]
        try store.save(writes)
        #expect(try store.load() == writes)
        #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
    }
}

@MainActor
struct EnvironmentChoiceTests {
    private func defaults(_ args: [String: String]) -> UserDefaults {
        let suite = "pp-tests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.setVolatileDomain(args, forName: UserDefaults.argumentDomain)
        return d
    }

    @Test func debugDefaultsToTheMock() {
        #expect(AppEnvironment.resolve(defaults([:]), underTests: false).kind == .mock)
    }

    @Test func anExplicitChoiceIsRememberedWithItsHost() {
        let d = defaults(["PPEnvironment": "emulator", "PPEmulatorHost": "192.168.1.20"])
        let first = AppEnvironment.resolve(d, underTests: false)
        #expect(first.kind == .emulator)
        #expect(first.host == "192.168.1.20")
        // Opened later from the Home Screen: no arguments.
        d.setVolatileDomain([:], forName: UserDefaults.argumentDomain)
        let later = AppEnvironment.resolve(d, underTests: false)
        #expect(later.kind == .emulator)
        #expect(later.host == "192.168.1.20")
        // Back to the mock, once.
        d.setVolatileDomain(["PPEnvironment": "mock"], forName: UserDefaults.argumentDomain)
        #expect(AppEnvironment.resolve(d, underTests: false).kind == .mock)
        d.setVolatileDomain([:], forName: UserDefaults.argumentDomain)
        #expect(AppEnvironment.resolve(d, underTests: false).kind == .mock)
    }

    @Test func theSimulatorFallsBackToLocalhost() {
        #expect(AppEnvironment.resolve(defaults(["PPEnvironment": "emulator"]), underTests: false).host == "127.0.0.1")
    }

    @Test func underTestsOnlyAnExplicitArgumentCounts() {
        let d = defaults(["PPEnvironment": "emulator"])
        _ = AppEnvironment.resolve(d, underTests: false) // remembered
        d.setVolatileDomain([:], forName: UserDefaults.argumentDomain)
        #expect(AppEnvironment.resolve(d, underTests: true).kind == .mock)
    }
}

struct BoundaryTests {
    @Test func idsMatchAcrossForms() {
        let dashed = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
        let wire = "e621e1f8c36c495a93fc0c247a3e6e5f"
        #expect(RemoteID.wire(dashed) == wire)
        #expect(RemoteID.uuid(wire)?.uuidString == dashed)
        #expect(RemoteID.same(dashed, wire))
        #expect(RemoteID.uuid("self") == nil)
    }

    @Test func configKeepsDefaultsForMissingOrMistypedKeys() {
        let c = RTDBLiveRepository.config(["intentionsPerPerson": 2, "basePremiumPool": "ten", "graceCap": 3])
        #expect(c.intentionsPerPerson == 2)
        #expect(c.graceCap == 3)
        #expect(c.basePremiumPool == AppConfig.defaults.basePremiumPool)
    }
}

@MainActor
struct NameStepModelTests {
    @Test func noSelfNameMeansTheNameStepAndSetSelfNameEndsIt() async throws {
        let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
        backend.header.update { $0?.displayName = nil; $0?.selfSubjectId = nil }
        let home = HomeModel(environment: .mock(backend))
        let running = Task { await home.run() }
        defer { running.cancel() }
        try await waitFor { home.needsSelfName }
        try await home.setSelfName("  Ann   Lee ")
        try await waitFor { !home.needsSelfName }
        #expect(backend.header.value?.displayName == "Ann Lee")
        #expect(backend.subjects.value.first { $0.isSelf }?.publicName == "Ann Lee")
    }

    @Test func theSeededMockNeverShowsIt() async throws {
        let home = HomeModel(environment: .mock(MockBackend(latency: .milliseconds(1), liveDrift: false)))
        let running = Task { await home.run() }
        defer { running.cancel() }
        try await waitFor { home.isLoaded }
        #expect(!home.needsSelfName)
    }

    @Test func contactInfoAndOfflineComeBackAsTheirErrors() async {
        let backend = MockBackend(latency: .milliseconds(1), liveDrift: false)
        let home = HomeModel(environment: .mock(backend))
        await #expect(throws: SelfNameError.input(.contactInfo)) { try await home.setSelfName("call 555-123-4567") }
        backend.online = false
        await #expect(throws: SelfNameError.offline) { try await home.setSelfName("Ann") }
    }

    private func waitFor(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }
}
