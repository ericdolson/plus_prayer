import SwiftUI

/// SEAM (auth-onboarding.md, Flow step 2): a drawn stand-in for one line of
/// the real list paper, the name set live over it in Roca. To be replaced
/// by a photograph of a line of the printed list, shot in the ritual's
/// light (names otherwise never legible); the label and the name stay on top.
///
/// Paper (`onboardingPaper`), dashed stitch lines at both ends, "LIST 53"
/// at the top trailing corner, a faint guide line under the name, a soft
/// shadow. The same in both appearances. `content` (the name) is centered.
struct ListPaperLine<Content: View>: View {
    /// "List 53" (shown uppercase); nil while the list isn't known.
    let label: String?
    @ViewBuilder let content: () -> Content

    private var paper: PP.size.onboarding.paper.Type { PP.size.onboarding.paper.self }

    var body: some View {
        RoundedRectangle(cornerRadius: paper.radius)
            .fill(PP.color.onboardingPaper)
            .shadow(color: PP.color.shadow.opacity(PP.number.onboarding.paperShadow),
                    radius: paper.shadowRadius, y: paper.shadowY)
            .overlay { stitches }
            .overlay(alignment: .top) { guide }
            .overlay(alignment: .topTrailing) {
                if let label {
                    Text(verbatim: label)
                        .textCase(.uppercase)
                        .font(PP.type.onboardingPaperLabel)
                        .tracking(PP.number.onboarding.paperTracking * UIFont.preferredFont(forTextStyle: .caption2).pointSize)
                        .foregroundStyle(PP.color.onboardingPaperMuted)
                        .lineLimit(1)
                        .padding(.top, paper.edgeInset)
                        .padding(.trailing, paper.labelInset)
                        .accessibilityHidden(true)
                }
            }
            .overlay { content().padding(.horizontal, paper.guideInset) }
            .frame(minHeight: paper.height)
    }

    /// The dashed stitch lines at both ends.
    private var stitches: some View {
        HStack {
            stitch
            Spacer(minLength: 0)
            stitch
        }
        .padding(.horizontal, paper.perforationInset)
        .padding(.vertical, paper.edgeInset)
        .accessibilityHidden(true)
    }

    private var stitch: some View {
        StitchLine()
            .stroke(PP.color.onboardingPaperInk.opacity(PP.number.onboarding.paperPerforation),
                    style: StrokeStyle(lineWidth: paper.perforationStroke,
                                       dash: [paper.perforationDash, paper.perforationDash]))
            .frame(width: paper.perforationStroke)
    }

    private var guide: some View {
        Rectangle()
            .fill(PP.color.onboardingPaperInk.opacity(PP.number.onboarding.paperGuide))
            .frame(height: PP.size.onboarding.hairline)
            .padding(.horizontal, paper.guideInset)
            .padding(.top, paper.guideTop)
            .accessibilityHidden(true)
    }
}

/// A vertical line down the middle of its frame.
private struct StitchLine: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

#Preview("Paper line") {
    VStack(spacing: PP.space.xl) {
        ListPaperLine(label: L10n.Card.title(53)) {
            Text(verbatim: "Eric Olson")
                .font(PP.type.onboardingName)
                .scaleEffect(PP.number.onboarding.paperNameScale)
                .foregroundStyle(PP.color.onboardingPaperInk)
        }
        ListPaperLine(label: nil) { EmptyView() }
    }
    .padding(PP.space.xxl)
    .frame(maxHeight: .infinity)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}

#Preview("Paper line, light, large type") {
    ListPaperLine(label: L10n.Card.title(53)) {
        Text(verbatim: "Sarah Beth Parker")
            .font(PP.type.onboardingName)
            .foregroundStyle(PP.color.onboardingPaperInk)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
    .padding(PP.space.xxl)
    .frame(maxHeight: .infinity)
    .background(PP.color.ground)
    .preferredColorScheme(.light)
    .dynamicTypeSize(.accessibility3)
}
