import XCTest

/// First run on the mock (`-PPMockFresh`: no self name, no people;
/// auth-onboarding.md, "Flow (redesigned 2026-11-09, second pass)"): one
/// stage, name → the moment → someone → their intention → Home. No
/// screenshots: the checks are the accessibility tree.
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

    /// Step 1 → Continue → the moment (the name on the paper line, the
    /// mechanic).
    private func throughTheName(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(any(app, "label == 'Here, we pray for each other.'").waitForExistence(timeout: 10),
                      "step 1", file: file, line: line)
        XCTAssertTrue(any(app, "label == 'What’s your name?'").exists, file: file, line: line)
        XCTAssertFalse(any(app, "label CONTAINS 'Sign in'").exists, "no Sign in until sign-in exists",
                       file: file, line: line)
        XCTAssertFalse(app.buttons["onboarding.back"].exists, "no ‹ on the first step", file: file, line: line)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "no keyboard on arrival", file: file, line: line)
        let next = app.buttons["onboarding.name.continue"]
        XCTAssertTrue(next.exists, file: file, line: line)
        XCTAssertFalse(next.isEnabled, "unlit while empty", file: file, line: line)
        let field = app.textFields["onboarding.name.field"]
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "the field raises it",
                      file: file, line: line)
        field.typeText("Eric Olson")
        XCTAssertTrue(next.isEnabled, file: file, line: line)
        next.tap()

        XCTAssertTrue(any(app, "label == 'Pray with today’s list. Tomorrow your name is on it.'")
            .waitForExistence(timeout: 8), "the moment", file: file, line: line)
        XCTAssertTrue(any(app, "label == 'The list is printed and sealed each day, and kept private.'").exists,
                      file: file, line: line)
        XCTAssertTrue(any(app, "label == 'Eric Olson'").exists, "the name on the paper line", file: file, line: line)
        XCTAssertTrue(app.buttons["onboarding.back"].exists, file: file, line: line)
    }

    /// The moment → Continue → someone you pray for.
    private func toSomeone(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        app.buttons["onboarding.moment.continue"].tap()
        XCTAssertTrue(any(app, "label == 'Who do you pray for?'").waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(app.textFields["onboarding.someone.name"].waitForExistence(timeout: 3), file: file, line: line)
    }

    /// Name → the moment → someone (Julie Olson, "Mom") → her intention →
    /// Add → Home with Me, Mom (carried) and the intention; the pray button.
    @MainActor
    func testFullFlow() throws {
        let app = launch()
        throughTheName(app)
        toSomeone(app)

        XCTAssertTrue(any(app, "label == 'Printed on the list'").exists)
        XCTAssertTrue(any(app, "label == 'Only you see this'").exists)
        XCTAssertTrue(app.buttons["onboarding.notNow"].exists, "Not now, top trailing")
        let next = app.buttons["onboarding.someone.continue"]
        XCTAssertFalse(next.isEnabled, "a name is required")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "the name field is focused")
        app.textFields["onboarding.someone.name"].typeText("Julie Olson")
        let alias = app.textFields["onboarding.someone.alias"]
        alias.tap()
        alias.typeText("Mom")
        XCTAssertTrue(next.isEnabled)
        next.tap()

        XCTAssertTrue(any(app, "label == 'What are you praying for, for Mom?'").waitForExistence(timeout: 5))
        XCTAssertTrue(any(app, "label BEGINSWITH 'Carried on the list with you.'").exists)
        XCTAssertTrue(any(app, "label == 'Mom'").exists, "only her, by what you call her")
        XCTAssertTrue(app.buttons["onboarding.skip"].exists, "Skip, top trailing")
        let field = app.textFields["onboarding.intention.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.typeText("Healing after surgery")
        app.buttons["onboarding.intention.add"].tap()

        XCTAssertTrue(any(app, "label BEGINSWITH 'Me, Eric Olson'").waitForExistence(timeout: 8), "Home, with Me")
        XCTAssertTrue(any(app, "label BEGINSWITH 'Mom, Julie Olson'").exists, "Mom on Home")
        XCTAssertTrue(any(app, "label CONTAINS 'Mom, Julie Olson, carried'").exists, "carried")
        XCTAssertTrue(any(app, "label BEGINSWITH 'Healing after surgery'").exists, "her intention")
        let pray = app.buttons["Pray"]
        XCTAssertTrue(pray.waitForExistence(timeout: 5))
        let landed = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: pray)
        wait(for: [landed], timeout: 5) // the pray button arrives last
        XCTAssertFalse(app.buttons["onboarding.intention.add"].exists, "onboarding has gone")
        XCTAssertFalse(app.buttons["home.selfIntention.add"].exists, "not before the first prayer")
    }

    /// ‹ Back keeps the name; the person step's Not now → Home with only
    /// Me. After the first prayer, the line under Me ("Add an intention for
    /// yourself") shows, and × hides it.
    @MainActor
    func testBackThenNotNowThenTheLineUnderMe() throws {
        let app = launch()
        throughTheName(app)
        app.buttons["onboarding.back"].tap()
        let field = app.textFields["onboarding.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "back on step 1")
        XCTAssertEqual(field.value as? String, "Eric Olson", "the name is kept")
        app.buttons["onboarding.name.continue"].tap()
        XCTAssertTrue(any(app, "label == 'Pray with today’s list. Tomorrow your name is on it.'")
            .waitForExistence(timeout: 8), "the moment again")
        toSomeone(app)
        app.buttons["onboarding.notNow"].tap()

        XCTAssertTrue(any(app, "label BEGINSWITH 'Me, Eric Olson'").waitForExistence(timeout: 8), "Home, with Me")
        let pray = app.buttons["Pray"]
        XCTAssertTrue(pray.waitForExistence(timeout: 5))
        XCTAssertFalse(any(app, "label == 'Who do you pray for?'").exists)
        XCTAssertFalse(app.buttons["home.selfIntention.add"].exists, "not before the first prayer")

        // The first prayer, through the invitation, then Done.
        sleep(2) // the hand-off settles
        pray.tap()
        sleep(6)
        app.buttons["Amen"].firstMatch.tap()
        let hold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hold the'")).firstMatch
        XCTAssertTrue(hold.waitForExistence(timeout: 3), "the invitation")
        hold.tap()
        sleep(6)
        let amens = app.buttons.matching(NSPredicate(format: "label == 'Amen'")).allElementsBoundByIndex
        (amens.first { $0.isEnabled && $0.isHittable } ?? amens[0]).tap()
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "the closing sheet")
        done.tap()

        let line = app.buttons["home.selfIntention.add"]
        XCTAssertTrue(line.waitForExistence(timeout: 5), "the line under Me after the first prayer")
        XCTAssertTrue(any(app, "label CONTAINS 'Add an intention for yourself'").exists)
        app.buttons["home.selfIntention.dismiss"].tap()
        XCTAssertTrue(line.waitForNonExistence(timeout: 3), "dismissed")
    }

    /// The largest accessibility text size: every step's buttons stay on
    /// screen and tappable (the content scrolls, never clips).
    @MainActor
    func testLargestTextSize() throws {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let window = app.windows.firstMatch

        func onScreen(_ element: XCUIElement, _ what: String) {
            XCTAssertTrue(element.waitForExistence(timeout: 5), what)
            XCTAssertTrue(element.isHittable, "\(what) is tappable")
            XCTAssertTrue(window.frame.contains(element.frame), "\(what) fits on screen")
        }

        let field = app.textFields["onboarding.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        onScreen(app.buttons["onboarding.name.continue"], "Continue")
        field.tap()
        field.typeText("Eric Olson")
        onScreen(app.buttons["onboarding.name.continue"], "Continue above the keyboard")
        app.buttons["onboarding.name.continue"].tap()

        onScreen(app.buttons["onboarding.moment.continue"], "the moment's Continue")
        onScreen(app.buttons["onboarding.back"], "‹ Back")
        app.buttons["onboarding.moment.continue"].tap()

        let name = app.textFields["onboarding.someone.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        onScreen(app.buttons["onboarding.notNow"], "Not now")
        name.typeText("Julie Olson")
        onScreen(app.buttons["onboarding.someone.continue"], "Continue")
        app.buttons["onboarding.someone.continue"].tap()

        XCTAssertTrue(app.textFields["onboarding.intention.field"].waitForExistence(timeout: 5))
        onScreen(app.buttons["onboarding.intention.add"], "Add")
        onScreen(app.buttons["onboarding.skip"], "Skip")
        onScreen(app.buttons["onboarding.back"], "‹ Back")
        app.buttons["onboarding.skip"].tap()

        XCTAssertTrue(any(app, "label BEGINSWITH 'Julie Olson'").waitForExistence(timeout: 8), "Home")
    }
}
