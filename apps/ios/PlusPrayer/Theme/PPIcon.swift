import SwiftUI

/// Every icon in the app, in one place (design-direction §9): SF Symbols at a
/// light weight, plus our own glyphs drawn as custom symbols in the asset
/// catalog (Symbols/). Views never name a symbol directly.
nonisolated enum PPIcon {
    // Ours (custom symbols).
    /// The praying hands: the pray button, "Pray for Dad".
    static let pray = Image("pp.pray")
    /// The bloom: the carried mark. Until open-questions D1 it's the logo glyph,
    /// with the "+" cut out.
    static let carried = Image("pp.bloom")

    // SF Symbols.
    static let history = Image(systemName: "clock.arrow.circlepath")
    static let search = Image(systemName: "magnifyingglass")
    static let add = Image(systemName: "plus")
    static let filter = Image(systemName: "line.3.horizontal.decrease")
    static let close = Image(systemName: "xmark")
    static let check = Image(systemName: "checkmark")
    static let partial = Image(systemName: "minus")
    static let more = Image(systemName: "ellipsis")
    static let note = Image(systemName: "square.and.pencil")
    /// Back from a page pushed inside a sheet ("Who is this for?").
    static let back = Image(systemName: "chevron.backward")
}
