import CoreImage
import SwiftUI
import UIKit

/// The day's wax seal (design-direction §6, list-lifecycle.md): the bloom
/// pressed into wax. One gray stamp, tinted to the weekday's wax by
/// `sealVariant` (0 = Sunday … 6 = Saturday). `variant == nil` is the unsealed
/// state ("being filmed"): the same stamp as a neutral blank with its relief.
///
/// Dark theme: the wax body lifts toward its sheen where it needs it, and
/// seals from `size.seal.rimMinSize` up get a thin rim light so dark waxes
/// separate from dark surfaces. Large sizes switch to photographs once D3
/// lands; until then the tinted stamp is used everywhere.
struct WaxSeal: View {
    let variant: Int?
    var size: CGFloat = PP.size.seal.default
    /// VoiceOver label, e.g. "List 52, sealed"; nil = decorative.
    var accessibilityLabel: String? = nil

    @Environment(\.self) private var environment

    var body: some View {
        ZStack {
            if size >= PP.size.seal.rimMinSize, let rim = StampTint.silhouette(rimColor.resolve(in: environment)) {
                Image(uiImage: rim)
                    .resizable()
                    .frame(width: size + PP.size.seal.rimWidth * 2, height: size + PP.size.seal.rimWidth * 2)
            }
            if let seal = sealImage {
                Image(uiImage: seal).resizable().frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel ?? "")
        .accessibilityHidden(accessibilityLabel == nil)
    }

    private var index: Int? { variant.map { $0.mod(PP.color.wax.base.count) } }

    private var sealImage: UIImage? {
        guard let v = index else {
            return StampTint.relief(PP.color.unsealed.resolve(in: environment))
        }
        return StampTint.wax(base: PP.color.wax.body[v].resolve(in: environment),
                             sheen: PP.color.wax.sheen[v].resolve(in: environment))
    }

    /// Clear in light theme (the tokens are dark-only).
    private var rimColor: Color {
        guard let v = index else { return PP.color.unsealedRim.opacity(PP.number.waxDarkRimOpacity) }
        return PP.color.wax.rim[v]
    }
}

/// The same stamp unwaxed, in pewter: the streak badge's seal (§4). Never gold,
/// never a wax color (wax belongs to a list, not to you). Decorative.
struct PewterSeal: View {
    var size: CGFloat = PP.size.seal.badge
    /// One step dimmer: not yet prayed with the list today, or no streak.
    var dimmed = false

    @Environment(\.self) private var environment

    var body: some View {
        if let image = StampTint.relief((dimmed ? PP.color.inkFaint : PP.color.inkMuted).resolve(in: environment)) {
            Image(uiImage: image)
                .resizable()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

/// Tints the one gray stamp (Assets: Seals/Stamp) with Core Image color
/// matrices (the Flutter build's math), cached per color. Every seal (the
/// seven waxes, the unsealed blank, pewter, the rim) comes from the same art.
@MainActor
private enum StampTint {
    /// Facts about the stamp art, not design tokens: its face sits at this
    /// gray, its highlights near white.
    private static let face: CGFloat = 0.77

    /// sRGB working space: the stamp math (like Flutter's) is on sRGB values,
    /// not Core Image's default linear light.
    private static let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let context = CIContext(options: [.workingColorSpace: srgb, .outputColorSpace: srgb])
    private static var cache: [String: UIImage] = [:]
    private static let source: CIImage? = UIImage(resource: .stamp).cgImage.map { CIImage(cgImage: $0) }

    /// Face → `base`, highlights → `sheen`, shadows darker along the same line.
    static func wax(base: Color.Resolved, sheen: Color.Resolved) -> UIImage? {
        let b = rgb(base), s = rgb(sheen)
        let k = (0..<3).map { (s[$0] - b[$0]) / (1 - face) }
        return render(key: "wax\(b)\(s)",
                      rows: k.map { [$0 / 3, $0 / 3, $0 / 3] },
                      bias: (0..<3).map { b[$0] - k[$0] * face })
    }

    /// Moves the face onto `tint` and keeps every tone's distance from it.
    static func relief(_ tint: Color.Resolved) -> UIImage? {
        let t = rgb(tint)
        return render(key: "relief\(t)",
                      rows: Array(repeating: [1 / 3, 1 / 3, 1 / 3], count: 3),
                      bias: t.map { $0 - face })
    }

    /// The silhouette in one color; nil when fully transparent (light theme).
    static func silhouette(_ fill: Color.Resolved) -> UIImage? {
        guard fill.opacity > 0 else { return nil }
        let f = rgb(fill)
        return render(key: "silhouette\(f)\(fill.opacity)",
                      rows: Array(repeating: [0, 0, 0], count: 3),
                      bias: f,
                      alpha: CGFloat(fill.opacity))
    }

    /// The color's sRGB components (rounded, so cache keys are stable).
    private static func rgb(_ c: Color.Resolved) -> [CGFloat] {
        let cg = c.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil) ?? c.cgColor
        let parts = cg.components ?? [0, 0, 0]
        return (0..<3).map { (parts[min($0, parts.count - 1)] * 1000).rounded() / 1000 }
    }

    private static func render(key: String, rows: [[CGFloat]], bias: [CGFloat], alpha: CGFloat = 1) -> UIImage? {
        if let hit = cache[key] { return hit }
        guard let source, let filter = CIFilter(name: "CIColorMatrix") else { return nil }
        filter.setValue(source, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: rows[0][0], y: rows[0][1], z: rows[0][2], w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: rows[1][0], y: rows[1][1], z: rows[1][2], w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: rows[2][0], y: rows[2][1], z: rows[2][2], w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: alpha), forKey: "inputAVector")
        filter.setValue(CIVector(x: bias[0], y: bias[1], z: bias[2], w: 0), forKey: "inputBiasVector")
        guard let output = filter.outputImage?.cropped(to: source.extent),
              let cg = context.createCGImage(output, from: source.extent) else { return nil }
        let image = UIImage(cgImage: cg)
        cache[key] = image
        return image
    }
}

private extension Int {
    func mod(_ n: Int) -> Int { ((self % n) + n) % n }
}

#Preview("Seals") {
    VStack(spacing: PP.space.xl) {
        HStack(spacing: PP.space.md) {
            ForEach(0..<7) { WaxSeal(variant: $0) }
        }
        HStack(spacing: PP.space.lg) {
            WaxSeal(variant: nil, size: PP.size.card.stamp)
            WaxSeal(variant: 3, size: PP.size.card.stamp)
        }
        HStack(spacing: PP.space.lg) {
            PewterSeal()
            PewterSeal(dimmed: true)
            ForEach(0..<7) { WaxSeal(variant: $0, size: PP.size.bead.diameter) }
        }
    }
    .padding(PP.space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(PP.color.cardSurface)
}
