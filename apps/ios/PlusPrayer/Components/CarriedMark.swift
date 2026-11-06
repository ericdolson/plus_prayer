import SwiftUI

/// The carried mark (design-direction §5): a small neutral bloom trailing every
/// carried name and intention, so a long list shows at a glance what goes on
/// the printed list. Flat `carriedMark` ink, never gold or blue. Absence is
/// never marked.
///
/// It's an inline glyph in the same `Text`, tied to the last word with a
/// no-break space, so it never wraps alone and follows the ellipsis when
/// truncated.
/// It scales with Dynamic Type (a custom symbol sized by a text style).
enum CarriedMark {
    /// The bloom symbol's height as a share of its font size: a font of
    /// `glyph / glyphEm` draws a `glyph`-tall mark.
    static let glyphEm: CGFloat = 0.72

    enum Context {
        /// After a Roca name: ~11 pt glyph, 6 pt gap.
        case name
        /// After a 13 pt intention: ~9 pt glyph, 4 pt gap.
        case intention

        /// The symbol is ~0.72 em tall, so these text styles give the token
        /// sizes (`size.carriedMark.name` ≈ subheadline, `.intention` ≈ footnote)
        /// and scale with the text beside them.
        var font: Font {
            switch self {
            case .name: .subheadline
            case .intention: .footnote
            }
        }

        private var textStyle: UIFont.TextStyle {
            switch self {
            case .name: .subheadline
            case .intention: .footnote
            }
        }

        var gap: CGFloat {
            switch self {
            case .name: PP.size.carriedMark.nameGap
            case .intention: PP.size.carriedMark.intentionGap
            }
        }

        /// Kerning that widens (or narrows) a no-break space, set in the mark's
        /// font, to exactly `gap`.
        var spaceKerning: CGFloat {
            let font = UIFont.preferredFont(forTextStyle: textStyle)
            let space = ("\u{00A0}" as NSString).size(withAttributes: [.font: font]).width
            return gap - space
        }
    }

    /// `text`, then the mark if `carried`.
    static func after(_ text: Text, carried: Bool, context: Context) -> Text {
        guard carried else { return text }
        // A no-break space (the mark never wraps alone), kerned to the gap.
        let space = Text(verbatim: "\u{00A0}").font(context.font).kerning(context.spaceKerning)
        let mark = Text(PPIcon.carried)
            .font(context.font)
            .foregroundStyle(PP.color.carriedMark)
        return Text("\(text)\(space)\(mark)")
    }
}

/// A single-line label (Home rows) with the carried mark after it. The text
/// truncates and the mark stays, right after the ellipsis (§5). For text
/// that may wrap, use `CarriedMark.after(_:carried:context:)`.
struct CarriedLabel: View {
    let text: String
    let carried: Bool
    let context: CarriedMark.Context

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: context.gap) {
            Text(verbatim: text).lineLimit(1)
            if carried {
                Text(PPIcon.carried)
                    .font(context.font)
                    .foregroundStyle(PP.color.carriedMark)
                    .layoutPriority(1)
            }
        }
    }
}

#Preview("Carried mark") {
    VStack(alignment: .leading, spacing: PP.space.lg) {
        CarriedMark.after(Text("Dad"), carried: true, context: .name)
            .font(PP.type.name).foregroundStyle(PP.color.ink)
        CarriedMark.after(Text("Healing after his surgery"), carried: true, context: .intention)
            .font(PP.type.intention).foregroundStyle(PP.color.inkIntention)
        CarriedMark.after(Text("Rest for his heart"), carried: false, context: .intention)
            .font(PP.type.intention).foregroundStyle(PP.color.inkIntention)
        CarriedLabel(text: "A name long enough that it has to be truncated at the end", carried: true, context: .name)
            .font(PP.type.name).foregroundStyle(PP.color.ink)
        CarriedLabel(text: "Dad", carried: true, context: .name)
            .font(PP.type.name).foregroundStyle(PP.color.ink)
    }
    .padding(PP.space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(PP.color.ground)
}
