import PlusPrayerDomain
import SwiftUI

// Home rows (design-direction §3, §5). One line each, no dividers, no
// chevrons; the whole row is the tap target. Names: a 44 pt avatar and the
// name in Roca, 52 pt tall (the avatar and its ring's room). Intentions:
// smaller sans on the thread, their text aligned with the name's, on a ~40 pt
// pitch. An intention's first line sits at the top of its row, so it hangs
// just under its name and the group reads as one unit; the space goes
// between groups. `space.groupGap` is the *visible* gap (the last row's ink
// to the next avatar); the list adds `GroupSpacing.above(afterIntention:)`,
// which subtracts the rows' own insets. The last intention drops the 40 pt
// minimum (its empty bottom would add ~17 pt to the gap) and keeps a 40 pt
// tap target by reaching into the gap below it.
//
// Held today = the gold ring (names) or dot (intentions). Secondary text only
// for exceptional states ("Answered · Oct 19", "Not on the list …").
//
// These take plain values and closures; the list decides what they show.
// The trailing slot is empty in nav mode; in prayer the check fades into it
// (`check` non-nil) and a tap checks instead of opening the item.

/// A name: avatar, name, carried mark.
struct NameRow: View {
    let initials: String
    let tone: Int
    /// The alias if there is one ("Dad", "Me"), else the name.
    let label: String
    let carried: Bool
    let held: Bool
    /// The one exceptional-state line, if any.
    var secondary: SecondaryLine? = nil
    /// Has intentions below it on the thread.
    var hasIntentions = false
    /// VoiceOver: the full sentence for the row.
    let accessibilityLabel: String
    /// In prayer: this row's check. nil = nav mode.
    var check: HoldState? = nil
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: PP.space.md) {
            MonogramAvatar(initials: initials, tone: tone)
                .heldRing(held)
            VStack(alignment: .leading, spacing: PP.space.xxs) {
                CarriedLabel(text: label, carried: carried, context: .name)
                    .font(PP.type.name)
                    .foregroundStyle(PP.color.ink)
                secondary
            }
            Spacer(minLength: 0)
            CheckSlot(check: check)
        }
        .padding(.leading, PP.space.gutter)
        .padding(.trailing, PP.space.gutter)
        .padding(.vertical, PP.space.xs)
        .frame(minHeight: PP.size.row.name)
        .thread(hasIntentions ? .trunk : nil)
        .rowInteraction(label: accessibilityLabel, check: check, onTap: onTap)
    }
}

/// An intention on its name's thread.
struct IntentionRow: View {
    let text: String
    let carried: Bool
    let held: Bool
    var secondary: SecondaryLine? = nil
    /// `.branch` if more intentions follow under the same name; nil without
    /// a thread (a name's page, where the page is the name): then there's no
    /// Home indent either, and the row sits flush with the section title
    /// (dot, then text).
    let thread: ThreadPart?
    let accessibilityLabel: String
    var check: HoldState? = nil
    var onTap: () -> Void = {}

    /// The first line's band: at least as tall as the prayer check, so the dot,
    /// the branch and the check line up on it.
    @ScaledMetric(relativeTo: .footnote) private var lineHeight = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: .init(preferredContentSizeCategory: .large)).lineHeight
    private var band: CGFloat { max(PP.size.check, lineHeight) }
    private var isLast: Bool { thread == .lastBranch }

    var body: some View {
        HStack(alignment: .top, spacing: PP.space.sm) {
            HeldDot(held: held)
                .frame(width: thread == nil ? PP.size.held.dot : ThreadGeometry.textStart - PP.space.sm,
                       height: band, alignment: .trailing)
            VStack(alignment: .leading, spacing: PP.space.xxs) {
                CarriedMark.after(Text(verbatim: text), carried: carried, context: .intention)
                    .font(PP.type.intention)
                    .foregroundStyle(PP.color.inkIntention)
                    .lineLimit(2)
                    .padding(.top, (band - lineHeight) / 2)
                secondary
            }
            Spacer(minLength: 0)
            CheckSlot(check: check).frame(height: band)
        }
        .padding(.leading, thread == nil ? PP.space.gutter : 0)
        .padding(.trailing, PP.space.gutter)
        .padding(.top, PP.space.xxs)
        .padding(.bottom, PP.space.sm)
        .frame(minHeight: isLast ? nil : PP.size.row.intention, alignment: .top)
        .thread(thread, branchY: PP.space.xxs + band / 2)
        .rowInteraction(label: accessibilityLabel, check: check,
                        tapReach: isLast ? max(0, PP.size.row.intention - (PP.space.xxs + band + PP.space.sm)) : 0,
                        onTap: onTap)
    }
}

