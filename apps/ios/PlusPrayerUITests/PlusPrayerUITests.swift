import XCTest

/// Smoke flows on the mock (apps/ios/CLAUDE.md, "Tests"). Screenshots are
/// attached to the result bundle for a look at the real sheets.
final class PlusPrayerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Pray → Amen without the list → the invitation → hold the list → Amen
    /// → the closing sheet → Done → the card says they'll be on List 53.
    @MainActor
    func testPrayThroughTheInvitation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        app.buttons["Pray"].tap()
        usleep(1_500_000)
        attach(app, "0 counting down")
        sleep(5)
        app.buttons["Amen"].firstMatch.tap()

        let hold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hold the'")).firstMatch
        XCTAssertTrue(hold.waitForExistence(timeout: 3), "the invitation opens")
        sleep(1)
        attach(app, "1 invitation")

        hold.tap()
        sleep(2)
        attach(app, "2 holding")
        sleep(4)
        enabledAmen(app).tap()

        let carried = app.staticTexts["You’ll be carried on List\u{00a0}53."]
        let carriedPlain = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'carried on List'")).firstMatch
        XCTAssertTrue(carried.waitForExistence(timeout: 3) || carriedPlain.exists, "the closing sheet")
        sleep(1)
        attach(app, "3 closing")

        app.buttons["Add a note"].tap()
        sleep(1)
        attach(app, "4 note")
        app.typeText("A quiet morning.")
        app.buttons["Save"].tap()

        let covered = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'on List\u{00a0}53' OR label CONTAINS 'on List 53'")).firstMatch
        XCTAssertTrue(covered.waitForExistence(timeout: 3), "the card's status line")
        sleep(1)
        attach(app, "5 home after")
    }

    /// + → a name (the keyboard stays up across tabs) → the For push (search
    /// inactive, keyboard down) and a pick (the intention refocused) → Add →
    /// the offer, titled "Added" under Dad's row (pushed in, keyboard still
    /// up) → an intention → Add → on Home.
    @MainActor
    func testAddANameWithAnIntention() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        app.buttons["Add"].firstMatch.tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Name is focused on open")
        XCTAssertTrue(app.switches["Carry onto the list"].firstMatch.exists, "the carry row")
        XCTAssertTrue(app.navigationBars.buttons["Cancel"].exists, "the glass X, read as Cancel")
        app.typeText("Gary Olson")
        sleep(1)
        attach(app, "add 1 name")

        // Switch tabs: the keyboard never goes down.
        app.segmentedControls.buttons["Intention"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up on Intention")
        sleep(1)
        attach(app, "add 2 intention tab")

        // The For row pushes "Who is this for?"; picking comes back.
        app.buttons["For"].tap()
        // The native bar, its title and back visible: the search starts inactive.
        let chooser = app.navigationBars["Who is this for?"]
        XCTAssertTrue(chooser.waitForExistence(timeout: 2), "the pushed list")
        XCTAssertTrue(chooser.staticTexts["Who is this for?"].exists, "the title shows")
        XCTAssertTrue(chooser.buttons.element(boundBy: 0).exists, "back shows")
        XCTAssertTrue(app.searchFields.firstMatch.exists, "its native search")
        let keyboardDown = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.firstMatch)
        wait(for: [keyboardDown], timeout: 2)
        sleep(1)
        attach(app, "add 3a who is this for")
        app.searchFields.firstMatch.tap()
        app.typeText("mo")
        sleep(1)
        attach(app, "add 3 who is this for")
        app.buttons["addSheet.for.mom"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "the intention is refocused after the pick")
        XCTAssertEqual(app.buttons["For"].value as? String, "Mom")
        XCTAssertFalse(app.navigationBars.buttons["BackButton"].exists, "back on the form, nothing pushed")

        // Back without a pick refocuses it too.
        app.buttons["For"].tap()
        XCTAssertTrue(chooser.waitForExistence(timeout: 2))
        chooser.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "the intention is refocused after back")
        XCTAssertEqual(app.buttons["For"].value as? String, "Mom", "back keeps the person")

        app.segmentedControls.buttons["Name"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up back on Name")

        app.textFields["What you call them · optional"].tap()
        app.typeText("Dad")
        attach(app, "add 4 alias")
        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.navigationBars["Added"].waitForExistence(timeout: 3), "the offer step, titled Added")
        XCTAssertTrue(app.staticTexts["Dad"].exists, "under the person's row")
        XCTAssertTrue(app.navigationBars.buttons["Skip"].exists, "Skip, not back: the name is saved")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up into the offer")
        sleep(1)
        attach(app, "add 5 offer")
        app.typeText("Healing after surgery")
        app.navigationBars.buttons["Add"].tap()

        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad, Gary Olson'"))
        XCTAssertTrue(row.firstMatch.waitForExistence(timeout: 3), "the new name on Home")
        sleep(1)
        attach(app, "add 6 home")
    }

    /// Long-press Dad → "Add intention" → the intention form for him (X /
    /// Add, keyboard up) → Add → on Home under Dad.
    @MainActor
    func testAddAnIntentionFromANameRow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad, Gary Olson'"))
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 3))
        dad.firstMatch.press(forDuration: 1)
        let menuItem = app.buttons["Add intention"]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 2), "the row's context menu")
        attach(app, "row 1 menu")
        menuItem.tap()

        XCTAssertTrue(app.staticTexts["Dad"].waitForExistence(timeout: 3), "the person's row")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "the intention is focused")
        XCTAssertTrue(app.navigationBars.buttons["Cancel"].exists, "X, not Skip")
        XCTAssertFalse(app.buttons["For"].exists, "no For row: the person is given")
        app.typeText("Strength for the week")
        sleep(1)
        attach(app, "row 2 intention form")
        app.navigationBars.buttons["Add"].tap()

        let added = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Strength for the week'"))
        XCTAssertTrue(added.firstMatch.waitForExistence(timeout: 3), "the intention on Home")
        attach(app, "row 3 home")
    }

    /// 🔎 → the row docks above the keyboard with the compact pray button →
    /// results → no matches → under Still to hold, "Show →" widens to All →
    /// × closes it.
    @MainActor
    func testSearch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        app.buttons["Search"].firstMatch.tap()
        let field = app.textFields["Search"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "the field is focused")
        sleep(1)
        attach(app, "search 0 open")
        XCTAssertFalse(app.buttons["History"].exists, "the pill is the search field")
        XCTAssertTrue(app.buttons["Pray"].exists, "the pray button stays beside it")

        app.typeText("dad")
        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad, Gary Olson'"))
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 2))
        sleep(1)
        attach(app, "search 1 dad")

        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "zzz")
        let none = app.descendants(matching: .any)["No matches for “zzz”"]
        XCTAssertTrue(none.waitForExistence(timeout: 3), "after typing pauses")
        attach(app, "search 2 no matches")

        // Lower the keyboard: the field stays (full height) with its results.
        app.keyboards.buttons["search"].tap()
        sleep(1)
        attach(app, "search 2b keyboard down")
        XCTAssertTrue(field.exists)
        XCTAssertFalse(app.buttons["History"].exists)

        // Still to hold hides a held match; the hint widens to All.
        app.buttons["Filter"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Still to hold'")).firstMatch.tap()
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "surgery")
        let hint = app.buttons["Show 1 match in All"]
        XCTAssertTrue(hint.waitForExistence(timeout: 3))
        sleep(1)
        attach(app, "search 3 match hint")
        hint.tap()
        let healing = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Healing after his surgery'"))
        XCTAssertTrue(healing.firstMatch.waitForExistence(timeout: 2))

        app.buttons["Close search"].tap()
        XCTAssertFalse(field.waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["History"].exists)
    }

    private func enabledAmen(_ app: XCUIApplication) -> XCUIElement {
        let amens = app.buttons.matching(NSPredicate(format: "label == 'Amen'")).allElementsBoundByIndex
        return amens.first { $0.isEnabled && $0.isHittable } ?? amens[0]
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
