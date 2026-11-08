import PlusPrayerDomain
import SwiftUI

/// A page's History preview (detail-page.md "History preview", 2026-11-08):
/// the title with "See all ›", one non-wrapping row of the most recent
/// strand nodes with "Today ▾" above the first, and the tiles (flat
/// `cardSurface`; hidden at zero; three or fewer in one row, four as a 2×2
/// grid). Every door opens History filtered to this subject: "See all" and
/// the row on All (a node on that day's sheet), each tile on its tab.
struct HistoryPreviewSection: View {
    let subjectId: String
    let values: HistoryPreviewValues
    let today: LocalDate

    @State private var rowWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Page.history)
                    .font(PP.type.sectionTitle)
                    .foregroundStyle(PP.color.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: PP.space.sm)
                NavigationLink(value: route(.all)) {
                    HStack(spacing: PP.space.xxs) {
                        Text(L10n.History.seeAll)
                        PPIcon.disclosure.imageScale(.small)
                    }
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("page.history.seeAll")
            }
            VStack(alignment: .leading, spacing: 0) {
                StrandTodayCaption(text: L10n.History.today)
                HStack(spacing: 0) {
                    ForEach(fitting, id: \.self) { item in
                        StrandItemView(item: item, today: today, action: .push { day in
                            .history(HistoryRequest(scope: .subject(subjectId), tab: .all, day: day))
                        })
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            }
            tiles
        }
        .padding(.horizontal, PP.space.gutter)
    }

    /// As many items as fit the width, never wrapping.
    private var fitting: [StrandItem] {
        guard rowWidth > 0 else { return Array(values.recent.prefix(1)) }
        var width: CGFloat = 0
        var items: [StrandItem] = []
        for item in values.recent {
            let w: CGFloat = if case .gap = item { PP.size.history.gap } else { PP.size.history.nodePitch }
            guard width + w <= rowWidth else { break }
            width += w
            items.append(item)
        }
        // Never end on a fold.
        if case .gap = items.last { items.removeLast() }
        return items
    }

    private func route(_ tab: HistoryTab) -> Route {
        .history(HistoryRequest(scope: .subject(subjectId), tab: tab))
    }

    // MARK: Tiles

    private struct Tile: Identifiable {
        let id: HistoryTab
        let number: Int
        let words: String
        var second: String? = nil
        var gold = false
    }

    private var shownTiles: [Tile] {
        let t = values.totals
        var tiles: [Tile] = []
        if t.prayers > 0 { tiles.append(Tile(id: .held, number: t.prayers, words: L10n.History.tilePrayers(t.prayers))) }
        if t.lists > 0 {
            tiles.append(Tile(id: .lists, number: t.lists, words: L10n.History.tileLists(t.lists),
                              second: L10n.History.listPrayers(t.worldPrayers)))
        }
        if t.journal > 0 { tiles.append(Tile(id: .journal, number: t.journal, words: L10n.History.tileJournal)) }
        if values.showsAnswered && t.answered > 0 {
            tiles.append(Tile(id: .answered, number: t.answered, words: L10n.History.tileAnswered, gold: true))
        }
        return tiles
    }

    @ViewBuilder private var tiles: some View {
        let tiles = shownTiles
        if !tiles.isEmpty {
            // Three or fewer share a row; four make a 2×2 grid.
            let columns = tiles.count == 4 ? 2 : tiles.count
            Grid(horizontalSpacing: PP.space.sm, verticalSpacing: PP.space.sm) {
                ForEach(Array(stride(from: 0, to: tiles.count, by: columns)), id: \.self) { start in
                    GridRow {
                        ForEach(tiles[start..<min(start + columns, tiles.count)]) { tile in
                            tileView(tile)
                        }
                    }
                }
            }
        }
    }

    private func tileView(_ tile: Tile) -> some View {
        NavigationLink(value: route(tile.id)) {
            VStack(spacing: PP.space.xxs) {
                Text(tile.number, format: .number)
                    .font(PP.type.sectionTitle)
                    .foregroundStyle(tile.gold ? PP.color.heldGoldText : PP.color.ink)
                    .monospacedDigit()
                Text(tile.words)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
                if let second = tile.second {
                    Text(second)
                        .font(PP.type.caption)
                        .foregroundStyle(PP.color.inkMuted)
                        .monospacedDigit()
                }
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, PP.space.md)
            .padding(.horizontal, PP.space.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PP.color.cardSurface, in: RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("page.history.tile.\(tile.id)")
    }
}
