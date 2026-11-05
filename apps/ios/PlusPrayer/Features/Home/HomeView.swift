import PlusPrayerDomain
import SwiftUI

/// Home (screens.md, design-direction §3–§7): header, community card, rows,
/// floating bar; prayer mode in place (the halo, checks in the rows and the
/// card, Cancel, the prayer bar, the pray button's countdown to Amen).
/// Sample values until the mock data source exists; search, the filter's
/// effect, the list invitation and the closing sheet come in later slices.
struct HomeView: View {
    @State private var session: PrayerSession

    init(session: PrayerSession = PrayerSession(graph: Sample.graph, heldToday: ["dad", "dad.surgery"])) {
        _session = State(initialValue: session)
    }
    @State private var filter: HomeFilter = .all
    @State private var confirmingDiscard = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                card
                ForEach(Array(Sample.groups.enumerated()), id: \.element.id) { index, group in
                    groupRows(group)
                        .padding(.top, index == 0 ? 0 : PP.space.groupGap)
                }
            }
            .padding(.top, PP.space.xl)
            .padding(.bottom, PP.space.xl)
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .safeAreaBar(edge: .top) { header }
        .safeAreaBar(edge: .bottom) { bar }
        .background(PP.color.ground)
        .overlay { Halo(active: session.isPraying, flare: session.amenCount) }
        .sensoryFeedback(.impact(weight: .light), trigger: session.checkCount)
        .confirmationDialog(L10n.Prayer.discardQuestion, isPresented: $confirmingDiscard,
                            titleVisibility: .visible) { discardActions }
    }

    private var card: some View {
        let check: Bool? = session.isPraying ? session.selection.listIncluded : nil
        return CommunityCard(listNumber: 52, sealVariant: 3, people: 4345, prayers: 3881,
                             presence: PresenceLine(window: .now, count: 239),
                             carried: Sample.carried,
                             status: session.listHeldToday ? .covered : .prayToCarry,
                             held: session.listHeld,
                             check: check,
                             onTap: { if session.isPraying { session.toggleList() } })
            .padding(.horizontal, PP.space.gutter)
            .padding(.bottom, PP.space.cardToList)
    }

    private var header: some View {
        let onCancel: (() -> Void)? = session.isPraying ? { cancel() } : nil
        return HomeHeader(initials: "EO", tone: 7,
                          streakState: session.listHeldToday ? .sealedToday : .alive, streakDays: 6,
                          filter: $filter, counts: HomeFilterCounts(all: 11, stillToHold: 8, carried: 8),
                          onCancel: onCancel)
    }

    private var bar: some View {
        HomeBar(prayerStartedAt: session.startedAt, prayingWith: 238,
                onPray: { session.start() }, onAmen: { session.amen() })
    }

    @ViewBuilder private var discardActions: some View {
        // Not .destructive: the system would paint it red, and +Prayer has no red.
        Button(L10n.Prayer.discard) { session.cancel() }
        Button(L10n.Prayer.keepPraying, role: .cancel) {}
    }

    private func cancel() {
        if session.needsDiscardConfirmation(at: .now) {
            confirmingDiscard = true
        } else {
            session.cancel()
        }
    }

    @ViewBuilder
    private func groupRows(_ group: Sample.Group) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NameRow(initials: group.initials, tone: group.tone, label: group.label, carried: group.carried,
                    held: session.isHeld(group.id), secondary: nil, hasIntentions: !group.intentions.isEmpty,
                    accessibilityLabel: group.label,
                    check: session.isPraying ? session.check(group.id) : nil,
                    onTap: { tap(group.id) })
            ForEach(Array(group.intentions.enumerated()), id: \.element.id) { index, intention in
                IntentionRow(text: intention.text, carried: intention.carried, held: session.isHeld(intention.id),
                             secondary: intention.answered.map { SecondaryLine(text: $0, kind: .answered) },
                             thread: index == group.intentions.count - 1 ? .lastBranch : .branch,
                             accessibilityLabel: intention.text,
                             check: session.isPraying ? session.check(intention.id) : nil,
                             onTap: { tap(intention.id) })
            }
        }
    }

    /// In prayer a tap checks; in nav mode it opens the item (a later slice).
    private func tap(_ id: String) {
        if session.isPraying { session.toggle(id) }
    }
}

/// Placeholder content until the mock data source exists.
enum Sample {
    struct Intention: Identifiable {
        let id: String
        let text: String
        var carried = false
        var answered: String? = nil
    }

    struct Group: Identifiable {
        let id: String
        let label: String
        let initials: String
        let tone: Int
        var carried = true
        var intentions: [Intention] = []
    }

    static let groups: [Group] = [
        Group(id: "me", label: "Me", initials: "EO", tone: 7,
              intentions: [Intention(id: "me.work", text: "Patience with the new job", carried: true)]),
        Group(id: "dad", label: "Dad", initials: "D", tone: 0,
              intentions: [Intention(id: "dad.surgery", text: "Healing after his surgery", carried: true),
                           Intention(id: "dad.heart", text: "Rest for his heart")]),
        Group(id: "mom", label: "Mom", initials: "M", tone: 8,
              intentions: [Intention(id: "mom.ruth", text: "A safe delivery for Ruth", answered: "Answered · Oct 19")]),
        Group(id: "dk", label: "Daniel Kim", initials: "DK", tone: 10),
        Group(id: "op", label: "Olivia Park", initials: "OP", tone: 13),
        Group(id: "ray", label: "Uncle Ray", initials: "U", tone: 14),
        Group(id: "june", label: "Grandma June", initials: "G", tone: 3, carried: false),
        Group(id: "bea", label: "Aunt Bea", initials: "A", tone: 6, carried: false),
        Group(id: "sam", label: "Sam", initials: "S", tone: 9, carried: false),
    ]

    static let graph = SubjectGraph(intentionsByName: Dictionary(uniqueKeysWithValues: groups.map {
        ($0.id, $0.intentions.map(\.id))
    }))

    static let carried: [CommunityCard.Person] = [
        .init(id: "me", initials: "EO", tone: 7, spokenName: "You", isSelf: true),
        .init(id: "d", initials: "D", tone: 0, spokenName: "Dad", isSelf: false),
        .init(id: "m", initials: "M", tone: 8, spokenName: "Mom", isSelf: false),
        .init(id: "dk", initials: "DK", tone: 10, spokenName: "Daniel Kim", isSelf: false),
        .init(id: "op", initials: "OP", tone: 13, spokenName: "Olivia Park", isSelf: false),
        .init(id: "u", initials: "U", tone: 14, spokenName: "Uncle Ray", isSelf: false),
    ]
}

#Preview("Dark") { HomeView().preferredColorScheme(.dark) }
#Preview("In prayer") {
    // Started 11 s ago (Amen is available), the list and a few rows checked.
    let session = PrayerSession(graph: Sample.graph, clock: { .now.addingTimeInterval(-11) })
    session.start()
    session.toggleList()
    session.toggle("dad.heart")
    session.toggle("mom")
    session.toggle("mom.ruth")
    return HomeView(session: session).preferredColorScheme(.dark)
}
#Preview("Light") { HomeView().preferredColorScheme(.light) }
#Preview("Counting down") {
    // 2 s in: the ring is decaying, Amen isn't available yet.
    let session = PrayerSession(graph: Sample.graph, clock: { .now.addingTimeInterval(-2) })
    session.start()
    return HomeView(session: session).preferredColorScheme(.light)
}
