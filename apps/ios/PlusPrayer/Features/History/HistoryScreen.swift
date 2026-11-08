import PlusPrayerDomain
import SwiftUI

/// History (history.md, 2026-11-08): one screen, everyone combined or
/// filtered to one person (or, from an intention's page, one intention).
/// The filter is Home's control in the toolbar: a glyph that opens a
/// searchable people list, then an "{alias} ×" chip (× widens to everyone).
/// Tabs: a native segmented control, All · Held · Lists · Journal ·
/// Answered (a menu button at accessibility text sizes). All is the strand;
/// each other tab is the full list behind one of its marks. Tapping a node
/// opens that day's half-height sheet.
///
/// Inert for now: Prayer detail (the Held, Journal and day-sheet rows) and
/// past lists' pages (the Lists rows).
struct HistoryScreen: View {
    @Environment(HomeModel.self) private var home
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var scope: HistoryScope
    @State private var tab: HistoryTab
    @State private var sheetDay: SheetDay?
    @State private var choosing = false
    /// A node on a page's preview row opens History on that day's sheet,
    /// once, after the push.
    private let openingDay: LocalDate?
    @State private var openedDay = false

    init(request: HistoryRequest) {
        _scope = State(initialValue: request.scope)
        _tab = State(initialValue: request.tab)
        openingDay = request.day
    }

    var body: some View {
        ScrollView {
            if let values = home.historyScreen(scope) {
                content(values)
                    .padding(.vertical, PP.space.lg)
            }
        }
        .safeAreaBar(edge: .top) { tabs }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .background(PP.color.ground)
        .navigationTitle(L10n.History.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { filter } }
        .navigationDestination(isPresented: $choosing) {
            HistoryPeopleList(selected: scope.subjectId) { id in
                scope = .subject(id)
                choosing = false
            }
        }
        .sheet(item: $sheetDay) { day in
            HistoryDaySheet(date: day.date, scope: scope)
        }
        .onAppear {
            guard !openedDay, let openingDay else { return }
            openedDay = true
            sheetDay = SheetDay(date: openingDay)
        }
    }

    // MARK: The filter

    /// Home's control in toolbar form: the glyph, or the chip with its × (the
    /// toolbar's own glass holds both as one capsule).
    @ViewBuilder private var filter: some View {
        if let chip = home.historyChip(scope) {
            HStack(spacing: PP.space.xxs) {
                Button { choosing = true } label: {
                    Text(verbatim: chip)
                        .font(PP.type.label)
                        .foregroundStyle(PP.color.ink)
                        .lineLimit(1)
                        .frame(maxWidth: PP.size.history.chipMaxWidth)
                }
                .accessibilityIdentifier("history.filter.chip")
                .accessibilityHint(L10n.Home.filter)
                Button { scope = .everyone } label: {
                    PPIcon.close
                        .imageScale(.small)
                        .foregroundStyle(PP.color.inkMuted)
                }
                .accessibilityLabel(L10n.Home.clearFilter)
                .accessibilityIdentifier("history.filter.clear")
            }
        } else {
            Button { choosing = true } label: {
                PPIcon.filter.foregroundStyle(PP.color.ink)
            }
            .accessibilityLabel(L10n.Home.filter)
            .accessibilityIdentifier("history.filter")
        }
    }

    // MARK: Tabs

