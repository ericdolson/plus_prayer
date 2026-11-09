import FirebaseCore
import FirebaseDataConnect
import FirebaseFunctions
import Foundation
import PlusPrayerConnector
import PlusPrayerDomain

// The real repositories over the generated SQL Connect SDK and the user
// callables (apps/ios/CLAUDE.md, "Repositories"). Operation names and auth
// come from backend/dataconnect/connector/OPERATIONS.md. They re-read after
// writes (`RemoteData.changed`), so the UI can't tell them from the mock.

/// The reads every screen shares, and who re-reads after a write.
@MainActor
final class RemoteData {
    let backend: FirebaseBackend
    let subjects: RemoteValue<[Subject]>
    let header: RemoteValue<UserHeader>
    let history: RemoteValue<HistoryLog>
    let meta: RemoteValue<CurrentList?>
    private(set) var status: RemoteValue<MyListStatus?>!

    init(backend: FirebaseBackend) {
        self.backend = backend
        let connector = backend.connector
        subjects = RemoteValue("GetMySubjects") {
            _ = try await backend.uid()
            let data = try await serverThenCache { try await connector.getMySubjectsQuery.execute(fetchPolicy: $0) }
            return data.prayerSubjects.map(Self.subject)
        }
        header = RemoteValue("GetMyHeader") {
            let uid = try await backend.uid()
            let data = try await serverThenCache { try await connector.getMyHeaderQuery.execute(fetchPolicy: $0) }
            // No User row yet (the auth trigger hasn't landed) reads as an
            // account with no self name: the name step.
            return data.user.map(Self.header) ?? UserHeader(id: uid)
        }
        history = RemoteValue("History") {
            _ = try await backend.uid()
            // TODO(history paging): one read of up to 1,000 prayers and
            // 5,000 entries covers the beta; page by period when it doesn't.
            let prayers = try await serverThenCache {
                try await connector.getMyPrayerHistoryQuery.execute(fetchPolicy: $0) { $0.limit = 1000 }
            }
            let entries = try await serverThenCache {
                try await connector.getMyListEntriesQuery.execute(fetchPolicy: $0) { $0.limit = 5000 }
            }
            return Self.history(prayers, entries)
        }
        meta = RemoteValue("GetCurrentListMeta") {
            _ = try await backend.uid()
            let data = try await serverThenCache { try await connector.getCurrentListMetaQuery.execute(fetchPolicy: $0) }
            return data.prayerLists.first.flatMap { Self.list($0) }
        }
        status = RemoteValue("GetMyListStatus") { [weak self] in
            guard let list = self?.meta.value ?? nil, let listId = RemoteID.uuid(list.id) else { return nil }
            let data = try await serverThenCache {
                try await connector.getMyListStatusQuery.execute(fetchPolicy: $0, listId: listId)
            }
            return Self.status(list.id, data)
        }
    }

    /// After a write: re-read what it can change.
    func changed(subjects: Bool = true, header: Bool = true, history: Bool = true, list: Bool = true) async {
        await withDiscardingTaskGroup { group in
            if subjects { group.addTask { await self.subjects.refresh() } }
            if header { group.addTask { await self.header.refresh() } }
            if history { group.addTask { await self.history.refresh() } }
            if list {
                group.addTask {
                    await self.meta.refresh()
                    await self.status.refresh()
                }
            }
        }
    }

    // MARK: Mapping (generated types stop here)

    static func subject(_ s: GetMySubjectsQuery.Data.PrayerSubject) -> Subject {
        Subject(id: RemoteID.string(s.id), kind: s.kind == .INTENTION ? .intention : .soul,
                parentId: s.parentId.map(RemoteID.string), publicName: s.publicName, alias: s.personalLabel,
                isSelf: s.isSelf, isCarried: s.isCarried, sortOrder: s.sortOrder, avatarTone: s.avatarTone,
                resolution: s.resolution.flatMap { $0 == .ANSWERED ? .answered : $0 == .RELEASED ? .released : nil },
                resolvedAt: s.resolvedAt?.dateValue(), createdAt: s.createdAt.dateValue(),
                lastPrayed: s.lastPrayed.first.flatMap { RemoteScalars.date($0.prayer.localDate) })
    }

    static func header(_ u: GetMyHeaderQuery.Data.User) -> UserHeader {
        UserHeader(id: u.id, displayName: u.displayName, selfSubjectId: u.selfSubject.first.map { RemoteID.string($0.id) },
                   currentStreak: u.currentStreak, bestStreak: u.bestStreak,
                   lastListLocalDate: u.lastListLocalDate.flatMap(RemoteScalars.date), graceDays: u.graceDays,
                   includeLimit: u.includeLimit, trialStartedAt: u.trialStartedAt?.dateValue(),
                   entitlementExpiresAt: u.entitlementExpiresAt?.dateValue())
    }

    static func list(_ l: GetCurrentListMetaQuery.Data.PrayerList) -> CurrentList? {
        guard let date = RemoteScalars.date(l.listDate) else { return nil }
        return CurrentList(id: RemoteID.string(l.id), listNumber: l.listNumber, listDate: date,
                           isPublished: l.status == "published", soulCount: l.soulCount,
                           intentionCount: l.intentionCount, prayerCount: l.prayerCount,
                           currentFrom: l.currentFrom?.dateValue(), closesAt: l.closesAt?.dateValue(),
                           sealVariant: l.sealVariant)
    }

    static func status(_ listId: String, _ d: GetMyListStatusQuery.Data) -> MyListStatus {
        MyListStatus(listId: listId,
                     entries: d.myEntries.map {
                         ListEntry(subjectId: $0.subject.map { RemoteID.string($0.id) }, publicName: $0.publicName,
                                   isName: $0.kind != .INTENTION, isSelf: $0.subject?.isSelf ?? false)
                     },
                     prayersWithList: d.myPrayersWithList.first?._count ?? 0)
    }

