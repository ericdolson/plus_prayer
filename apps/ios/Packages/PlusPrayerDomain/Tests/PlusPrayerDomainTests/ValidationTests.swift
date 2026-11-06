import Testing
@testable import PlusPrayerDomain

struct NoteTests {
    @Test func blankIsNoNote() {
        #expect(cleanNote("  \n ") == nil)
    }

    @Test func trimmed() {
        #expect(cleanNote("  A quiet morning.\n") == "A quiet morning.")
    }

    @Test func cutAtTheCapByGrapheme() {
        let long = String(repeating: "🙏🏽", count: TextCap.note + 5)
        #expect(cleanNote(long)?.count == TextCap.note)
    }
}
