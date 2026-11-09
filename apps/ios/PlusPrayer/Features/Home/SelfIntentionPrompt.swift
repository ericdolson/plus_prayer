import SwiftUI

/// One quiet line under the Me row after the first prayer
/// (auth-onboarding.md, "After the first Amen"): "Add an intention for
/// yourself" (blue: it opens the add-intention form for Me) with "It prints
/// beside your name." under it, and a × that hides it for good. Aligned
/// with the row's text, where an intention would hang.
struct SelfIntentionPrompt: View {
    /// Dismissed for good on this device (`@AppStorage`).
    nonisolated static let dismissedKey = "home.selfIntention.dismissed"

    let onAdd: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
            Button(action: onAdd) {
                VStack(alignment: .leading, spacing: PP.space.xxs) {
                    Text(L10n.Home.selfIntention)
                        .font(PP.type.bodySmall)
                        .foregroundStyle(PP.color.primary)
                    Text(L10n.Home.selfIntentionLine)
                        .font(PP.type.caption)
                        .foregroundStyle(PP.color.inkMuted)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("home.selfIntention.add")
            Button(action: onDismiss) {
                PPIcon.close
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
                    .frame(width: PP.size.hitTarget, height: PP.size.hitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Home.selfIntentionDismiss)
            .accessibilityIdentifier("home.selfIntention.dismiss")
        }
        .padding(.leading, ThreadGeometry.textStart)
        .padding(.trailing, PP.space.xs)
    }
}

#Preview("Under Me") {
    VStack(alignment: .leading, spacing: 0) {
        NameRow(initials: "EO", tone: 11, label: "Me", carried: true, held: true, accessibilityLabel: "Me")
        SelfIntentionPrompt(onAdd: {}, onDismiss: {})
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}

#Preview("Under Me, light, large type") {
    VStack(alignment: .leading, spacing: 0) {
        NameRow(initials: "EO", tone: 11, label: "Me", carried: true, held: true, accessibilityLabel: "Me")
        SelfIntentionPrompt(onAdd: {}, onDismiss: {})
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(PP.color.ground)
    .preferredColorScheme(.light)
    .dynamicTypeSize(.accessibility2)
}
