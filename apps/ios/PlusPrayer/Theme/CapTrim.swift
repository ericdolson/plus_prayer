import SwiftUI
import UIKit

/// The system font of a text style and weight at the current Dynamic Type
/// size, for metrics SwiftUI doesn't expose (cap height, ascender).
nonisolated func systemFontMetrics(_ style: UIFont.TextStyle, weight: UIFont.Weight,
                                   size: DynamicTypeSize) -> UIFont {
    let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
    let pointSize = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits).pointSize
    return UIFont.systemFont(ofSize: pointSize, weight: weight)
}

extension View {
    /// Trims a text's frame down to its cap height at the top, so a gap above
    /// it is measured to the letters, not to the font's ascender room. Gaps
    /// in a form then read as designed: from the element above (a field's
    /// edge, or a text's descender line) to the next text's cap height.
    /// - Parameter toBaseline: also trim the bottom to the baseline (a label
    ///   above its control: the gap is measured from the baseline, and
    ///   descenders hang into it).
    func capTrimmed(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular,
                    toBaseline: Bool = false) -> some View {
        modifier(CapTrim(style: style, weight: weight, toBaseline: toBaseline))
    }
}

private struct CapTrim: ViewModifier {
    let style: UIFont.TextStyle
    let weight: UIFont.Weight
    let toBaseline: Bool
    @Environment(\.dynamicTypeSize) private var size

    func body(content: Content) -> some View {
        let font = systemFontMetrics(style, weight: weight, size: size)
        content
            .padding(.top, -(font.ascender - font.capHeight))
            .padding(.bottom, toBaseline ? -(font.lineHeight - font.ascender) : 0)
    }
}
