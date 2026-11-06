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
        sleep(6)
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

    /// + → a name (the keyboard stays up across tabs) → Add → the offer
    /// (pushed in, keyboard still up) → an intention → Add → on Home.
    @MainActor
    func testAddANameWithAnIntention() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        app.buttons["Add"].firstMatch.tap()
        let name = app.textFields["Their name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Name is focused on open")
        app.typeText("Gary Olson")
        sleep(1)
        attach(app, "add 1 name")

        // Switch tabs: the keyboard never goes down.
        app.segmentedControls.buttons["Intention"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up on Intention")
        sleep(1)
        attach(app, "add 2 intention tab")
        app.segmentedControls.buttons["Name"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up back on Name")

        app.textFields["e.g. Dad"].tap()
        app.typeText("Dad")
        attach(app, "add 3 alias")
        app.navigationBars.buttons["Add"].tap()

        let offer = app.staticTexts["Dad is on your list."]
        XCTAssertTrue(offer.waitForExistence(timeout: 3), "the offer step")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up into the offer")
        sleep(1)
        attach(app, "add 4 offer")
        app.typeText("Healing after surgery")
        app.navigationBars.buttons["Add"].tap()

        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad, Gary Olson'"))
        XCTAssertTrue(row.firstMatch.waitForExistence(timeout: 3), "the new name on Home")
        sleep(1)
        attach(app, "add 5 home")
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
