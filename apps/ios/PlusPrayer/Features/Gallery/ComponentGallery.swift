import SwiftUI

/// A scratch screen showing the signature components on the ground, in the
/// current theme. Build step 1 only; Home replaces it as the root.
struct ComponentGallery: View {
    @State private var held = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PP.space.xl) {
                Text(verbatim: "List 52")
                    .font(PP.type.name)
                    .foregroundStyle(PP.color.ink)

                nameRow(initials: "EO", tone: 7, name: "Me", held: false)
                nameRow(initials: "D", tone: 0, name: "Dad", held: held)
                nameRow(initials: "M", tone: 8, name: "Mom", held: false)

                HStack(spacing: PP.space.sm) {
                    HeldDot(held: held)
                    CarriedLabel(text: "Healing after his surgery", carried: true, context: .intention)
                        .font(PP.type.intention)
                        .foregroundStyle(PP.color.inkIntention)
                }

                HStack(spacing: PP.space.lg) {
                    PPIcon.pray.font(.title2).foregroundStyle(PP.color.onPrimary)
                        .frame(width: PP.size.prayButton.diameter, height: PP.size.prayButton.diameter)
                        .background(PP.color.primary, in: Circle())
                    PPIcon.history.font(.title2).fontWeight(.light).foregroundStyle(PP.color.ink)
                    PPIcon.search.font(.title2).fontWeight(.light).foregroundStyle(PP.color.ink)
                    PPIcon.add.font(.title2).fontWeight(.light).foregroundStyle(PP.color.ink)
                }

                Button(held ? "Release" : "Hold") { held.toggle() }
            }
            .padding(PP.space.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(PP.color.ground)
    }

    private func nameRow(initials: String, tone: Int, name: String, held: Bool) -> some View {
        HStack(spacing: PP.space.md) {
            MonogramAvatar(initials: initials, tone: tone).heldRing(held)
            CarriedLabel(text: name, carried: true, context: .name)
                .font(PP.type.name)
                .foregroundStyle(PP.color.ink)
        }
    }
}

#Preview("Dark") { ComponentGallery().preferredColorScheme(.dark) }
#Preview("Light") { ComponentGallery().preferredColorScheme(.light) }
