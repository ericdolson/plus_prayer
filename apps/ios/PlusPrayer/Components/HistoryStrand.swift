import SwiftUI

// The History strand's marks (history.md "All — the strand", design-direction
// §5): a node is a full neutral disc; Home's two marks give it meaning — the
// bloom pressed in (on that day's printed list) and the gold held ring (you
// prayed). A neutral corner dot = a journal entry; a small gold ✦ in the
// lower corner = an intention answered. No hollow states. Empty runs fold to
// one `··`; a month tab sits where the month turns. Plain values in.

/// One day's node, drawn in its `size.history.nodePitch` slot (the tap
/// area). Decorative: the button around it says the day in words.
struct StrandNodeMark: View {
    var onList = false
    var prayed = false
    var journal = false
    var answered = false

    var body: some View {
        ZStack {
            Circle()
                .fill(PP.color.historyNode)
                .frame(width: PP.size.history.node, height: PP.size.history.node)
                .overlay {
                    if onList {
                        PPIcon.carried
                            .font(.system(size: PP.size.history.bloom / PPIcon.carriedEm))
                            .foregroundStyle(PP.color.ink.opacity(PP.number.historyBloom))
                    }
                }
                .heldRing(prayed, step: .small)
                .overlay(alignment: .topTrailing) {
                    if journal {
                        Circle()
                            .fill(PP.color.inkMuted)
                            .frame(width: PP.size.history.journalDot, height: PP.size.history.journalDot)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if answered {
                        PPIcon.answered
                            .font(.system(size: PP.size.history.answeredMark))
                            .foregroundStyle(PP.color.heldGold)
                    }
                }
        }
        .frame(width: PP.size.history.nodePitch, height: PP.size.history.nodePitch)
        .accessibilityHidden(true)
    }
}

/// A run of empty days, any length: `··`. It shows that time passed without
/// counting it.
struct StrandGapMark: View {
    let spokenLabel: String

    var body: some View {
        Text(verbatim: "··")
            .font(PP.type.bodySmall)
            .foregroundStyle(PP.color.inkFaint)
            .frame(width: PP.size.history.gap, height: PP.size.history.nodePitch)
            .accessibilityElement()
            .accessibilityLabel(spokenLabel)
    }
}

/// The month tab: a tiny calendar page with the short month ("Nov"), inline
/// where the month turns. A heading for VoiceOver.
struct StrandMonthTab: View {
    let text: String
    let spokenLabel: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PP.size.history.monthTabRadius, style: .continuous)
        Text(verbatim: text)
            .font(PP.type.labelSmall)
            .foregroundStyle(PP.color.inkMuted)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, PP.space.xs)
            .padding(.top, PP.size.history.monthTabBand + PP.space.xxs)
            .padding(.bottom, PP.space.xxs)
            .frame(minWidth: PP.size.history.monthTab)
            .background {
                shape.fill(PP.color.cardSurface)
                    .overlay(alignment: .top) {
                        Rectangle().fill(PP.color.inkMuted).frame(height: PP.size.history.monthTabBand)
                    }
                    .clipShape(shape)
                    .overlay { shape.strokeBorder(PP.color.hairline, lineWidth: PP.size.thread.stroke) }
            }
            .frame(height: PP.size.history.nodePitch)
            .padding(.horizontal, PP.space.xxs)
            .accessibilityElement()
            .accessibilityLabel(spokenLabel)
            .accessibilityAddTraits(.isHeader)
    }
}

/// "Today ▾", always above the first node.
struct StrandTodayCaption: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(PP.type.caption)
            PPIcon.today
                .font(PP.type.caption)
                .imageScale(.small)
        }
        .foregroundStyle(PP.color.inkMuted)
        .fixedSize()
        .frame(minWidth: PP.size.history.nodePitch)
        .accessibilityHidden(true)
    }
}

/// Lays its children out like a sentence: left to right (leading to
/// trailing), wrapping onto the next line when the next one doesn't fit.
struct StrandFlow: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews)
        let width = rows.map { $0.reduce(0) { $0 + $1.size.width } }.max() ?? 0
        let height = rows.reduce(0) { $0 + ($1.map(\.size.height).max() ?? 0) }
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews) {
            let height = row.map(\.size.height).max() ?? 0
            var x = bounds.minX
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (height - item.size.height) / 2),
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width
            }
            y += height
        }
    }

    private struct Item {
        let index: Int
        let size: CGSize
    }

    private func rows(width: CGFloat, _ subviews: Subviews) -> [[Item]] {
        var rows: [[Item]] = [[]]
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(Item(index: index, size: size))
            x += size.width
        }
        return rows
    }
}

#Preview("Strand marks") {
    VStack(alignment: .leading, spacing: PP.space.lg) {
        StrandTodayCaption(text: "Today")
        StrandFlow {
            StrandNodeMark()
            StrandNodeMark(onList: true)
            StrandNodeMark(prayed: true)
            StrandNodeMark(onList: true, prayed: true, journal: true)
            StrandGapMark(spokenLabel: "No activity")
            StrandNodeMark(onList: true, prayed: true, answered: true)
            StrandMonthTab(text: "Oct", spokenLabel: "October")
            StrandNodeMark(onList: true, journal: true)
            StrandNodeMark(onList: true)
            StrandNodeMark(prayed: true)
        }
    }
    .padding(PP.space.gutter)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}

#Preview("Strand marks · light · large type") {
    StrandFlow {
        StrandNodeMark(onList: true, prayed: true, journal: true)
        StrandGapMark(spokenLabel: "No activity")
        StrandMonthTab(text: "Oct", spokenLabel: "October")
        StrandNodeMark(onList: true, answered: true)
    }
    .padding(PP.space.gutter)
    .background(PP.color.ground)
    .preferredColorScheme(.light)
    .dynamicTypeSize(.accessibility2)
}
