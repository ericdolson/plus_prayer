import Testing
@testable import PlusPrayerDomain

struct AvatarToneTests {
    /// Expected values computed by the Flutter build's Dart implementation,
    /// so the platforms agree on every person's color.
    @Test(arguments: [
        ("", 5),
        ("a", 12),
        ("3f2b8c1e-9d4a-4f6b-8e2a-1c5d7e9f0a3b", 9),
        ("00000000-0000-0000-0000-000000000000", 1),
        ("self-eric", 9),
        ("Zoë 🙏", 5),
    ])
    func matchesFlutter(id: String, tone: Int) {
        #expect(defaultAvatarTone(id: id) == tone)
    }

    @Test func staysInPalette() {
        for i in 0..<500 {
            #expect((0..<avatarToneCount).contains(defaultAvatarTone(id: "subject-\(i)")))
        }
    }
}

struct InitialsTests {
    @Test(arguments: [
        ("Dad", "D"),
        ("Daniel Kim", "DK"),
        ("eric  david olson", "EO"),
        ("  ", ""),
        ("Zoë Ørsted", "ZØ"),
        ("🙏 Group", "🙏G"),
    ])
    func initialsOf(name: String, expected: String) {
        #expect(initials(name) == expected)
    }
}

struct MonogramTests {
    @Test func yoursFromYourNameOthersFromWhatYouCallThem() {
        #expect(monogram(Fixture.tree["self"]!) == "EO")
        #expect(monogram(Fixture.tree["dad"]!) == "D")
        #expect(monogram(Fixture.tree["bea"]!) == "AB")
        #expect(monogram(Fixture.name("p", "Our parish", order: 0)) == "OP")
    }
}
