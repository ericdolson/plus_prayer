import PlusPrayerDomain
import SwiftUI

/// Home (screens.md, design-direction §3–§7): header, community card, rows,
/// floating bar; prayer mode in place (the halo, checks in the rows and the
/// card, Cancel, the prayer bar, the pray button's countdown to Amen).
/// Runs on `HomeModel` (the repositories, through the domain rules) and
/// `PrayerSession`. Amen ends in `PrayerSheet` (the list invitation, then the
/// closing sheet). Search docks above the keyboard (`HomeSearch.swift`).
/// Home is the root of a navigation stack (its own bar hidden): a name row
/// pushes the name's page, and adding a name lands there.
/// The halo and the PrayerSheet sit on the stack, not on Home's content, so
/// a prayer said on a page (in place, detail-page.md) gets them there too.
/// A page's "Pray for others", back or swipe-back leaves the page with the
/// session still praying (`leavePage`): the stack pops to Home.
struct HomeView: View {
    @Environment(HomeModel.self) private var home
    @Environment(PrayerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmingDiscard = false
    @State private var adding: AddSheetModel?
    /// First run, while it's up (`OnboardingModel`).
    @State private var onboarding: OnboardingModel?
    /// What's pushed over Home: pages (names and intentions) and History.
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            homeContent
                .toolbar(.hidden, for: .navigationBar)
                .routes()
        }
        .overlay { Halo(active: session.isPraying, flare: session.amenCount) }
        .sensoryFeedback(.impact(weight: .light), trigger: session.checkCount)
        .sheet(isPresented: prayerSheetShown) { PrayerSheet() }
        // No self name yet (auth-onboarding.md, resume by state): onboarding
        // over Home from Welcome. It stays through Welcome back and the
        // guided add once the name is saved, until Add others later or
        // Continue; a later launch with a name opens Home.
        .fullScreenCover(isPresented: onboardingShown) {
            if let onboarding { OnboardingFlow(model: onboarding) }
        }
        .onChange(of: home.needsSelfName, initial: true) { _, needs in
            if needs && onboarding == nil { onboarding = OnboardingModel(home: home) }
        }
        .onChange(of: onboarding?.isFinished) { _, finished in
            if finished == true { onboarding = nil }
        }
        // Back or swipe-back off a page praying in place: Home, still praying.
        .onChange(of: path) { old, new in
            if new.count < old.count && session.page != nil && session.isPraying { session.leavePage() }
        }
        // Left the page ("Pray for others", or back from a page with others
        // under it): straight to Home.
        .onChange(of: session.page) { old, new in
            if old != nil && new == nil && session.isPraying && !path.isEmpty { path = [] }
        }
        // Here, not on Home's content: a pushed page takes that off screen,
        // which would cancel the streams the page needs too.
        .task { await home.run() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { home.refreshToday() }
        }
    }

    private var onboardingShown: Binding<Bool> {
        Binding(get: { onboarding != nil }, set: { if !$0 { onboarding = nil } })
    }

    private var homeContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if home.cardShown, let card = home.card {
                    cardView(card)
                        .transition(.opacity)
                }
                let groups = home.groups
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    groupRows(group)
                        .padding(.top, index == 0 ? 0 : GroupSpacing.above(
                            afterIntention: !groups[index - 1].intentions.isEmpty))
                        .transition(.opacity)
                }
                if home.allHeldShown {
                    quietLines([L10n.Filter.allHeld])
                }
                // Live, like the rows: shown as soon as nothing matches, its
                // text following the query (never hidden and shown again).
                if home.noMatches {
                    NoMatchesView(query: home.query.trimmingCharacters(in: .whitespacesAndNewlines),
                                  showsAdd: !session.isPraying, // adding mid-prayer isn't a goal
                                  hiddenByFilter: home.matchesHiddenByFilter,
                                  onAdd: { adding = AddSheetModel(home: home, name: home.query) },
                                  onShowAll: { home.showAllMatches() })
                        .transition(.opacity)
                }
                if home.carriedHelperShown {
                    // "[ Choose who's carried ] → Your portion" joins these
                    // when Your portion exists (build step 6).
                    quietLines([L10n.Filter.carriedMeaning, L10n.Filter.carriedKeep])
                }
            }
            .padding(.top, PP.space.xl)
            .padding(.bottom, PP.space.xl)
            // Rows leaving (a filter change, the fold after linger) close up;
            // Reduce Motion: a quick fade.
            .animation(reduceMotion ? .easeOut(duration: PP.duration.quick) : .easeInOut(duration: PP.duration.fold),
                       value: home.groups.map(\.id) + (home.cardShown ? [HomeModel.cardKey] : []))
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .safeAreaBar(edge: .top) { header }
        .safeAreaBar(edge: .bottom) { bar }
        .background(PP.color.ground)
        .discardPrayerDialog(isPresented: $confirmingDiscard, session: session)
        .sheet(item: $adding) { model in
            AddSheet(model: model)
                // A name just added: its page, as Contacts opens what you
                // just created.
                .onDisappear { if let id = model.addedNameId { path.append(.subject(id)) } }
        }
    }

    private func cardView(_ card: CardValues) -> some View {
        let check: Bool? = session.isPraying ? session.selection.listIncluded : nil
        return CommunityCard(listNumber: card.listNumber, sealVariant: card.sealVariant,
                             people: card.people, prayers: card.prayers, presence: card.presence,
                             carried: card.carried.map {
                                 CommunityCard.Person(id: $0.id, initials: $0.initials, tone: $0.tone,
                                                      spokenName: $0.spokenName, isSelf: $0.isSelf)
                             },
                             status: card.status, closingMinutes: card.closingMinutes,
                             held: card.heldToday || session.selection.listIncluded,
                             check: check,
                             onTap: { if session.isPraying { session.toggleList() } })
            .padding(.horizontal, PP.space.gutter)
            .padding(.bottom, PP.space.cardToList)
    }

    @ViewBuilder private var header: some View {
        @Bindable var home = home
        let onCancel: (() -> Void)? = session.isPraying ? { cancel() } : nil
        let me = home.me
        HomeHeader(initials: me?.initials ?? "", tone: me?.tone ?? 0,
                   streakState: me?.streakState ?? .none, streakDays: me?.streakDays ?? 0,
                   filter: $home.filter, counts: home.counts,
                   onCancel: onCancel)
    }

    private var bar: some View {
        HomeDock(onHistory: { path.append(.history(HistoryRequest())) },
                 onAdd: { adding = AddSheetModel(home: home) }, onAmen: amen)
    }

    /// The pray button's Amen: commits, or opens the invitation first.
    private func amen() { session.amen(logTo: home) }

    /// The invitation, then the closing sheet; dismissing the closing sheet
    /// ends the session (the invitation can't be dismissed).
    private var prayerSheetShown: Binding<Bool> {
        Binding(get: { session.isInvited || session.closing != nil },
                set: { shown in if !shown { session.close() } })
    }

    private func cancel() { session.cancel(confirming: &confirmingDiscard) }

    private func quietLines(_ lines: [String]) -> some View {
        VStack(spacing: PP.space.xs) {
            ForEach(lines, id: \.self) { Text($0) }
        }
        .font(PP.type.bodySmall)
        .foregroundStyle(PP.color.inkMuted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PP.space.gutter)
        .padding(.vertical, PP.space.xl)
        .transition(.opacity)
    }

    @ViewBuilder
    private func groupRows(_ group: NameGroup) -> some View {
        let name = group.name
        VStack(alignment: .leading, spacing: 0) {
            NameRow(initials: name.initials, tone: name.tone, label: name.label, carried: name.carried,
                    held: held(name), secondary: secondary(name), hasIntentions: !group.intentions.isEmpty,
                    accessibilityLabel: name.accessibilityLabel(heldOutsidePrayer: !session.isPraying && name.heldToday),
                    check: session.isPraying ? session.check(name.id) : nil,
                    onTap: { tap(name.id) })
                // A name shown only for an intention the filter keeps: dimmed;
                // the intention stays at full strength.
                .opacity(name.isContext ? PP.number.contextRow : 1)
                // Quick actions (design-direction §5): only "Add intention"
                // for now; Edit / Answered / Release / Archive join as built.
                // None in prayer, where a row is a check.
                .contextMenu {
                    if !session.isPraying {
                        Button(L10n.Home.addIntention) { adding = AddSheetModel(home: home, intentionFor: name.id) }
                    }
                }
            ForEach(Array(group.intentions.enumerated()), id: \.element.id) { index, intention in
                IntentionRow(text: intention.label, carried: intention.carried, held: held(intention),
                             secondary: secondary(intention),
                             thread: index == group.intentions.count - 1 ? .lastBranch : .branch,
                             accessibilityLabel: intention.accessibilityLabel(
                                heldOutsidePrayer: !session.isPraying && intention.heldToday),
                             check: session.isPraying ? session.check(intention.id) : nil,
                             onTap: { tap(intention.id) })
                    .transition(.opacity)
            }
        }
    }

    /// The gold ring / dot: held today, or held live in this prayer.
    private func held(_ row: RowItem) -> Bool { row.heldToday || session.isHeld(row.id) }

    private func secondary(_ row: RowItem) -> SecondaryLine? {
        row.secondary.map { SecondaryLine(text: $0.text, kind: $0.answered ? .answered : .notice) }
    }

    /// In prayer a tap checks; in browse mode a row opens its page (a
    /// name's or an intention's: `SubjectPage` picks by kind).
    private func tap(_ id: String) {
        if session.isPraying {
            session.toggle(id)
        } else {
            path.append(.subject(id))
        }
    }
}

