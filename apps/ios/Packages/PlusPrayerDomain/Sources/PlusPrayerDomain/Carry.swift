import Foundation

// What goes on the printed list (monetization.md, subjects.md; Q32,
// 2026-11-08). Mirrors the server's backend/functions/src/pool.ts so the
// app shows what the next list will print.
//
// - A place = one carried PERSON (a name) beyond the self name. Intentions
//   never cost a place.
// - An intention's `isCarried` means "chosen to print with its person"; each
//   person (Me included) has at most `AppConfig.intentionsPerPerson` chosen.
//   It prints only when its person is carried (or is the self).
// - Resolved items are never list-eligible (answering the chosen intention
//   frees the choice).

/// Does `subject` print (beyond the self name)? A name: carried. An
/// intention: chosen, and its person carried or the self.
public func isEffectivelyCarried(_ subject: Subject, in tree: SubjectTree) -> Bool {
    if subject.isSelf || !subject.isCarried || subject.isResolved { return false }
    if subject.isName { return true }
    guard let parent = tree.parent(of: subject.id) else { return false }
    return parent.isSelf || parent.isCarried
}

/// Whether the row shows the carried mark (design-direction §5): the same
/// set the Carried filter shows. The self is always carried; an intention's
/// mark = chosen ∧ its person carried.
public func showsCarriedMark(_ subject: Subject, in tree: SubjectTree) -> Bool {
    subject.isSelf || isEffectivelyCarried(subject, in: tree)
}

/// The people on the community card's avatar row (and the invitation): you
/// first, then your carried names in your order. Intentions have no avatars.
public func carriedNames(_ tree: SubjectTree) -> [Subject] {
    (tree.me.map { [$0] } ?? []) + tree.names.filter { isEffectivelyCarried($0, in: tree) }
}

// MARK: The pool (monetization.md, Q32)
//
// Effective entitlement: `includeLimit` people while `entitlementExpiresAt`
// is in the future; before the first prayer (never prayed, never entitled)
// the trial's pool, `AppConfig.basePremiumPool` (2026-11-09); otherwise
// free = 0 (you, with your intention). Mirrors pool.ts `effectiveLimit`.
// `prePool` is /config's basePremiumPool (the compiled default when the
// caller has no config).

public let freeCarryLimit = 0

public func hasActiveEntitlement(_ user: UserHeader, now: Date) -> Bool {
    user.entitlementExpiresAt.map { $0 > now } ?? false
}

/// Pre-trial (auth-onboarding.md "Trial starts at the first prayer",
/// 2026-11-09): never prayed (no `trialStartedAt`) and never entitled (no
/// `entitlementExpiresAt`). The people added in onboarding are carried; the
/// 14-day clock starts at the first prayer.
public func isPreTrial(_ user: UserHeader) -> Bool {
    user.trialStartedAt == nil && user.entitlementExpiresAt == nil
}

/// The free tier: no active entitlement and not pre-trial.
public func isFreeTier(_ user: UserHeader, now: Date) -> Bool {
    !hasActiveEntitlement(user, now: now) && !isPreTrial(user)
}

/// The people the pool counts: carried names beyond the self.
public func carriedPeople(_ tree: SubjectTree) -> [Subject] {
    tree.names.filter { !$0.isSelf && $0.isCarried && !$0.isResolved }
}

/// A person's chosen intentions: open ones flagged to print with them, in
/// their order. Answered ones don't count.
public func chosenIntentions(of personId: String, in tree: SubjectTree) -> [Subject] {
    tree.intentions(of: personId).filter { $0.isCarried && !$0.isResolved }
}

/// A person's open intentions: what "Prints with" offers (Answered and
/// Released aren't listed).
public func openIntentions(of personId: String, in tree: SubjectTree) -> [Subject] {
    tree.intentions(of: personId).filter { !$0.isResolved }
}

public struct PoolCheck: Sendable, Equatable {
    /// The carried people fit.
    public let fits: Bool
    /// Carried people beyond you.
    public let carried: Int
    /// What they're measured against (free → `freeCarryLimit`).
    public let limit: Int
    public let isFree: Bool
}

/// Do the tree's carried people fit the user's effective entitlement now?
public func checkPool(_ tree: SubjectTree, user: UserHeader, now: Date,
                      prePool: Int = AppConfig.defaults.basePremiumPool) -> PoolCheck {
    let carried = carriedPeople(tree).count
    let limit = effectivePoolLimit(user, now: now, prePool: prePool)
    return PoolCheck(fits: carried <= limit, carried: carried, limit: limit,
                     isFree: isFreeTier(user, now: now))
}

/// The pool the carry is measured against now: `includeLimit` while the
/// entitlement is active, `prePool` before the first prayer, else free (0).
public func effectivePoolLimit(_ user: UserHeader, now: Date,
                               prePool: Int = AppConfig.defaults.basePremiumPool) -> Int {
    if hasActiveEntitlement(user, now: now) { return user.includeLimit }
    return isPreTrial(user) ? prePool : freeCarryLimit
}

