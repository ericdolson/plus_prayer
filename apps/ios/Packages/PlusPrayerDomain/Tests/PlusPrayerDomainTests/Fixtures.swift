import Foundation
@testable import PlusPrayerDomain

/// A small tree like the mock seed: Me (+1), Dad (+2, one private), Mom (+1
/// answered), Bea (not carried, +1 carried).
enum Fixture {
    static let today = LocalDate(year: 2026, month: 11, day: 5)
    static let epoch = Date(timeIntervalSince1970: 1_780_000_000)

    static func name(_ id: String, _ text: String, order: Int, alias: String? = nil, carried: Bool = true,
                     isSelf: Bool = false, prayed: Int? = nil) -> Subject {
        Subject(id: id, kind: .soul, publicName: text, alias: alias, isSelf: isSelf, isCarried: carried,
                sortOrder: order, createdAt: epoch, lastPrayed: prayed.map { today.adding(days: -$0) })
    }

    static func intention(_ id: String, _ parent: String, _ text: String, order: Int, carried: Bool = true,
                          prayed: Int? = nil, answered: Bool = false) -> Subject {
        Subject(id: id, kind: .intention, parentId: parent, publicName: text, isCarried: carried,
                sortOrder: order, resolution: answered ? .answered : nil, resolvedAt: answered ? epoch : nil,
                createdAt: epoch, lastPrayed: prayed.map { today.adding(days: -$0) })
    }

    static let subjects: [Subject] = [
        name("dad", "Gary Olson", order: 1, alias: "Dad", prayed: 0),
        intention("dad-2", "dad", "Rest for his heart", order: 2, carried: false),
        intention("dad-1", "dad", "Healing after his surgery", order: 1, prayed: 0),
        name("self", "Eric Olson", order: 0, alias: "Me", isSelf: true, prayed: 1),
        intention("self-1", "self", "Patience with the new job", order: 1),
        name("mom", "Margaret Olson", order: 2, alias: "Mom", prayed: 2),
        intention("mom-1", "mom", "A safe delivery for Ruth", order: 1, answered: true),
        name("bea", "Beatrice Moreno", order: 3, alias: "Aunt Bea", carried: false),
        intention("bea-1", "bea", "Her new home", order: 1),
    ]

    static let tree = SubjectTree(subjects)
}
