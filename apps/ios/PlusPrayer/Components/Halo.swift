import SwiftUI

/// The prayer-mode halo (design-direction §7): a gold glow framing the screen,
/// following the display's own corners. It frames the session; it is not a
/// second signature motion.
/// - Enter/exit: fades over `duration.haloFade`.
/// - At rest: nearly still, one slow breath (`number.halo.restLow` ↔ `restHigh`).
/// - A committing Amen (`flare` changes): a quick rise to `flarePeak` and
///   `flareReach`× the reach, a slower settle, then the fade-out.
/// - Reduce Motion: static at `number.halo.reduceMotion`; plain fades.
/// The resting glow stays within `size.halo.maxInwardReach` of the edge.
struct Halo: View {
    let active: Bool
    /// Bumps on each committing Amen.
    let flare: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var level: Double = 0
    @State private var reach: Double = 1
    @State private var breathing = false
    @State private var flaring = false

    private var width: CGFloat {
        PP.size.halo.glowWidth * (colorScheme == .light ? PP.number.halo.lightWidthScale : 1)
    }

    var body: some View {
        ConcentricRectangle()
            // Centered on the screen's edge: the outer half is off-screen, so the
            // visible band is `width` wide.
            .stroke(PP.color.halo, lineWidth: width * reach * 2)
            .blur(radius: width * reach / 2)
            .opacity(level)
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
        withAnimation(.easeOut(duration: PP.duration.haloFade)) { level = rest } completion: { breathe() }
    }

    /// Opacity drifts between the rest levels, very slowly, until the session ends.
    private func breathe() {
        guard active, !reduceMotion, !flaring else { return }
        breathing = true
        withAnimation(.easeInOut(duration: PP.duration.haloBreath).repeatForever(autoreverses: true)) {
            level = PP.number.halo.restHigh
        }
    }

    private func exit() {
        breathing = false
        withAnimation(.easeOut(duration: PP.duration.haloFade)) { level = 0; reach = 1 }
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
