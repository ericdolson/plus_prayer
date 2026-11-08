import PlusPrayerDomain
import SwiftUI

// Home's header and floating bar (design-direction §4). No header slab and no
// divider: the list scrolls beneath and dissolves under the platform's soft
// scroll edge (Tier B on iOS). Controls float on their own glass. The pill and
// pray button are our layout (Tier A) on native glass; the pray button's glass
// is tinted action blue.
//
//     Normal:     ( History  🔎  ＋ )   ( 🙏 )
//     In prayer:  ( 3:12 · with 229    🔎 )   ( Amen )
//     Header normal:     [avatar][✱ 6] ………… [filter]  or  [Still to hold ×]
//     Header in prayer:  [Cancel] ……………………… [filter]  or  [Still to hold ×]

/// Leading: your avatar (→ You, on glass tinted with your tone) and the streak
/// badge; in prayer, Cancel.
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
                // One glass container so the avatar and streak blend into
                // each other when either grows under a tap (otherwise each
                // renders alone and the streak always sits on top). Same
                // pattern as HomeBar: container spacing = the gap. sm, not xs:
                // two separate controls read as two pieces, not crowded.
                GlassEffectContainer(spacing: PP.space.sm) {
                    HStack(spacing: PP.space.sm) {
                        // On interactive glass tinted with your tone, like the
                        // pray button, so it gives under the finger like the
                        // other controls.
                        Button(action: onYou) {
                            MonogramAvatar(initials: initials, tone: tone, size: PP.size.avatar.header, filled: false)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.tint(MonogramAvatar.color(tone: tone)).interactive(), in: .circle)
                        .accessibilityLabel(L10n.Home.you)

                        StreakBadge(state: streakState, days: streakDays, onTap: onStreak)
                    }
                }
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
/// of the same height: two separate glass shapes. The pill changes in place:
///
///     Normal:     ( History  🔎  ＋ )   ( 🙏 )
///     In prayer:  ( 3:12 · with 229    🔎 )   ( Amen )
///     Searching:  ( 🔍 dad          ✕ )   ( 🙏 )
///
/// Searching, the pill's own glass becomes the search field and the pray
/// button stays its own circle beside it; with the keyboard up both ride
/// above it at the compact height (`compact`).
struct HomeBar<SearchField: View>: View {
    /// Non-nil in prayer mode.
    var prayerStartedAt: Date? = nil
    /// Others praying now; nil below the display threshold.
    var prayingWith: Int? = nil
    /// The pill is the search field.
    var searching = false
    /// The keyboard is up: both controls take the compact height.
    var compact = false
    var onHistory: () -> Void = {}
    var onSearch: () -> Void = {}
    var onAdd: () -> Void = {}
    var onPray: () -> Void = {}
    var onAmen: () -> Void = {}
    @ViewBuilder var searchField: () -> SearchField

    private var height: CGFloat { compact ? PP.size.bar.compact : PP.size.bar.height }

    var body: some View {
        GlassEffectContainer(spacing: PP.size.bar.gap) {
            HStack(spacing: PP.size.bar.gap) {
                Group {
                    if searching {
                        searchField()
                    } else if let prayerStartedAt {
                        prayerBar(startedAt: prayerStartedAt)
                    } else {
                        HStack(spacing: 0) {
                            pillButton(PPIcon.history, L10n.Home.history, onHistory)
                            pillButton(PPIcon.search, L10n.Home.search, onSearch)
                            pillButton(PPIcon.add, L10n.Home.add, onAdd)
                        }
                    }
                }
                .transition(.opacity)
                .frame(height: height)
                .glassEffect(.regular.interactive(), in: .capsule)

                PrayButton(startedAt: prayerStartedAt, diameter: height, onPray: onPray, onAmen: onAmen)
            }
        }
        .padding(.horizontal, PP.size.bar.inset)
        .animation(.easeOut(duration: PP.duration.settle), value: prayerStartedAt == nil)
        .animation(.easeOut(duration: PP.duration.settle), value: searching)
        .animation(.easeOut(duration: PP.duration.settle), value: compact)
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

/// The round pray button on Home's bar: a `CountdownButton` with the
/// praying hands. On start a small pie inside runs down over the minimum
/// (~5 s), then it becomes Amen. Before that, taps do nothing (Cancel is
/// always there).
struct PrayButton: View {
    var startedAt: Date? = nil
    var diameter: CGFloat = PP.size.prayButton.diameter
    let onPray: () -> Void
    var onAmen: () -> Void = {}

    var body: some View {
        CountdownButton(startedAt: startedAt, diameter: diameter, minimum: PrayerSession.minimum,
                        idleLabel: L10n.Home.pray, onStart: onPray, onComplete: onAmen) {
            PPIcon.pray
                .font(.system(size: PP.size.bar.icon, weight: .regular))
                .foregroundStyle(PP.color.onPrimary)
        }
    }
}
