import Observation
import SwiftUI

/// The bridge between onboarding and Home for the hand-off
/// (auth-onboarding.md, Flow step 5). Home reports where its header avatar,
/// a row's avatar and the pray button are (`handoffAnchor(_:)`), keeps the
/// ones in `hidden` invisible until onboarding's copies land on them, and
/// stays hidden itself until `homeShown`.
@MainActor @Observable
final class HomeHandoff {
    /// Home's anchors, in global coordinates.
    var frames: [HandoffAnchor: CGRect] = [:]
    var hidden: Set<HandoffAnchor> = []
    /// Home's content (its own ground is always there).
    var homeShown = false

    /// What Home's views read from the environment.
    var anchoring: HandoffAnchoring {
        HandoffAnchoring(report: { [weak self] anchor, frame in
            if self?.frames[anchor] != frame { self?.frames[anchor] = frame }
        }, hidden: hidden)
    }
}
