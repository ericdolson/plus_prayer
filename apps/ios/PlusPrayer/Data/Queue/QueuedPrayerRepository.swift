import FirebaseDataConnect
import FirebaseCore
import Foundation
import Network
import PlusPrayerConnector
import PlusPrayerDomain

/// logPrayer / updatePrayerNote through the offline queue (prayer-flow.md: a
/// prayer must succeed with no signal). The prayer is on disk before
/// `logPrayer` returns; `localPrayers` folds it into Home at once and keeps
/// it there until a re-read after the server's reaction (onPrayerLogged:
/// the streak, the list count) has had time to land, so nothing blinks.
final class QueuedPrayerRepository: PrayerRepository {
    private let data: RemoteData
    private var queue: WriteQueue!
    private let unsent = Watched<[NewPrayer]>([])
    private var recentlySent: [NewPrayer] = []
    private let local = Watched<[NewPrayer]>([])
    /// How long a sent prayer stays folded in, and when the reads are re-run
    /// (the emulator sweeper applies a prayer within ~3 s; the trigger in
    /// production within a second or two).
    private let rereads: [Duration] = [.zero, .seconds(4), .seconds(10)]
    private let holdSent: Duration = .seconds(15)

    init(data: RemoteData, store: any QueueStore = FileQueueStore.standard()) {
        self.data = data
        let backend = data.backend
        queue = WriteQueue(
            store: store,
            send: { write in await Self.send(write, backend: backend) },
            onChange: { [weak self] writes in
                let prayers = writes.compactMap(\.write.prayer)
                await MainActor.run { self?.setUnsent(prayers) }
            },
            onSent: { [weak self] write in
                await self?.didSend(write)
            })
        Task { await queue.flush() } // what an earlier launch left
    }

    func logPrayer(_ prayer: NewPrayer) async {
        // Folded in before the write is even persisted, so Amen's gold is instant.
        setUnsent(unsent.value + [prayer])
        await queue.enqueue(.logPrayer(prayer))
    }

    func updateNote(prayerId: String, note: String?) async {
        await queue.enqueue(.updateNote(prayerId: prayerId, note: note))
    }

    func localPrayers() -> AsyncStream<[NewPrayer]> { local.stream() }

    /// Sends what's waiting (launch, the scene becoming active, reconnect).
    func flush() async { await queue.flush() }

    private func setUnsent(_ prayers: [NewPrayer]) {
        unsent.send(prayers)
        publish()
    }

    private func publish() {
        var seen = Set<String>()
        local.send((unsent.value + recentlySent).filter { seen.insert($0.id).inserted })
    }

    private func didSend(_ write: PendingWrite) async {
        guard let prayer = write.prayer else {
            await data.changed(subjects: false, header: false, list: false) // a note: History only
            return
        }
        recentlySent.append(prayer)
        publish()
        Task {
            for (index, delay) in rereads.enumerated() {
                let previous = index == 0 ? .zero : rereads[index - 1]
                try? await Task.sleep(for: delay - previous)
                await data.changed()
            }
            try? await Task.sleep(for: holdSent - rereads.last!)
            recentlySent.removeAll { $0.id == prayer.id }
            publish()
        }
    }

    /// One write to SQL Connect. A server refusal (a failed `@check`, a bad
    /// variable) is permanent; anything else (no connection, the emulators
    /// down) is retried.
    private static func send(_ write: PendingWrite, backend: FirebaseBackend) async -> SendOutcome {
        do {
            _ = try await backend.uid()
        } catch {
            return .retry
        }
        let connector = backend.connector
        do {
            switch write {
            case .logPrayer(let p):
                guard let id = RemoteID.uuid(p.id) else { return .drop(reason: "prayer id isn't a UUID") }
                let listId = p.communityListId.flatMap(RemoteID.uuid)
                let note = p.note
                _ = try await connector.logPrayerMutation.execute(
                    id: id, startedAt: Timestamp(date: p.startedAt), prayedAt: Timestamp(date: p.prayedAt),
                    durationSeconds: p.durationSeconds, localDate: try RemoteScalars.local(p.localDate),
                    timezone: p.timezone, listContextNumber: p.listContextNumber,
                    subjectIds: p.subjectIds.compactMap(RemoteID.uuid)
                ) { vars in
                    // Always set, null included: a native SQL param over an
                    // unset variable fails ("Failed to compute Any_SQL_Expr").
                    vars.communityListId = listId
                    vars.note = note
                }
            case .updateNote(let prayerId, let note):
                guard let id = RemoteID.uuid(prayerId) else { return .drop(reason: "prayer id isn't a UUID") }
                _ = try await connector.updatePrayerNoteMutation.execute(id: id) { $0.note = note }
            }
            return .sent
        } catch let error as DataConnectOperationError {
            return .drop(reason: error.description)
        } catch let error as DataConnectCodecError {
            return .drop(reason: error.description)
        } catch {
            return .retry
        }
    }
}

/// Whether the device can reach the network (NWPathMonitor). On reconnect
/// the queue flushes and the reads are re-run.
final class PathNetworkRepository: NetworkRepository {
    private let monitor = NWPathMonitor()
    private let state = Watched(true)
    private var reconnect: [@MainActor () async -> Void] = []

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.update(online) }
        }
        monitor.start(queue: DispatchQueue(label: "dev.hammock.plusprayer.network"))
    }

    deinit { monitor.cancel() }

    func online() -> AsyncStream<Bool> { state.stream() }

    func onReconnect(_ action: @escaping @MainActor () async -> Void) { reconnect.append(action) }

    private func update(_ online: Bool) {
        let was = state.value
        state.send(online)
        if online && !was { for action in reconnect { Task { await action() } } }
    }
}
