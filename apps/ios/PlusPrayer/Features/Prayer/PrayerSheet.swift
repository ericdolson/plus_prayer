import PlusPrayerDomain
import SwiftUI

/// The end of a prayer, in one native sheet (design-direction §0: Tier B, the
/// ring button, cluster and seal inside stay Tier A). It shows the Amen
/// invitation when a prayer ends without the list, then becomes the closing
/// sheet in place once the prayer is written, so there's no dismiss and
/// re-present between them. Sized to its content.
///
/// The invitation can't be swiped away (its Amen is the way out, with or
/// without the list); the closing sheet can, and leaving it ends the session.
struct PrayerSheet: View {
    @Environment(HomeModel.self) private var home
    @Environment(PrayerSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if session.isInvited, let card = home.card {
                InvitationView(card: card, holdingSince: session.holdingListSince,
                               onHold: { session.holdList() },
                               onAmen: amenFromInvitation)
                    .transition(.opacity)
            } else if let prayer = session.closing {
                ClosingView(prayer: prayer,
                            onSaveNote: { text in Task { await home.saveNote(text, prayerId: prayer.id) } },
                            onDone: { session.close() })
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: PP.duration.settle), value: session.isInvited)
        .fittedDetent()
        .interactiveDismissDisabled(session.isInvited)
        .presentationDragIndicator(session.isInvited ? .hidden : .visible)
    }

    private func amenFromInvitation() {
        guard let prayer = session.amenFromInvitation() else { return }
        Task { await home.log(prayer) }
    }
}

// MARK: The Amen invitation

/// Amen without the list (prayer-flow.md, app-brief §3): a standalone, quiet
/// invitation, "Hold the 4,345 on List 52 in your prayer", and who'll be
/// carried. Tap → the same countdown as the pray button (a small pie running
/// down inside it), the line shifts to "Holding the 4,345 on List 52"; Amen
/// after ~5 s, and they may stay longer. Amen before tapping finishes without the list.
private struct InvitationView: View {
    let card: CardValues
    let holdingSince: Date?
    let onHold: () -> Void
    let onAmen: () -> Void

    private var holding: Bool { holdingSince != nil }

    private var line: String {
        holding ? L10n.Invitation.holding(people: card.people, list: card.listNumber)
                : L10n.Invitation.hold(people: card.people, list: card.listNumber)
    }

    var body: some View {
        VStack(spacing: PP.space.xl) {
            WaxSeal(variant: card.sealVariant, size: PP.size.seal.invitation)

            VStack(spacing: PP.space.md) {
                Text(line)
                    .font(PP.type.displayLine)
                    .foregroundStyle(PP.color.ink)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: PP.duration.settle), value: holding)
                    .onChange(of: holding) { _, now in
                        if now { AccessibilityNotification.Announcement(line).post() }
                    }

                AvatarCluster(people: card.carried.map {
                                  AvatarCluster.Person(id: $0.id, initials: $0.initials, tone: $0.tone,
                                                       name: $0.spokenName)
                              },
                              trailing: L10n.Invitation.willBe(card.listNumber + 1),
                              avatarSize: PP.size.cluster.avatarLarge,
                              surface: PP.color.sheet,
                              centered: true)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.heldGoldText)
            }

            CountdownButton(startedAt: holdingSince, diameter: PP.size.prayButton.invitation,
                            minimum: PrayerSession.minimum, idleLabel: line,
                            onStart: onHold, onComplete: onAmen) {
                PPIcon.pray
                    .font(.system(size: PP.size.bar.icon, weight: .regular))
                    .foregroundStyle(PP.color.onPrimary)
            }

            // Finish without the list: only before tapping in.
            Button(L10n.Prayer.amen, action: onAmen)
                .font(PP.type.label)
                .tint(PP.color.ink)
                .opacity(holding ? 0 : 1)
                .disabled(holding)
                .animation(.easeOut(duration: PP.duration.settle), value: holding)
        }
        .padding(.horizontal, PP.space.xl)
        .padding(.top, PP.space.xxl)
        .padding(.bottom, PP.space.lg)
        .frame(maxWidth: .infinity)
    }
}

