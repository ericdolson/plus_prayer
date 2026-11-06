import PlusPrayerDomain
import SwiftUI

/// The avatar cluster outside the card (design-direction §6; the card fills
/// its own row): grouped, overlapping avatars, then text that begins with
/// names and ends with `trailing`. Up to 5 people: every avatar, the text
/// counts the rest ("You, Dad + 3 will be on List 53"). More: 4 avatars and a
/// "+N" disc, and the text doesn't ("You, Dad and others …"). Layout rules in
/// PlusPrayerDomain (`layoutCluster`).
///
/// The text sits beside the avatars when it fits on one line, else full
/// width below them. VoiceOver reads every name. Plain avatars, no rims;
/// thin rings in the `surface` color separate the overlaps.
struct AvatarCluster: View {
    struct Person: Identifiable, Equatable {
        let id: String
        let initials: String
        let tone: Int
        /// As shown and read: "You", "Dad", "Daniel Kim".
        let name: String
    }

    let people: [Person]
    /// What follows the names: "will be on List 53".
    let trailing: String
    var avatarSize: CGFloat = PP.size.cluster.avatar
    /// What the cluster sits on, for the separator rings.
    var surface: Color = PP.color.ground
    /// Center the avatars and the text (the invitation).
    var centered = false

    private var layout: ClusterLayout<Person> { layoutCluster(people) }

    private var text: String {
        let named = layout.named.map(\.name)
        let names: String = switch named.count {
        case 0: ""
        case 1: named[0]
        default:
            if layout.overflow > 0 {
                L10n.Cluster.andOthers(named[0], named[1])
            } else if layout.counted > 0 {
                L10n.Cluster.counted(named[0], named[1], layout.counted)
            } else {
                L10n.Cluster.two(named[0], named[1])
            }
        }
        return L10n.Cluster.sentence(names, trailing)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PP.space.sm) {
                discs
                label.lineLimit(1).fixedSize()
            }
            VStack(alignment: centered ? .center : .leading, spacing: PP.space.sm) {
                discs
                label.multilineTextAlignment(centered ? .center : .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Cluster.sentence(people.map(\.name).formatted(.list(type: .and)), trailing))
    }

    private var label: some View { Text(text) }

    private var discs: some View {
        let layout = layout
        return HStack(spacing: -PP.size.cluster.overlap) {
            ForEach(Array(layout.avatars.enumerated()), id: \.element.id) { index, person in
                MonogramAvatar(initials: person.initials, tone: person.tone, size: avatarSize)
                    .overlay(separator)
                    .zIndex(Double(-index))
            }
            if layout.overflow > 0 {
                Circle()
                    .fill(PP.color.clusterOverflow)
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay {
                        Text(L10n.Card.overflow(layout.overflow))
                            .font(PP.type.initials(size: avatarSize * PP.number.initialsScale))
                            .foregroundStyle(PP.color.inkMuted)
                            .lineLimit(1)
                    }
                    .overlay(separator)
                    .zIndex(-Double(layout.avatars.count))
            }
        }
        .fixedSize()
    }

    private var separator: some View {
        Circle().strokeBorder(surface, lineWidth: avatarSize * PP.number.clusterSeparator)
    }
}

#Preview("Avatar cluster") {
    let people: [AvatarCluster.Person] = [
        .init(id: "me", initials: "EO", tone: 7, name: "You"),
        .init(id: "d", initials: "D", tone: 0, name: "Dad"),
        .init(id: "m", initials: "M", tone: 8, name: "Mom"),
        .init(id: "dk", initials: "DK", tone: 10, name: "Daniel Kim"),
        .init(id: "op", initials: "OP", tone: 13, name: "Our parish"),
        .init(id: "u", initials: "U", tone: 14, name: "Ukraine"),
    ]
    VStack(spacing: PP.space.xl) {
        AvatarCluster(people: Array(people.prefix(1)), trailing: "will be on List 53")
        AvatarCluster(people: Array(people.prefix(4)), trailing: "will be on List 53")
        AvatarCluster(people: people, trailing: "will be on List 53",
                      avatarSize: PP.size.cluster.avatarLarge, centered: true)
    }
    .font(PP.type.bodySmall)
    .padding(PP.space.gutter)
    .background(PP.color.ground)
}