/// The space a list adds above a name group (not the first) so the visible
/// gap, from the previous row's ink to the next avatar, is `space.groupGap`.
nonisolated enum GroupSpacing {
    /// - Parameter afterIntention: the previous group ends with an intention
    ///   (else with a name that has none).
    static func above(afterIntention: Bool) -> CGFloat {
        // A name row's vertical padding above its avatar; below the previous
        // row's ink, the intention's bottom padding or the name's own.
        let previous = afterIntention ? PP.space.sm : PP.space.xs
        return max(0, PP.space.groupGap - PP.space.xs - previous)
    }
}

/// The one quiet second line a row may carry.
struct SecondaryLine: View {
    enum Kind {
        /// "Answered · Oct 19": gold carries the emphasis, never larger than the intention.
        case answered
        /// "Not printed on List 53 · …": muted.
        case notice
    }

    let text: String
    let kind: Kind

    var body: some View {
        Text(verbatim: text)
            .font(kind == .answered ? PP.type.answered : PP.type.caption)
            .foregroundStyle(kind == .answered ? PP.color.heldGoldText : PP.color.inkMuted)
            .lineLimit(1)
    }
}

/// The trailing slot: empty in nav mode, the check in prayer (fading in).
struct CheckSlot: View {
    let check: HoldState?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PrayerCheck(state: check ?? .none)
            .opacity(check == nil ? 0 : 1)
            .animation(.easeOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle), value: check == nil)
    }
}

extension View {
    /// The whole row is one element: a button in nav mode, a toggle in prayer
    /// (held / partly held / not held), one sentence to VoiceOver.
    /// `tapReach` extends the tap target below the row (into empty space).
    func rowInteraction(label: String, check: HoldState?, tapReach: CGFloat = 0,
                        onTap: @escaping () -> Void) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(ExtendedRect(bottom: tapReach))
            .onTapGesture(perform: onTap)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(check.map(\.spoken) ?? "")
            .accessibilityAddTraits(check == nil ? .isButton : .isToggle)
    }
}

/// A rectangle reaching `bottom` points past the view's bottom edge.
private struct ExtendedRect: Shape {
    let bottom: CGFloat
    nonisolated func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height + bottom))
    }
}

extension HoldState {
    var spoken: String {
        switch self {
        case .none: L10n.Row.notHeld
        case .held: L10n.Row.held
        case .partial: L10n.Row.partial
        }
    }
}

#Preview("Rows") {
    ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
            NameRow(initials: "EO", tone: 7, label: "Me", carried: true, held: false,
                    hasIntentions: true, accessibilityLabel: "Me, carried")
            IntentionRow(text: "Patience with the new job", carried: true, held: false,
                         thread: .lastBranch, accessibilityLabel: "Patience with the new job, carried")

            NameRow(initials: "D", tone: 0, label: "Dad", carried: true, held: true,
                    hasIntentions: true, accessibilityLabel: "Dad, carried. Held today")
                .padding(.top, GroupSpacing.above(afterIntention: true))
            IntentionRow(text: "Healing after his surgery", carried: true, held: true,
                         thread: .branch, accessibilityLabel: "Healing after his surgery, carried. Held today")
            IntentionRow(text: "Rest for his heart", carried: false, held: false,
                         thread: .lastBranch, accessibilityLabel: "Rest for his heart")

            NameRow(initials: "M", tone: 8, label: "Mom", carried: true, held: false,
                    hasIntentions: true, accessibilityLabel: "Mom, carried")
                .padding(.top, GroupSpacing.above(afterIntention: true))
            IntentionRow(text: "A safe delivery for Ruth", carried: false, held: false,
                         secondary: SecondaryLine(text: "Answered · Oct 19", kind: .answered),
                         thread: .lastBranch, accessibilityLabel: "A safe delivery for Ruth. Answered, October 19")

            NameRow(initials: "DK", tone: 10, label: "Daniel Kim", carried: true, held: false,
                    accessibilityLabel: "Daniel Kim, carried")
                .padding(.top, GroupSpacing.above(afterIntention: true))
        }
        .padding(.vertical, PP.space.xl)
    }
    .background(PP.color.ground)
}
