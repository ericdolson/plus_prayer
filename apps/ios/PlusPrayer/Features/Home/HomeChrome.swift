import SwiftUI

// Home's header and floating bar (design-direction §4). No header slab and no
// divider: the list scrolls beneath and dissolves under the platform's soft
// scroll edge (Tier B on iOS). Controls float on their own glass. The pill and
// pray button are our layout (Tier A) on native glass; the pray button stays
// solid action blue.

/// Leading: your avatar (~32 pt, → You) and the streak badge. Trailing: the
/// filter, or the active-filter chip in its place.
struct HomeHeader: View {
    let initials: String
    let tone: Int
    let streakState: StreakBadge.State
    let streakDays: Int
    @Binding var filter: HomeFilter
    let counts: HomeFilterCounts
    var onYou: () -> Void = {}
    var onStreak: () -> Void = {}

    var body: some View {
        HStack(spacing: PP.space.xs) {
            Button(action: onYou) {
                MonogramAvatar(initials: initials, tone: tone, size: PP.size.avatar.header)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Home.you)

            StreakBadge(state: streakState, days: streakDays, onTap: onStreak)

            Spacer(minLength: PP.space.md)

            HomeFilterControl(filter: $filter, counts: counts)
        }
        .padding(.horizontal, PP.space.gutter)
        .padding(.vertical, PP.space.sm)
    }
}

/// The floating pill (History · Search · +) and, beside it on the thumb side,
/// the round pray button of the same height.
struct HomeBar: View {
    var onHistory: () -> Void = {}
    var onSearch: () -> Void = {}
    var onAdd: () -> Void = {}
    var onPray: () -> Void = {}

    var body: some View {
        GlassEffectContainer(spacing: PP.size.bar.gap) {
            HStack(spacing: PP.size.bar.gap) {
                HStack(spacing: 0) {
                    pillButton(PPIcon.history, L10n.Home.history, onHistory)
                    pillButton(PPIcon.search, L10n.Home.search, onSearch)
                    pillButton(PPIcon.add, L10n.Home.add, onAdd)
                }
                .frame(height: PP.size.bar.height)
                .glassEffect(.regular.interactive(), in: .capsule)

                PrayButton(action: onPray)
            }
        }
        .padding(.horizontal, PP.size.bar.inset)
    }

    private func pillButton(_ icon: Image, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .font(.system(size: PP.size.bar.icon, weight: .light))
                .foregroundStyle(PP.color.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// The round pray button: solid action blue (never glass, never gold). It
/// becomes Amen with its countdown ring in prayer mode (a later slice).
struct PrayButton: View {
    var diameter: CGFloat = PP.size.prayButton.diameter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PPIcon.pray
                .font(.system(size: PP.size.bar.icon, weight: .regular))
                .foregroundStyle(PP.color.onPrimary)
                .frame(width: diameter, height: diameter)
                .background(PP.color.primary, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(L10n.Home.pray)
    }
}

/// A quiet press: a slight dip, no bounce (the check is the only spring).
private struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -PP.number.pressed : 0)
            .animation(.easeOut(duration: PP.duration.quick), value: configuration.isPressed)
    }
}
