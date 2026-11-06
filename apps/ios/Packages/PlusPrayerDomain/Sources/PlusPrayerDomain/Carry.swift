import Foundation

// What goes on the printed list (monetization.md, subjects.md). Mirrors the
// server's backend/functions/src/pool.ts so the app shows what the next list
// will print.
//
// - Effective carry: an intention is carried only if it and its name are
//   (or its name is the self). The self name is always carried and isn't
//   part of the pool.
// - Resolved items are never list-eligible.

/// Is `subject` effectively carried (beyond the self name)?
public func isEffectivelyCarried(_ subject: Subject, in tree: SubjectTree) -> Bool {
    if subject.isSelf || !subject.isCarried || subject.isResolved { return false }
    if subject.isName { return true }
    guard let parent = tree.parent(of: subject.id) else { return false }
    return parent.isSelf || parent.isCarried
}

/// Whether the row shows the carried mark (design-direction §5): the same
/// set the Carried filter shows. The self is always carried.
public func showsCarriedMark(_ subject: Subject, in tree: SubjectTree) -> Bool {
    subject.isSelf || isEffectivelyCarried(subject, in: tree)
}

/// The people on the community card's avatar row (and the invitation): you
/// first, then your effectively carried names in your order. Intentions have
/// no avatars.
public func carriedNames(_ tree: SubjectTree) -> [Subject] {
    (tree.me.map { [$0] } ?? []) + tree.names.filter { isEffectivelyCarried($0, in: tree) }
}

// MARK: The pool (monetization.md)
//
// Effective entitlement: `includeLimit` while `entitlementExpiresAt` is in
// the future; otherwise free = 1, which must be an intention under Me.

public let freeCarryLimit = 1

public func hasActiveEntitlement(_ user: UserHeader, now: Date) -> Bool {
    user.entitlementExpiresAt.map { $0 > now } ?? false
}

/// Everything effectively carried beyond the self name.
public func effectiveCarried(_ tree: SubjectTree) -> [Subject] {
    tree.all.filter { isEffectivelyCarried($0, in: tree) }
}

public struct PoolCheck: Sendable, Equatable {
    /// The carried set fits.
    public let fits: Bool
    public let carried: Int
    /// What the carry is measured against (free → `freeCarryLimit`).
    public let limit: Int
    public let isFree: Bool
}

/// Does the tree's carried set fit the user's effective entitlement now?
public func checkPool(_ tree: SubjectTree, user: UserHeader, now: Date) -> PoolCheck {
    let carried = effectiveCarried(tree)
    if hasActiveEntitlement(user, now: now) {
        return PoolCheck(fits: carried.count <= user.includeLimit, carried: carried.count,
                         limit: user.includeLimit, isFree: false)
    }
    let me = tree.me?.id
    let fitsFree = carried.count <= freeCarryLimit && carried.allSatisfy { $0.isIntention && $0.parentId == me }
    return PoolCheck(fits: fitsFree, carried: carried.count, limit: freeCarryLimit, isFree: true)
}

/// Auto-carry (monetization.md): a new name or intention is carried while
/// the pool has room; otherwise it's saved for private prayer.
public func carriesNewSubject(_ new: Subject, in tree: SubjectTree, user: UserHeader, now: Date) -> Bool {
    var carried = new
    carried.isCarried = true
    let all = Array(tree.all) + [carried]
    return checkPool(SubjectTree(all), user: user, now: now).fits
}

/// The pool the carry is measured against now: `includeLimit` while the
/// entitlement is active, else free (1). The add sheet's "All {pool} places".
public func effectivePoolLimit(_ user: UserHeader, now: Date) -> Int {
    hasActiveEntitlement(user, now: now) ? user.includeLimit : freeCarryLimit
}

// MARK: The add sheet's invitation when the pool is full
//
// PROPOSED, not decided (open-questions Q31): kept to this one rule so the
// cadence is easy to change. Never silent, never on Home; the sheet says
// "{alias} is saved for your own prayers. All {pool} places on the list are
// in use." and then, under it:

public enum PoolFullInvitation: Sendable, Equatable {
    /// The first full-pool add of your local day, when a larger pool exists:
    /// "Membership carries up to {premiumPool} of your people each day."
    /// + [See membership].
    case membership(premiumPool: Int)
    /// Otherwise: only the small "Your portion" link (it holds the upgrade
    /// path). On the top pool there's never an upsell.
    case portionLink
}

/// - Parameters:
///   - premiumPool: the base subscription's pool (`/config` `basePremiumPool`).
///   - shownOn: the local day the membership invitation was last shown on
///     this device ("shown today" is device-local).
///   - cooldownDays: days before it can show again. 1 = once per local day
///     (the placeholder); 7 would be first time, then at most weekly.
public func poolFullInvitation(user: UserHeader, now: Date, today: LocalDate, premiumPool: Int,
                               shownOn: LocalDate?, cooldownDays: Int = 1) -> PoolFullInvitation {
    guard effectivePoolLimit(user, now: now) < premiumPool else { return .portionLink }
    if let shownOn, today.days(since: shownOn) < cooldownDays { return .portionLink }
    return .membership(premiumPool: premiumPool)
}

/// The free pool (you're always carried free, so "Your free place").
public func isFreePool(_ user: UserHeader, now: Date) -> Bool { !hasActiveEntitlement(user, now: now) }

/// The ~500-item abuse cap (server config `subjectCap`; not a paywall). It
/// counts active subjects, the ones on Home (Answered included), the same set
/// the app sees, so archiving makes room and the add sheet's line matches the
/// server. (A quiet ~5,000 total-row hard cap is server-only.)
public let subjectCap = 500
