import Foundation

// First run (auth-onboarding.md, "Flow (redesigned 2026-11-09, second
// pass)", "After the first Amen", "Onboarding resume is state-based", "One
// name field").

/// Where the app opens, from data only (never a stored step counter).
public enum LaunchDestination: Sendable, Equatable {
    /// The account isn't ready yet (no header): nothing to decide.
    case waiting
    /// No self name: onboarding from its first step (your name).
    case onboarding
    /// A self name exists: Home. Quitting on the steps after the name
    /// lands here next launch (the person was optional; ＋ covers it).
    case home
}

public func launchDestination(_ header: UserHeader?) -> LaunchDestination {
    guard let header else { return .waiting }
    return header.hasSelfName ? .home : .onboarding
}

/// What the app calls a person it's adding: what you call them ("Mom")
/// when given, else their name ("Julie Olson"); cleaned. Drives the
/// person's avatar on the onboarding steps and their lines ("What are you
/// praying for, for {alias}?").
public func personLabel(name: String, alias: String) -> String {
    let alias = cleanText(alias)
    return alias.isEmpty ? cleanText(name) : alias
}

/// The user has prayed at least once: a prayer in the History log, one
/// still on the device, a day with the list, or a name held on some day
/// (each prayer leaves at least one of these).
public func hasPrayed(_ user: UserHeader?, tree: SubjectTree, loggedPrayers: Int, localPrayers: Int) -> Bool {
    loggedPrayers > 0 || localPrayers > 0 || user?.lastListLocalDate != nil
        || tree.all.contains { $0.lastPrayed != nil }
}

/// Home's quiet line under the Me row, "Add an intention for yourself"
/// (auth-onboarding.md, "After the first Amen"): only after the first
/// prayer (the first Home has only Pray lit), only while Me has no open
/// intention, and never again once dismissed (or before Me exists).
public func showsSelfIntentionPrompt(hasPrayed: Bool, tree: SubjectTree, dismissed: Bool) -> Bool {
    guard hasPrayed, !dismissed, let me = tree.me else { return false }
    return openIntentions(of: me.id, in: tree).isEmpty
}
