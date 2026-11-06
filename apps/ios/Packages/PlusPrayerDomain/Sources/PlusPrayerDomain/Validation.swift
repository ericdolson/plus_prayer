import Foundation

// Text rules (app-brief "Input validation", subjects.md), the same as the
// server's (backend/functions: the contact check) and the Flutter build's.
// Caps count grapheme clusters: Swift's `String.count` already does.
//
// Names and intentions are printed, so they can't include phone numbers,
// emails or links; verse references ("John 3:16"), room numbers, dates and
// years must still save. Aliases are owner-only and never checked for
// contact info.

public enum TextCap {
    public static let name = 40
    public static let intention = 80
    public static let alias = 40
    /// A prayer's private note.
    public static let note = 1000

    public static func printed(_ kind: SubjectKind) -> Int { kind == .soul ? name : intention }
}

public enum TextIssue: Sendable, Equatable {
    /// Nothing to save.
    case empty
    /// Over the cap.
    case tooLong(cap: Int)
    /// A phone number, email or link in printed text.
    case contactInfo
}

/// Trims and collapses whitespace runs (newlines included) to one space, as
/// the server stores it.
public func cleanText(_ text: String) -> String {
    text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
}

/// A name or an intention: the printed text.
public func validatePrinted(_ raw: String, kind: SubjectKind) -> TextIssue? {
    let text = cleanText(raw)
    if text.isEmpty { return .empty }
    let cap = TextCap.printed(kind)
    if text.count > cap { return .tooLong(cap: cap) }
    if hasContactInfo(text) { return .contactInfo }
    return nil
}

/// An alias: optional, capped, never checked for contact info.
public func validateAlias(_ raw: String?) -> TextIssue? {
    guard let raw else { return nil }
    return cleanText(raw).count > TextCap.alias ? .tooLong(cap: TextCap.alias) : nil
}

/// A note as saved: trimmed, nil when empty, cut at the cap.
public func cleanNote(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : String(trimmed.prefix(TextCap.note))
}

// MARK: Contact detection

private func regex(_ pattern: String) -> NSRegularExpression {
    try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
}

private nonisolated(unsafe) let email = regex(#"[^\s@]+@[^\s@]+\.[a-z]{2,}"#)
private nonisolated(unsafe) let urlPrefix = regex(#"\bhttps?://|\bwww\."#)
/// A label followed by a real TLD and no more letters ("St. Jude", "e.g."
/// and initials don't qualify).
private nonisolated(unsafe) let domain = regex(
    #"\b[a-z0-9][a-z0-9-]*\.(com|net|org|edu|gov|info|biz|io|co|me|ly|app|dev|ai|xyz|online|site|store|blog|page|link|tv|gg|us|uk|ca|au|nz|ie|in|de|fr|es|it|nl|be|ch|at|pt|br|mx|ph|za|ng|ke)(?![a-z])"#)

/// Numeric things that aren't phone numbers, removed before counting digits.
private nonisolated(unsafe) let notPhone = [
    regex(#"\b\d{4}-\d{1,2}-\d{1,2}\b"#), // 2026-10-18
    regex(#"\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b"#), // 10/18/2026, 18.10.26, 10-18-2026
    regex(#"\b(1[89]|20)\d{2}\s*[-–—]\s*(1[89]|20)\d{2}\b"#), // 1945-2023
    regex(#"\b\d{1,3}:\d{1,3}(\s*[-–]\s*\d{1,3}(:\d{1,3})?)?\b"#), // 3:16, 41:10-13, 3:16-4:2
]

/// A run of digits joined by phone separators (space, dot, dash, parens, plus).
private nonisolated(unsafe) let digitRun = regex(#"\+?\(?\d[\d\s.()-]*\d"#)

private func matches(_ re: NSRegularExpression, _ text: String) -> Bool {
    re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
}

public func hasPhoneNumber(_ text: String) -> Bool {
    var t = text
    for re in notPhone {
        t = re.stringByReplacingMatches(in: t, range: NSRange(t.startIndex..., in: t), withTemplate: " ")
    }
    return digitRun.matches(in: t, range: NSRange(t.startIndex..., in: t)).contains { match in
        guard let range = Range(match.range, in: t) else { return false }
        return t[range].filter(\.isASCIIDigit).count >= 7
    }
}

public func hasContactInfo(_ text: String) -> Bool {
    matches(email, text) || matches(urlPrefix, text) || matches(domain, text) || hasPhoneNumber(text)
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