/// Places free now (never below 0).
public func placesLeft(_ tree: SubjectTree, user: UserHeader, now: Date,
                       prePool: Int = AppConfig.defaults.basePremiumPool) -> Int {
    max(0, effectivePoolLimit(user, now: now, prePool: prePool) - carriedPeople(tree).count)
}

/// Auto-carry (monetization.md): a new name is carried while the pool has
/// room; a new intention is chosen while its person is under the cap.
public func carriesNewSubject(_ new: Subject, in tree: SubjectTree, user: UserHeader, now: Date,
                              cap: Int = AppConfig.defaults.intentionsPerPerson,
                              prePool: Int = AppConfig.defaults.basePremiumPool) -> Bool {
    if new.isName { return placesLeft(tree, user: user, now: now, prePool: prePool) > 0 }
    guard let parentId = new.parentId else { return false }
    return chosenIntentions(of: parentId, in: tree).count < cap
}

// MARK: A person's carry toggle (detail-page.md "Carry card", Q32)

/// A person's "Carry onto the list ✱" toggle on their page.
public struct CarryOffer: Sendable, Equatable {
    /// The toggle can turn on (or is on: turning off always works).
    public let hasRoom: Bool
    /// Where the toggle stands: the person's flag.
    public let startsOn: Bool
    /// Carried people now, beyond you, this person included when carried.
    public let used: Int
    public let pool: Int
    /// No active entitlement: the free pool (you, with your intention).
    public let isFree: Bool

    public init(hasRoom: Bool, startsOn: Bool, used: Int, pool: Int, isFree: Bool = false) {
        self.hasRoom = hasRoom
        self.startsOn = startsOn
        self.used = used
        self.pool = pool
        self.isFree = isFree
    }

    /// Places free now (never below 0).
    public var left: Int { max(0, pool - used) }
}

/// The carry toggle for the person `nameId` (not the self).
public func nameCarryOffer(nameId: String, in tree: SubjectTree, user: UserHeader, now: Date,
                           prePool: Int = AppConfig.defaults.basePremiumPool) -> CarryOffer {
    let pool = effectivePoolLimit(user, now: now, prePool: prePool)
    let isFree = isFreeTier(user, now: now)
    let used = carriedPeople(tree).count
    guard let name = tree[nameId], name.isName, !name.isSelf else {
        return CarryOffer(hasRoom: false, startsOn: false, used: used, pool: pool, isFree: isFree)
    }
    return CarryOffer(hasRoom: name.isCarried || used < pool, startsOn: name.isCarried, used: used, pool: pool,
                      isFree: isFree)
}

/// The toggle's subtitle (one place = one person; never negative).
public enum NameCarryMeter: Sendable, Equatable {
    /// "3 places left" (carried or not).
    case left(Int)
    /// Not carried, and it would take the last place: "This uses your last
    /// place".
    case usesLast
    /// Nothing free (carried with none left, over the pool, or full and
    /// off): "All 10 places in use" (a pool of 1: "Your one place is in
    /// use").
    case allInUse(pool: Int)
    /// The free tier: "Free carries you and your intention" (off: disabled,
    /// with "Make room for {alias}").
    case free
}

public func nameCarryMeter(_ offer: CarryOffer) -> NameCarryMeter {
    if offer.isFree { return .free }
    let left = offer.left
    if left == 0 { return .allInUse(pool: offer.pool) }
    if !offer.startsOn && left == 1 { return .usesLast }
    return .left(left)
}

// MARK: An intention's "Print with {alias} ✱" (screens.md, detail-page.md, Q32)

/// The toggle that chooses an intention to print with its person: the add
/// sheet's carry row (a new intention) and an intention's page.
public struct IntentionCarryOffer: Sendable, Equatable {
    /// The person is the self ("Print with your name ✱").
    public let isSelf: Bool
    /// The person is carried (the self always is).
    public let personCarried: Bool
    /// Where the toggle starts: the intention's own flag on its page; for a
    /// new one, on while the person has room under the cap and is carried
    /// (a new intention never spends a place by default).
    public let startsOn: Bool
    /// The toggle can turn on: the person is carried, or there's a place to
    /// carry them. Turning off always works.
    public let hasRoom: Bool
    /// The person's chosen intentions it would replace when turned on (at
    /// the cap): "Instead of “…”". Empty below the cap.
    public let replaces: [Subject]
    /// Turning it on also carries the person: "Also carries {alias} · N
    /// places left".
    public let alsoCarriesPerson: Bool
    /// Places free now (never below 0).
    public let left: Int
    public let pool: Int
    public let isFree: Bool
}

