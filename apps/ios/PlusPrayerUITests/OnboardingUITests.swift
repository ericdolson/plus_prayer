import XCTest

/// First run on the mock (`-PPMockFresh`: no self name, no people;
/// auth-onboarding.md, "Flow (revised 2026-11-09)"). No screenshots: the
/// checks are the accessibility tree.
final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock", "-PPMockFresh"] + extra
        app.launch()
        return app
    }

    private func any(_ app: XCUIApplication, _ format: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: format)).firstMatch
    }

    /// Welcome → Begin → the name → Continue → Welcome back.
    private func throughTheName(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let begin = app.buttons["onboarding.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 10), "Welcome", file: file, line: line)
        XCTAssertTrue(any(app, "label == 'Your name, carried by the world.'").exists, file: file, line: line)
        XCTAssertTrue(any(app, "label == 'One list. Everyone. Every day.'").exists, file: file, line: line)
        XCTAssertFalse(any(app, "label CONTAINS 'Sign in'").exists, "no sign-in link until sign-in exists",
                       file: file, line: line)
        begin.tap()

        XCTAssertTrue(any(app, "label == 'What’s your name?'").waitForExistence(timeout: 5), file: file, line: line)
        let field = app.textFields["onboarding.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3), file: file, line: line)
        let next = app.buttons["onboarding.name.continue"]
        XCTAssertFalse(next.isEnabled, "disabled while empty", file: file, line: line)
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.exists, "‹ back to Welcome", file: file, line: line)
        field.tap()
        field.typeText("Eric Olson")
        XCTAssertTrue(next.isEnabled, file: file, line: line)
        next.tap()

        XCTAssertTrue(any(app, "label == 'Welcome, Eric Olson.'").waitForExistence(timeout: 5), "Welcome back",
                      file: file, line: line)
        XCTAssertTrue(any(app, "label == 'Who else do you hold?'").exists, file: file, line: line)
        XCTAssertTrue(any(app, "label BEGINSWITH 'The list is printed, sealed and kept private.'").exists,
                      file: file, line: line)
        XCTAssertFalse(app.descendants(matching: .any)["onboarding.added"].exists, "no row before the first add",
                       file: file, line: line)
    }

    /// Begin → name → Welcome back → Add someone → Julie Olson, "Mom" →
    /// Continue → an intention → Add → Welcome back with Mom's avatar →
    /// Continue → Home with Me, Mom and her intention.
    @MainActor
    func testGuidedFirstAdd() throws {
        let app = launch()
        throughTheName(app)
        XCTAssertTrue(app.buttons["onboarding.back.later"].exists, "Add others later")
        app.buttons["onboarding.back.add"].tap()

        XCTAssertTrue(any(app, "label == 'Who’s someone you pray for?'").waitForExistence(timeout: 5))
        XCTAssertTrue(any(app, "label == 'Printed on the list'").exists)
        XCTAssertTrue(any(app, "label == 'Only you see this'").exists)
        let next = app.buttons["onboarding.someone.continue"]
        XCTAssertFalse(next.isEnabled, "a name is required")
        let name = app.textFields["onboarding.someone.name"]
        name.tap()
        name.typeText("Julie Olson")
        let alias = app.textFields["onboarding.someone.alias"]
        alias.tap()
        alias.typeText("Mom")
        XCTAssertTrue(any(app, "label == 'Mom will be carried on the list with you.'").waitForExistence(timeout: 3))
        next.tap()

        XCTAssertTrue(any(app, "label == 'What are you praying for, for Mom?'").waitForExistence(timeout: 5))
        let field = app.textFields["onboarding.intention.field"]
        field.tap()
        field.typeText("Healing after surgery")
        app.buttons["onboarding.intention.add"].tap()

        let row = app.descendants(matching: .any)["onboarding.added"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "back on Welcome back, with the row")
        XCTAssertEqual(row.label, "Added: Mom", "only the people added, never you")
        XCTAssertTrue(app.buttons["onboarding.back.add"].label.contains("Add another"))
        app.buttons["onboarding.back.continue"].tap()

        XCTAssertTrue(any(app, "label BEGINSWITH 'Me, Eric Olson'").waitForExistence(timeout: 5), "Home, with Me")
        XCTAssertTrue(any(app, "label BEGINSWITH 'Mom, Julie Olson'").exists, "Mom on Home")
        XCTAssertTrue(any(app, "label CONTAINS 'Mom, Julie Olson, carried'").exists, "carried")
        XCTAssertTrue(any(app, "label BEGINSWITH 'Healing after surgery'").exists, "her intention")
        XCTAssertFalse(app.buttons["onboarding.begin"].exists)
    }

    /// Begin → name → Add others later → Home.
    @MainActor
    func testAddOthersLater() throws {
        let app = launch()
        throughTheName(app)
        app.buttons["onboarding.back.later"].tap()
        XCTAssertTrue(any(app, "label BEGINSWITH 'Me, Eric Olson'").waitForExistence(timeout: 5), "Home, with Me")
        XCTAssertTrue(app.buttons["Pray"].exists)
        XCTAssertFalse(any(app, "label == 'Who else do you hold?'").exists)
    }

    /// The largest accessibility text size: every screen's question and its
    /// buttons stay on screen and tappable (layouts scroll, never clip).
    @MainActor
    func testLargestTextSize() throws {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let window = app.windows.firstMatch

        func onScreen(_ element: XCUIElement, _ what: String) {
            XCTAssertTrue(element.waitForExistence(timeout: 5), what)
            XCTAssertTrue(element.isHittable, "\(what) is tappable")
            XCTAssertTrue(window.frame.contains(element.frame), "\(what) fits on screen")
        }

        onScreen(app.buttons["onboarding.begin"], "Begin")
        app.buttons["onboarding.begin"].tap()
        let field = app.textFields["onboarding.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Eric Olson")
        onScreen(app.buttons["onboarding.name.continue"], "Continue above the keyboard")
        app.buttons["onboarding.name.continue"].tap()

        XCTAssertTrue(any(app, "label == 'Welcome, Eric Olson.'").waitForExistence(timeout: 5))
        onScreen(app.buttons["onboarding.back.add"], "Add someone")
        onScreen(app.buttons["onboarding.back.later"], "Add others later")
        app.buttons["onboarding.back.add"].tap()

        let name = app.textFields["onboarding.someone.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Julie Olson")
        onScreen(app.buttons["onboarding.someone.continue"], "Continue")
        app.buttons["onboarding.someone.continue"].tap()

        XCTAssertTrue(app.textFields["onboarding.intention.field"].waitForExistence(timeout: 5))
        onScreen(app.buttons["onboarding.intention.add"], "Add")
        onScreen(app.buttons["onboarding.intention.skip"], "Skip")
        app.buttons["onboarding.intention.skip"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["onboarding.added"].waitForExistence(timeout: 5))
        onScreen(app.buttons["onboarding.back.continue"], "Continue")
        app.buttons["onboarding.back.continue"].tap()
        XCTAssertTrue(any(app, "label BEGINSWITH 'Julie Olson'").waitForExistence(timeout: 5), "Home")
    }
}