    static func history(_ p: GetMyPrayerHistoryQuery.Data, _ e: GetMyListEntriesQuery.Data) -> HistoryLog {
        HistoryLog(
            prayers: p.prayers.compactMap { prayer in
                guard let day = RemoteScalars.date(prayer.localDate) else { return nil }
                return LoggedPrayer(id: RemoteID.string(prayer.id), startedAt: prayer.startedAt.dateValue(),
                                    localDate: day, durationSeconds: prayer.durationSeconds,
                                    autoSaved: prayer.endedBy == .AUTO, note: prayer.note,
                                    held: Set(prayer.held.map { RemoteID.string($0.id) }))
            },
            entries: e.prayerListEntries.compactMap { entry in
                guard let subject = entry.subject, let date = RemoteScalars.date(entry.list.listDate) else { return nil }
                return LoggedEntry(subjectId: RemoteID.string(subject.id),
                                   list: ListRecord(listId: RemoteID.string(entry.list.id),
                                                    listNumber: entry.list.listNumber, listDate: date,
                                                    prayerCount: entry.list.prayerCount,
                                                    sealVariant: entry.list.sealVariant))
            })
    }
}

// MARK: Subjects

/// getMySubjects, the History log (getMyPrayerHistory + getMyListEntries),
/// and the subject callables.
final class SQLConnectSubjectRepository: SubjectRepository {
    let data: RemoteData
    init(data: RemoteData) { self.data = data }

    func subjects() -> AsyncStream<[Subject]> { data.subjects.stream() }
    func history() -> AsyncStream<HistoryLog> { data.history.stream() }

    func addSubject(_ input: NewSubject) async throws -> AddedSubject {
        var args: [String: Any] = [
            "kind": input.kind == .intention ? "INTENTION" : "SOUL",
            "publicName": input.publicName,
            "carry": input.carry,
            "carryParent": input.carryParent,
        ]
        if let parentId = input.parentId { args["parentId"] = RemoteID.wire(parentId) }
        if let alias = input.alias, !alias.trimmingCharacters(in: .whitespaces).isEmpty { args["personalLabel"] = alias }
        let result: [String: Any]
        do {
            result = try await data.backend.call("addSubject", args)
        } catch {
            throw Self.addError(error)
        }
        guard let rawId = result["id"] as? String, let uuid = RemoteID.uuid(rawId) else { throw AddSubjectError.failed }
        // The tone picked when the sheet opened (the callable doesn't take it).
        if input.kind == .soul, let tone = input.avatarTone {
            _ = try? await data.backend.connector.setSubjectAvatarToneMutation.execute(id: uuid) { $0.avatarTone = tone }
        }
        await data.changed(header: false, history: false, list: false)
        return AddedSubject(id: RemoteID.string(uuid), isCarried: result["isCarried"] as? Bool ?? false,
                            parentCarried: result["parentCarried"] as? Bool,
                            effectivelyCarried: result["effectivelyCarried"] as? Bool ?? false)
    }

    func setCarriedItems(_ ids: [String]) async throws {
        do {
            _ = try await data.backend.call("setCarriedItems", ["carriedIds": ids.map(RemoteID.wire)])
        } catch {
            await data.subjects.refresh()
            throw Self.carryError(error)
        }
        await data.changed(header: false, history: false, list: false)
    }

    func restoreSubject(_ id: String) async throws -> Bool {
        let result: [String: Any]
        do {
            result = try await data.backend.call("restoreSubject", ["id": RemoteID.wire(id)])
        } catch {
            throw Self.carryError(error)
        }
        await data.changed(header: false, list: false)
        return result["isCarried"] as? Bool ?? false
    }

    static func addError(_ error: CallableError) -> AddSubjectError {
        if error.isUnreachable { return .offline }
        switch error.code {
        case .invalidArgument where error.reason == "CONTACT_OR_LINK": return .input(.contactInfo)
        case .resourceExhausted: return .cap
        default: return .failed
        }
    }

    static func carryError(_ error: CallableError) -> SetCarriedError {
        if error.isUnreachable { return .offline }
        switch (error.code, error.reason) {
        case (.failedPrecondition, "OVER_LIMIT"): return .overLimit
        case (.failedPrecondition, "OVER_CAP"): return .overCap
        default: return .failed
        }
    }
}

// MARK: The user

/// getMyHeader and the setSelfName callable.
final class SQLConnectUserRepository: UserRepository {
    let data: RemoteData
    init(data: RemoteData) { self.data = data }

    func header() -> AsyncStream<UserHeader?> {
        let source = data.header.stream()
        return AsyncStream { continuation in
            let task = Task {
                for await value in source { continuation.yield(value) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func setSelfName(_ name: String, avatarTone: Int?) async throws {
        let result: [String: Any]
        do {
            result = try await data.backend.call("setSelfName", ["name": name])
        } catch {
            if error.isUnreachable { throw SelfNameError.offline }
            if error.code == .invalidArgument, error.reason == "CONTACT_OR_LINK" { throw SelfNameError.input(.contactInfo) }
            throw SelfNameError.failed
        }
        await data.changed(history: false, list: false)
        // A new self takes the tone the name screen showed (the callable
        // doesn't take it); best effort, like addSubject's.
        if result["created"] as? Bool == true, let tone = avatarTone,
           let selfId = data.header.value?.selfSubjectId, let uuid = RemoteID.uuid(selfId) {
            _ = try? await data.backend.connector.setSubjectAvatarToneMutation.execute(id: uuid) { $0.avatarTone = tone }
            await data.changed(header: false, history: false, list: false)
        }
    }
}
