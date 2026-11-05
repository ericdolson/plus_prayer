import SwiftUI

/// Home (screens.md, design-direction §3–§6). The shell for now: header,
/// floating bar and scroll edges over sample rows. The community card,
/// prayer mode, search and real data come in later slices.
struct HomeView: View {
    @State private var filter: HomeFilter = .all
    @State private var dadHeld = true

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                SampleRows(dadHeld: $dadHeld)
            }
            .padding(.top, PP.space.sm)
            .padding(.bottom, PP.space.xl)
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .safeAreaBar(edge: .top) {
            HomeHeader(initials: "EO", tone: 7, streakState: .sealedToday, streakDays: 6,
                       filter: $filter, counts: HomeFilterCounts(all: 11, stillToHold: 8, carried: 8))
        }
        .safeAreaBar(edge: .bottom) {
            HomeBar()
        }
        .background(PP.color.ground)
    }
}

/// Placeholder content until the mock data source exists (slice 4).
private struct SampleRows: View {
    @Binding var dadHeld: Bool

    var body: some View {
        NameRow(initials: "EO", tone: 7, label: "Me", carried: true, held: false,
                hasIntentions: true, accessibilityLabel: "Me, carried")
        IntentionRow(text: "Patience with the new job", carried: true, held: false,
                     thread: .lastBranch, accessibilityLabel: "Patience with the new job, carried")

        NameRow(initials: "D", tone: 0, label: "Dad", carried: true, held: dadHeld,
                hasIntentions: true, accessibilityLabel: "Dad, carried", onTap: { dadHeld.toggle() })
            .padding(.top, PP.space.groupGap)
        IntentionRow(text: "Healing after his surgery", carried: true, held: dadHeld,
                     thread: .branch, accessibilityLabel: "Healing after his surgery, carried",
                     onTap: { dadHeld.toggle() })
        IntentionRow(text: "Rest for his heart", carried: false, held: false,
                     thread: .lastBranch, accessibilityLabel: "Rest for his heart")

        NameRow(initials: "M", tone: 8, label: "Mom", carried: true, held: false,
                hasIntentions: true, accessibilityLabel: "Mom, carried")
            .padding(.top, PP.space.groupGap)
        IntentionRow(text: "A safe delivery for Ruth", carried: false, held: false,
                     secondary: SecondaryLine(text: "Answered · Oct 19", kind: .answered),
                     thread: .lastBranch, accessibilityLabel: "A safe delivery for Ruth. Answered, October 19")

        ForEach(Self.more, id: \.name) { person in
            NameRow(initials: person.initials, tone: person.tone, label: person.name, carried: person.carried,
                    held: false, accessibilityLabel: person.name)
                .padding(.top, PP.space.groupGap)
        }
    }

    private static let more: [(name: String, initials: String, tone: Int, carried: Bool)] = [
        ("Daniel Kim", "DK", 10, true), ("Olivia Park", "OP", 13, true), ("Uncle Ray", "U", 14, true),
        ("Grandma June", "G", 3, false), ("Aunt Bea", "A", 6, false), ("Sam", "S", 9, false),
    ]
}

#Preview("Dark") { HomeView().preferredColorScheme(.dark) }
#Preview("Light") { HomeView().preferredColorScheme(.light) }
