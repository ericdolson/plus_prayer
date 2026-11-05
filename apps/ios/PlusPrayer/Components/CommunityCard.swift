import PlusPrayerDomain
import SwiftUI

/// The community card (design-direction §6): the value of the app, at the top
/// of Home. A flat `cardSurface`, no shadow or border. It answers two
/// questions at a glance: is the list alive (the world block) and are my people
/// going onto the next list (the you block, the one thing you can act on).
///
///     ╭──────────────────────────────────────╮  gold border when you've
///     │▓ seal ▓  List 52                     │  prayed with the list today
///     │▓▓▓▓▓    4,345 people · 3,881 prayers │
///     │         ● 239 praying now            │
///     │ (EO)(D)(M)(DK)(OP)(U)                │
///     │ Pray to carry them onto List 53      │
///     ╰──────────────────────────────────────╯
///
/// The day's seal sits large in the top-leading corner, cropped by the card's
/// corner (~70% visible). Tap → Today's list. Plain values in; the Home model
/// computes them (presence ladder, gate, carried people).
struct CommunityCard: View {
    struct Person: Identifiable, Equatable {
        let id: String
        let initials: String
        let tone: Int
        /// The name VoiceOver reads ("You" for the self).
        let spokenName: String
        let isSelf: Bool
    }

    let listNumber: Int
    /// nil = unsealed ("being filmed").
    let sealVariant: Int?
    let people: Int
    let prayers: Int
    let presence: PresenceLine?
    /// You first, then your carried names in your order. Never empty.
    let carried: [Person]
    let status: TomorrowStatus
    /// Minutes until the cutoff, when the closing notice should replace the
    /// status line (only if you haven't prayed with the list today).
    var closingMinutes: Int? = nil
    /// Prayed with the list today (local day), or held in this prayer: the
    /// held ring around the card.
    var held = false
    /// In prayer: whether the list is checked. nil = nav mode. The whole card
    /// is the checkable "hold the list" target; its check sits in the
    /// trailing slot, aligned to the title line.
    var check: Bool? = nil
    var onTap: () -> Void = {}

    private var inPrayer: Bool { check != nil }

    private var nextList: Int { listNumber + 1 }
    private var aboutYouOnly: Bool { carried.allSatisfy(\.isSelf) }

    private var statusText: String {
        if let closingMinutes {
            return L10n.Card.closesSoon(list: listNumber, minutes: closingMinutes, next: nextList, aboutYouOnly: aboutYouOnly)
        }
        return L10n.Card.status(status, next: nextList, aboutYouOnly: aboutYouOnly)
    }

    private var statusIsActionable: Bool { closingMinutes != nil || status.isActionable }

    var body: some View {
        ZStack(alignment: .topLeading) {
            WaxSeal(variant: sealVariant, size: PP.size.card.stamp)
                .offset(x: -PP.size.card.stampOffsetX, y: -PP.size.card.stampOffsetY)

            VStack(alignment: .leading, spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    worldBeside
                    worldBelow
                }
                AvatarRow(people: carried)
                    .padding(.top, PP.space.md)
                Text(statusText)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(statusIsActionable ? PP.color.ink : PP.color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, PP.space.statusUnderAvatars)
            }
            .padding(PP.space.inset)
        }
        .overlay(alignment: .topTrailing) {
            CheckSlot(check: check.map { $0 ? .held : .none })
                .padding([.top, .trailing], PP.space.inset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PP.color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous))
        .heldRing(held, cornerRadius: PP.radius.card)
        .contentShape(RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
        .accessibilityValue(check.map { ($0 ? HoldState.held : .none).spoken } ?? "")
        .accessibilityAddTraits(inPrayer ? .isToggle : .isButton)
    }

    // MARK: World block

    /// How much of the stamp shows inside the card.
    private var stampVisible: CGSize {
        CGSize(width: PP.size.card.stamp - PP.size.card.stampOffsetX,
               height: PP.size.card.stamp - PP.size.card.stampOffsetY)
    }

    /// Beside the stamp: only if the title and both counts fit on one line.
    private var worldBeside: some View {
        WorldLines(title: L10n.Card.title(listNumber), people: people, prayers: prayers,
                   presence: inPrayer ? nil : presence, countsMayWrap: false)
            .padding(.leading, stampVisible.width - PP.space.inset + PP.space.md)
            .frame(minHeight: stampVisible.height - PP.space.inset, alignment: .topLeading)
    }

    /// Below the stamp, at large text sizes.
    private var worldBelow: some View {
        WorldLines(title: L10n.Card.title(listNumber), people: people, prayers: prayers,
                   presence: inPrayer ? nil : presence, countsMayWrap: true)
            .padding(.top, stampVisible.height - PP.space.inset + PP.space.md)
    }

    private var spokenSummary: String {
        let seal = sealVariant == nil ? L10n.Card.beingFilmed(listNumber) : L10n.Card.sealed(listNumber)
        var parts = [seal, "\(L10n.Card.people(people)), \(L10n.Card.prayers(prayers))"]
        if !inPrayer, let presence { parts.append(WorldLines.spoken(presence)) }
        parts.append(ListFormatter.localizedString(byJoining: carried.map(\.spokenName)))
        parts.append(statusText)
        return parts.joined(separator: ". ")
    }
}

