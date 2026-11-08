import SwiftUI

// Marks of presence (design-direction §5, §7, §8). Rows mark presence, never
// absence: gold means held. A held avatar wears a gold ring, a held intention
// a gold dot, both until local midnight; in prayer they appear live as rows
// are checked. Crisp gold in both themes, never a static glow. Turning one on
// gives a brief bloom (dark theme; `heldGlow` is clear in light) that settles
// into the crisp mark. Reduce Motion: a plain quick fade, no bloom.
// Decorative: rows say "held" in words.

/// The held ring scales in steps, not proportionally (design-direction §5,
/// 2026-11-08): ring / gap 1.5 / 1.5 up to ~32 pt, 2 / 2 at 40–44 pt and on
/// the community card, 3 / 3 at ~96 pt.
enum HeldRingStep {
    case small, medium, large

    var ring: CGFloat {
        switch self {
        case .small: PP.size.held.ringSmall
        case .medium: PP.size.held.ring
        case .large: PP.size.held.ringLarge
        }
    }

    var gap: CGFloat {
        switch self {
        case .small: PP.size.held.ringGapSmall
        case .medium: PP.size.held.ringGap
        case .large: PP.size.held.ringGapLarge
        }
    }
}

extension View {
    /// The held ring around an avatar (round) or the community card
    /// (`cornerRadius` = the card's): crisp gold at `step`'s stroke and gap,
    /// always solid. Drawn outside the view's bounds, so it never shifts
    /// layout.
    func heldRing(_ held: Bool, cornerRadius: CGFloat? = nil, step: HeldRingStep = .medium) -> some View {
        modifier(HeldRing(held: held, cornerRadius: cornerRadius, step: step))
    }
}

private struct HeldRing: ViewModifier {
    let held: Bool
    let cornerRadius: CGFloat?
    let step: HeldRingStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var outset: CGFloat { step.ring + step.gap }

    func body(content: Content) -> some View {
        content.background {
            ring
                .padding(-outset)
                .opacity(held ? 1 : 0)
                .animation(.easeOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle), value: held)
                .bloom(on: held, color: PP.color.heldGlow, radius: PP.space.sm)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var ring: some View {
        if let cornerRadius {
            // Concentric with the card's corners.
            RoundedRectangle(cornerRadius: cornerRadius + outset, style: .continuous)
                .strokeBorder(PP.color.heldGold, lineWidth: step.ring)
        } else {
            Circle().strokeBorder(PP.color.heldGold, lineWidth: step.ring)
        }
    }
}

/// The small gold dot where the thread meets a held intention. Holds its
/// space when not shown.
struct HeldDot: View {
    let held: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(PP.color.heldGold)
            .frame(width: PP.size.held.dot, height: PP.size.held.dot)
            .opacity(held ? 1 : 0)
            .animation(.easeOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle), value: held)
            .bloom(on: held, color: PP.color.heldGlow, radius: PP.size.held.dot)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private extension View {
    /// The check moment's gold bloom (§8): when `on` turns true, a glow swells
    /// and settles to nothing over `duration.bloom`, leaving the crisp mark.
    /// Already on at first appearance: no bloom. Reduce Motion: never.
    func bloom(on: Bool, color: Color, radius: CGFloat) -> some View {
        modifier(Bloom(on: on, color: color, radius: radius))
    }
}

private struct Bloom: ViewModifier {
    let on: Bool
    let color: Color
    let radius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 0.0, trigger: on) { view, glow in
            view.shadow(color: color.opacity(glow), radius: radius)
        } keyframes: { _ in
            let rise = PP.duration.bloom * PP.number.bloomRiseShare
            if on && !reduceMotion {
                CubicKeyframe(1, duration: rise)
                CubicKeyframe(0, duration: PP.duration.bloom - rise)
            } else {
                CubicKeyframe(0, duration: 0)
            }
        }
    }
}

#Preview("Held ring and dot") {
    @Previewable @State var held = true
    VStack(alignment: .leading, spacing: PP.space.xl) {
        HStack(spacing: PP.space.xl) {
            MonogramAvatar(initials: "D", tone: 0).heldRing(held)
            MonogramAvatar(initials: "M", tone: 8).heldRing(!held)
            HeldDot(held: held)
        }
        RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous)
            .fill(PP.color.cardSurface)
            .frame(height: 120)
            .heldRing(held, cornerRadius: PP.radius.card)
        Button("Toggle held") { held.toggle() }
    }
    .padding(PP.space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(PP.color.ground)
}
