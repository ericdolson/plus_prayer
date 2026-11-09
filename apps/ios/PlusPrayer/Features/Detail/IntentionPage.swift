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
/// Praying in place (detail-page.md): the "Pray" capsule starts a prayer
/// here with the intention checked (its name with it, by the selection
/// rules). The carry card, the History preview and ‹ fade out; the person's
/// name stays above as plain text (not checkable, not a link): it's held
/// whenever the intention is. "Pray for others" under the intention goes to
/// Home still praying. Answered intentions can be prayed for too.
///
/// Not yet: the ⋯ menu (Answered / Release / Edit).
struct IntentionPage: View {
    let id: String

    @Environment(HomeModel.self) private var home
    @Environment(PrayerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmingDiscard = false
    @State private var pending: Bool?
    @State private var carryError: String?
    @ScaledMetric(relativeTo: .body) private var bloomHeight = PP.size.carriedMark.carryRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Praying on this page, through the closing sheet: stripped to the intention.
    private var inPrayer: Bool { session.page == id }
    /// Praying here now: its check, Cancel, the prayer bar.
    private var praying: Bool { inPrayer && session.isPraying }

    var body: some View {
        ScrollView {
            if let page = home.intentionPage(id) {
                VStack(alignment: .leading, spacing: PP.space.xl) {
                    header(page)
                    if page.answered == nil && !inPrayer {
                        carryCard(page)
                            .padding(.horizontal, PP.space.gutter)
                            .transition(.opacity)
                    }
                    if inPrayer {
                        PrayForOthersLink { session.leavePage() }
                            .transition(.opacity)
                    }
                    if !inPrayer, let preview = home.historyPreview(id) {
                        HistoryPreviewSection(subjectId: id, values: preview, today: home.today)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, PP.space.lg)
                .animation(reduceMotion ? .easeOut(duration: PP.duration.quick)
                                        : .easeInOut(duration: PP.duration.strip),
                           value: inPrayer)
            }
        }
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .pagePrayBar {
            if home.intentionPage(id) != nil {
                PagePrayBar(label: L10n.Page.pray(for: nil),
                            prayerStartedAt: praying ? session.startedAt : nil,
                            prayingWith: home.prayingWith,
                            onPray: { session.start(list: home.listContext, on: id) },
                            onAmen: { session.amen(logTo: home) })
            }
        }
        .navigationBarBackButtonHidden(inPrayer)
        .toolbar {
            if praying {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Prayer.cancel) { session.cancel(confirming: &confirmingDiscard) }
                }
            }
        }
        .swipeBackWhileBackHidden(praying)
        .discardPrayerDialog(isPresented: $confirmingDiscard, session: session)
        .onChange(of: home.intentionCarryOffer(personId: home.intentionPage(id)?.personId ?? "",
                                               intentionId: id).startsOn) { pending = nil }
        .onDisappear { carryError = nil }
    }

    /// In prayer: the person's name is plain text (not a link, not a
    /// check); the intention gets Home's check in the trailing slot, and a
    /// tap on it checks; its gold dot follows (held today, or in this prayer).
    private func header(_ page: IntentionPageValues) -> some View {
        let held = page.heldToday || session.isHeld(id)
        return VStack(alignment: .leading, spacing: PP.space.xs) {
            if inPrayer {
                personName(page)
            } else {
                NavigationLink(value: Route.subject(page.personId)) { personName(page) }
                    .buttonStyle(.plain)
            }
            HStack(alignment: .top, spacing: PP.space.sm) {
                HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
                    if held {
                        HeldDot(held: true)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                            .transition(.opacity)
                    }
                    Text(verbatim: page.text)
                        .font(PP.type.intentionTitle)
                        .foregroundStyle(PP.color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityValue(page.heldToday && !praying ? L10n.Row.heldToday : "")
                }
                Spacer(minLength: 0)
                // On the first line, like a Home row's.
                CheckSlot(check: praying ? session.check(id) : nil)
            }
            .contentShape(Rectangle())
            .onTapGesture { if praying { session.toggle(id) } }
            .accessibilityElement(children: praying ? .combine : .contain)
            .accessibilityValue(praying ? session.check(id).spoken : "")
            .accessibilityAddTraits(praying ? .isToggle : [])
            .accessibilityIdentifier("page.intention")
            if let answered = page.answered {
                Text(verbatim: answered)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.heldGoldText)
            }
        }
        .padding(.horizontal, PP.space.gutter)
    }

    private func personName(_ page: IntentionPageValues) -> some View {
        Text(verbatim: page.personLabel)
            .font(PP.type.bodySmall)
            .foregroundStyle(PP.color.inkMuted)
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
    @State private var home: HomeModel
    @State private var session: PrayerSession

    init(id: String) {
        self.id = id
        let home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))
        _home = State(initialValue: home)
        _session = State(initialValue: PrayerSession(graph: { home.graph }))
    }

    var body: some View {
        NavigationStack {
            IntentionPage(id: id)
                .routes()
        }
        .overlay { Halo(active: session.isPraying, flare: session.amenCount) }
        .environment(home)
        .environment(session)
        .task { await home.run() }
    }
}

#Preview("Chosen") { IntentionPagePreview(id: "dad-1").preferredColorScheme(.dark) }
#Preview("Not chosen") { IntentionPagePreview(id: "dad-2").preferredColorScheme(.light) }
#Preview("Answered") { IntentionPagePreview(id: "mom-1").preferredColorScheme(.light) }
#Preview("Large type") { IntentionPagePreview(id: "self-1").dynamicTypeSize(.accessibility2) }