// MARK: The closing sheet

/// After the final Amen (app-brief §3): the closing line when the prayer held
/// the list ("You'll be carried on List 53."), and an optional private note.
/// The prayer is already written (or waiting on the device); the note follows
/// it.
private struct ClosingView: View {
    let prayer: NewPrayer
    let onSaveNote: (String) -> Void
    let onDone: () -> Void

    @State private var writing = false
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(spacing: PP.space.xl) {
            if prayer.includesList {
                Text(L10n.Closing.carried(prayer.listContextNumber + 1))
                    .font(PP.type.displayLine)
                    .foregroundStyle(PP.color.ink)
                    .multilineTextAlignment(.center)
            }

            if writing {
                VStack(spacing: PP.space.lg) {
                    TextField(L10n.Closing.noteHint, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($noteFocused)
                        .textInputAutocapitalization(.sentences)
                        .onChange(of: note) { _, text in
                            if text.count > TextCap.note { note = String(text.prefix(TextCap.note)) }
                        }
                    Button {
                        onSaveNote(note)
                        onDone()
                    } label: {
                        Text(L10n.Common.save).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(PP.color.primary)
                    .controlSize(.large)
                }
                .onAppear { noteFocused = true }
            } else {
                VStack(spacing: PP.space.sm) {
                    Button {
                        writing = true
                    } label: {
                        Label { Text(L10n.Closing.addToJournal) } icon: { PPIcon.note }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .tint(PP.color.ink)
                    .controlSize(.large)

                    Button(L10n.Common.done, action: onDone)
                        .tint(PP.color.ink)
                        .controlSize(.large)
                }
            }
        }
        .padding(.horizontal, PP.space.xl)
        .padding(.top, PP.space.xxl)
        .padding(.bottom, PP.space.lg)
        .frame(maxWidth: .infinity)
    }
}

// MARK: Fitted detent

extension View {
    /// A sheet exactly as tall as its content (it follows the content as it
    /// changes: the invitation becoming the closing sheet, the note opening).
    func fittedDetent() -> some View { modifier(FittedDetent()) }
}

private struct FittedDetent: ViewModifier {
    @State private var height: CGFloat?

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
            .presentationDetents(height.map { [.height($0)] } ?? [.medium])
    }
}

// MARK: Previews (on the mock)

/// The sheet's content on its own, at a given point in the flow.
private struct PrayerSheetPreview: View {
    enum Moment { case invitation, holding, closingWithList, closingWithout }

    @State private var home: HomeModel
    @State private var session: PrayerSession
    private let moment: Moment

    init(_ moment: Moment) {
        let home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))
        // Started 8 s ago; the invitation tapped 2 s ago.
        let base = Date.now
        var offset: TimeInterval = -8
        let session = PrayerSession(graph: { home.graph }, clock: { base.addingTimeInterval(offset) })
        session.start(list: ListContext(listId: "list-52", listNumber: 52))
        offset = 0
        switch moment {
        case .invitation, .holding:
            _ = session.amen(prayedWithListToday: false)
            if moment == .holding {
                offset = -2
                session.holdList()
                offset = 0
            }
        case .closingWithList:
            session.toggleList()
            _ = session.amen(prayedWithListToday: false)
        case .closingWithout:
            _ = session.amen(prayedWithListToday: true)
        }
        _home = State(initialValue: home)
        _session = State(initialValue: session)
        self.moment = moment
    }

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) { PrayerSheet() }
            .environment(home)
            .environment(session)
            .task { await home.run() }
    }
}

#Preview("Invitation") { PrayerSheetPreview(.invitation).preferredColorScheme(.dark) }
#Preview("Invitation, holding") { PrayerSheetPreview(.holding).preferredColorScheme(.dark) }
#Preview("Closing, with the list") { PrayerSheetPreview(.closingWithList).preferredColorScheme(.light) }
#Preview("Closing, without") { PrayerSheetPreview(.closingWithout).preferredColorScheme(.dark) }
