import PlusPrayerDomain
import SwiftUI

/// A name's page (detail-page.md, DECIDED 2026-11-03 + the 2026-11-07
/// notes): the person (a 96 pt avatar, the alias with the printed name
/// under it, the status line), their carry row (not on the self page), and
/// their intentions with the way to add one. Pushed from a Home row, and
/// where adding a name lands.
///
/// Not yet: the counts, History, the ⋯ menu, the pray button and praying
/// in place, and intention pages.
struct PersonPage: View {
    let id: String

    @Environment(HomeModel.self) private var home
    @State private var adding: AddSheetModel?
    /// The carry toggle while setCarriedItems is on its way: shown at once,
    /// until the name's flag catches up (or the call fails).
    @State private var pendingCarry: Bool?
    @ScaledMetric(relativeTo: .body) private var bloomHeight = PP.size.carriedMark.carryRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            if let page = home.page(id) {
                VStack(alignment: .leading, spacing: PP.space.xl) {
                    header(page)
                    if !page.isSelf { carryRow(page) }
                    intentions(page)
                }
                .padding(.vertical, PP.space.lg)
            }
        }
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $adding) { model in AddSheet(model: model) }
        .onChange(of: home.nameCarryOffer(id).startsOn) { pendingCarry = nil }
    }

    // MARK: The person

    private func header(_ page: PersonPageValues) -> some View {
        VStack(spacing: PP.space.xs) {
            MonogramAvatar(initials: page.initials, tone: page.tone, size: PP.size.avatar.person)
                .heldRing(page.heldToday)
                .padding(.bottom, PP.space.sm)
            Text(verbatim: page.label)
                .font(PP.type.displayTitle)
                .foregroundStyle(PP.color.ink)
            if let printed = page.printedName {
                Text(verbatim: printed)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.inkMuted)
            }
            if let status = page.status {
                Text(L10n.Page.status(status, name: page.label, isSelf: page.isSelf))
                    .font(PP.type.bodySmall)
                    // Weight follows state, as on the card: what's still to
                    // do in ink, what's done (or absent) muted.
                    .foregroundStyle(isActionable(status) ? PP.color.ink : PP.color.inkMuted)
                    .padding(.top, PP.space.xs)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PP.space.gutter)
        .accessibilityElement(children: .combine)
    }

    private func isActionable(_ status: PersonPageValues.Status) -> Bool {
        switch status {
        case .list(let tomorrow, _): tomorrow.isActionable
        case .closing: true
        case .notOnList: false
        }
    }

    // MARK: The carry row

    /// A native toggle with the add sheet's meter as its subtitle. Off with
    /// no room: disabled, with "Make room for {alias}" under it (inert until
    /// Membership / Your portion exist).
    private func carryRow(_ page: PersonPageValues) -> some View {
        let offer = home.nameCarryOffer(id)
        let isOn = pendingCarry ?? offer.startsOn
        let meter = L10n.Add.carryMeter(carryMeter(offer, kind: .soul, isOn: isOn))
        let binding = Binding(get: { isOn }, set: { setCarried($0) })
        return VStack(alignment: .leading, spacing: PP.space.sm) {
            Toggle(isOn: binding) {
                CarryTitle.text(bloomHeight: bloomHeight, dynamicTypeSize: dynamicTypeSize)
                Text(meter)
            }
            .ppSwitch()
            .disabled(!offer.hasRoom || !home.isOnline || pendingCarry != nil)
            .accessibilityLabel(L10n.Add.carryTitle)
            .accessibilityHint(meter)
            if !offer.hasRoom && !isOn {
                Button(L10n.Page.makeRoom(for: page.label)) {}
                    .tint(PP.color.primary)
                    .accessibilityHint(L10n.Add.makeRoomHint)
            }
        }
        .padding(.horizontal, PP.space.gutter)
    }

    private func setCarried(_ on: Bool) {
        pendingCarry = on
        Task {
            do {
                try await home.setCarried(id, on)
            } catch {
                // The toggle goes back to the name's flag.
                pendingCarry = nil
            }
        }
    }

    // MARK: Intentions

    private func intentions(_ page: PersonPageValues) -> some View {
        VStack(alignment: .leading, spacing: PP.space.sm) {
            Text(L10n.Page.intentions)
                .font(PP.type.name)
                .foregroundStyle(PP.color.ink)
                .padding(.horizontal, PP.space.gutter)
                .accessibilityAddTraits(.isHeader)
            if page.intentions.isEmpty {
                // None yet: the invitation, prominent.
                Button { addIntention() } label: {
                    Label { Text(L10n.Page.firstIntention(for: page.label, isSelf: page.isSelf)) } icon: { PPIcon.add }
                }
                .buttonStyle(.glassProminent)
                .tint(PP.color.primary)
                .padding(.horizontal, PP.space.gutter)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(page.intentions.enumerated()), id: \.element.id) { index, intention in
                        IntentionRow(text: intention.label, carried: intention.carried, held: intention.heldToday,
                                     secondary: intention.secondary.map {
                                         SecondaryLine(text: $0.text, kind: $0.answered ? .answered : .notice)
                                     },
                                     thread: index == page.intentions.count - 1 ? .lastBranch : .branch,
                                     accessibilityLabel: intention.accessibilityLabel(
                                        heldOutsidePrayer: intention.heldToday))
                    }
                }
                Button { addIntention() } label: {
                    Label { Text(L10n.Page.addIntention(for: page.label, isSelf: page.isSelf)) } icon: { PPIcon.add }
                }
                .tint(PP.color.primary)
                .padding(.horizontal, PP.space.gutter)
            }
        }
    }

    private func addIntention() {
        adding = AddSheetModel(home: home, intentionFor: id)
    }
}

// MARK: Previews (on the mock)

private struct PersonPagePreview: View {
    let id: String
    @State private var home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))

    var body: some View {
        NavigationStack {
            PersonPage(id: id)
        }
        .environment(home)
        .task { await home.run() }
    }
}

#Preview("Dad") { PersonPagePreview(id: "dad").preferredColorScheme(.dark) }
#Preview("Not carried") { PersonPagePreview(id: "bea").preferredColorScheme(.light) }
#Preview("No intentions") { PersonPagePreview(id: "daniel").preferredColorScheme(.light) }
#Preview("Me") { PersonPagePreview(id: "self").preferredColorScheme(.dark) }
