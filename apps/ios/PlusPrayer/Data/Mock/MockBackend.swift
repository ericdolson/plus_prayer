import Foundation
import PlusPrayerDomain

/// An in-memory stand-in for SQL Connect, the callables and RTDB, applying
/// the rules the server applies (through PlusPrayerDomain). The mock
/// repositories are views over it. No Firebase calls.
///
/// Scenario controls for debugging and tests: go offline (`online`), move
/// the clock (`advanceClock`), close, flip and seal the list, set the live
/// counts.
@MainActor
final class MockBackend {
    let subjects: Watched<[Subject]>
    let header: Watched<UserHeader?>
    let list: Watched<CurrentList?>
    let myStatus: Watched<MyListStatus?>
    let stats: Watched<LiveStats>
    let config = Watched(AppConfig.defaults)

    /// Simulated network latency for writes.
    let latency: Duration
    /// Nudge the live counts now and then, as `/stats/live` does.
    private let liveDrift: Bool
    private var driftTask: Task<Void, Never>?

    /// Off → writes wait on the device (the queue's job) until it's back on,
    /// and online-only commands fail.
    var online = true {
        didSet {
            connected.send(online)
            if online && !oldValue { reconnectHandlers.forEach { $0() } }
        }
    }
    let connected = Watched(true)
    private var reconnectHandlers: [() -> Void] = []

    /// Prayer notes by prayer id (`updatePrayerNote`).
    private(set) var notes: [String: String] = [:]

    /// The mock's "now": real time plus whatever the clock was advanced by.
    private var clockOffset: TimeInterval = 0
    private var loggedPrayerIds: Set<String> = []

    init(seed: MockSeed? = nil, latency: Duration = .milliseconds(250), liveDrift: Bool = true) {
        let seed = seed ?? MockSeed.standard(now: .now)
        subjects = Watched(seed.subjects)
        header = Watched(seed.header)
        list = Watched(seed.list)
        myStatus = Watched(seed.myStatus)
        stats = Watched(seed.stats)
        self.latency = latency
        self.liveDrift = liveDrift
    }

    func now() -> Date { Date.now.addingTimeInterval(clockOffset) }

    /// Moves the mock's clock forward (past midnight, past a cutoff).
    func advanceClock(by interval: TimeInterval) { clockOffset += interval }

    func onReconnect(_ handler: @escaping () -> Void) { reconnectHandlers.append(handler) }

    // MARK: Writes

    /// logPrayer + onPrayerLogged; idempotent by id, like the server.
    func applyPrayer(_ prayer: NewPrayer) {
        guard loggedPrayerIds.insert(prayer.id).inserted else { return }
        notes[prayer.id] = prayer.note
        subjects.send(subjectsWithLocalPrayers(subjects.value, [prayer]))

        guard prayer.includesList else { return }
        header.update { $0 = $0.map { afterListPrayer($0, on: prayer.localDate) } }
        guard let current = list.value, prayer.communityListId == current.id,
              current.closesAt.map({ prayer.startedAt < $0 }) ?? true else { return }
        list.update { $0?.prayerCount += 1 }
        if myStatus.value?.listId == current.id {
            myStatus.update { $0?.prayersWithList += 1 }
        }
    }

    /// updatePrayerNote: note only, and only for a prayer the server has.
    func applyNote(prayerId: String, note: String?) {
        guard loggedPrayerIds.contains(prayerId) else { return }
        notes[prayerId] = note
    }

    private var nextId = 1

