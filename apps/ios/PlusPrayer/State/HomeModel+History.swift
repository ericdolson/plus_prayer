import Foundation
import PlusPrayerDomain

// History (history.md, 2026-11-08) and a page's History preview
// (detail-page.md): the log from the repository with this device's unsent
// prayers folded in, scoped and shaped by PlusPrayerDomain.

extension HomeModel {
    /// The log with this device's unsent prayers folded in; nil until loaded.
    var effectiveHistoryLog: HistoryLog? {
        historyLog.map { historyLogWithLocalPrayers($0, localPrayers, tree: tree) }
    }

    func scopedHistory(_ scope: HistoryScope, calendar: Calendar = .current) -> ScopedHistory? {
        guard let log = effectiveHistoryLog else { return nil }
        return PlusPrayerDomain.scopedHistory(log, scope: scope, tree: tree, calendar: calendar)
    }

    // MARK: A page's preview

    /// The row of recent days and the tiles; nil until loaded. An
    /// intention's page has no Answered tile (its title already says so).
    func historyPreview(_ id: String, calendar: Calendar = .current) -> HistoryPreviewValues? {
        guard let subject = tree[id], let h = scopedHistory(.subject(id), calendar: calendar) else { return nil }
        let totals = historyTotals(h, currentListId: list?.id, livePrayerCount: list?.prayerCount)
        return HistoryPreviewValues(recent: recentStrand(h, today: today), totals: totals,
                                    showsAnswered: subject.isName)
    }

    // MARK: The History screen

    /// The chip's text for a scope: the person's alias (else name), or the
    /// intention's text; nil for everyone.
    func historyChip(_ scope: HistoryScope) -> String? {
        scope.subjectId.flatMap { tree[$0] }.map { $0.isName ? $0.label : $0.publicName }
    }

    func historyScreen(_ scope: HistoryScope, calendar: Calendar = .current) -> HistoryScreenValues? {
        guard let log = effectiveHistoryLog, let h = scopedHistory(scope, calendar: calendar) else { return nil }
        let tree = tree
        let unfiltered = scope == .everyone
        let header = header.map { headerWithLocalPrayers($0, localPrayers) }
        let streak = header.map { effectiveStreak($0, today: today) } ?? 0
        return HistoryScreenValues(
            scope: scope,
            streakDays: unfiltered && streak > 0 ? streak : nil,
            time: unfiltered && !h.prayers.isEmpty
                ? prayerTime(h.prayers, today: today, firstWeekday: calendar.firstWeekday) : nil,
            strand: strand(h, today: today),
            held: heldByDay(h).map { DayGroup(date: $0.date, items: $0.items.map { row($0, unfiltered, tree) }) },
            lists: h.lists.map(stitched),
            journal: journalByDay(h).map { DayGroup(date: $0.date, items: $0.items.map { row($0, unfiltered, tree) }) },
            answered: answeredSummaries(h, log: log).compactMap { summary in
                guard let intention = tree[summary.moment.intentionId],
                      let person = tree[summary.moment.personId] else { return nil }
                return AnsweredRowValues(id: intention.id, text: intention.publicName, personLabel: person.label,
                                         date: summary.moment.date, prayers: summary.prayers, lists: summary.lists)
            })
    }

    /// The day sheet: the list line(s), what was answered, the prayers.
    func historyDaySheet(_ date: LocalDate, scope: HistoryScope, calendar: Calendar = .current) -> DaySheetValues? {
        guard let h = scopedHistory(scope, calendar: calendar) else { return nil }
        let tree = tree
        let day = historyDay(date, in: h)
        return DaySheetValues(date: date, lists: day.lists.map(stitched),
                              answered: day.answered.compactMap { tree[$0.intentionId]?.publicName },
                              prayers: day.prayers.map { row($0, scope == .everyone, tree) })
    }

    // MARK: Values

    /// The current list carries the live count.
    private func stitched(_ record: ListRecord) -> ListRecord {
        guard let list, record.listId == list.id else { return record }
        return ListRecord(listId: record.listId, listNumber: record.listNumber, listDate: record.listDate,
                          prayerCount: list.prayerCount, sealVariant: list.sealVariant)
    }

    private func row(_ prayer: LoggedPrayer, _ withPeople: Bool, _ tree: SubjectTree) -> PrayerRowValues {
        PrayerRowValues(id: prayer.id, startedAt: prayer.startedAt, durationSeconds: prayer.durationSeconds,
                        autoSaved: prayer.autoSaved, note: prayer.hasNote ? prayer.note : nil,
                        people: withPeople ? peopleHeld(prayer, in: tree).map {
                            HeldPerson(id: $0.id, initials: monogram($0), tone: $0.tone,
                                       name: $0.isSelf ? L10n.Card.you : $0.label)
                        } : nil)
    }
}

// MARK: View values

struct HistoryPreviewValues: Equatable {
    /// Newest first, no month tabs; the view shows as many as fit.
    let recent: [StrandItem]
    let totals: HistoryTotals
    let showsAnswered: Bool
}

struct HistoryScreenValues: Equatable {
    let scope: HistoryScope
    /// Unfiltered only: "6 days with the world" (hidden at 0).
    let streakDays: Int?
    /// Unfiltered only: "Time in prayer · …".
    let time: PrayerTime?
    let strand: Strand
    let held: [DayGroup<PrayerRowValues>]
    /// Newest first; the current list with its live count.
    let lists: [ListRecord]
    let journal: [DayGroup<PrayerRowValues>]
    let answered: [AnsweredRowValues]

    /// The quiet line a tab shows when it has nothing for this scope
    /// (history.md "Empty tabs"): Held, Lists and Journal; All always has
    /// today, and Answered stays blank.
    func emptyLine(_ tab: HistoryTab) -> String? {
        switch tab {
        case .held: held.isEmpty ? L10n.History.emptyHeld : nil
        case .lists: lists.isEmpty ? L10n.History.emptyLists : nil
        case .journal: journal.isEmpty ? L10n.History.emptyJournal : nil
        case .all, .answered: nil
        }
    }
}

/// One prayer in the day sheet, Held or Journal.
nonisolated struct PrayerRowValues: Identifiable, Equatable, Sendable {
    let id: String
    let startedAt: Date
    let durationSeconds: Int
    /// Shown as "~38 min".
    let autoSaved: Bool
    /// The journal entry, in full.
    let note: String?
    /// Who it held, unfiltered only (nil when filtered).
    let people: [HeldPerson]?
}

nonisolated struct HeldPerson: Identifiable, Equatable, Sendable {
    let id: String
    let initials: String
    let tone: Int
    /// "You" for the self.
    let name: String
}

struct AnsweredRowValues: Identifiable, Equatable {
    let id: String
    let text: String
    let personLabel: String
    let date: LocalDate
    let prayers: Int
    let lists: Int
}

struct DaySheetValues: Identifiable, Equatable {
    let date: LocalDate
    let lists: [ListRecord]
    /// The intentions answered that day.
    let answered: [String]
    let prayers: [PrayerRowValues]
    var id: LocalDate { date }
}
