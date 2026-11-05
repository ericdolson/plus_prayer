import SwiftUI

/// A scratch screen showing the signature components on the ground, in the
/// current theme. Build step 1 only; Home replaces it as the root.
struct ComponentGallery: View {
    @State private var dadHeld = true

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "List 52")
                    .font(PP.type.name)
                    .foregroundStyle(PP.color.ink)
                    .padding(.horizontal, PP.space.gutter)
                    .padding(.bottom, PP.space.xl)

                NameRow(initials: "EO", tone: 7, label: "Me", carried: true, held: false,
                        hasIntentions: true, accessibilityLabel: "Me, carried")
                IntentionRow(text: "Patience with the new job", carried: true, held: false,
                             thread: .lastBranch, accessibilityLabel: "Patience with the new job, carried")

                // Tap Dad or his first intention to watch the ring and dot (and the bloom, in dark).
                NameRow(initials: "D", tone: 0, label: "Dad", carried: true, held: dadHeld,
                        hasIntentions: true, accessibilityLabel: "Dad, carried",
                        onTap: { dadHeld.toggle() })
                    .padding(.top, PP.space.groupGap)
                IntentionRow(text: "Healing after his surgery", carried: true, held: dadHeld,
                             thread: .branch, accessibilityLabel: "Healing after his surgery, carried",
                             onTap: { dadHeld.toggle() })
                IntentionRow(text: "Rest for his heart", carried: false, held: false,
                             thread: .lastBranch, accessibilityLabel: "Rest for his heart")

                NameRow(initials: "M", tone: 8, label: "Mom", carried: true, held: false,
                        hasIntentions: true, accessibilityLabel: "Mom, carried")
                    .padding(.top, PP.space.groupGap)
                IntentionRow(text: "A safe delivery for Ruth", carried: false, held: false,
                             secondary: SecondaryLine(text: "Answered · Oct 19", kind: .answered),
                             thread: .lastBranch, accessibilityLabel: "A safe delivery for Ruth. Answered, October 19")

                NameRow(initials: "DK", tone: 10, label: "Daniel Kim", carried: true, held: false,
                        accessibilityLabel: "Daniel Kim, carried")
                    .padding(.top, PP.space.groupGap)

                // Glyph sampler (not the real bar; that comes with the Home shell).
                HStack(spacing: PP.space.lg) {
                    PPIcon.pray.font(.title2).foregroundStyle(PP.color.onPrimary)
                        .frame(width: PP.size.prayButton.diameter, height: PP.size.prayButton.diameter)
                        .background(PP.color.primary, in: Circle())
                    PPIcon.history.font(.title2).fontWeight(.light)
                    PPIcon.search.font(.title2).fontWeight(.light)
                    PPIcon.add.font(.title2).fontWeight(.light)
                }
                .foregroundStyle(PP.color.ink)
                .padding(.horizontal, PP.space.gutter)
                .padding(.top, PP.space.xxl)
            }
            .padding(.vertical, PP.space.xl)
        }
        .background(PP.color.ground)
    }
}

#Preview("Dark") { ComponentGallery().preferredColorScheme(.dark) }
#Preview("Light") { ComponentGallery().preferredColorScheme(.light) }
