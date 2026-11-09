import SwiftUI

/// The intention thread (design-direction §5): a thin neutral line drops from
/// the bottom-center of a name's avatar and curves into each of its
/// intentions, like a prayer strand. Each row draws its own part behind its
/// content; the parts meet at the row edges. It never changes color or weight
/// (the held dot sits where a branch ends).
nonisolated enum ThreadPart: Equatable {
    /// A name with intentions below: from under the avatar (clear of the held
    /// ring) to the row's bottom.
    case trunk
    /// An intention with more below: the branch into it, and the trunk on down.
    case branch
    /// The last intention: the trunk ends in its branch.
    case lastBranch
}

/// Shared x positions, measured from the leading edge of the screen.
nonisolated enum ThreadGeometry {
    /// The avatar's center.
    static var trunkX: CGFloat { PP.space.gutter + PP.size.avatar.row / 2 }
    /// Where name text (and so intention text) starts.
    static var textStart: CGFloat { PP.space.gutter + PP.size.avatar.row + PP.space.md }
    /// The held dot's center: the end of a branch.
    static var branchEndX: CGFloat { textStart - PP.space.sm - PP.size.held.dot / 2 }
}

nonisolated struct ThreadShape: Shape {
    let part: ThreadPart
    /// Trunk: the avatar's diameter (it's vertically centered in the row).
    var avatarDiameter: CGFloat = PP.size.avatar.row
    /// Branch: where it meets the dot, from the row's top.
    var branchY: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let x = ThreadGeometry.trunkX
        switch part {
        case .trunk:
            let top = rect.midY + avatarDiameter / 2 + PP.size.held.ring + PP.size.held.ringGap
            guard top < rect.maxY else { return path }
            path.move(to: CGPoint(x: x, y: top))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        case .branch, .lastBranch:
            let endX = ThreadGeometry.branchEndX
            let r = min(PP.size.thread.radius, branchY, endX - x)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: branchY - r))
            path.addQuadCurve(to: CGPoint(x: x + r, y: branchY), control: CGPoint(x: x, y: branchY))
            path.addLine(to: CGPoint(x: endX, y: branchY))
            if part == .branch {
                path.move(to: CGPoint(x: x, y: branchY - r))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
        }
        return path
    }
}

extension View {
    /// Draws this row's part of the thread behind it (mirrored in RTL).
    /// `trunkClearance`: for a `.trunk` under something other than a row
    /// avatar (the person page's "Intentions" title), the height centered in
    /// the row that the trunk starts below.
    func thread(_ part: ThreadPart?, branchY: CGFloat = 0, trunkClearance: CGFloat = PP.size.avatar.row) -> some View {
        background(alignment: .topLeading) {
            if let part {
                ThreadShape(part: part, avatarDiameter: trunkClearance, branchY: branchY)
                    .stroke(PP.color.thread, style: StrokeStyle(lineWidth: PP.size.thread.stroke, lineCap: .round))
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
        }
    }
}
