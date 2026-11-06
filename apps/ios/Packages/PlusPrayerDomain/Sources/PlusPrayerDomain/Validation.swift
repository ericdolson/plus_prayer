import Foundation

// Text rules (app-brief "Input validation", subjects.md). Caps count
// grapheme clusters: Swift's `String.count` already does. The contact check
// for names and intentions comes with the add sheet.

public enum TextCap {
    public static let name = 40
    public static let intention = 80
    public static let alias = 40
    /// A prayer's private note.
    public static let note = 1000
}

/// A note as saved: trimmed, nil when empty, cut at the cap.
public func cleanNote(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : String(trimmed.prefix(TextCap.note))
}
