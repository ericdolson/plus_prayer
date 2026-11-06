// Monogram avatars (design-direction.md §1b): white initials on a bright tone.
// The default tone comes from a hash of the subject id (not the name, so a
// rename doesn't recolor anyone); the user can pick another palette index.

/// Size of the tone palette; matches the backend's 0–15 range check.
public let avatarToneCount = 16

/// FNV-1a (32-bit) over the id's UTF-16 code units, mod 16.
///
/// Must return the same tone as the Flutter build (`defaultAvatarTone` in
/// `app/lib/domain/rules/avatar.dart`) and the Android app, or the same
/// person changes color across devices. Frozen at launch.
public func defaultAvatarTone(id: String) -> Int {
    var hash: UInt32 = 0x811C_9DC5
    for unit in id.utf16 {
        hash ^= UInt32(unit)
        hash = hash &* 0x0100_0193
    }
    return Int(hash % UInt32(avatarToneCount))
}

/// Up to two initials (first and last word), in any script. Works on
/// grapheme clusters, so "Zoë" and emoji stay whole.
public func initials(_ text: String) -> String {
    let words = text.split(whereSeparator: \.isWhitespace)
    guard let first = words.first?.first else { return "" }
    guard words.count > 1, let last = words.last?.first else {
        return String(first).uppercased()
    }
    return String(first).uppercased() + String(last).uppercased()
}

/// A subject's avatar initials, the same on its row, the header and the
/// card's row (design-direction §6): your own from your printed name ("EO",
/// not "M" for "Me"), everyone else's from what you call them ("D" for Dad).
public func monogram(_ subject: Subject) -> String {
    initials(subject.isSelf ? subject.publicName : subject.label)
}

// MARK: New subjects (design-direction §1b, 2026-11-05)

/// The tones used least among `tones` (the tones you see on Home: stored, or
/// the hashed fallback), in palette order. The add sheet picks one of these
/// at random when it opens and stores it on create.
public func leastUsedTones(_ tones: [Int]) -> [Int] {
    var counts = Array(repeating: 0, count: avatarToneCount)
    for tone in tones where (0..<avatarToneCount).contains(tone) { counts[tone] += 1 }
    let fewest = counts.min() ?? 0
    return counts.indices.filter { counts[$0] == fewest }
}

/// A tone for a new subject: least used, ties at random.
public func pickTone(_ tones: [Int], using generator: inout some RandomNumberGenerator) -> Int {
    leastUsedTones(tones).randomElement(using: &generator) ?? 0
}
