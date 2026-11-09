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
    /// History: your prayers (with what each held) and your subjects' list
    /// entries (getMyPrayerHistory + the entries).
    let history: Watched<HistoryLog>

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

    /// Journal entries by prayer id (`updatePrayerNote`).
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
        history = Watched(seed.history)
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
        // The server links each held intention's name too.
        let tree = SubjectTree(subjects.value)
        let held = Set(prayer.subjectIds + prayer.subjectIds.compactMap { tree.parent(of: $0)?.id })
        history.update { $0.prayers.append(LoggedPrayer(id: prayer.id, startedAt: prayer.startedAt,
                                                       localDate: prayer.localDate,
                                                       durationSeconds: prayer.durationSeconds, note: prayer.note,
                                                       held: held)) }

        // The first prayer starts the 14-day reverse trial (onPrayerLogged),
        // unless an entitlement is already active.
        header.update { header in
            guard var next = header, next.trialStartedAt == nil, !hasActiveEntitlement(next, now: now()) else { return }
            next.trialStartedAt = now()
            next.entitlementExpiresAt = now().addingTimeInterval(14 * 86_400)
            next.includeLimit = config.value.basePremiumPool
            header = next
        }

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
        history.update { h in
            for i in h.prayers.indices where h.prayers[i].id == prayerId { h.prayers[i].note = note }
        }
    }

    private var nextId = 1

    /// The addSubject callable, with the server's rules (Q32): text checks,
    /// the cap, the parent must be one of your names, appended at the bottom
    /// of its level. A name is carried while the pool has room. An intention
    /// asked to carry is chosen; at its person's cap it swaps in (the
    /// person's last chosen by order is unchosen). `carryParent` carries
    /// the person too, pool-checked, all or nothing.
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
                              isCarried: false,
                              sortOrder: (level.map(\.sortOrder).max() ?? 0) + 1,
                              avatarTone: input.kind == .soul ? input.avatarTone : nil,
                              createdAt: now())
        nextId += 1
        var updated = current
        let tree = SubjectTree(current)
        let prePool = config.value.basePremiumPool
        if input.carry, let header = header.value {
            if subject.isName {
                subject.isCarried = placesLeft(tree, user: header, now: now(), prePool: prePool) > 0
            } else if let parentId = input.parentId, let parent = tree[parentId] {
                let lift = input.carryParent && !parent.isSelf && !parent.isCarried
                let fits = !lift || placesLeft(tree, user: header, now: now(), prePool: prePool) > 0
                let cap = config.value.intentionsPerPerson
                if fits && cap > 0 {
                    // Chosen; at the cap, a swap.
                    for extra in chosenIntentions(of: parentId, in: tree).dropFirst(cap - 1) {
                        if let i = updated.firstIndex(where: { $0.id == extra.id }) { updated[i].isCarried = false }
                    }
                    subject.isCarried = true
                    if lift, let i = updated.firstIndex(where: { $0.id == parentId }) { updated[i].isCarried = true }
                }
            }
        }
        subjects.send(updated + [subject])
        let parent = updated.first { $0.id == input.parentId }
        return AddedSubject(id: subject.id, isCarried: subject.isCarried, parentCarried: parent?.isCarried,
                            effectivelyCarried: subject.isCarried && (parent.map { $0.isSelf || $0.isCarried } ?? true))
    }

    /// The setCarriedItems callable (Q32): exactly `ids` carried (names) or
    /// chosen (intentions), the self and resolved items aside. Names going
    /// from off to on are pool-checked (`.overLimit`); a person whose chosen
    /// intentions grow must end within the cap (`.overCap`). A swap is never
    /// pool-checked, and a save that only reduces is always accepted
    /// (backend/functions/src/subjects.ts).
    func setCarriedItems(_ ids: [String]) async throws(SetCarriedError) {
        try? await Task.sleep(for: latency)
        guard online else { throw .offline }
        guard !failsAdds else { throw .failed }
        let wanted = Set(ids)
        let proposed = subjects.value.map { subject in
            var subject = subject
            if !subject.isSelf && !subject.isResolved { subject.isCarried = wanted.contains(subject.id) }
            return subject
        }
        let before = SubjectTree(subjects.value)
        let after = SubjectTree(proposed)
        let addsName = proposed.contains { $0.isName && !$0.isSelf && $0.isCarried && before[$0.id]?.isCarried != true }
        if addsName, let header = header.value, !checkPool(after, user: header, now: now(), prePool: config.value.basePremiumPool).fits {
            throw .overLimit
        }
        let cap = config.value.intentionsPerPerson
        for person in after.names {
            let was = Set(chosenIntentions(of: person.id, in: before).map(\.id))
            let chosen = chosenIntentions(of: person.id, in: after)
            if chosen.contains(where: { !was.contains($0.id) }) && chosen.count > cap { throw .overCap }
        }
        subjects.send(proposed)
    }

    /// The setSelfName callable: the first call creates the self ("Me",
    /// always carried) and sets the display name; later calls rename it.
    /// `avatarTone` (SetSubjectAvatarTone after the callable) colors a new
    /// self as onboarding's name screen showed it.
    func setSelfName(_ raw: String, avatarTone: Int? = nil) async throws(SelfNameError) {
        try? await Task.sleep(for: latency)
        guard online else { throw .offline }
        guard !failsAdds else { throw .failed }
        if let issue = validatePrinted(raw, kind: .soul) { throw .input(issue) }
        let name = cleanText(raw)
        if let i = subjects.value.firstIndex(where: \.isSelf) {
            subjects.update { $0[i].publicName = name }
        } else {
            subjects.update { $0.insert(Subject(id: "self", kind: .soul, publicName: name, alias: "Me", isSelf: true,
                                                isCarried: true, sortOrder: 0, avatarTone: avatarTone,
                                                createdAt: now()), at: 0) }
        }
        header.update { header in
            guard var next = header else { return }
            next.displayName = name
            next.selfSubjectId = next.selfSubjectId ?? "self"
            header = next
        }
    }

    /// The restoreSubject callable, for an item the mock holds outside Home
    /// (it has no archive yet): `item` and, for a name, its cascade-archived
    /// `intentions` come back. Pool- and cap-aware like the server: a name
    /// over the pool, or an intention to a person at the cap, comes back
    /// with its own flag off (a name's intentions keep theirs). A Released
    /// intention reopens. Returns the item's flag after.
    @discardableResult
    func restoreSubject(_ item: Subject, intentions: [Subject] = []) async throws(SetCarriedError) -> Bool {
        try? await Task.sleep(for: latency)
        guard online else { throw .offline }
        var restored = item
        if restored.resolution == .released {
            restored.resolution = nil
            restored.resolvedAt = nil
        }
        if let header = header.value {
            restored.isCarried = restoredCarryFlag(restored, intentions: intentions, into: SubjectTree(subjects.value),
                                                   user: header, now: now(), cap: config.value.intentionsPerPerson,
                                                   prePool: config.value.basePremiumPool)
        }
        subjects.send(subjects.value + [restored] + (item.isName ? intentions : []))
        return restored.isCarried
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
        guard let current = list.value else { return }
        history.update { h in
            for i in h.entries.indices where h.entries[i].list.listId == current.id {
                let l = h.entries[i].list
                h.entries[i].list = ListRecord(listId: l.listId, listNumber: l.listNumber, listDate: l.listDate,
                                               prayerCount: l.prayerCount, sealVariant: current.sealVariant)
            }
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
        history.update { h in
            // The closing list settles at its last count.
            for i in h.entries.indices where h.entries[i].list.listId == current.id {
                let l = h.entries[i].list
                h.entries[i].list = ListRecord(listId: l.listId, listNumber: l.listNumber, listDate: l.listDate,
                                               prayerCount: current.prayerCount, sealVariant: current.sealVariant)
            }
            let record = ListRecord(listId: next.id, listNumber: next.listNumber, listDate: next.listDate,
                                    prayerCount: 0)
            h.entries += printed.map { LoggedEntry(subjectId: $0.id, list: record) }
        }
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