// MARK: Previews (always on the mock)

private struct HomePreview: View {
    @State private var home: HomeModel
    @State private var session: PrayerSession

    /// `startedAgo`: begin a prayer that many seconds ago; `checks`: ids to
    /// check in it ("list" for the card).
    init(filter: HomeFilter = .all, startedAgo: TimeInterval? = nil, checks: [String] = []) {
        let environment = AppEnvironment.mock(MockBackend(latency: .zero, liveDrift: false))
        let home = HomeModel(environment: environment)
        home.filter = filter
        let session = PrayerSession(graph: { home.graph },
                                    clock: { .now.addingTimeInterval(-(startedAgo ?? 0)) })
        _home = State(initialValue: home)
        _session = State(initialValue: session)
        if startedAgo != nil {
            session.start(list: ListContext(listId: "list-52", listNumber: 52))
            self.checks = checks
        }
    }

    private var checks: [String] = []

    var body: some View {
        HomeView()
            .environment(home)
            .environment(session)
            .task {
                // The graph exists once the subjects have arrived.
                try? await Task.sleep(for: .milliseconds(50))
                for id in checks { id == "list" ? session.toggleList() : session.toggle(id) }
            }
    }
}

#Preview("Dark") { HomePreview().preferredColorScheme(.dark) }
#Preview("Light") { HomePreview().preferredColorScheme(.light) }
#Preview("Still to hold") { HomePreview(filter: .stillToHold).preferredColorScheme(.dark) }
#Preview("Carried") { HomePreview(filter: .carried).preferredColorScheme(.light) }
#Preview("In prayer") {
    // Started 11 s ago (Amen is available), the list and a few rows checked.
    HomePreview(startedAgo: 11, checks: ["list", "dad-2", "mom", "mom-1"]).preferredColorScheme(.dark)
}
#Preview("Counting down") { HomePreview(startedAgo: 2).preferredColorScheme(.light) }
#Preview("Large type") {
    HomePreview().environment(\.dynamicTypeSize, .accessibility2).preferredColorScheme(.dark)
}

