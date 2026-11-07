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
/// entitlement is active, else free (1). The add sheet's meter.
public func effectivePoolLimit(_ user: UserHeader, now: Date) -> Int {
    hasActiveEntitlement(user, now: now) ? user.includeLimit : freeCarryLimit
}

// MARK: The add sheet's carry row (screens.md, "Carry row")
//
// "Carry onto the list", a toggle, and a meter saying what's left. On
// by default while there's room; with no room it's off and disabled, with an
// (inert for now) "Make room …" under the meter. An intention under a name
// that isn't carried (for any reason) starts off; turning it on carries the
// name too, and the line states the true cost.

/// What the pool counts in, for every `{unit}`. One place to change if
/// open-questions Q32 (people, not items) is adopted.
public enum PoolUnit: Sendable, Equatable {
    case places
}

public let poolUnit = PoolUnit.places

public struct CarryOffer: Sendable, Equatable {
    /// The toggle can turn on: the pool has room for it (and, for an
    /// intention under an uncarried name, for the name too).
    public let hasRoom: Bool
    /// Where the toggle starts.
    public let startsOn: Bool
    /// Turning it on also carries the intention's name ("Also carries Dad").
    public let alsoCarriesParent: Bool
    /// What's carried now, beyond you.
    public let used: Int
    public let pool: Int
    /// How many units turning it on uses: 1, or more when it carries its
    /// name (and the name's intentions still marked carried come back).
    public let cost: Int
    /// No active entitlement: the free pool (one intention under Me).
    public let isFree: Bool

    public init(hasRoom: Bool, startsOn: Bool, alsoCarriesParent: Bool, used: Int, pool: Int, cost: Int = 1,
                isFree: Bool = false) {
        self.hasRoom = hasRoom
        self.startsOn = startsOn
        self.alsoCarriesParent = alsoCarriesParent
        self.used = used
        self.pool = pool
        self.cost = cost
        self.isFree = isFree
    }
}

/// The carry row for a new name (`parentId` nil) or a new intention under
/// `parentId`, against the tree as it is now.
public func carryOffer(kind: SubjectKind, parentId: String?, in tree: SubjectTree, user: UserHeader,
                       now: Date) -> CarryOffer {
    let used = effectiveCarried(tree).count
    let pool = effectivePoolLimit(user, now: now)
    let isFree = !hasActiveEntitlement(user, now: now)
    guard kind == .soul || parentId != nil else {
        return CarryOffer(hasRoom: false, startsOn: false, alsoCarriesParent: false, used: used, pool: pool,
                          isFree: isFree)
    }
    var subjects = Array(tree.all)
    var alsoCarriesParent = false
    if kind == .intention, let parentId, let index = subjects.firstIndex(where: { $0.id == parentId }),
       !subjects[index].isSelf, !subjects[index].isCarried {
        // Carrying it brings the name back, with any intentions still marked
        // carried under it (setCarriedItems' rule).
        subjects[index].isCarried = true
        alsoCarriesParent = true
    }
    subjects.append(Subject(id: "\u{0}new", kind: kind, parentId: kind == .intention ? parentId : nil,
                            publicName: "", isCarried: true, sortOrder: .max, createdAt: now))
    let after = SubjectTree(subjects)
    let hasRoom = checkPool(after, user: user, now: now).fits
    return CarryOffer(hasRoom: hasRoom, startsOn: hasRoom && !alsoCarriesParent,
                      alsoCarriesParent: alsoCarriesParent, used: used, pool: pool,
                      cost: effectiveCarried(after).count - used, isFree: isFree)
}