    @ViewBuilder private var tabs: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // A native menu button showing the current tab ("All ⌄").
                Picker(L10n.History.tabsLabel, selection: $tab) { tabItems }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker(L10n.History.tabsLabel, selection: $tab) { tabItems }
                    .pickerStyle(.segmented)
            }
        }
        .tint(PP.color.ink)
        .accessibilityIdentifier("history.tabs")
        .padding(.horizontal, PP.space.gutter)
        .padding(.vertical, PP.space.sm)
    }

    private var tabItems: some View {
        ForEach(HistoryTab.allCases, id: \.self) { Text($0.title).tag($0) }
    }

    // MARK: Content

    @ViewBuilder private func content(_ values: HistoryScreenValues) -> some View {
        let today = home.today
        let withPeople = scope == .everyone
        if let line = values.emptyLine(tab) {
            // One quiet line (history.md "Empty tabs").
            Text(line)
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
                .padding(.horizontal, PP.space.gutter)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            tabContent(values, today: today, withPeople: withPeople)
        }
    }

    @ViewBuilder private func tabContent(_ values: HistoryScreenValues, today: LocalDate,
                                         withPeople: Bool) -> some View {
        switch tab {
        case .all:
            HistoryAllTab(values: values, today: today) { sheetDay = SheetDay(date: $0) }
        case .held:
            HistoryPrayersTab(groups: values.held, today: today, style: .held, withPeople: withPeople)
        case .lists:
            HistoryListsTab(lists: values.lists, today: today)
        case .journal:
            HistoryPrayersTab(groups: values.journal, today: today, style: .journal, withPeople: withPeople)
        case .answered:
            HistoryAnsweredTab(rows: values.answered, today: today)
        }
    }
}

/// The day a sheet is open for.
struct SheetDay: Identifiable, Hashable {
    let date: LocalDate
    var id: LocalDate { date }
}

// MARK: The people list

/// The filter's list: everyone in Home order, Me first, searchable (the
/// add sheet's "Who is this for?" pattern), the current one checked.
/// Picking someone narrows History to them.
private struct HistoryPeopleList: View {
    let selected: String?
    let onPick: (String) -> Void

    @Environment(HomeModel.self) private var home
    @State private var query = ""

    var body: some View {
        let names = home.pickerNames(matching: query)
        List {
            if names.isEmpty {
                Text(L10n.Add.noMatches(query.trimmingCharacters(in: .whitespacesAndNewlines)))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            ForEach(names) { name in
                Button { onPick(name.id) } label: {
                    HStack {
                        MonogramAvatar(initials: name.initials, tone: name.tone, size: PP.size.avatar.picker)
                        Text(name.label)
                            .foregroundStyle(PP.color.ink)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if name.id == selected {
                            PPIcon.check.foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(name.label)
                .accessibilityIdentifier("history.people.\(name.id)")
                .accessibilityAddTraits(name.id == selected ? [.isButton, .isSelected] : .isButton)
                .listRowBackground(PP.color.raised)
            }
        }
        .scrollContentBackground(.hidden)
        .background(PP.color.ground)
        .tint(PP.color.ink)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: L10n.Search.placeholder)
        .navigationTitle(L10n.History.people)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: Previews (on the mock)

private struct HistoryPreview: View {
    let request: HistoryRequest
    @State private var home: HomeModel
    @State private var session: PrayerSession

    init(request: HistoryRequest) {
        self.request = request
        let home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))
        _home = State(initialValue: home)
        // Answered rows push an intention's page, which reads the session.
        _session = State(initialValue: PrayerSession(graph: { home.graph }))
    }

    var body: some View {
        NavigationStack {
            HistoryScreen(request: request)
                .routes()
        }
        .environment(home)
        .environment(session)
        .task { await home.run() }
    }
}

#Preview("Everyone") { HistoryPreview(request: HistoryRequest()).preferredColorScheme(.dark) }
#Preview("Dad · Held") {
    HistoryPreview(request: HistoryRequest(scope: .subject("dad"), tab: .held)).preferredColorScheme(.light)
}
#Preview("Journal") { HistoryPreview(request: HistoryRequest(tab: .journal)).preferredColorScheme(.dark) }
#Preview("Lists") { HistoryPreview(request: HistoryRequest(tab: .lists)).preferredColorScheme(.light) }
#Preview("Answered") { HistoryPreview(request: HistoryRequest(tab: .answered)).preferredColorScheme(.dark) }
#Preview("Large type") {
    HistoryPreview(request: HistoryRequest(scope: .subject("bea"))).dynamicTypeSize(.accessibility2)
}
