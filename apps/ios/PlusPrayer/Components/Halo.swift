import SwiftUI

/// The prayer-mode halo (design-direction §7): a solid gold line on the
/// screen's edge (`size.halo.edge`) with a gold glow over it, both following
/// the display's own corners. The line holds; the glow accents it. It frames
/// the session; it is not a second signature motion.
/// - Enter/exit: both fade over `duration.haloFade`.
/// - At rest: the line is steady; the glow breathes (`number.halo.restLow` ↔
///   `restHigh`, `duration.haloBreath` each way).
/// - A committing Amen (`flare` changes): a quick rise to `flarePeak` and
///   `flareReach`× the reach, a slower settle, then the fade-out.
/// - Reduce Motion: the glow is static at `number.halo.reduceMotion`; plain fades.
/// The resting glow stays within `size.halo.maxInwardReach` of the edge.
struct Halo: View {
    let active: Bool
    /// Bumps on each committing Amen.
    let flare: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// The whole halo's presence (the line's opacity).
    @State private var shown: Double = 0
    /// The glow's opacity.
    @State private var level: Double = 0
    @State private var reach: Double = 1
    @State private var breathing = false
    @State private var flaring = false

    private var width: CGFloat {
        PP.size.halo.glowWidth * (colorScheme == .light ? PP.number.halo.lightWidthScale : 1)
    }

    var body: some View {
        // Strokes are centered on the screen's edge: the outer half is
        // off-screen, so each visible band is half its line width.
        ZStack {
            ConcentricRectangle()
                .stroke(PP.color.halo, lineWidth: width * reach * 2)
                .blur(radius: width * reach / 2)
                .opacity(level)
            ConcentricRectangle()
                .stroke(PP.color.halo, lineWidth: PP.size.halo.edge * 2)
        }
            .opacity(shown)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { if active { enter() } }
            .onChange(of: active) { _, isActive in
                if isActive { enter() } else if !flaring { exit() }
            }
            .onChange(of: flare) { _, _ in amenFlare() }
    }

    private var rest: Double { reduceMotion ? PP.number.halo.reduceMotion : PP.number.halo.restLow }

    private func enter() {
        withAnimation(.easeOut(duration: PP.duration.haloFade)) { shown = 1; level = rest } completion: { breathe() }
    }

    /// The glow drifts between the rest levels until the session ends.
    private func breathe() {
        guard active, !reduceMotion, !flaring else { return }
        breathing = true
        withAnimation(.easeInOut(duration: PP.duration.haloBreath).repeatForever(autoreverses: true)) {
            level = PP.number.halo.restHigh
        }
    }

    private func exit() {
        breathing = false
        withAnimation(.easeOut(duration: PP.duration.haloFade)) {
            // Setting level also stops the breath's repeating animation.
            shown = 0; level = 0; reach = 1
        }
    }

    private func amenFlare() {
        guard !reduceMotion else { exit(); return }
        flaring = true
        breathing = false
        let settle = PP.duration.haloFlare - PP.duration.haloFlareRise
        DispatchQueue.main.asyncAfter(deadline: .now() + PP.duration.haloFlareOffset) {
            withAnimation(PP.easing.out(PP.duration.haloFlareRise)) {
                level = PP.number.halo.flarePeak
                reach = PP.number.halo.flareReach
            } completion: {
                withAnimation(PP.easing.inOut(settle)) { reach = 1 } completion: {
                    flaring = false
                    exit()
                }
            }
        }
    }
}

#Preview("Halo") {
    @Previewable @State var active = true
    @Previewable @State var flare = 0
    ZStack {
        PP.color.ground.ignoresSafeArea()
        VStack(spacing: PP.space.lg) {
            Button(active ? "Cancel" : "Pray") { active.toggle() }
            Button("Amen") { flare += 1; active = false }
        }
        Halo(active: active, flare: flare)
    }
}
