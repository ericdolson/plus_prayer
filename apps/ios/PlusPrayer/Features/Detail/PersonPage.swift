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
/// Praying in place (detail-page.md): the blue capsule in the pray-button
/// slot ("Pray for Dad"; "Pray" on the self page) starts a prayer here,
/// with the person checked. What isn't the subject fades out together
/// (the carry card, the History preview, the Intentions ＋ or the first-
/// intention button, ‹); Cancel takes ‹'s place; the capsule becomes the
/// pray button with the pill beside it. The name gets its check (its
/// avatar's ring follows it), intentions get Home's; "Pray for others"
/// goes to Home still praying. After Amen it all fades back as the closing
/// sheet goes, so the new counts land in view.
///
/// Not yet: the ⋯ menu.
struct PersonPage: View {
    let id: String

    @Environment(HomeModel.self) private var home
    @Environment(PrayerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmingDiscard = false
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

    /// Praying on this page, from the start through the closing sheet: the
    /// page is stripped to the subject.
    private var inPrayer: Bool { session.page == id }
    /// Praying here now (not yet closing): checks, Cancel, the prayer bar.
    private var praying: Bool { inPrayer && session.isPraying }

    var body: some View {
        ScrollView {
            if let page = home.page(id) {
                VStack(alignment: .leading, spacing: PP.space.xl) {
                    header(page)
                    if !inPrayer {
                        carryCard(page)
                            .padding(.horizontal, PP.space.gutter)
                            .transition(.opacity)
                    }
                    // In prayer with no intentions there's nothing to show here.
                    if !(inPrayer && page.intentions.isEmpty) {
                        intentions(page)
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
                // Out together, back together (~250 ms); Reduce Motion: a quick fade.
                .animation(reduceMotion ? .easeOut(duration: PP.duration.quick)
                                        : .easeInOut(duration: PP.duration.strip),
                           value: inPrayer)
            }
        }
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaBar(edge: .bottom) {
            if let page = home.page(id) {
                PagePrayBar(label: L10n.Page.pray(for: page.isSelf ? nil : page.label),
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
        .sheet(item: $adding) { model in AddSheet(model: model) }
        .navigationDestination(isPresented: $choosingPrintsWith) { PrintsWithList(personId: id) }
        .onChange(of: home.nameCarryOffer(id).startsOn) { pendingCarry = nil }
        // Leaving the page (back, or another page pushed over it) clears
        // the failure line.
        .onDisappear { carryError = nil }
    }

    // MARK: The person

    /// In prayer the name gets its check in the trailing slot, like a Home
    /// row, and a tap on the person checks it; the avatar's ring follows
    /// (held today, or held in this prayer, as on Home).
    private func header(_ page: PersonPageValues) -> some View {
        VStack(spacing: PP.space.xs) {
            HStack(spacing: 0) {
                // Balances the check so the avatar stays centered.
                Color.clear.frame(width: PP.size.check, height: PP.size.check)
                Spacer(minLength: PP.space.sm)
                MonogramAvatar(initials: page.initials, tone: page.tone, size: PP.size.avatar.person)
                    .heldRing(page.heldToday || session.isHeld(id), step: .large)
                Spacer(minLength: PP.space.sm)
                CheckSlot(check: praying ? session.check(id) : nil)
            }
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
        .contentShape(Rectangle())
        .onTapGesture { if praying { session.toggle(id) } }
        .accessibilityElement(children: .combine)
        .accessibilityValue(praying ? session.check(id).spoken : "")
        .accessibilityAddTraits(praying ? .isToggle : [])
        .accessibilityIdentifier("page.person")
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
                // content); none while the prominent first-intention button
                // shows, nor in prayer.
                if !page.intentions.isEmpty && !inPrayer {
                    Button { addIntention() } label: {
                        PPIcon.add
                            .font(PP.type.sectionTitle)
                            .frame(minWidth: PP.size.hitTarget, minHeight: PP.size.hitTarget)
                            .contentShape(Rectangle())
                    }
                    .tint(PP.color.primary)
                    .accessibilityLabel(L10n.Page.addIntention(for: page.label, isSelf: page.isSelf))
                    .transition(.opacity)
                }
            }
            // The title row keeps the ＋'s height, so nothing moves as it goes.
            .frame(minHeight: page.intentions.isEmpty ? nil : PP.size.hitTarget)
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
                        if praying {
                            // In prayer a tap checks (Home's rules), as on Home.
                            intentionRow(intention, check: session.check(intention.id)) {
                                session.toggle(intention.id)
                            }
                        } else {
                            NavigationLink(value: Route.subject(intention.id)) {
                                intentionRow(intention, check: nil)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func intentionRow(_ intention: RowItem, check: HoldState?, onTap: @escaping () -> Void = {}) -> some View {
        IntentionRow(text: intention.label, carried: intention.carried,
                     held: intention.heldToday || session.isHeld(intention.id),
                     secondary: intention.secondary.map {
                         SecondaryLine(text: $0.text, kind: $0.answered ? .answered : .notice)
                     },
                     // No thread: the page is the name.
                     thread: nil,
                     accessibilityLabel: intention.accessibilityLabel(
                        heldOutsidePrayer: check == nil && intention.heldToday),
                     check: check, onTap: onTap)
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
            PersonPage(id: id)
                .routes()
        }
        .overlay { Halo(active: session.isPraying, flare: session.amenCount) }
        .environment(home)
        .environment(session)
        .task { await home.run() }
    }
}

#Preview("Dad") { PersonPagePreview(id: "dad").preferredColorScheme(.dark) }
#Preview("Not carried") { PersonPagePreview(id: "bea").preferredColorScheme(.light) }
#Preview("No intentions") { PersonPagePreview(id: "daniel").preferredColorScheme(.light) }
#Preview("Me") { PersonPagePreview(id: "self").preferredColorScheme(.dark) }
#Preview("Dad · large type") { PersonPagePreview(id: "dad").dynamicTypeSize(.accessibility2) }