    /// The addSubject callable, with the server's rules: text checks, the
    /// cap, the parent must be one of your names, appended at the bottom of
    /// its level, carried when asked while the pool has room (with its name,
    /// when asked: `carryParent`).
    func addSubject(_ input: NewSubject) async throws(AddSubjectError) -> AddedSubject {
        try? await Task.sleep(for: latency)
        guard online else { throw .offline }
        guard !failsAdds else { throw .failed }
        if let issue = validatePrinted(input.publicName, kind: input.kind)
            ?? (input.kind == .soul ? validateAlias(input.alias) : nil) {
            throw .input(issue)
        }
        let current = subjects.value
        guard current.count < subjectCap else { throw .cap }
        if input.kind == .intention {
            guard let parentId = input.parentId, current.contains(where: { $0.id == parentId && $0.isName }) else {
                throw .input(.empty)
            }
        }
        let level = current.filter { !$0.isSelf && $0.parentId == input.parentId }
        let alias = input.alias.map(cleanText).flatMap { $0.isEmpty ? nil : $0 }
        var subject = Subject(id: "m\(nextId)", kind: input.kind, parentId: input.parentId,
                              publicName: cleanText(input.publicName),
                              alias: input.kind == .soul ? alias : nil,
                              isCarried: true,
                              sortOrder: (level.map(\.sortOrder).max() ?? 0) + 1,
                              avatarTone: input.kind == .soul ? input.avatarTone : nil,
                              createdAt: now())
        nextId += 1
        var updated = current
        if !input.carry {
            subject.isCarried = false
        } else if let header = header.value {
            if input.carryParent, let index = updated.firstIndex(where: { $0.id == input.parentId }) {
                updated[index].isCarried = true
            }
            subject.isCarried = checkPool(SubjectTree(updated + [subject]), user: header, now: now()).fits
            if !subject.isCarried { updated = current }
        }
        subjects.send(updated + [subject])
        let parent = updated.first { $0.id == input.parentId }
        return AddedSubject(id: subject.id, isCarried: subject.isCarried, parentCarried: parent?.isCarried,
                            effectivelyCarried: subject.isCarried && (parent.map { $0.isSelf || $0.isCarried } ?? true))
    }

    // MARK: Scenario controls

    /// addSubject fails as the server would for anything unexpected (or the
    /// quiet hard cap).
    var failsAdds = false

    /// Sets the list's cutoff, as closeList does (mirrored to RTDB).
    func setClosesAt(_ closesAt: Date?) {
        list.update { $0?.closesAt = closesAt }
    }

    /// Seals the current list in its weekday's wax, or takes it back to
    /// "being filmed".
    func setSealed(_ sealed: Bool) {
        list.update {
            guard var current = $0 else { return }
            current.isPublished = sealed
            current.sealVariant = sealed ? current.listDate.weekdayFromSunday : nil
            $0 = current
        }
    }

    /// The morning routine, compressed: the current list closes, the next one
    /// becomes current (unsealed until its video). If you prayed with the
    /// closing list, you and your carried names are printed on the new one.
    func flipList() {
        guard let current = list.value else { return }
        let covered = (myStatus.value?.prayersWithList ?? 0) > 0
        let next = CurrentList(id: "list-\(current.nextListNumber)", listNumber: current.nextListNumber,
                               listDate: current.listDate.adding(days: 1), isPublished: false,
                               soulCount: current.soulCount + 37, intentionCount: current.intentionCount + 9,
                               prayerCount: 0, currentFrom: now())
        let tree = SubjectTree(subjects.value)
        let printed = covered ? carriedNames(tree).flatMap { name in
            [name] + tree.intentions(of: name.id).filter { isEffectivelyCarried($0, in: tree) }
        } : []
        list.send(next)
        myStatus.send(MyListStatus(listId: next.id, entries: printed.map {
            ListEntry(subjectId: $0.id, publicName: $0.publicName, isName: $0.isName, isSelf: $0.isSelf)
        }))
    }

    func setStats(_ next: LiveStats) { stats.send(next) }

    /// Starts the live counts drifting (once), while the app runs.
    func startLiveDrift() {
        guard liveDrift, driftTask == nil else { return }
        driftTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                guard let self else { return }
                let s = self.stats.value
                self.setStats(LiveStats(prayingNow: max(0, s.prayingNow + Int.random(in: -3...3)),
                                        prayedLastHour: s.prayedLastHour + Int.random(in: 0...2),
                                        prayedToday: s.prayedToday + Int.random(in: 0...2)))
            }
        }
    }
}
