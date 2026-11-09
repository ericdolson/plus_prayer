import XCTest

/// The app on the real repositories against the local emulators
/// (backend/CLAUDE.md, "Test on your phone with the emulators"). Skipped
/// unless the runner sets `PP_EMULATOR_SMOKE=1` (`TEST_RUNNER_PP_EMULATOR_SMOKE=1`
/// on the xcodebuild command line), so the UI tests stay on the mock. Run in
/// order, with the backend steps between them:
///
///   1. `npm run emulators` (empty), then `testNameStepOnFirstRun`;
///   2. `npm run seed:emulator` (the uid that test signed in with), then
///      `testSeededHomePageHistoryAndPrayer`;
///   3. after a restore (`npm run emulators:seeded`), `testRestoredSnapshot`.
///
/// No screenshots: the checks are the accessibility tree.
final class EmulatorSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(ProcessInfo.processInfo.environment["PP_EMULATOR_SMOKE"] == "1",
                          "Emulator smoke tests run only against running emulators (PP_EMULATOR_SMOKE=1)")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "emulator", "-PPEmulatorHost", "127.0.0.1"]
        app.launch()
        return app
    }

    private func any(_ app: XCUIApplication, _ format: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: format)).firstMatch
    }

    /// A new anonymous account has no self name: onboarding over Home
    /// ("Here, we pray for each other." · "What's your name?"); Continue
    /// calls setSelfName and plays the moment (the name on the paper line);
    /// then Not now on the person step → Home with "Me".
    @MainActor
    func testNameStepOnFirstRun() throws {
        let app = launch()
        let field = app.textFields["onboarding.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 20), "onboarding for an account with no self name")
        XCTAssertTrue(any(app, "label == 'What’s your name?'").exists, "the name step")
        XCTAssertFalse(app.buttons["onboarding.name.continue"].isEnabled, "nothing to save yet")
        field.tap()
        field.typeText("Eric Olson")
        app.buttons["onboarding.name.continue"].tap()

        XCTAssertTrue(any(app, "label BEGINSWITH 'Pray with today’s list.'")
            .waitForExistence(timeout: 15), "the moment")
        XCTAssertTrue(any(app, "label == 'Eric Olson'").exists, "the full name on the paper line")
        app.buttons["onboarding.moment.continue"].tap()
        let notNow = app.buttons["onboarding.notNow"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5), "someone you pray for")
        notNow.tap()
        XCTAssertTrue(any(app, "label BEGINSWITH 'Me, Eric Olson'").waitForExistence(timeout: 15), "Home, with Me")
        XCTAssertTrue(app.buttons["Pray"].waitForExistence(timeout: 5))
    }

    /// After `seed:emulator`: Home (the seeded people, List 70), Dad's page
    /// (History tiles from the new query), the History screen (Lists), and a
    /// full prayer holding Dad: Pray → Amen → the invitation → hold the list → Amen → the
    /// closing sheet → a journal entry → the card says List 71.
    @MainActor
    func testSeededHomePageHistoryAndPrayer() throws {
        let app = launch()
        let dad = any(app, "label BEGINSWITH 'Dad, Gary Olson'")
        XCTAssertTrue(dad.waitForExistence(timeout: 20), "Dad on Home")
        for person in ["Mom, Margaret Olson", "Daniel Kim", "Our parish", "Ukraine", "Aunt Bea, Beatrice Moreno", "Lena Park"] {
            XCTAssertTrue(any(app, "label BEGINSWITH '\(person)'").exists, "\(person) on Home")
        }
        XCTAssertTrue(any(app, "label CONTAINS 'List\u{00a0}70' OR label CONTAINS 'List 70'").waitForExistence(timeout: 10),
                      "the card shows today's list")
        XCTAssertTrue(any(app, "label CONTAINS 'Answered'").exists, "Mom's answered intention")

        // Dad's page: the carry card and History from the real reads.
        dad.tap()
        XCTAssertTrue(app.switches["Carry onto the list"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.switches["Carry onto the list"].firstMatch.value as? String, "1", "Dad is carried")
        let prayersTile = app.buttons["page.history.tile.held"]
        let listsTile = app.buttons["page.history.tile.lists"]
        XCTAssertTrue(prayersTile.waitForExistence(timeout: 10), "the your-prayers tile")
        XCTAssertGreaterThanOrEqual(leadingNumber(prayersTile.label) ?? 0, 30, "Dad near-daily: \(prayersTile.label)")
        XCTAssertTrue(listsTile.exists, "the lists tile (getMyListEntries)")
        XCTAssertGreaterThanOrEqual(leadingNumber(listsTile.label) ?? 0, 40, "Dad on most lists: \(listsTile.label)")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // History, everyone: the Lists tab lists the lists you were on.
        XCTAssertTrue(dad.waitForExistence(timeout: 5))
        app.buttons["History"].tap()
        let lists = app.segmentedControls.buttons["Lists"]
        XCTAssertTrue(lists.waitForExistence(timeout: 10))
        lists.tap()
        XCTAssertTrue(any(app, "label CONTAINS 'List\u{00a0}70' OR label CONTAINS 'List 70'").waitForExistence(timeout: 5),
                      "today's list in History")
        XCTAssertTrue(any(app, "label CONTAINS 'List\u{00a0}69' OR label CONTAINS 'List 69'").exists, "yesterday's")
        app.segmentedControls.buttons["Journal"].tap()
        XCTAssertTrue(any(app, "label CONTAINS 'Ruth’s baby is here' OR label CONTAINS \"Ruth's baby is here\"")
            .waitForExistence(timeout: 5), "the journal entry on the answered day")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Pray → Amen → the invitation → hold the list → Amen → closing.
        XCTAssertTrue(app.buttons["Pray"].waitForExistence(timeout: 5))
        app.buttons["Pray"].tap()
        // Mid-prayer a row checks: hold Dad.
        XCTAssertTrue(dad.waitForExistence(timeout: 3))
        dad.tap()
        sleep(6)
        app.buttons["Amen"].firstMatch.tap()
        let hold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hold the'")).firstMatch
        XCTAssertTrue(hold.waitForExistence(timeout: 5), "the invitation opens")
        hold.tap()
        sleep(6)
        enabledAmen(app).tap()
        XCTAssertTrue(any(app, "label CONTAINS 'carried on List'").waitForExistence(timeout: 5), "the closing sheet")
        XCTAssertTrue(any(app, "label CONTAINS '71'").exists, "the next list is 71")
        app.buttons["Add to journal"].tap()
        sleep(1)
        app.typeText("Emulator smoke test.")
        app.buttons["Save"].tap()
        XCTAssertTrue(any(app, "label CONTAINS 'on List\u{00a0}71' OR label CONTAINS 'on List 71'").waitForExistence(timeout: 10),
                      "the card: carried onto List 71")
        // Long enough for the queue to send and the sweeper to apply it.
        sleep(8)
    }

    /// After a restore from the snapshot: the same account (the anonymous
    /// user survived), its seeded data, and nothing from before the restore.
    @MainActor
    func testRestoredSnapshot() throws {
        let app = launch()
        XCTAssertTrue(any(app, "label BEGINSWITH 'Dad, Gary Olson'").waitForExistence(timeout: 20), "the seeded account")
        XCTAssertFalse(any(app, "label == 'What’s your name?'").exists, "not a new account")
        XCTAssertFalse(any(app, "label CONTAINS 'on List\u{00a0}71' OR label CONTAINS 'on List 71'").waitForExistence(timeout: 5),
                       "the prayer from before the restore is gone")
    }

    private func leadingNumber(_ label: String) -> Int? {
        Int(label.prefix { $0.isNumber || $0 == "," }.replacingOccurrences(of: ",", with: ""))
    }

    private func enabledAmen(_ app: XCUIApplication) -> XCUIElement {
        let amens = app.buttons.matching(NSPredicate(format: "label == 'Amen'")).allElementsBoundByIndex
        return amens.first { $0.isEnabled && $0.isHittable } ?? amens[0]
    }
}
