import SwiftUI

/// The ring button (app-brief §4): the pray button's countdown and the Amen
/// invitation's share it ("same visual language", prayer-flow.md). A round
/// button, action blue (never gold), on interactive Liquid Glass tinted blue.
///
/// - Not started (`startedAt` nil): shows `idle`; a tap calls `onStart`.
/// - Counting: a ring just outside the disc decays clockwise over `minimum`
///   while the tint dims and the glass stops responding; shows `counting`
///   with the seconds so far. Taps do nothing.
/// - Done: "Amen"; a tap calls `onComplete`.
///
/// Reduce Motion: the ring steps once a second.
struct RingButton<Idle: View, Counting: View>: View {
    var startedAt: Date?
    var diameter: CGFloat = PP.size.prayButton.diameter
    var minimum: TimeInterval = PP.duration.prayHold
    /// VoiceOver, before it starts.
    let idleLabel: String
    let onStart: () -> Void
    let onComplete: () -> Void
    @ViewBuilder let idle: () -> Idle
    /// Shown while counting down, given the seconds since `startedAt`.
    @ViewBuilder let counting: (TimeInterval) -> Counting

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil, paused: startedAt == nil)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let progress = progress(elapsed)
            let isCounting = startedAt != nil && progress < 1
            let done = startedAt != nil && !isCounting
            Button {
                if startedAt == nil { onStart() } else if done { onComplete() }
            } label: {
                ZStack {
                    if done {
                        Text(L10n.Prayer.amen)
                            .font(PP.type.label)
                            .foregroundStyle(PP.color.onPrimary)
                            .lineLimit(1)
                    } else if isCounting {
                        counting(elapsed)
                    } else {
                        idle()
                    }
                }
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular
                            .tint(isCounting ? PP.color.primary.opacity(PP.number.prayButtonDim) : PP.color.primary)
                            .interactive(!isCounting),
                         in: .circle)
            .overlay {
                if isCounting {
                    Circle()
                        .trim(from: 0, to: 1 - progress)
                        .stroke(PP.color.primary,
                                style: StrokeStyle(lineWidth: PP.size.prayButton.ringGap * PP.number.ringStroke,
                                                   lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(-PP.size.prayButton.ringGap)
                        .allowsHitTesting(false)
                }
            }
            .disabled(isCounting)
            .accessibilityLabel(startedAt == nil ? idleLabel : L10n.Prayer.amen)
        }
    }

    private func progress(_ elapsed: TimeInterval) -> Double {
        guard startedAt != nil else { return 1 }
        let steps = reduceMotion ? elapsed.rounded(.down) : elapsed
        return min(1, max(0, steps / minimum))
    }
}

#Preview("Ring button") {
    HStack(spacing: PP.space.xl) {
        RingButton(idleLabel: L10n.Home.pray, onStart: {}, onComplete: {}) {
            PPIcon.pray.foregroundStyle(PP.color.onPrimary)
        } counting: { _ in
            PPIcon.pray.foregroundStyle(PP.color.primary)
        }
        RingButton(startedAt: .now, diameter: PP.size.prayButton.invitation,
                   idleLabel: L10n.Invitation.hold(people: 4345, list: 52),
                   onStart: {}, onComplete: {}) {
            EmptyView()
        } counting: { elapsed in
            Text(verbatim: "\(Int(elapsed))").font(PP.type.displayLine).foregroundStyle(PP.color.primary)
        }
    }
    .padding(PP.space.xl)
    .background(PP.color.ground)
}
