import SwiftUI

/// The countdown button (app-brief §4): the pray button and the Amen
/// invitation share it. A round button, action blue (never gold), on
/// interactive Liquid Glass tinted blue.
///
/// - Not started (`startedAt` nil): shows `idle`; a tap calls `onStart`.
/// - Counting: the tint dims and the glass stops responding; a small pie
///   inside the disc runs down to nothing over `minimum`. It stays inside
///   the button (no ring outside, no change in size), like the App Store's
///   download progress or the Dynamic Island's timer. Taps do nothing.
/// - Done: "Amen"; a tap calls `onComplete`.
///
/// Reduce Motion: the pie steps once a second.
struct CountdownButton<Idle: View>: View {
    var startedAt: Date?
    var diameter: CGFloat = PP.size.prayButton.diameter
    var minimum: TimeInterval = PP.duration.prayHold
    /// VoiceOver, before it starts.
    let idleLabel: String
    let onStart: () -> Void
    let onComplete: () -> Void
    /// Morphs with another glass shape of this id in the same container
    /// (a page's "Pray for Dad" capsule becomes this button).
    var glassID: GlassID? = nil
    @ViewBuilder let idle: () -> Idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil, paused: startedAt == nil)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let progress = progress(elapsed)
            let counting = startedAt != nil && progress < 1
            let done = startedAt != nil && !counting
            Button {
                if startedAt == nil { onStart() } else if done { onComplete() }
            } label: {
                ZStack {
                    if done {
                        Text(L10n.Prayer.amen)
                            .font(PP.type.label)
                            .foregroundStyle(PP.color.onPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .transition(.opacity)
                    } else if counting {
                        CountdownPie(remaining: 1 - progress)
                            .fill(PP.color.primary)
                            .frame(width: diameter * PP.number.countdownPie,
                                   height: diameter * PP.number.countdownPie)
                            .transition(.opacity)
                    } else {
                        idle().transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: PP.duration.quick), value: done)
                .animation(.easeOut(duration: PP.duration.quick), value: counting)
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular
                            .tint(counting ? PP.color.primary.opacity(PP.number.prayButtonDim) : PP.color.primary)
                            .interactive(!counting),
                         in: .circle)
            .glassID(glassID)
            .disabled(counting)
            .accessibilityLabel(startedAt == nil ? idleLabel : L10n.Prayer.amen)
        }
    }

    private func progress(_ elapsed: TimeInterval) -> Double {
        guard startedAt != nil else { return 1 }
        let steps = reduceMotion ? elapsed.rounded(.down) : elapsed
        return min(1, max(0, steps / minimum))
    }
}

/// A glass shape's identity for morphing between shapes
/// (`glassEffectID`) inside one `GlassEffectContainer`.
struct GlassID {
    let id: String
    let namespace: Namespace.ID
}

extension View {
    /// `glassEffectID` when there is one.
    @ViewBuilder func glassID(_ glass: GlassID?) -> some View {
        if let glass { glassEffectID(glass.id, in: glass.namespace) } else { self }
    }
}

/// What's left of the countdown: a wedge from 12 o'clock, its leading edge
/// moving clockwise until nothing is left.
struct CountdownPie: Shape {
    /// 1 = a full disc, 0 = nothing.
    var remaining: Double

    nonisolated func path(in rect: CGRect) -> Path {
        guard remaining > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(-90 + (1 - remaining) * 360)
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview("Countdown button") {
    HStack(spacing: PP.space.xl) {
        CountdownButton(idleLabel: L10n.Home.pray, onStart: {}, onComplete: {}) {
            PPIcon.pray.foregroundStyle(PP.color.onPrimary)
        }
        CountdownButton(startedAt: .now, idleLabel: L10n.Home.pray, onStart: {}, onComplete: {}) {
            PPIcon.pray.foregroundStyle(PP.color.onPrimary)
        }
        CountdownButton(startedAt: .now.addingTimeInterval(-6), idleLabel: L10n.Home.pray,
                        onStart: {}, onComplete: {}) {
            PPIcon.pray.foregroundStyle(PP.color.onPrimary)
        }
    }
    .padding(PP.space.xl)
    .background(PP.color.ground)
}
