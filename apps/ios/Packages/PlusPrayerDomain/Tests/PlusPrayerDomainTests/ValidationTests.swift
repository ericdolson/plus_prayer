import Testing
@testable import PlusPrayerDomain

// The same BLOCKED / ALLOWED lists as backend/functions/test/contact.test.ts
// and the Flutter build's validation_test.dart, so all three agree.

let blocked = [
    "Call 555-123-4567", "555 1234", "(555) 123-4567", "555.123.4567", "+44 20 7946 0958",
    "Text me 5551234567", "Ana 0917 123 4567", "jane@example.com", "Write to jane.doe@mail.co.uk",
    "www.example.com", "example.com", "visit example.org/pray", "https://x.org/a", "See PrayForAna.net",
]

let allowed = [
    "John 3:16", "Psalm 23", "Isaiah 41:10-13", "Romans 8:28-39", "Mark 10:45 and Psalm 91", "Room 412",
    "Rm 1203, Bed 4", "Ward 7B", "Apt 12, Unit 5", "Flight 1234", "10/18/2026", "2026-10-18", "18.10.26",
    "Oct 18, 2026", "Jan 3 2026 surgery at 9", "Gary Olson 1945-2023", "Gary Olson (1945–2023)", "St. Jude",
    "St. Mary's Hospital", "Dr. Kim", "e.g. healing", "Mom (age 84)",
]

struct ContactDetectionTests {
    @Test(arguments: blocked) func blocks(_ text: String) {
        #expect(hasContactInfo(text))
    }

    @Test(arguments: allowed) func allows(_ text: String) {
        #expect(!hasContactInfo(text))
    }
}

struct PrintedTextTests {
    @Test func contactInfoIsBlockedInBoth() {
        #expect(validatePrinted("Ana 555-123-4567", kind: .soul) == .contactInfo)
        #expect(validatePrinted("Donate at example.org", kind: .intention) == .contactInfo)
    }

    @Test func verseReferencesYearsRoomsAndSaintsSave() {
        #expect(validatePrinted("Strength — Isaiah 41:10", kind: .intention) == nil)
        #expect(validatePrinted("Gary Olson 1945-2023", kind: .soul) == nil)
        #expect(validatePrinted("St. Jude Room 412", kind: .soul) == nil)
    }

    @Test func emptyOrWhitespaceOnly() {
        #expect(validatePrinted("", kind: .soul) == .empty)
        #expect(validatePrinted("  \n\t ", kind: .intention) == .empty)
    }

    @Test func capsFortyForANameEightyForAnIntention() {
        #expect(validatePrinted(String(repeating: "a", count: 40), kind: .soul) == nil)
        #expect(validatePrinted(String(repeating: "a", count: 41), kind: .soul) == .tooLong(cap: 40))
        #expect(validatePrinted(String(repeating: "a", count: 80), kind: .intention) == nil)
        #expect(validatePrinted(String(repeating: "a", count: 81), kind: .intention) == .tooLong(cap: 80))
    }

    @Test func capsCountVisibleCharacters() {
        #expect(validatePrinted(String(repeating: "👨‍👩‍👧", count: 40), kind: .soul) == nil)
        #expect(validatePrinted(String(repeating: "é", count: 41), kind: .soul) == .tooLong(cap: 40))
        #expect("नमस्ते".count == 3)
        #expect(validatePrinted(String(repeating: "王", count: 40), kind: .soul) == nil)
    }

    @Test func whitespaceRunsCollapseBeforeCounting() {
        #expect(cleanText("  Gary \n  Olson  ") == "Gary Olson")
        #expect(validatePrinted(String(repeating: "a", count: 20) + "     " + String(repeating: "b", count: 19),
                                kind: .soul) == nil)
    }
}

struct AliasTests {
    @Test func neverCheckedForContactInfo() {
        #expect(validateAlias("Ana 555-123-4567") == nil)
        #expect(validateAlias("Bea www.bea.com") == nil)
    }

    @Test func optionalAndCappedAtForty() {
        #expect(validateAlias(nil) == nil)
        #expect(validateAlias("") == nil)
        #expect(validateAlias(String(repeating: "d", count: 40)) == nil)
        #expect(validateAlias(String(repeating: "d", count: 41)) == .tooLong(cap: 40))
    }
}

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
