import Foundation

// The app's own types (apps/ios/CLAUDE.md, "Layers"): repositories map the
// generated connector and RTDB shapes into these at their boundary. Field
// names follow the schema (backend/dataconnect/schema/schema.gql) unless a
// comment says otherwise.

// MARK: Subjects

/// A name ("soul": person, group, cause) or an intention (a request under a name).
public enum SubjectKind: String, Sendable, Codable {
    case soul, intention
}

public enum Resolution: String, Sendable, Codable {
    case answered, released
}

/// A `PrayerSubject` as Home sees it (getMySubjects).
public struct Subject: Sendable, Hashable, Identifiable {
    public let id: String
    public let kind: SubjectKind
    /// The intention's name; nil for a name.
    public let parentId: String?
    /// The printed text.
    public var publicName: String
    /// Owner-only alias (`personalLabel`); the self's is "Me".
    public var alias: String?
    public var isSelf: Bool
    /// The user's own choice to print it. Effective carry also needs the
    /// parent name carried (`isEffectivelyCarried`).
    public var isCarried: Bool
    public var sortOrder: Int
    /// Palette index; nil = the default from the id hash (`defaultAvatarTone`).
    public var avatarTone: Int?
    public var resolution: Resolution?
    public var resolvedAt: Date?
    public let createdAt: Date
    /// Local date of the user's latest prayer that held it.
    public var lastPrayed: LocalDate?

    public init(id: String, kind: SubjectKind, parentId: String? = nil, publicName: String,
                alias: String? = nil, isSelf: Bool = false, isCarried: Bool = false, sortOrder: Int,
                avatarTone: Int? = nil, resolution: Resolution? = nil, resolvedAt: Date? = nil,
                createdAt: Date, lastPrayed: LocalDate? = nil) {
        precondition((kind == .intention) == (parentId != nil), "An intention needs a name; a name has none")
        self.id = id
        self.kind = kind
        self.parentId = parentId
        self.publicName = publicName
        self.alias = alias
        self.isSelf = isSelf
        self.isCarried = isCarried
        self.sortOrder = sortOrder
        self.avatarTone = avatarTone
        self.resolution = resolution
        self.resolvedAt = resolvedAt
        self.createdAt = createdAt
        self.lastPrayed = lastPrayed
    }

    public var isName: Bool { kind == .soul }
    public var isIntention: Bool { kind == .intention }
    public var isResolved: Bool { resolution != nil }

    /// What the owner sees in their own list: the alias if set.
    public var label: String {
        if let alias, !alias.trimmingCharacters(in: .whitespaces).isEmpty { return alias }
        return publicName
    }

    /// The avatar's palette index: the user's pick, else the id hash.
    public var tone: Int { avatarTone ?? defaultAvatarTone(id: id) }
}

// MARK: The list

/// The current daily list: getCurrentListMeta, with the live `prayerCount`
/// and `closesAt` from RTDB `/lists/current`. Never names.
public struct CurrentList: Sendable, Hashable, Identifiable {
    public let id: String
    public let listNumber: Int
    public let listDate: LocalDate
    /// status == "published".
    public var isPublished: Bool
    /// People on the list ("Hold the 4,345 on List 52").
    public var soulCount: Int
    public var intentionCount: Int
    public var prayerCount: Int
    public var currentFrom: Date?
    /// The exact cutoff. A prayer counts for this list if it STARTED before it.
    public var closesAt: Date?
    /// 0 = Sunday … 6 = Saturday; nil = unsealed ("being filmed").
    public var sealVariant: Int?

    public init(id: String, listNumber: Int, listDate: LocalDate, isPublished: Bool, soulCount: Int,
                intentionCount: Int, prayerCount: Int, currentFrom: Date? = nil, closesAt: Date? = nil,
                sealVariant: Int? = nil) {
        self.id = id
        self.listNumber = listNumber
        self.listDate = listDate
        self.isPublished = isPublished
        self.soulCount = soulCount
        self.intentionCount = intentionCount
        self.prayerCount = prayerCount
        self.currentFrom = currentFrom
        self.closesAt = closesAt
        self.sealVariant = sealVariant
    }

    /// The list a prayer with this one carries you onto.
    public var nextListNumber: Int { listNumber + 1 }
}

/// getMyListStatus for one list: which of yours are printed on it, and
/// whether you've prayed with it (the gate for the next list).
public struct MyListStatus: Sendable, Hashable {
    public let listId: String
    public var entries: [ListEntry]
    /// Your prayers with `communityList` = this list.
    public var prayersWithList: Int

    public init(listId: String, entries: [ListEntry] = [], prayersWithList: Int = 0) {
        self.listId = listId
        self.entries = entries
        self.prayersWithList = prayersWithList
    }
}

/// One of your entries on a printed list. `subjectId` is nil when the subject
/// was deleted after printing (the entry keeps its printed name).
public struct ListEntry: Sendable, Hashable {
    public let subjectId: String?
    public let publicName: String
    public let isName: Bool
    public let isSelf: Bool

    public init(subjectId: String?, publicName: String, isName: Bool, isSelf: Bool = false) {
        self.subjectId = subjectId
        self.publicName = publicName
        self.isName = isName
        self.isSelf = isSelf
    }
}

// MARK: The user

