import SwiftUI

// The stage's motion (design/explorations/onboarding/d-merged/notes.md,
// "Motion spec"): text groups fade and rise in and out; a few anchors (the
// user's avatar, the person's, the user's name) stay on screen and travel
// between slots that each step lays out; the hand-off sends them into Home.

/// Where the stage's anchors can sit: invisible placeholders each step lays
/// out (`stageSlot(_:)`), measured in the stage's coordinate space.
enum StageSlot: Hashable {
    /// Step 1: the name field's text.
    case nameField
    /// Step 2: the avatar above the name, where the name first stands, and
    /// the name on the paper line.
    case momentAvatar, nameAbove, nameOnPaper
    /// Step 3: the small avatar in the top bar, between the corners.
    case topAvatar
    /// Step 3 and 4: the person's avatar.
    case someoneAvatar, intentionAvatar
    /// The one blue button.
    case button
    /// The scrolling content's visible frame (anchors resting in it are
    /// clipped to it).
    case viewport
}

/// Where an anchor is heading: one of the stage's slots, or a Home view
/// (the hand-off).
enum StageTarget: Equatable {
    case slot(StageSlot)
    case home(HandoffAnchor)
}

/// The stage's slot frames, in global coordinates (as Home reports its
/// own). Kept after a step's content goes, so an anchor can leave from where
/// it last was.
@MainActor @Observable
final class StageGeometry {
    var frames: [StageSlot: CGRect] = [:]
    /// The anchors layer's origin in global coordinates (full screen).
    var origin: CGPoint = .zero

    /// A global frame in the anchors layer's coordinates.
    func local(_ global: CGRect) -> CGRect { global.offsetBy(dx: -origin.x, dy: -origin.y) }

    func local(_ slot: StageSlot) -> CGRect? { frames[slot].map(local) }
}

extension View {
    /// Reports this view's frame as `slot`.
    func stageSlot(_ slot: StageSlot) -> some View {
        modifier(StageSlotModifier(slot: slot))
    }

    /// An incoming text group: fades in and rises `rise` after `delay`
    /// (`duration.settle`, ease-out); Reduce Motion: a short fade, sooner.
    func onboardingLine(delay: TimeInterval, rise: CGFloat = PP.size.onboarding.textRise) -> some View {
        modifier(OnboardingLine(delay: delay, rise: rise))
    }
}

enum OnboardingTiming {
    /// Delay of the `index`th incoming text group after a step change.
    static func line(_ index: Int, after start: TimeInterval = PP.duration.onboardingTextDelay) -> TimeInterval {
        start + Double(index) * PP.duration.onboardingStagger
    }
}

private struct StageSlotModifier: ViewModifier {
    let slot: StageSlot
    @Environment(StageGeometry.self) private var geometry

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            if geometry.frames[slot] != frame { geometry.frames[slot] = frame }
        }
    }
}

private struct OnboardingLine: ViewModifier {
    let delay: TimeInterval
    let rise: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : rise)
            .onAppear {
                let animation: Animation = reduceMotion
                    ? .easeOut(duration: PP.duration.quick).delay(min(delay, PP.duration.onboardingReduceMotionBeat))
                    : PP.easing.out(PP.duration.settle).delay(delay)
                withAnimation(animation) { shown = true }
            }
    }
}

/// An anchor's way between targets. Its progress lives apart (the stage's
/// state) and only ever grows: a trip animates it from `base` to `base + 1`,
/// so a new trip never has to reset it first (which would coalesce with the
/// animation).
struct Trip: Equatable {
    var target: StageTarget?
    /// Where it left from (global); nil: it's simply at the target.
    var from: CGRect?
    var base: Double = 0

    /// Goes to `target` at once (`progress` is the anchor's current progress).
    mutating func jump(to target: StageTarget?, progress: Double) {
        self.target = target
        from = nil
        base = progress
    }

    /// Starts a trip from `from` to `target`; then animate the progress to
    /// `progress + 1`.
    mutating func leave(from: CGRect?, to target: StageTarget?, progress: Double) {
        self.target = target
        self.from = from
        base = progress
    }
}

/// Puts a view at its trip's place: between `from` and `to` while `progress`
/// runs from `base` to `base + 1`, at `to` after (following it live, so a
/// scroll moves it at once).
struct TravelEffect: ViewModifier, Animatable {
    enum Mode {
        /// Drawn at the target's size, scaled on the way (avatars).
        case scale
        /// Its frame takes the in-between size (the button becoming round).
        case resize
        /// Only moves (the name, which scales itself).
        case move
    }

    var progress: Double
    let base: Double
    let from: CGRect?
    let to: CGRect
    let mode: Mode

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let t = min(1, max(0, progress - base))
        let rect = from.map { Self.lerp($0, to, t) } ?? to
        switch mode {
        case .scale:
            content
                .frame(width: to.width, height: to.height)
                .scaleEffect(to.width > 0 ? rect.width / to.width : 1)
                .position(x: rect.midX, y: rect.midY)
        case .resize:
            content
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        case .move:
            content.position(x: rect.midX, y: rect.midY)
        }
    }

    nonisolated static func lerp(_ a: CGRect, _ b: CGRect, _ t: Double) -> CGRect {
        CGRect(x: a.minX + (b.minX - a.minX) * t, y: a.minY + (b.minY - a.minY) * t,
               width: a.width + (b.width - a.width) * t, height: a.height + (b.height - a.height) * t)
    }
}

/// Clips an anchor resting in the scrolling content to its visible frame
/// (so it scrolls under the corners like the text does); nil: unclipped.
struct ViewportMask: ViewModifier {
    let clip: CGRect?

    func body(content: Content) -> some View {
        content.mask {
            if let clip {
                Rectangle().frame(width: clip.width, height: clip.height).position(x: clip.midX, y: clip.midY)
            } else {
                Rectangle()
            }
        }
    }
}