/// The bottom of Home: the bar. Searching, its pill becomes the search field
/// and, with the keyboard up, both controls ride above it at the compact
/// height.
///
/// The keyboard drives it, not the focus state: a field inside a safe-area
/// bar takes focus when asked, but its `@FocusState` doesn't read back true
/// there (iOS 26), so the dock follows the keyboard's own notifications.
private struct HomeDock: View {
    let onHistory: () -> Void
    let onAdd: () -> Void
    let onAmen: () -> Void

    @Environment(HomeModel.self) private var home
    @Environment(PrayerSession.self) private var session
    @FocusState private var searchFocused: Bool
    @State private var keyboardUp = false

    var body: some View {
        @Bindable var home = home
        HomeBar(prayerStartedAt: session.startedAt, prayingWith: home.prayingWith,
                searching: home.isSearching, compact: home.isSearching && keyboardUp,
                onHistory: onHistory, onSearch: { home.openSearch() }, onAdd: onAdd,
                onPray: { session.start(list: home.listContext) },
                onAmen: onAmen) {
            SearchField(query: $home.query, focused: $searchFocused, onClose: closeSearch)
        }
        // A little air between the controls and the keyboard.
        .padding(.bottom, home.isSearching && keyboardUp ? PP.space.sm : 0)
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification) {
                keyboardUp = true
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification) {
                keyboardUp = false
                // A search left empty closes itself when the keyboard goes.
                if !home.hasQuery { home.closeSearch() }
            }
        }
    }

    private func closeSearch() {
        searchFocused = false
        home.closeSearch()
    }
}