/// getMyHeader: the signed-in user's stored fields. Display values (the
/// effective streak, "prayed with the list today") come from `Streak.swift`.
public struct UserHeader: Sendable, Hashable {
    public let id: String
    /// nil until setSelfName: onboarding resumes at "What's your name?".
    public var displayName: String?
    public var selfSubjectId: String?
    public var currentStreak: Int
    public var bestStreak: Int
    /// The last local day the user prayed WITH THE LIST.
    public var lastListLocalDate: LocalDate?
    public var graceDays: Int
    /// Pool size beyond the self name, in people (Q32), while an
    /// entitlement is active.
    public var includeLimit: Int
    public var trialStartedAt: Date?
    public var entitlementExpiresAt: Date?

    public init(id: String, displayName: String? = nil, selfSubjectId: String? = nil, currentStreak: Int = 0,
                bestStreak: Int = 0, lastListLocalDate: LocalDate? = nil, graceDays: Int = 0,
                includeLimit: Int = 0, trialStartedAt: Date? = nil, entitlementExpiresAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.selfSubjectId = selfSubjectId
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastListLocalDate = lastListLocalDate
        self.graceDays = graceDays
        self.includeLimit = includeLimit
        self.trialStartedAt = trialStartedAt
        self.entitlementExpiresAt = entitlementExpiresAt
    }

    public var hasSelfName: Bool { displayName != nil && selfSubjectId != nil }
}

// MARK: Live (RTDB)

/// RTDB `/stats/live` (server-written, public-read).
public struct LiveStats: Sendable, Hashable {
    /// People (not devices) in prayer right now.
    public var prayingNow: Int
    public var prayedLastHour: Int
    public var prayedToday: Int

    public static let empty = LiveStats(prayingNow: 0, prayedLastHour: 0, prayedToday: 0)

    public init(prayingNow: Int, prayedLastHour: Int, prayedToday: Int) {
        self.prayingNow = prayingNow
        self.prayedLastHour = prayedLastHour
        self.prayedToday = prayedToday
    }
}

/// RTDB `/config` over these compiled-in defaults (schema-brief §5; the same
/// values as backend/functions/config/client-config.json).
public struct AppConfig: Sendable, Hashable {
    public var graceCap = 2
    public var graceIntervalDays = 7
    public var presenceDisplayThreshold = 10
    public var minAppVersion = "0.0.0"
    public var minPrayerSeconds = 5
    public var draftResumeMinutes = 30
    public var autoSaveHours = 6
    public var durationCapHours = 4
    /// The base subscription's pool, in people (monetization.md; Q32).
    public var basePremiumPool = 10
    /// How many chosen intentions each carried person (Me included) prints
    /// with (Q32, 2026-11-08). The server enforces it; the app follows it.
    public var intentionsPerPerson = 1

    public static let defaults = AppConfig()

    public init() {}
}

// MARK: Prayers

/// One finished prayer, as sent to `logPrayer` (OPERATIONS.md §C). Written
/// once, at the final Amen; immutable except for the note.
public struct NewPrayer: Sendable, Hashable, Codable, Identifiable {
    /// Client-generated UUID: a resend is a no-op on the server.
    public let id: String
    public let startedAt: Date
    /// End time.
    public let prayedAt: Date
    public let durationSeconds: Int
    /// Device local date and zone at the START.
    public let localDate: LocalDate
    public let timezone: String
    /// Set iff the list was included (the list current at the start).
    public let communityListId: String?
    /// The list current at the start, always set.
    public let listContextNumber: Int
    public var note: String?
    /// Held items. The server also links each intention's name.
    public let subjectIds: [String]
    /// When each held item was checked (schema-brief §12).
    public let checkedAt: [String: Date]

    /// `durationSeconds` is the time from start to end, held within what the
    /// server accepts: at least the minimum (a prayer can only end after it)
    /// and at most the cap (`AppConfig`: 5 s, 4 h).
    public init(id: String, startedAt: Date, prayedAt: Date, localDate: LocalDate, timezone: String,
                communityListId: String?, listContextNumber: Int, subjectIds: [String],
                checkedAt: [String: Date] = [:], note: String? = nil, config: AppConfig = .defaults) {
        self.id = id
        self.startedAt = startedAt
        self.prayedAt = prayedAt
        let seconds = Int(prayedAt.timeIntervalSince(startedAt).rounded(.down))
        self.durationSeconds = min(max(seconds, config.minPrayerSeconds), config.durationCapHours * 3600)
        self.localDate = localDate
        self.timezone = timezone
        self.communityListId = communityListId
        self.listContextNumber = listContextNumber
        self.subjectIds = subjectIds
        self.checkedAt = checkedAt
        self.note = note
    }

    public var includesList: Bool { communityListId != nil }
}

/// The list a prayer was started with: what `NewPrayer` records about it.
public struct ListContext: Sendable, Hashable {
    public let listId: String
    public let listNumber: Int

    public init(listId: String, listNumber: Int) {
        self.listId = listId
        self.listNumber = listNumber
    }
}

/// The prayer the user just finished, as `logPrayer` takes it. Ids are
/// sorted, so a resend is byte-identical.
public func newPrayer(id: String, selection: PrayerSelection, startedAt: Date, endedAt: Date,
                      list: ListContext, calendar: Calendar = .current, config: AppConfig = .defaults) -> NewPrayer {
    NewPrayer(id: id, startedAt: startedAt, prayedAt: endedAt,
              localDate: LocalDate(startedAt, calendar: calendar),
              timezone: calendar.timeZone.identifier,
              communityListId: selection.listIncluded ? list.listId : nil,
              listContextNumber: list.listNumber,
              subjectIds: selection.held.sorted(),
              checkedAt: selection.checkedAt,
              config: config)
}