/// A name's carry row on its own page (detail-page.md, "Carry row"): the
/// toggle shows the name's flag (`startsOn`); turning it on needs room for
/// the name and the intentions still flagged under it (`cost`); `used`
/// leaves the name out, so the meter says what's left before it. Turning
/// it off always works.
public func nameCarryOffer(nameId: String, in tree: SubjectTree, user: UserHeader, now: Date) -> CarryOffer {
    let pool = effectivePoolLimit(user, now: now)
    let isFree = !hasActiveEntitlement(user, now: now)
    var subjects = Array(tree.all)
    guard let index = subjects.firstIndex(where: { $0.id == nameId && $0.isName && !$0.isSelf }) else {
        return CarryOffer(hasRoom: false, startsOn: false, alsoCarriesParent: false,
                          used: effectiveCarried(tree).count, pool: pool, isFree: isFree)
    }
    let isCarried = subjects[index].isCarried
    subjects[index].isCarried = false
    let used = effectiveCarried(SubjectTree(subjects)).count
    subjects[index].isCarried = true
    let carried = SubjectTree(subjects)
    return CarryOffer(hasRoom: isCarried || checkPool(carried, user: user, now: now).fits, startsOn: isCarried,
                      alsoCarriesParent: false, used: used, pool: pool,
                      cost: effectiveCarried(carried).count - used, isFree: isFree)
}

/// A name's carry row subtitle on its page (detail-page.md, 2026-11-07):
/// what this name costs and what's free overall, so "3 left" matches Home
/// and Your portion.
public enum NameCarryMeter: Sendable, Equatable {
    /// Carried: "Uses 2 places · 3 left" (the name and its carried
    /// intentions; "Uses 1 place · 3 left" with none).
    case uses(cost: Int, left: Int)
    /// Not carried, and turning it on brings back intentions still marked
    /// carried: "Would use 2 places · 3 left".
    case wouldUse(cost: Int, left: Int)
    /// Not carried, costing one: "3 places left".
    case left(Int)
    /// Not carried, and it would take everything left: "This uses your last
    /// 2 places".
    case usesLast(Int)
    /// Not carried and nothing left: "All 10 places in use".
    case allInUse(pool: Int)
    /// The free pool: "Free carries you and one intention of your own".
    case freeYouAndOneIntention
}

/// The page's meter for `nameCarryOffer`. "Left" is what's free overall
/// now (never below 0, a lapsed trial included).
public func nameCarryMeter(_ offer: CarryOffer) -> NameCarryMeter {
    if offer.isFree { return .freeYouAndOneIntention }
    let used = offer.used + (offer.startsOn ? offer.cost : 0)
    let left = max(0, offer.pool - used)
    if offer.startsOn { return .uses(cost: offer.cost, left: left) }
    if left == 0 { return .allInUse(pool: offer.pool) }
    if offer.cost == left { return .usesLast(left) }
    return offer.cost > 1 ? .wouldUse(cost: offer.cost, left: left) : .left(left)
}

/// The carry row's muted meter line.
public enum CarryMeter: Sendable, Equatable {
    /// "3 places left": what's left before this item.
    case left(Int)
    /// On, and it takes everything left: "This uses your last place" /
    /// "This uses your last 2 places".
    case usesLast(Int)
    /// Full or over the pool (a lapsed trial): "All 10 places in use" (a
    /// pool of 1: "Your one place is in use"), never "7 of 1".
    case allInUse(pool: Int)
    /// Free pool, Name tab: "Free carries you and one intention of your own".
    case freeYouAndOneIntention
}

/// The meter counts what's left, not including this item, so the toggle
/// doesn't change it, except that turning it on when its full cost is
/// everything left says so (and the "Also carries" line then leaves out
/// its cost).
public func carryMeter(_ offer: CarryOffer, kind: SubjectKind, isOn: Bool) -> CarryMeter {
    if kind == .soul && offer.isFree { return .freeYouAndOneIntention }
    let left = offer.pool - offer.used
    if left <= 0 { return .allInUse(pool: offer.pool) }
    if isOn && offer.cost >= left { return .usesLast(left) }
    return .left(left)
}

/// The ~500-item abuse cap (server config `subjectCap`; not a paywall). It
/// counts active subjects, the ones on Home (Answered included), the same set
/// the app sees, so archiving makes room and the add sheet's line matches the
/// server. (A quiet ~5,000 total-row hard cap is server-only.)
public let subjectCap = 500