/// - Parameters:
///   - intentionId: an existing intention (its page); nil for a new one
///     (the add sheet).
///   - cap: `AppConfig.intentionsPerPerson`.
public func intentionCarryOffer(personId: String, intentionId: String? = nil, in tree: SubjectTree,
                                user: UserHeader, now: Date,
                                cap: Int = AppConfig.defaults.intentionsPerPerson,
                                prePool: Int = AppConfig.defaults.basePremiumPool) -> IntentionCarryOffer {
    let person = tree[personId]
    let isSelf = person?.isSelf ?? false
    let personCarried = isSelf || (person?.isCarried ?? false)
    let left = placesLeft(tree, user: user, now: now, prePool: prePool)
    let others = chosenIntentions(of: personId, in: tree).filter { $0.id != intentionId }
    let isOn = intentionId.flatMap { tree[$0] }.map { $0.isCarried && !$0.isResolved }
    let replaces = others.count >= max(cap, 1) ? Array(others.suffix(others.count - max(cap, 1) + 1)) : []
    let hasRoom = cap > 0 && (personCarried || left > 0)
    let startsOn = isOn ?? (hasRoom && personCarried && replaces.isEmpty)
    return IntentionCarryOffer(isSelf: isSelf, personCarried: personCarried, startsOn: startsOn,
                               hasRoom: (isOn ?? false) || hasRoom, replaces: (isOn ?? false) ? [] : replaces,
                               alsoCarriesPerson: !personCarried, left: left,
                               pool: effectivePoolLimit(user, now: now, prePool: prePool),
                               isFree: isFreeTier(user, now: now))
}

// MARK: Choosing what prints (setCarriedItems' input)

/// What's carried (names) and chosen (intentions) now: setCarriedItems'
/// whole set, before a change. The self and resolved items aside.
public func carriedIds(_ tree: SubjectTree) -> Set<String> {
    Set(tree.all.filter { !$0.isSelf && !$0.isResolved && $0.isCarried }.map(\.id))
}

/// After choosing `intentionId` to print with its person (on), at `cap`:
/// the person's last chosen intentions by order make room (a swap). Off
/// just unchooses it. With `carryPerson`, the person is carried too.
public func choosing(_ intentionId: String, _ on: Bool, in tree: SubjectTree,
                     cap: Int = AppConfig.defaults.intentionsPerPerson, carryPerson: Bool = false) -> Set<String> {
    var ids = carriedIds(tree)
    guard let intention = tree[intentionId], let personId = intention.parentId else { return ids }
    guard on else {
        ids.remove(intentionId)
        return ids
    }
    let others = chosenIntentions(of: personId, in: tree).filter { $0.id != intentionId }
    let keep = max(cap - 1, 0)
    for extra in others.dropFirst(keep) { ids.remove(extra.id) }
    ids.insert(intentionId)
    if carryPerson, let person = tree[personId], !person.isSelf { ids.insert(personId) }
    return ids
}

/// "Prints with": the check list's result after a tap. `intentionId` nil =
/// "Name only" (nothing chosen). At cap 1 a tap moves the check; with a
/// higher cap a tap toggles, and at the cap an unchecked row changes
/// nothing (the view disables it).
public func printsWith(_ intentionId: String?, for personId: String, in tree: SubjectTree,
                       cap: Int = AppConfig.defaults.intentionsPerPerson) -> Set<String> {
    var ids = carriedIds(tree)
    let chosen = chosenIntentions(of: personId, in: tree)
    guard let intentionId else {
        for c in chosen { ids.remove(c.id) }
        return ids
    }
    if cap <= 1 {
        for c in chosen { ids.remove(c.id) }
        if cap == 1 { ids.insert(intentionId) }
        return ids
    }
    if ids.contains(intentionId) {
        ids.remove(intentionId)
    } else if chosen.count < cap {
        ids.insert(intentionId)
    }
    return ids
}

// MARK: Restore (subjects.md; mirrors the server's restoreSubject)

/// `item` (as restored: Released reopened) and, for a name, its
/// cascade-archived `intentions` come back into `tree`. Returns the item's
/// own flag after: kept, or false when a name would go over the pool, or
/// an intention's person already has `cap` chosen. A name's intentions keep
/// their choices. Never blocks the restore.
public func restoredCarryFlag(_ item: Subject, intentions: [Subject] = [], into tree: SubjectTree,
                              user: UserHeader, now: Date,
                              cap: Int = AppConfig.defaults.intentionsPerPerson,
                              prePool: Int = AppConfig.defaults.basePremiumPool) -> Bool {
    guard item.isCarried else { return false }
    if item.isName {
        let after = SubjectTree(Array(tree.all) + [item] + intentions)
        return checkPool(after, user: user, now: now, prePool: prePool).fits
    }
    guard !item.isResolved, let parentId = item.parentId else { return true }
    return chosenIntentions(of: parentId, in: tree).filter { $0.id != item.id }.count < cap
}

/// The ~500-item abuse cap (server config `subjectCap`; not a paywall). It
/// counts active subjects, the ones on Home (Answered included), the same set
/// the app sees, so archiving makes room and the add sheet's line matches the
/// server. (A quiet ~5,000 total-row hard cap is server-only.)
public let subjectCap = 500
