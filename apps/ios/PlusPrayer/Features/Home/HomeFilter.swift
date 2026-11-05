import SwiftUI

/// Home's filter (design-direction §4): All · Still to hold · Carried.
enum HomeFilter: CaseIterable, Hashable {
    case all, stillToHold, carried

    var label: String {
        switch self {
        case .all: L10n.Filter.all
        case .stillToHold: L10n.Filter.stillToHold
        case .carried: L10n.Filter.carried
        }
    }
}

/// How many rows each filter shows (computed by the Home model from data).
struct HomeFilterCounts: Equatable {
    var all = 0
    var stillToHold = 0
    var carried = 0

    func count(_ filter: HomeFilter) -> Int {
        switch filter {
        case .all: all
        case .stillToHold: stillToHold
        case .carried: carried
        }
    }
}

/// The header's filter control. All → a filter glyph on glass; anything else
/// → a chip `[ Still to hold × ]` in its place (tap the label to reopen the
/// menu, × back to All). The menu is the native one (Tier B): counts in the
/// title, never 0; the system check marks the active filter; Still to hold at
/// 0 shows "Everyone's been held today." instead of a count.
struct HomeFilterControl: View {
    @Binding var filter: HomeFilter
    let counts: HomeFilterCounts

    var body: some View {
        if filter == .all {
            menu {
                PPIcon.filter
                    .font(.system(size: PP.size.header.icon, weight: .light))
                    .foregroundStyle(PP.color.ink)
                    .frame(width: PP.size.header.control, height: PP.size.header.control)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel(L10n.Home.filter)
        } else {
            HStack(spacing: PP.space.xxs) {
                menu {
                    Text(filter.label)
                        .font(PP.type.label)
                        .foregroundStyle(PP.color.ink)
                        .padding(.leading, PP.space.md)
                }
                Button {
                    filter = .all
                } label: {
                    PPIcon.close
                        .font(.system(size: PP.size.header.icon, weight: .regular))
                        .imageScale(.small)
                        .foregroundStyle(PP.color.inkMuted)
                        .frame(width: PP.size.header.control, height: PP.size.header.control)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Home.clearFilter)
            }
            .frame(height: PP.size.header.control)
            // An active filter raises the glass's tint: neutral, never blue.
            .glassEffect(.regular.tint(PP.color.raised).interactive(), in: .capsule)
        }
    }

    private func menu(@ViewBuilder label: () -> some View) -> some View {
        Menu {
            Picker(selection: $filter) {
                ForEach(HomeFilter.allCases, id: \.self) { item in
                    let count = counts.count(item)
                    Group {
                        if item == .stillToHold && count == 0 {
                            // Title + subtitle in a system menu.
                            Text(item.label)
                            Text(L10n.Filter.allHeld)
                        } else {
                            Text(count > 0 ? L10n.Filter.withCount(item.label, count) : item.label)
                        }
                    }
                    .tag(item)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}
