import PlusPrayerDomain
import SwiftUI

/// An intention's page (detail-page.md "Intention page"; minimal slice):
/// no avatar; the person's name above the title (tappable → their page);
/// the intention as the title in the system sans (Title 2 semibold, wraps)
/// with a gold dot before it when held today; the carry card ("Print with
/// {alias} ✱" and the status line); the History preview filtered to it
/// (no Answered tile). Answered: gold "Answered · {date}" under the title
/// and no carry card.
///
/// Not yet: the ⋯ menu (Answered / Release / Edit), the pray button.
struct IntentionPage: View {
    let id: String

    @Environment(HomeModel.self) private var home
    @State private var pending: Bool?
    @State private var carryError: String?
    @ScaledMetric(relativeTo: .body) private var bloomHeight = PP.size.carriedMark.carryRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            if let page = home.intentionPage(id) {
                VStack(alignment: .leading, spacing: PP.space.xl) {
                    header(page)
                    if page.answered == nil {
                        carryCard(page)
                            .padding(.horizontal, PP.space.gutter)
                    }
                    if let preview = home.historyPreview(id) {
                        HistoryPreviewSection(subjectId: id, values: preview, today: home.today)
                    }
                }
                .padding(.vertical, PP.space.lg)
            }
        }
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: home.intentionCarryOffer(personId: home.intentionPage(id)?.personId ?? "",
                                               intentionId: id).startsOn) { pending = nil }
        .onDisappear { carryError = nil }
    }

    private func header(_ page: IntentionPageValues) -> some View {
        VStack(alignment: .leading, spacing: PP.space.xs) {
            NavigationLink(value: Route.subject(page.personId)) {
                Text(verbatim: page.personLabel)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
            }
            .buttonStyle(.plain)
            HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
                if page.heldToday {
                    HeldDot(held: true)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                }
                Text(verbatim: page.text)
                    .font(PP.type.intentionTitle)
                    .foregroundStyle(PP.color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityValue(page.heldToday ? L10n.Row.heldToday : "")
            }
            if let answered = page.answered {
                Text(verbatim: answered)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.heldGoldText)
            }
        }
        .padding(.horizontal, PP.space.gutter)
    }

    /// "Print with {alias} ✱" (on Me's intentions: "Print with your name ✱").
    /// Subtitle: "Instead of “{chosen}”" when another is chosen (on = swap);
    /// "Also carries {alias} · N places left" when the person isn't carried
    /// (on carries them too). Disabled with "Make room for {alias}" when
    /// that needs a place and none is free. Never silent, like the person's
    /// toggle.
    private func carryCard(_ page: IntentionPageValues) -> some View {
        let offer = home.intentionCarryOffer(personId: page.personId, intentionId: id)
        let isOn = pending ?? offer.startsOn
        var lines: [String] = []
        if !isOn, let replaced = offer.replaces.first { lines.append(L10n.Add.insteadOf(replaced.publicName)) }
        if !isOn && offer.alsoCarriesPerson && offer.hasRoom {
            lines.append(L10n.Add.alsoCarries(page.personLabel, left: offer.left))
        }
        let subtitle = lines.joined(separator: "\n")
        let title = L10n.Add.printWith(page.personLabel, isSelf: page.personIsSelf)
        let status = page.status.map {
            L10n.Page.status($0, about: .intention, person: page.personLabel)
        }
        return CarryCard(status: status, statusActionable: page.status?.isActionable ?? false) {
            VStack(alignment: .leading, spacing: PP.space.sm) {
                Toggle(isOn: Binding(get: { isOn }, set: { set($0, pool: offer.pool) })) {
                    CarryTitle.text(title, bloomHeight: bloomHeight, dynamicTypeSize: dynamicTypeSize)
                    if !subtitle.isEmpty { Text(subtitle) }
                }
                .ppSwitch()
                .disabled((!isOn && !offer.hasRoom) || !home.isOnline || pending != nil)
                .accessibilityLabel(title)
                .accessibilityHint(subtitle)
                if let line = home.isOnline ? carryError : L10n.Page.carryOffline {
                    Text(line)
                        .font(PP.type.bodySmall)
                        .foregroundStyle(PP.color.ink)
                }
                if !offer.hasRoom && !isOn {
                    Button(L10n.Page.makeRoom(for: page.personLabel)) {}
                        .tint(PP.color.primary)
                        .accessibilityHint(L10n.Add.makeRoomHint)
                }
            }
        }
    }

    private func set(_ on: Bool, pool: Int) {
        pending = on
        carryError = nil
        Task {
            do {
                try await home.choose(id, on)
            } catch {
                pending = nil
                carryError = switch error {
                case SetCarriedError.overLimit where on: L10n.Page.filledUp(pool: pool)
                case SetCarriedError.offline: L10n.Page.carryOffline
                default: L10n.Page.carryFailed
                }
            }
        }
    }
}

private struct IntentionPagePreview: View {
    let id: String
    @State private var home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))

    var body: some View {
        NavigationStack {
            IntentionPage(id: id)
                .routes()
        }
        .environment(home)
        .task { await home.run() }
    }
}

#Preview("Chosen") { IntentionPagePreview(id: "dad-1").preferredColorScheme(.dark) }
#Preview("Not chosen") { IntentionPagePreview(id: "dad-2").preferredColorScheme(.light) }
#Preview("Answered") { IntentionPagePreview(id: "mom-1").preferredColorScheme(.light) }
#Preview("Large type") { IntentionPagePreview(id: "self-1").dynamicTypeSize(.accessibility2) }
