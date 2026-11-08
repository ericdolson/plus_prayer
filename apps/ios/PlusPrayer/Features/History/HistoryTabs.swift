import PlusPrayerDomain
import SwiftUI

// History's tabs (history.md): All (the strand), Held, Lists, Journal,
// Answered; and the day sheet. Values come from `HomeModel.historyScreen`.

// MARK: All — the strand

struct HistoryAllTab: View {
    let values: HistoryScreenValues
    let today: LocalDate
    let onDay: (LocalDate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.xl) {
            // About you: unfiltered only.
            if values.streakDays != nil || values.time != nil {
                VStack(alignment: .leading, spacing: PP.space.xxs) {
                    if let days = values.streakDays { Text(L10n.History.streak(days)) }
                    if let time = values.time { Text(L10n.History.time(time)).monospacedDigit() }
                }
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
            }
            VStack(alignment: .leading, spacing: 0) {
                StrandTodayCaption(text: L10n.History.today)
                StrandFlow {
                    ForEach(values.strand.items, id: \.self) { item in
                        StrandItemView(item: item, today: today, action: .open(onDay))
                    }
                }
            }
            if !values.strand.older.isEmpty {
                VStack(alignment: .leading, spacing: PP.space.md) {
                    ForEach(Array(values.strand.older.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .firstTextBaseline, spacing: PP.space.md) {
                            Text(L10n.History.period(row.period, today: today))
                                .font(PP.type.periodLabel)
                                .foregroundStyle(PP.color.ink)
                            Spacer(minLength: PP.space.sm)
                            Text(L10n.History.periodSummary(row.summary))
                                .font(PP.type.bodySmall)
                                .foregroundStyle(PP.color.inkMuted)
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .accessibilityLabel(L10n.History.periodSummarySpoken(row.summary))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            Text(L10n.History.begun(values.strand.begun, today: today))
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
        }
        .padding(.horizontal, PP.space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One strand item: a node (a button that opens its day), a fold, or a
/// month tab. Shared with a page's preview row.
struct StrandItemView: View {
    /// A node opens its day: here (the sheet), or by pushing History.
    enum Action {
        case open((LocalDate) -> Void)
        case push((LocalDate) -> Route)
    }

    let item: StrandItem
    let today: LocalDate
    let action: Action

    var body: some View {
        switch item {
        case .node(let node):
            Group {
                switch action {
                case .open(let open):
                    Button { open(node.date) } label: { mark(node) }
                case .push(let route):
                    NavigationLink(value: route(node.date)) { mark(node) }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.History.node(node, lists: node.listNumbers, today: today))
            .accessibilityIdentifier("history.node.\(node.date)")
        case .gap:
            StrandGapMark(spokenLabel: L10n.History.noActivity)
        case .month(let year, let month):
            StrandMonthTab(text: L10n.History.monthTab(year: year, month: month),
                           spokenLabel: L10n.History.monthName(year: year, month: month, withYear: year != today.year))
        }
    }

    private func mark(_ node: StrandNode) -> some View {
        StrandNodeMark(onList: node.onList, prayed: node.prayed, journal: node.journal, answered: node.answered)
            .contentShape(Rectangle())
    }
}

// MARK: Held and Journal

/// Prayers under day headings ("Today", "Yesterday", "Thursday, Nov 5").
/// Held: time · length, who it held (unfiltered), ✎ with an entry.
/// Journal: the entries in full, set for reading, with who the prayer held
/// (unfiltered). Rows will open Prayer detail; inert until it exists.
struct HistoryPrayersTab: View {
    enum Style { case held, journal }

    let groups: [DayGroup<PrayerRowValues>]
    let today: LocalDate
    let style: Style
    let withPeople: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: PP.space.xl) {
            ForEach(groups, id: \.date) { group in
                VStack(alignment: .leading, spacing: PP.space.md) {
                    Text(L10n.History.dayHeading(group.date, today: today))
                        .font(PP.type.periodLabel)
                        .foregroundStyle(PP.color.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(group.items) { prayer in
                        switch style {
                        case .held: HeldRow(prayer: prayer, withPeople: withPeople)
                        case .journal: JournalEntry(prayer: prayer, withPeople: withPeople)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PP.space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "7:42 AM · 12 min", who it held, ✎.
struct HeldRow: View {
    let prayer: PrayerRowValues
    let withPeople: Bool

    var body: some View {
        HStack(alignment: .center, spacing: PP.space.md) {
            Text(L10n.History.prayerLine(startedAt: prayer.startedAt, seconds: prayer.durationSeconds,
                                         autoSaved: prayer.autoSaved))
                .font(PP.type.body)
                .foregroundStyle(PP.color.ink)
                .monospacedDigit()
            Spacer(minLength: PP.space.sm)
            if withPeople, let people = prayer.people, !people.isEmpty {
                HeldCluster(people: people)
            }
            if prayer.note != nil {
                PPIcon.journal
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
                    .accessibilityLabel(L10n.History.journalEntry)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// An entry in full, set for reading.
struct JournalEntry: View {
    let prayer: PrayerRowValues
    let withPeople: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.sm) {
            if withPeople, let people = prayer.people, !people.isEmpty {
                HeldCluster(people: people)
            }
            if let note = prayer.note {
                Text(verbatim: note)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.ink)
                    .lineSpacing(PP.space.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Who a prayer held: the avatars alone, every name for VoiceOver.
struct HeldCluster: View {
    let people: [HeldPerson]

    var body: some View {
        AvatarCluster(people: people.map {
            AvatarCluster.Person(id: $0.id, initials: $0.initials, tone: $0.tone, name: $0.name)
        }, trailing: nil)
    }
}

// MARK: Lists

/// One row per list: a small wax seal · "List 52" (Roca) · "Sat, Nov 7" ·
/// "3,475 prayers". Rows will open the past list's page; inert until it
/// exists.
struct HistoryListsTab: View {
    let lists: [ListRecord]
    let today: LocalDate

    var body: some View {
        LazyVStack(alignment: .leading, spacing: PP.space.lg) {
            ForEach(lists) { list in
                HStack(spacing: PP.space.md) {
                    WaxSeal(variant: list.sealVariant, size: PP.size.history.listSeal)
                    VStack(alignment: .leading, spacing: PP.space.xxs) {
                        Text(L10n.History.listTitle(list.listNumber))
                            .font(PP.type.name)
                            .foregroundStyle(PP.color.ink)
                        Text(L10n.History.listDate(list.listDate, today: today))
                            .font(PP.type.bodySmall)
                            .foregroundStyle(PP.color.inkMuted)
                    }
                    Spacer(minLength: PP.space.sm)
                    Text(L10n.History.listPrayers(list.prayerCount))
                        .font(PP.type.bodySmall)
                        .foregroundStyle(PP.color.inkMuted)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, PP.space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Answered

/// The intention (sans) → the person (small, muted) → "Answered Nov 3"
/// (gold) → "You prayed 12 times · On 30 lists" (muted). No celebration.
/// A row opens the intention's page.
struct HistoryAnsweredTab: View {
    let rows: [AnsweredRowValues]
    let today: LocalDate

    var body: some View {
        LazyVStack(alignment: .leading, spacing: PP.space.xl) {
            ForEach(rows) { row in
                NavigationLink(value: Route.subject(row.id)) {
                    VStack(alignment: .leading, spacing: PP.space.xxs) {
                        Text(verbatim: row.text)
                            .font(PP.type.body)
                            .foregroundStyle(PP.color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: row.personLabel)
                            .font(PP.type.caption)
                            .foregroundStyle(PP.color.inkMuted)
                        Text(L10n.History.answeredOn(row.date, today: today))
                            .font(PP.type.bodySmall)
                            .foregroundStyle(PP.color.heldGoldText)
                        if let counts = L10n.History.prayedAndLists(prayers: row.prayers, lists: row.lists) {
                            Text(counts)
                                .font(PP.type.bodySmall)
                                .foregroundStyle(PP.color.inkMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, PP.space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: The day sheet

/// A native half-height sheet for one day: the date, "On List 46 · 3,475
/// prayers" when on a list, "Answered · {intention}" in gold, then each
/// prayer (time · length, who it held when unfiltered, its entry in full).
/// A day with no prayer shows only what happened.
struct HistoryDaySheet: View {
    let date: LocalDate
    let scope: HistoryScope

    @Environment(HomeModel.self) private var home

    var body: some View {
        ScrollView {
            if let day = home.historyDaySheet(date, scope: scope) {
                VStack(alignment: .leading, spacing: PP.space.lg) {
                    VStack(alignment: .leading, spacing: PP.space.xs) {
                        Text(L10n.History.longDate(date, today: home.today))
                            .font(PP.type.sectionTitle)
                            .foregroundStyle(PP.color.ink)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(day.lists) { list in
                            Text(L10n.History.onList(list.listNumber, prayers: list.prayerCount))
                                .font(PP.type.bodySmall)
                                .foregroundStyle(PP.color.inkMuted)
                        }
                        ForEach(day.answered, id: \.self) { text in
                            Text(L10n.History.answered(text))
                                .font(PP.type.bodySmall)
                                .foregroundStyle(PP.color.heldGoldText)
                        }
                    }
                    ForEach(day.prayers) { prayer in
                        VStack(alignment: .leading, spacing: PP.space.sm) {
                            HeldRow(prayer: PrayerRowValues(id: prayer.id, startedAt: prayer.startedAt,
                                                            durationSeconds: prayer.durationSeconds,
                                                            autoSaved: prayer.autoSaved, note: nil,
                                                            people: prayer.people),
                                    withPeople: scope == .everyone)
                            if let note = prayer.note {
                                Text(verbatim: note)
                                    .font(PP.type.body)
                                    .foregroundStyle(PP.color.ink)
                                    .lineSpacing(PP.space.xs)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, PP.space.gutter)
                .padding(.vertical, PP.space.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(PP.color.sheet)
    }
}
