import SwiftUI
import UIKit

/// "Carry onto the list ✱" / "Print with Dad ✱": every carry toggle's title
/// (a person's page, an intention's page, the add sheet). The bloom trails it, inkMuted in every state,
/// `size.carriedMark.carryRow` tall at the default size and centered on the
/// title's cap height. Callers hold the scaled height
/// (`@ScaledMetric(relativeTo: .body)`) and pass the Dynamic Type size.
enum CarryTitle {
    static func text(_ title: String = L10n.Add.carryTitle, bloomHeight: CGFloat,
                     dynamicTypeSize: DynamicTypeSize) -> Text {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let capHeight = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits).capHeight
        // The bloom sits on the baseline: lowered to center on the cap height.
        let bloom = Text(PPIcon.carried)
            .font(.system(size: bloomHeight / PPIcon.carriedEm))
            .baselineOffset((capHeight - bloomHeight) / 2)
            .foregroundStyle(PP.color.inkMuted)
        return Text("\(Text(verbatim: title))\u{00A0}\(bloom)")
    }
}