/// "List 52" (Roca), the counts row, and the presence line.
private struct WorldLines: View {
    let title: String
    let people: Int
    let prayers: Int
    let presence: PresenceLine?
    /// Below the stamp the counts may break at the middle dot; beside it they
    /// must fit whole (else the block moves below).
    let countsMayWrap: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.xxs) {
            Text(title)
                .font(PP.type.name)
                .foregroundStyle(PP.color.ink)
                .fixedSize()
            if countsMayWrap {
                ViewThatFits(in: .horizontal) {
                    countsRow
                    VStack(alignment: .leading, spacing: PP.space.xxs) {
                        count(L10n.Card.people(people), people)
                        count(L10n.Card.prayers(prayers), prayers)
                    }
                }
            } else {
                countsRow
            }
            if let presence {
                // If it doesn't fit whole, it hides: never truncate a number.
                ViewThatFits(in: .horizontal) {
                    presenceLine(presence)
                    Color.clear.frame(width: 0, height: 0)
                }
            }
        }
        .font(PP.type.bodySmall)
    }

    private var countsRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
            count(L10n.Card.people(people), people)
            Text(verbatim: "·").foregroundStyle(PP.color.inkMuted)
            count(L10n.Card.prayers(prayers), prayers)
        }
        .fixedSize()
    }

    /// The number in ink (tabular), the word muted.
    private func count(_ text: String, _ n: Int) -> Text {
        var styled = AttributedString(text)
        styled.foregroundColor = PP.color.inkMuted
        if let range = styled.range(of: n.formatted()) {
            styled[range].foregroundColor = PP.color.ink
        }
        return Text(styled).monospacedDigit()
    }

    private func presenceLine(_ p: PresenceLine) -> some View {
        HStack(alignment: .center, spacing: PP.space.xs + PP.space.xxs) {
            if p.window == .now {
                Circle().fill(PP.color.ink).frame(width: PP.size.card.liveDot, height: PP.size.card.liveDot)
            }
            Text(Self.shown(p))
                .foregroundStyle(PP.color.inkMuted)
                .monospacedDigit()
        }
        .fixedSize()
    }

    static func shown(_ p: PresenceLine) -> String {
        switch p.window {
        case .now: L10n.Card.prayingNow(p.count)
        case .lastHour: L10n.Card.prayedLastHour(p.count)
        case .today: L10n.Card.prayedToday(p.count)
        }
    }

    static func spoken(_ p: PresenceLine) -> String {
        p.window == .lastHour ? L10n.Card.prayedLastHourSpoken(p.count) : shown(p)
    }
}

/// Your carried people, filling the card's width: 28 pt avatars overlapping
/// a little (two-letter initials are never covered), thin `cardSurface`
/// rings between them, and a "+N" disc only when they don't all fit.
private struct AvatarRow: View {
    let people: [CommunityCard.Person]

    private let size = PP.size.card.avatar
    private var step: CGFloat { size - PP.size.card.avatarOverlap }

    var body: some View {
        GeometryReader { geometry in
            let capacity = discCapacity(width: geometry.size.width, size: size, step: step)
            let fill = fillRow(people: people.count, capacity: capacity)
            ZStack(alignment: .leading) {
                ForEach(Array(people.prefix(fill.shown).enumerated()), id: \.element.id) { index, person in
                    MonogramAvatar(initials: person.initials, tone: person.tone, size: size)
                        .overlay(separator)
                        .offset(x: CGFloat(index) * step)
                        .zIndex(Double(-index))
                }
                if fill.overflow > 0 {
                    Circle()
                        .fill(PP.color.clusterOverflow)
                        .frame(width: size, height: size)
                        .overlay {
                            Text(L10n.Card.overflow(fill.overflow))
                                .font(PP.type.initials(size: size * PP.number.initialsScale))
                                .foregroundStyle(PP.color.inkMuted)
                                .lineLimit(1)
                        }
                        .overlay(separator)
                        .offset(x: CGFloat(fill.shown) * step)
                }
            }
        }
        .frame(height: size)
        .accessibilityHidden(true)
    }

    private var separator: some View {
        Circle().strokeBorder(PP.color.cardSurface, lineWidth: size * PP.number.clusterSeparator)
    }
}

#Preview("Community card") {
    let people: [CommunityCard.Person] = [
        .init(id: "me", initials: "EO", tone: 7, spokenName: "You", isSelf: true),
        .init(id: "d", initials: "D", tone: 0, spokenName: "Dad", isSelf: false),
        .init(id: "m", initials: "M", tone: 8, spokenName: "Mom", isSelf: false),
        .init(id: "dk", initials: "DK", tone: 10, spokenName: "Daniel Kim", isSelf: false),
        .init(id: "op", initials: "OP", tone: 13, spokenName: "Olivia Park", isSelf: false),
        .init(id: "u", initials: "U", tone: 14, spokenName: "Uncle Ray", isSelf: false),
    ]
    let many = people + (0..<12).map { .init(id: "x\($0)", initials: "A", tone: $0, spokenName: "Friend \($0)", isSelf: false) }
    ScrollView {
        VStack(spacing: PP.space.xl) {
            CommunityCard(listNumber: 52, sealVariant: 3, people: 4345, prayers: 3881,
                          presence: PresenceLine(window: .now, count: 239), carried: people, status: .prayToCarry)
            CommunityCard(listNumber: 52, sealVariant: 3, people: 4345, prayers: 3881,
                          presence: PresenceLine(window: .lastHour, count: 640), carried: many, status: .covered,
                          held: true)
            CommunityCard(listNumber: 52, sealVariant: nil, people: 4345, prayers: 3881,
                          presence: nil, carried: [people[0]], status: .prayToCarry, closingMinutes: 5)
        }
        .padding(PP.space.gutter)
    }
    .background(PP.color.ground)
}
