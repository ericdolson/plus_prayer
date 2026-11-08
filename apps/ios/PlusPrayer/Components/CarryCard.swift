import SwiftUI

/// The carry card on a page (detail-page.md "Carry card", 2026-11-08): a flat
/// `cardSurface` container with the in-content radius, the only box on the
/// page. Its controls on top, a hairline, then the status line as the
/// footer (weight follows state: what's still to do in ink, the rest
/// muted). The self page's card holds only the status line.
struct CarryCard<Controls: View>: View {
    /// The footer; nil while the list isn't known yet.
    let status: String?
    let statusActionable: Bool
    @ViewBuilder let controls: Controls

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            controls
            if Controls.self != EmptyView.self && status != nil {
                Divider().overlay(PP.color.hairline)
            }
            if let status {
                Text(status)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(statusActionable ? PP.color.ink : PP.color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(nil, value: status)
            }
        }
        .padding(PP.space.inset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PP.color.cardSurface, in: RoundedRectangle(cornerRadius: PP.radius.card, style: .continuous))
    }
}

extension CarryCard where Controls == EmptyView {
    /// The self page: the status line only.
    init(status: String?, statusActionable: Bool) {
        self.init(status: status, statusActionable: statusActionable) { EmptyView() }
    }
}

#Preview("Carry card") {
    VStack(spacing: PP.space.xl) {
        CarryCard(status: "Pray with today's list to carry Dad onto List\u{00A0}53", statusActionable: true) {
            Toggle(isOn: .constant(true)) {
                Text(verbatim: "Carry onto the list")
                Text(verbatim: "3 places left")
            }
            .ppSwitch()
        }
        CarryCard(status: "You'll be on List\u{00A0}53", statusActionable: false)
    }
    .padding(PP.space.gutter)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}

#Preview("Carry card · light · large type") {
    CarryCard(status: "Private · in your prayers only", statusActionable: false) {
        Toggle(isOn: .constant(false)) {
            Text(verbatim: "Carry onto the list")
            Text(verbatim: "This uses your last place")
        }
        .ppSwitch()
    }
    .padding(PP.space.gutter)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(PP.color.ground)
    .dynamicTypeSize(.accessibility2)
}
