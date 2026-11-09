import SwiftUI

// Onboarding's hand-off into Home (auth-onboarding.md, Flow step 5): the
// user's avatar travels into Home's header, the person's into their row,
// and the blue button becomes the pray button. Onboarding draws those
// travelling copies over Home; the Home views they land on report where they
// are and stay hidden until the copy arrives, then show (the copy goes).
// Outside onboarding there's no `handoffAnchoring` and this does nothing.

/// A Home view an onboarding anchor travels into.
enum HandoffAnchor: Hashable, Sendable {
    /// Your avatar in Home's header.
    case selfAvatar
    /// A name row's avatar (by subject id).
    case avatar(String)
    /// The round pray button.
    case prayButton
}

/// Set by Home while onboarding is over it: where to report the anchors'
/// frames (global coordinates), and which to keep hidden for now.
struct HandoffAnchoring: Sendable {
    let report: @MainActor @Sendable (HandoffAnchor, CGRect) -> Void
    let hidden: Set<HandoffAnchor>
}

extension EnvironmentValues {
    @Entry var handoffAnchoring: HandoffAnchoring? = nil
}

extension View {
    /// Marks this view as where an onboarding anchor lands (nil: not one).
    func handoffAnchor(_ anchor: HandoffAnchor?) -> some View {
        modifier(HandoffAnchorModifier(anchor: anchor))
    }
}

private struct HandoffAnchorModifier: ViewModifier {
    let anchor: HandoffAnchor?
    @Environment(\.handoffAnchoring) private var anchoring
    /// The last frame, so it can be reported when onboarding arrives after
    /// the view has settled (no geometry change to report it then).
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        let hidden = anchor.map { anchoring?.hidden.contains($0) ?? false } ?? false
        // The same modifiers either way, so the view keeps its identity when
        // onboarding goes.
        content
            .opacity(hidden ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { new in
                frame = new
                report()
            }
            .onChange(of: anchoring == nil) { report() }
    }

    private func report() {
        if let anchor, let anchoring, let frame { anchoring.report(anchor, frame) }
    }
}
