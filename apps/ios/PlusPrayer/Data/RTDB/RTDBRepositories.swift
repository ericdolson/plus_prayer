import FirebaseDatabase
import Foundation
import PlusPrayerDomain

// RTDB (backend/functions/src/live.ts): server-written, public-read nodes
// the app subscribes to while it runs.
//   /lists/current  { listId (32 hex), listNumber, prayerCount, closesAt ms|null }
//   /stats/live     { prayingNow, prayedLastHour, prayedToday, updatedAt }
//   /config         client-visible tunables over the compiled-in defaults

/// One RTDB node, observed for as long as anyone watches.
@MainActor
final class RTDBNode<Value: Sendable> {
    private let ref: DatabaseReference
    private let parse: @Sendable (Any?) -> Value
    private let store: Watched<Value>
    private var handle: DatabaseHandle?

    init(_ ref: DatabaseReference, initial: Value, parse: @escaping @Sendable (Any?) -> Value) {
        self.ref = ref
        self.parse = parse
        store = Watched(initial)
    }

    var value: Value { store.value }

    func stream() -> AsyncStream<Value> {
        if handle == nil {
            let parse = self.parse
            handle = ref.observe(.value) { [weak self] snapshot in
                let value = parse(snapshot.value)
                MainActor.assumeIsolated { self?.store.send(value) }
            }
        }
        return store.stream()
    }
}

/// The live count and cutoff of the current list.
nonisolated struct LiveCurrentList: Sendable, Equatable {
    let listId: String
    let listNumber: Int
    let prayerCount: Int
    let closesAt: Date?

    static func parse(_ value: Any?) -> LiveCurrentList? {
        guard let dict = value as? [String: Any], let listId = dict["listId"] as? String,
              let number = (dict["listNumber"] as? NSNumber)?.intValue else { return nil }
        return LiveCurrentList(listId: listId, listNumber: number,
                               prayerCount: (dict["prayerCount"] as? NSNumber)?.intValue ?? 0,
                               closesAt: (dict["closesAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) })
    }
}

/// getCurrentListMeta merged with RTDB `/lists/current` (the live count and
/// closesAt), and getMyListStatus for the current list.
final class FirebaseListRepository: ListRepository {
    let data: RemoteData
    private let live: RTDBNode<LiveCurrentList?>
    private let merged = Watched<CurrentList?>(nil)
    private var started = false

    init(data: RemoteData) {
        self.data = data
        live = RTDBNode(data.backend.database.reference(withPath: "lists/current"), initial: nil,
                        parse: LiveCurrentList.parse)
    }

    func currentList() -> AsyncStream<CurrentList?> {
        start()
        return merged.stream()
    }

    func myStatus() -> AsyncStream<MyListStatus?> {
        start()
        return data.status.stream()
    }

    private func start() {
        guard !started else { return }
        started = true
        let metaStream = data.meta.stream()
        let liveStream = live.stream()
        _ = data.status.stream() // reads once the list is known
        Task {
            for await meta in metaStream {
                merge(meta, live.value)
                await data.status.refresh()
            }
        }
        Task {
            for await value in liveStream {
                merge(data.meta.value ?? nil, value)
                // The list flipped (N+1 is current): read its metadata.
                if let value, let meta = data.meta.value ?? nil, value.listNumber > meta.listNumber {
                    await data.meta.refresh()
                }
            }
        }
    }

    private func merge(_ meta: CurrentList?, _ live: LiveCurrentList?) {
        guard var list = meta else { return merged.send(nil) }
        if let live, RemoteID.same(live.listId, list.id) {
            // Postgres is the counter; RTDB mirrors it ahead of a re-read.
            list.prayerCount = max(list.prayerCount, live.prayerCount)
            if let closesAt = live.closesAt { list.closesAt = closesAt }
        }
        merged.send(list)
    }
}

/// RTDB `/stats/live` and `/config`.
final class RTDBLiveRepository: LiveRepository {
    private let statsNode: RTDBNode<LiveStats>
    private let configNode: RTDBNode<AppConfig>

    init(database: Database) {
        statsNode = RTDBNode(database.reference(withPath: "stats/live"), initial: .empty) { value in
            let dict = value as? [String: Any] ?? [:]
            func int(_ key: String) -> Int { (dict[key] as? NSNumber)?.intValue ?? 0 }
            return LiveStats(prayingNow: int("prayingNow"), prayedLastHour: int("prayedLastHour"),
                             prayedToday: int("prayedToday"))
        }
        configNode = RTDBNode(database.reference(withPath: "config"), initial: .defaults) { value in
            Self.config(value as? [String: Any] ?? [:])
        }
    }

    func stats() -> AsyncStream<LiveStats> { statsNode.stream() }
    func config() -> AsyncStream<AppConfig> { configNode.stream() }

    /// `/config` over the compiled-in defaults; a missing or mistyped key
    /// keeps its default (as the server's resolveClientConfig does).
    nonisolated static func config(_ d: [String: Any]) -> AppConfig {
        var c = AppConfig.defaults
        func int(_ key: String) -> Int? { (d[key] as? NSNumber)?.intValue }
        if let v = int("graceCap") { c.graceCap = v }
        if let v = int("graceIntervalDays") { c.graceIntervalDays = v }
        if let v = int("presenceDisplayThreshold") { c.presenceDisplayThreshold = v }
        if let v = d["minAppVersion"] as? String { c.minAppVersion = v }
        if let v = int("minPrayerSeconds") { c.minPrayerSeconds = v }
        if let v = int("draftResumeMinutes") { c.draftResumeMinutes = v }
        if let v = int("autoSaveHours") { c.autoSaveHours = v }
        if let v = int("durationCapHours") { c.durationCapHours = v }
        if let v = int("basePremiumPool") { c.basePremiumPool = v }
        if let v = int("intentionsPerPerson") { c.intentionsPerPerson = v }
        return c
    }
}
