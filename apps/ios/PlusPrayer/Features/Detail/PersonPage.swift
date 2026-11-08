import PlusPrayerDomain
import SwiftUI

/// A name's page, a dashboard (detail-page.md, 2026-11-03 + 2026-11-07/08
/// + Q32): the person (a 96 pt avatar, the alias with the printed name
/// under it), the carry card (the toggle, "Prints with", the status line;
/// the self page's card holds only the status), their intentions with the
/// ＋ on the section title, and the History preview (its doors open
/// History filtered to them). Pushed from a Home row, and where adding a
/// name lands; an intention row pushes its page.
///
/// Not yet: the ⋯ menu, the pray button and praying in place.
struct PersonPage: View {
    let id: String

    @Environment(HomeModel.self) private var home
    @State private var adding: AddSheetModel?
    /// The carry toggle while setCarriedItems is on its way: shown at once,
    /// until the person's flag catches up (or the call fails).
    @State private var pendingCarry: Bool?
    /// Why the toggle flipped back (ink, like other errors), under the row
    /// until the next tap on the toggle or leaving the page.
    @State private var carryError: String?
    @State private var choosingPrintsWith = false
    @ScaledMetric(relativeTo: .body) private var bloomHeight = PP.size.carriedMark.carryRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            if let page = home.page(id) {
                VStack(alignment: .leading, spacing: PP.space.xl) {
                    header(page)
                    carryCard(page)
                        .padding(.horizontal, PP.space.gutter)
                    intentions(page)
                    if let preview = home.historyPreview(id) {
                        HistoryPreviewSection(subjectId: id, values: preview, today: home.today)
                    }
                }
                .padding(.vertical, PP.space.lg)
            }
        }
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $adding) { model in AddSheet(model: model) }
        .navigationDestination(isPresented: $choosingPrintsWith) { PrintsWithList(personId: id) }
        .onChange(of: home.nameCarryOffer(id).startsOn) { pendingCarry = nil }
        // Leaving the page (back, or another page pushed over it) clears
        // the failure line.
        .onDisappear { carryError = nil }
    }

    // MARK: The person

    private func header(_ page: PersonPageValues) -> some View {
        VStack(spacing: PP.space.xs) {
            MonogramAvatar(initials: page.initials, tone: page.tone, size: PP.size.avatar.person)
                .heldRing(page.heldToday, step: .large)
                .padding(.bottom, PP.space.sm)
            Text(verbatim: page.label)
                .font(PP.type.displayTitle)
                .foregroundStyle(PP.color.ink)
            if let printed = page.printedName {
                Text(verbatim: printed)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.inkMuted)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PP.space.gutter)
        .accessibilityElement(children: .combine)
    }

    // MARK: The carry card

    private func statusText(_ page: PersonPageValues) -> String? {
        page.status.map { L10n.Page.status($0, about: page.isSelf ? .me : .person(page.label)) }
    }

    @ViewBuilder private func carryCard(_ page: PersonPageValues) -> some View {
        let actionable = page.status?.isActionable ?? false
        if page.isSelf {
            CarryCard(status: statusText(page), statusActionable: actionable)
        } else {
            CarryCard(status: statusText(page), statusActionable: actionable) {
                carryToggle(page)
                if let chosen = page.printsWith, (pendingCarry ?? true) {
                    printsWithRow(chosen)
                }
            }
        }
    }

    /// The native toggle; its subtitle is the meter (one place = one person).
    /// Off and full (or on the free tier): disabled, "Make room for {alias}"
    /// under it (inert). Turning off asks nothing and is never blocked
    /// online. Never silent: offline it's disabled with "Needs a
    /// connection."; a failed change flips back and says why.
    @ViewBuilder private func carryToggle(_ page: PersonPageValues) -> some View {
        let offer = home.nameCarryOffer(id)
        let isOn = pendingCarry ?? offer.startsOn
        let meter = L10n.Page.carryMeter(nameCarryMeter(offer))
        let binding = Binding(get: { isOn }, set: { setCarried($0, pool: offer.pool) })
        VStack(alignment: .leading, spacing: PP.space.sm) {
            Toggle(isOn: binding) {
                CarryTitle.text(bloomHeight: bloomHeight, dynamicTypeSize: dynamicTypeSize)
                Text(meter)
            }
            .ppSwitch()
            .disabled((!isOn && !offer.hasRoom) || !home.isOnline || pendingCarry != nil)
            .accessibilityLabel(L10n.Add.carryTitle)
            .accessibilityHint(meter)
            if let line = carryFootnote {
                Text(line)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.ink)
                    .transition(.opacity)
            }
            if !offer.hasRoom && !isOn {
                Button(L10n.Page.makeRoom(for: page.label)) {}
                    .tint(PP.color.primary)
                    .accessibilityHint(L10n.Add.makeRoomHint)
            }
        }
        .animation(.easeOut(duration: PP.duration.quick), value: carryFootnote)
    }

    /// The line under the toggle: offline, else why the last change flipped back.
    private var carryFootnote: String? {
        home.isOnline ? carryError : L10n.Page.carryOffline
    }

    private func setCarried(_ on: Bool, pool: Int) {
        pendingCarry = on
        carryError = nil
        Task {
            do {
                try await home.setCarried(id, on)
            } catch {
                // Flips back to the person's flag, and says why.
                pendingCarry = nil
                carryError = switch error {
                case SetCarriedError.overLimit where on: L10n.Page.filledUp(pool: pool)
                case SetCarriedError.offline: L10n.Page.carryOffline
                default: L10n.Page.carryFailed
                }
            }
        }
    }

    /// "Prints with  Healing after his su… ›": pushes the native check list.
    private func printsWithRow(_ chosen: [String]) -> some View {
        let value = L10n.Page.printsWithValue(chosen)
        return Button { choosingPrintsWith = true } label: {
            HStack(spacing: PP.space.sm) {
                Text(L10n.Page.printsWith)
                    .foregroundStyle(PP.color.ink)
                Spacer(minLength: PP.space.sm)
                Text(verbatim: value)
                    .foregroundStyle(PP.color.inkMuted)
                    .lineLimit(1)
                PPIcon.disclosure
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
            }
            .font(PP.type.body)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Page.printsWith)
        .accessibilityValue(value)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Intentions

    private func intentions(_ page: PersonPageValues) -> some View {
        VStack(alignment: .leading, spacing: PP.space.sm) {
            HStack {
                sectionTitle(L10n.Page.intentions)
                Spacer(minLength: 0)
                // A plain action-blue ＋ on the title (no glass: it's in the
                // content); none while the prominent first-intention button shows.
                if !page.intentions.isEmpty {
                    Button { addIntention() } label: {
                        PPIcon.add
                            .font(PP.type.sectionTitle)
                            .frame(minWidth: PP.size.hitTarget, minHeight: PP.size.hitTarget)
                            .contentShape(Rectangle())
                    }
                    .tint(PP.color.primary)
                    .accessibilityLabel(L10n.Page.addIntention(for: page.label, isSelf: page.isSelf))
                }
            }
            .padding(.leading, PP.space.gutter)
            .padding(.trailing, PP.space.sm)
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
                    ForEach(page.intentions) { intention in
                        NavigationLink(value: Route.subject(intention.id)) {
                            IntentionRow(text: intention.label, carried: intention.carried, held: intention.heldToday,
                                         secondary: intention.secondary.map {
                                             SecondaryLine(text: $0.text, kind: $0.answered ? .answered : .notice)
                                         },
                                         // No thread: the page is the name.
                                         thread: nil,
                                         accessibilityLabel: intention.accessibilityLabel(
                                            heldOutsidePrayer: intention.heldToday))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(PP.type.sectionTitle)
            .foregroundStyle(PP.color.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func addIntention() {
        adding = AddSheetModel(home: home, intentionFor: id)
    }
}

/// Every pushed page: a name's or an intention's, by the subject's kind.
struct SubjectPage: View {
    let id: String
    @Environment(HomeModel.self) private var home

    var body: some View {
        if home.intentionPage(id) != nil {
            IntentionPage(id: id)
        } else {
            PersonPage(id: id)
        }
    }
}

// MARK: Previews (on the mock)

private struct PersonPagePreview: View {
    let id: String
    @State private var home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))

    var body: some View {
        NavigationStack {
            PersonPage(id: id)
                .routes()
        }
        .environment(home)
        .task { await home.run() }
    }
}

#Preview("Dad") { PersonPagePreview(id: "dad").preferredColorScheme(.dark) }
#Preview("Not carried") { PersonPagePreview(id: "bea").preferredColorScheme(.light) }
#Preview("No intentions") { PersonPagePreview(id: "daniel").preferredColorScheme(.light) }
#Preview("Me") { PersonPagePreview(id: "self").preferredColorScheme(.dark) }
#Preview("Dad · large type") { PersonPagePreview(id: "dad").dynamicTypeSize(.accessibility2) }
