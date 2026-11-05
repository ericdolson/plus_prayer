import PlusPrayerDomain
import SwiftUI

/// A row's trailing slot in prayer mode (design-direction §7, §8): a thin
/// neutral ring; checked = gold with a check, sprung in (the one spring in
/// the app); partial (a name with only some of its intentions held) = a gold
/// ring with a dash. Reduce Motion: fades only.
struct PrayerCheck: View {
    let state: HoldState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGFloat { PP.size.check }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(PP.color.inkMuted, lineWidth: PP.size.checkMark.noneStroke)
                .opacity(state == .none ? 1 : 0)
            Circle()
                .strokeBorder(PP.color.heldGold, lineWidth: PP.size.checkMark.partialStroke)
                .overlay {
                    Capsule()
                        .fill(PP.color.heldGold)
                        .frame(width: size * PP.number.checkDash, height: PP.size.checkMark.partialStroke)
                }
                .opacity(state == .partial ? 1 : 0)
            Circle()
                .fill(PP.color.heldGold)
                .overlay {
                    PPIcon.check
                        .font(.system(size: size * PP.number.checkGlyph, weight: .semibold))
                        .foregroundStyle(PP.color.onHeld)
                }
                .scaleEffect(state == .held || reduceMotion ? 1 : PP.number.checkSpringFrom)
                .opacity(state == .held ? 1 : 0)
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? .easeOut(duration: PP.duration.quick) : PP.easing.outBack(PP.duration.spring),
                   value: state)
        .accessibilityHidden(true)
    }
}

#Preview("Prayer check") {
    @Previewable @State var state: HoldState = .none
    VStack(spacing: PP.space.xl) {
        HStack(spacing: PP.space.xl) {
            PrayerCheck(state: .none)
            PrayerCheck(state: .partial)
            PrayerCheck(state: .held)
        }
        PrayerCheck(state: state)
            .onTapGesture { state = state == .held ? .none : .held }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(PP.color.ground)
}
