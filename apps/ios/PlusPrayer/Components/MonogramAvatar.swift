import SwiftUI

/// A monogram avatar (design-direction §1b, §2): white initials at 70% on a
/// bright tone. The initials are the system sans (not the serif), sized from
/// the disc rather than Dynamic Type, tracked slightly apart when there are
/// two. Too small for two letters → one; too small for one → color only.
///
/// Decorative to VoiceOver: the row or cluster around it says the name.
struct MonogramAvatar: View {
    /// Up to two initials (`initials(_:)` in PlusPrayerDomain).
    let initials: String
    /// Palette index, 0–15 (`PrayerSubject.avatarTone`, or the default from the id).
    let tone: Int
    var size: CGFloat = PP.size.avatar.row
    /// false: the initials only, for a control that puts them on glass tinted
    /// with `color(tone:)` (your avatar in Home's header).
    var filled = true

    static func color(tone: Int) -> Color {
        PP.color.avatarTones[tone.mod(PP.color.avatarTones.count)]
    }

    var body: some View {
        Circle()
            .fill(filled ? Self.color(tone: tone) : .clear)
            .frame(width: size, height: size)
            .overlay {
                if let glyph = Glyph(initials: initials, diameter: size) {
                    Text(glyph.text)
                        .font(PP.type.initials(size: glyph.size))
                        .tracking(glyph.isPair ? glyph.size * PP.number.initialsTracking : 0)
                        .foregroundStyle(PP.color.onAvatar)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .accessibilityHidden(true)
    }
}

/// What fits on a disc of a given diameter.
private struct Glyph {
    let text: String
    let size: CGFloat
    var isPair: Bool { text.count > 1 }

    init?(initials: String, diameter: CGFloat) {
        let minimum = PP.size.avatar.initialsMinGlyph
        let scaled = diameter * PP.number.initialsScale
        if initials.count > 1, scaled >= minimum {
            (text, size) = (initials, scaled)
        } else if let first = initials.first, minimum <= diameter / 2 {
            (text, size) = (String(first), max(scaled, minimum))
        } else {
            return nil
        }
    }
}

private extension Int {
    /// Always non-negative, unlike `%`.
    func mod(_ n: Int) -> Int { ((self % n) + n) % n }
}

#Preview("Sizes and tones") {
    VStack(alignment: .leading, spacing: PP.space.lg) {
        ForEach([PP.size.avatar.large, PP.size.avatar.row, PP.size.avatar.header,
                 PP.size.card.avatar, PP.size.cluster.avatar, PP.size.avatar.tiny], id: \.self) { size in
            HStack(spacing: PP.space.sm) {
                ForEach(0..<8) { tone in
                    MonogramAvatar(initials: tone.isMultiple(of: 2) ? "DK" : "D", tone: tone, size: size)
                }
            }
        }
    }
    .padding(PP.space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(PP.color.ground)
}
