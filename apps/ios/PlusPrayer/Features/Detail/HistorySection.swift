import PlusPrayerDomain
import SwiftUI

/// A page's History (detail-page.md "History (calendar, 2026-11-08)"): month
/// grids for the current and previous month, older periods as text rows,
/// then "Begun · {date}". The grid reuses Home's vocabulary, so it needs no
/// legend: gold ring = you held them, bloom = on the printed list, a faint
/// `thread` dot = the calendar's shape. Each grid is one accessibility
/// element. Tapping a day or period is v2.
struct HistorySection: View {
    let history: History
    let today: LocalDate
    /// The "Answered" hint: on an intention's own page only.
    let showsAnswered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.lg) {
            Text(L10n.Page.history)
                .font(PP.type.sectionTitle)
                .foregroundStyle(PP.color.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(history.grids, id: \.month) { grid in
                MonthGridView(grid: grid, label: L10n.History.monthName(year: grid.year, month: grid.month,
                                                                       withYear: grid.year != today.year),
                              showsAnswered: showsAnswered)
            }
            ForEach(Array(history.older.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: PP.space.xxs) {
                    PeriodLabel(text: L10n.History.period(row.period, today: today), summary: row.summary,
                                showsAnswered: showsAnswered)
                    summaryLine(row.summary)
                }
                .accessibilityElement(children: .combine)
            }
            Text(L10n.History.begun(history.begun, today: today))
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
        }
        .padding(.horizontal, PP.space.gutter)
    }
}

/// "You prayed 6 times · On 9 lists" (either half left out at 0).
@ViewBuilder private func summaryLine(_ summary: PeriodSummary) -> some View {
    if let text = L10n.History.summary(summary) {
        Text(text)
            .font(PP.type.bodySmall)
            .foregroundStyle(PP.color.inkMuted)
    }
}

/// The period's label with its ✎ count and "Answered" hint right-aligned.
private struct PeriodLabel: View {
    let text: String
    let summary: PeriodSummary
    let showsAnswered: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
            Text(text)
                .font(PP.type.periodLabel)
                .foregroundStyle(PP.color.ink)
            Spacer(minLength: PP.space.sm)
            if showsAnswered && summary.answered {
                Text(L10n.History.answered)
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.heldGoldText)
            }
            if summary.notes > 0 {
                Text(L10n.History.notes(summary.notes))
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
                    .accessibilityLabel(L10n.History.notesSpoken(summary.notes))
            }
        }
    }
}

private struct MonthGridView: View {
    let grid: MonthGrid
    let label: String
    let showsAnswered: Bool

    /// Weekday initials, starting on the locale's first weekday.
    private var weekdays: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.sm) {
            PeriodLabel(text: label, summary: grid.summary, showsAnswered: showsAnswered)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                        Text(verbatim: day)
                            .font(PP.type.caption)
                            .foregroundStyle(PP.color.inkMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                            DayGlyph(state: cell?.state ?? .blank)
                                .frame(maxWidth: .infinity)
                                .frame(height: PP.size.history.row)
                        }
                    }
                }
            }
            summaryLine(grid.summary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.History.gridSpoken(month: label, grid.summary))
    }
}

/// One day: nothing, the thread dot, the bloom, the gold ring, or both.
private struct DayGlyph: View {
    let state: HistoryDay

    var body: some View {
        ZStack {
            switch state {
            case .blank:
                Color.clear
            case .empty:
                dot
            case .onList:
                bloom
            case .held:
                ring
                dot
            case .heldOnList:
                ring
                bloom
            }
        }
        .frame(width: PP.size.history.ring, height: PP.size.history.ring)
    }

    private var dot: some View {
        Circle()
            .fill(PP.color.thread)
            .frame(width: PP.size.history.dayDot, height: PP.size.history.dayDot)
    }

    private var bloom: some View {
        PPIcon.carried
            .font(.system(size: PP.size.history.bloom / PPIcon.carriedEm))
            .foregroundStyle(PP.color.inkMuted)
    }

    private var ring: some View {
        Circle().strokeBorder(PP.color.heldGold, lineWidth: PP.size.held.ringSmall)
    }
}

#Preview("History") {
    let today = LocalDate(year: 2026, month: 11, day: 5)
    let detail = SubjectDetail(
        subjectId: "dad",
        entries: (1...30).filter { $0 % 4 != 0 }.map {
            let date = today.adding(days: -$0)
            return DetailListEntry(listId: "l\($0)", listNumber: 52 - $0, listDate: date, prayerCount: 100)
        },
        prayers: [3, 4, 9, 10, 18, 33, 40, 70].map {
            DetailPrayer(id: "p\($0)", localDate: today.adding(days: -$0), hasNote: $0 % 3 == 0)
        })
    ScrollView {
        HistorySection(history: history(detail, begun: LocalDate(year: 2026, month: 7, day: 12), today: today,
                                         firstWeekday: Calendar.current.firstWeekday),
                       today: today, showsAnswered: false)
    }
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}
