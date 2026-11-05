import SwiftUI

// Home's header and floating bar (design-direction §4). No header slab and no
// divider: the list scrolls beneath and dissolves under the platform's soft
// scroll edge (Tier B on iOS). Controls float on their own glass. The pill and
// pray button are our layout (Tier A) on native glass; the pray button stays
// solid action blue.
//
//     Normal:     ( History  🔎  ＋ )   ( 🙏 )
//     In prayer:  ( 3:12 · with 229    🔎 )   ( Amen )
//     Header normal:     [avatar][✱ 6] ………… [filter]  or  [Still to hold ×]
//     Header in prayer:  [Cancel] ……………………… [filter]  or  [Still to hold ×]

/// Leading: your avatar (→ You) and the streak badge; in prayer, Cancel.
/// Trailing: the filter, or the active-filter chip in its place.
struct HomeHeader: View {
    let initials: String
    let tone: Int
    let streakState: StreakBadge.State
    let streakDays: Int
    @Binding var filter: HomeFilter
    let counts: HomeFilterCounts
    /// Non-nil in prayer mode.
    var onCancel: (() -> Void)? = nil
    var onYou: () -> Void = {}
    var onStreak: () -> Void = {}

    var body: some View {
        HStack(spacing: PP.space.xs) {
            if let onCancel {
                Button(L10n.Prayer.cancel, action: onCancel)
                    .font(PP.type.label)
                    .foregroundStyle(PP.color.ink)
                    .padding(.horizontal, PP.space.md)
                    .frame(height: PP.size.header.control)
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .transition(.opacity)
            } else {
                Button(action: onYou) {
                    MonogramAvatar(initials: initials, tone: tone, size: PP.size.avatar.header)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Home.you)
                .transition(.opacity)

                StreakBadge(state: streakState, days: streakDays, onTap: onStreak)
                    .transition(.opacity)
            }

            Spacer(minLength: PP.space.md)

            HomeFilterControl(filter: $filter, counts: counts)
        }
        .padding(.horizontal, PP.space.gutter)
        .padding(.vertical, PP.space.sm)
        .animation(.easeOut(duration: PP.duration.settle), value: onCancel == nil)
    }
}

/// The floating pill and, beside it on the thumb side, the round pray button
/// of the same height. In prayer the pill becomes the prayer bar in place
/// (elapsed time · "with N" · 🔎) and the pray button counts down to Amen.
struct HomeBar: View {
    /// Non-nil in prayer mode.
    var prayerStartedAt: Date? = nil
    /// Others praying now; nil below the display threshold.
    var prayingWith: Int? = nil
    var onHistory: () -> Void = {}
    var onSearch: () -> Void = {}
    var onAdd: () -> Void = {}
    var onPray: () -> Void = {}
    var onAmen: () -> Void = {}

    var body: some View {
        GlassEffectContainer(spacing: PP.size.bar.gap) {
            HStack(spacing: PP.size.bar.gap) {
                Group {
                    if let prayerStartedAt {
                        prayerBar(startedAt: prayerStartedAt)
                    } else {
                        HStack(spacing: 0) {
                            pillButton(PPIcon.history, L10n.Home.history, onHistory)
                            pillButton(PPIcon.search, L10n.Home.search, onSearch)
                            pillButton(PPIcon.add, L10n.Home.add, onAdd)
                        }
                    }
                }
                .frame(height: PP.size.bar.height)
                .glassEffect(.regular.interactive(), in: .capsule)

                PrayButton(startedAt: prayerStartedAt, onPray: onPray, onAmen: onAmen)
            }
        }
        .padding(.horizontal, PP.size.bar.inset)
        .animation(.easeOut(duration: PP.duration.settle), value: prayerStartedAt == nil)
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

    private func prayerBar(startedAt: Date) -> some View {
        HStack(spacing: PP.space.sm) {
            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                let elapsed = Duration.seconds(max(0, context.date.timeIntervalSince(startedAt)))
                    .formatted(.time(pattern: .minuteSecond))
                Text(verbatim: elapsed)
                    .font(PP.type.count)
                    .foregroundStyle(PP.color.ink)
                    .accessibilityLabel(L10n.Prayer.time(elapsed))
            }
            if let prayingWith {
                Text(verbatim: "·").foregroundStyle(PP.color.inkMuted).accessibilityHidden(true)
                Text(L10n.Prayer.with(prayingWith))
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
                    .monospacedDigit()
                    .accessibilityLabel(L10n.Prayer.withSpoken(prayingWith))
            }
            Spacer(minLength: 0)
            Button(action: onSearch) {
                PPIcon.search
                    .font(.system(size: PP.size.bar.icon, weight: .light))
                    .foregroundStyle(PP.color.ink)
                    .frame(width: PP.size.bar.height, height: PP.size.bar.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Home.search)
        }
        .padding(.leading, PP.space.xl)
        .transition(.opacity)
    }
}

/// The round pray button: solid action blue (never glass, never gold). On
/// start a ring just outside the disc decays over the minimum (~5 s) while the
/// disc dims; then it becomes Amen. Before that, taps do nothing (Cancel is
/// always there). Reduce Motion: the ring steps once a second.
struct PrayButton: View {
    var startedAt: Date? = nil
    var diameter: CGFloat = PP.size.prayButton.diameter
    let onPray: () -> Void
    var onAmen: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil, paused: startedAt == nil)) { context in
            let progress = progress(at: context.date)
            let counting = startedAt != nil && progress < 1
            Button {
                if startedAt == nil { onPray() } else if !counting { onAmen() }
            } label: {
                ZStack {
                    if counting {
                        Circle().fill(PP.color.raised)
                        Circle().fill(PP.color.primary.opacity(PP.number.prayButtonDim))
                    } else {
                        Circle().fill(PP.color.primary)
                    }
                    if startedAt != nil && !counting {
                        Text(L10n.Prayer.amen)
                            .font(PP.type.label)
                            .foregroundStyle(PP.color.onPrimary)
                            .lineLimit(1)
                    } else {
                        PPIcon.pray
                            .font(.system(size: PP.size.bar.icon, weight: .regular))
                            .foregroundStyle(counting ? PP.color.primary : PP.color.onPrimary)
                    }
                }
                .frame(width: diameter, height: diameter)
                .overlay {
                    if counting {
                        // Decays clockwise from the top, just outside the disc.
                        Circle()
                            .trim(from: 0, to: 1 - progress)
                            .stroke(PP.color.primary,
                                    style: StrokeStyle(lineWidth: PP.size.prayButton.ringGap * PP.number.ringStroke,
                                                       lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(-PP.size.prayButton.ringGap)
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(PressDim())
            .disabled(counting)
            .accessibilityLabel(startedAt == nil ? L10n.Home.pray : L10n.Prayer.amen)
        }
    }

    private func progress(at now: Date) -> Double {
        guard let startedAt else { return 1 }
        let elapsed = now.timeIntervalSince(startedAt)
        let steps = reduceMotion ? elapsed.rounded(.down) : elapsed
        return min(1, max(0, steps / PrayerSession.minimum))
    }
}

/// A quiet press: a slight dip, no bounce (the check is the only spring).
private struct PressDim: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -PP.number.pressed : 0)
            .animation(.easeOut(duration: PP.duration.quick), value: configuration.isPressed)
    }
}
