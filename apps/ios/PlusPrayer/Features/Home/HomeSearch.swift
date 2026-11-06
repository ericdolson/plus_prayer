import PlusPrayerDomain
import SwiftUI

// Home search (design-direction §4). 🔎 turns the pill's own glass into the
// search field, beside the pray button; with the keyboard up both ride above
// it at the compact height. The list filters live behind it.

/// The pill's content while searching: 🔍 field ✕.
struct SearchField: View {
    @Binding var query: String
    var focused: FocusState<Bool>.Binding
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: PP.space.sm) {
            PPIcon.search
                .font(.system(size: PP.size.header.icon, weight: .light))
                .foregroundStyle(PP.color.inkMuted)
                .accessibilityHidden(true)
            TextField(L10n.Search.placeholder, text: $query)
                .focused(focused)
                .font(PP.type.body)
                .foregroundStyle(PP.color.ink)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                // Search lowers the keyboard; the field stays with its results.
                .onSubmit { focused.wrappedValue = false }
                .onAppear { focused.wrappedValue = true }
            Button(action: onClose) {
                PPIcon.close
                    .font(.system(size: PP.size.header.icon, weight: .light))
                    .imageScale(.small)
                    .foregroundStyle(PP.color.inkMuted)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, PP.space.md)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Search.close)
        }
        .padding(.leading, PP.space.lg)
    }
}

/// Search found nothing (design-direction §4, one layout for every case): one
/// quiet line, where only the query truncates, and one blue + Add that opens
/// the add sheet prefilled with the query (hidden in prayer). If a filter
/// hides matches, a match hint below says how many are in All.
struct NoMatchesView: View {
    let query: String
    let showsAdd: Bool
    let hiddenByFilter: Int?
    let onAdd: () -> Void
    let onShowAll: () -> Void

    var body: some View {
        VStack(spacing: PP.space.sm) {
            line
            if showsAdd {
                Button(action: onAdd) {
                    Label { Text(L10n.Search.add) } icon: { PPIcon.add }
                        .font(PP.type.label)
                }
                .tint(PP.color.primary)
            }
            if let hiddenByFilter {
                MatchHint(count: hiddenByFilter, onShow: onShowAll)
                    .padding(.top, PP.space.md)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PP.space.gutter)
        .padding(.top, PP.space.xl)
    }

    /// "No matches for “Robe”" on one line: the sentence around the query
    /// stays whole; a long query gives way with "…".
    private var line: some View {
        let slot = "\u{0}"
        let sentence = L10n.Search.noMatches(slot)
        let parts = sentence.components(separatedBy: slot)
        return HStack(spacing: 0) {
            Text(verbatim: parts.first ?? sentence).fixedSize()
            Text(verbatim: query).lineLimit(1).truncationMode(.tail)
            if parts.count > 1 { Text(verbatim: parts[1]).fixedSize() }
        }
        .font(PP.type.body)
        .foregroundStyle(PP.color.inkMuted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Search.noMatches(query))
    }
}

/// "1 match in All      Show →": the count, never the rows. Content, not a
/// floating control: a flat `cardSurface` with a soft radius, not glass. The
/// whole container is one button.
private struct MatchHint: View {
    let count: Int
    let onShow: () -> Void

    var body: some View {
        Button(action: onShow) {
            HStack(spacing: PP.space.md) {
                Text(L10n.Search.matchesInAll(count))
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(L10n.Search.show)
                    .font(PP.type.label)
                    .foregroundStyle(PP.color.primary)
            }
            .padding(.horizontal, PP.space.md)
            .padding(.vertical, PP.space.sm)
            .frame(minHeight: PP.size.hint.minHeight)
        }
        .buttonStyle(HintButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Search.showSpoken(count))
        .accessibilityAddTraits(.isButton)
    }
}

private struct HintButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(PP.color.cardSurface, in: RoundedRectangle(cornerRadius: PP.radius.hint))
            .overlay {
                RoundedRectangle(cornerRadius: PP.radius.hint)
                    .fill(PP.color.ink.opacity(configuration.isPressed ? PP.number.pressed : 0))
            }
            .contentShape(RoundedRectangle(cornerRadius: PP.radius.hint))
    }
}

#Preview("No matches") {
    VStack(spacing: PP.space.xxl) {
        NoMatchesView(query: "Robe", showsAdd: true, hiddenByFilter: nil, onAdd: {}, onShowAll: {})
        NoMatchesView(query: "A very long query that will not fit on one line at all", showsAdd: true,
                      hiddenByFilter: 1, onAdd: {}, onShowAll: {})
        NoMatchesView(query: "Robe", showsAdd: false, hiddenByFilter: 3, onAdd: {}, onShowAll: {})
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}
