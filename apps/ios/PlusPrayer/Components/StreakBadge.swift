import SwiftUI

/// The header's streak badge (design-direction §4, streaks-reminders.md): a
/// neutral pewter seal and the number, which carries the state. Never gold,
/// never a wax color. Sits on its own glass. Always tappable.
struct StreakBadge: View {
    enum State {
        /// Prayed with the list today: the number in ink.
        case sealedToday
        /// Alive, not yet today: the number in inkMuted, the seal one step dimmer.
        case alive
        /// No streak: a dim seal and no number (never "0").
        case none
    }

    let state: State
    let days: Int
    var onTap: () -> Void = {}

    private var showsNumber: Bool { state != .none && days > 0 }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: PP.space.xs) {
                PewterSeal(size: PP.size.seal.badge, dimmed: state != .sealedToday)
                if showsNumber {
                    Text(days, format: .number)
                        .font(PP.type.label)
                        .monospacedDigit()
                        .foregroundStyle(state == .sealedToday ? PP.color.ink : PP.color.inkMuted)
                }
            }
            .padding(.horizontal, PP.space.sm)
            .frame(height: PP.size.header.control)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel(L10n.Home.streak(showsNumber ? days : 0))
    }
}

#Preview("Streak badge") {
    VStack(spacing: PP.space.lg) {
        StreakBadge(state: .sealedToday, days: 6)
        StreakBadge(state: .alive, days: 6)
        StreakBadge(state: .none, days: 0)
    }
    .padding(PP.space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(PP.color.ground)
}
