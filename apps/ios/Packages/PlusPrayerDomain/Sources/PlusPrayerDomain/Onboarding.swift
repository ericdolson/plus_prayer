import Foundation

// First run (auth-onboarding.md, "Flow (revised 2026-11-09)", "Onboarding
// resume is state-based", "One name field").

/// Where the app opens, from data only (never a stored step counter).
public enum LaunchDestination: Sendable, Equatable {
    /// The account isn't ready yet (no header): nothing to decide.
    case waiting
    /// No self name: onboarding from its first screen (Welcome).
    case onboarding
    /// A self name exists: Home. Quitting on the screens after the name
    /// lands here next launch ("Who else" was optional; ＋ covers it).
    case home
}

public func launchDestination(_ header: UserHeader?) -> LaunchDestination {
    guard let header else { return .waiting }
    return header.hasSelfName ? .home : .onboarding
}

/// What the app calls a person it's adding: what you call them ("Mom")
/// when given, else their name ("Julie Olson"); cleaned. Drives the
/// guided add's avatar and its lines ("{alias} will be carried…").
public func personLabel(name: String, alias: String) -> String {
    let alias = cleanText(alias)
    return alias.isEmpty ? cleanText(name) : alias
}

/// The greeting's name (screen 3): the full name as printed, never a
/// guessed first name ("Sarah Beth Parker" stays whole).
public func greetingName(_ header: UserHeader?) -> String? {
    header?.displayName.map(cleanText).flatMap { $0.isEmpty ? nil : $0 }
}
