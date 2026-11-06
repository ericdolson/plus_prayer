// The avatar cluster outside the card (design-direction §6, decided
// 2026-10-27; the card's own row is the full-width fill in Card.swift):
// overlapping avatars first, then text that begins with names. You first,
// then the user's order. Up to 5 people: every avatar, and the text counts
// the rest ("You, Dad + 3"). More: 4 avatars and a "+N" disc, and the text
// doesn't count ("You, Dad and others"). The count appears exactly once.
// Used by the Amen invitation, Today's list and Your portion.

public struct ClusterLayout<Person> {
    /// Shown as overlapping avatars, in order.
    public let avatars: [Person]
    /// The "+N" disc after the avatars; 0 = no disc.
    public let overflow: Int
    /// Named in the text: the first one or two.
    public let named: [Person]
    /// Counted in the text after the names ("+ 3"); 0 when there's a disc or
    /// nobody beyond the names.
    public let counted: Int
}

extension ClusterLayout: Sendable where Person: Sendable {}
extension ClusterLayout: Equatable where Person: Equatable {}

public func layoutCluster<Person>(_ people: [Person], maxAvatars: Int = 5, maxNamed: Int = 2) -> ClusterLayout<Person> {
    let fits = people.count <= maxAvatars
    let avatars = fits ? people : Array(people.prefix(maxAvatars - 1))
    let named = Array(people.prefix(maxNamed))
    return ClusterLayout(avatars: avatars, overflow: people.count - avatars.count, named: named,
                         counted: fits ? people.count - named.count : 0)
}
