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

        app.buttons["Add to journal"].tap()
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

    /// + → a name (no carry row; the keyboard stays up across tabs) → the
    /// For push (search inactive, keyboard down) and a pick (the intention
    /// refocused) → back on Name, an alias → Add → the new person's page →
    /// back, the name on Home.
    @MainActor
    func testAddAName() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        app.buttons["Add"].firstMatch.tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Name is focused on open")
        XCTAssertFalse(app.switches["Carry onto the list"].firstMatch.exists, "no carry row on the Name tab")
        XCTAssertFalse(app.buttons["For"].exists, "the hidden Intention tab is out of the accessibility tree")
        XCTAssertTrue(app.navigationBars.buttons["Cancel"].exists, "the glass X, read as Cancel")
        app.typeText("Gary Olson")
        sleep(1)
        attach(app, "add 1 name")

        // Switch tabs: the keyboard never goes down.
        app.segmentedControls.buttons["Intention"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "keyboard stays up on Intention")
        XCTAssertTrue(app.switches["Print with your name"].firstMatch.exists, "the intention's carry toggle (Me)")
        XCTAssertFalse(app.textFields["Name"].exists, "the hidden Name tab is out of the accessibility tree")
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

        // Lands on the person's page.
        let page = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Gary Olson' AND label CONTAINS 'Dad'"))
        XCTAssertTrue(page.firstMatch.waitForExistence(timeout: 3), "the new person's page: the alias, the name under it")
        XCTAssertTrue(app.buttons["Add a first intention for Dad"].exists, "no intentions yet: the invitation")
        XCTAssertTrue(app.switches["Carry onto the list"].firstMatch.exists, "the carry row")
        sleep(1)
        attach(app, "add 5 page")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad, Gary Olson'"))
        XCTAssertTrue(row.firstMatch.waitForExistence(timeout: 3), "the new name on Home")
        attach(app, "add 6 home")
    }

    /// Long-press Dad → "Add intention" → the add-intention form for him (X /
    /// Add, keyboard up, the carry toggle) → Add → on Home under Dad.
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
        XCTAssertTrue(app.navigationBars.buttons["Cancel"].exists, "the glass X")
        XCTAssertFalse(app.buttons["For"].exists, "no For row: the person is given")
        XCTAssertTrue(app.switches["Print with Dad"].firstMatch.exists, "the same carry toggle")
        app.typeText("Strength for the week")
        sleep(1)
        attach(app, "row 2 intention form")
        app.navigationBars.buttons["Add"].tap()

        let added = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Strength for the week'"))
        XCTAssertTrue(added.firstMatch.waitForExistence(timeout: 3), "the intention on Home")
        attach(app, "row 3 home")
    }

    /// Aunt Bea's row → her page (the carry card's "Private · in your prayers
    /// only", the toggle off, her first-intention invitation) → carry her →
    /// the footer changes → her first intention → it's on the page, with the
    /// ＋ on the Intentions title.
    @MainActor
    func testANamesPage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let bea = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Aunt Bea'"))
        XCTAssertTrue(bea.firstMatch.waitForExistence(timeout: 3))
        bea.firstMatch.tap()
        let header = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Aunt Bea'"))
        XCTAssertTrue(header.firstMatch.waitForExistence(timeout: 3), "her page")
        let privateLine = app.staticTexts["Private · in your prayers only"]
        XCTAssertTrue(privateLine.waitForExistence(timeout: 3), "the card's footer while she isn't carried")
        let carry = app.switches["Carry onto the list"].firstMatch
        XCTAssertEqual(carry.value as? String, "0")
        sleep(1)
        attach(app, "page 1 not carried")

        carry.switches.firstMatch.tap()
        let gone = NSPredicate(format: "exists == false")
        wait(for: [expectation(for: gone, evaluatedWith: privateLine)], timeout: 3)
        XCTAssertEqual(carry.value as? String, "1")
        attach(app, "page 2 carried")

        app.buttons["Add a first intention for Aunt Bea"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "the add-intention form, focused")
        app.typeText("Her new home")
        app.navigationBars.buttons["Add"].tap()
        let added = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Her new home'"))
        XCTAssertTrue(added.firstMatch.waitForExistence(timeout: 3), "on her page")
        XCTAssertTrue(app.buttons["Add intention for Aunt Bea"].exists, "the ＋ on the title, once there's one")
        attach(app, "page 3 intention")
    }

    /// Dad's page → the "your prayers" tile → History filtered to Dad (the
    /// chip) on the Held tab → × widens to everyone, still on Held.
    @MainActor
    func testHistoryFromAPersonsTile() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad,'"))
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 3))
        dad.firstMatch.tap()
        let tile = app.buttons["page.history.tile.held"]
        XCTAssertTrue(app.buttons["page.history.seeAll"].waitForExistence(timeout: 3) || tile.exists)
        for _ in 0..<4 where !tile.isHittable { app.swipeUp() }
        XCTAssertTrue(tile.isHittable, "the tile, on Dad's page")
        tile.tap()

        let chip = app.buttons["history.filter.chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3), "History opens filtered")
        XCTAssertEqual(chip.label, "Dad")
        let held = app.segmentedControls.buttons["Held"]
        XCTAssertTrue(held.exists)
        XCTAssertTrue(held.isSelected, "on the Held tab")
        XCTAssertTrue(app.staticTexts["Today"].exists, "today's prayers under their heading")

        app.buttons["history.filter.clear"].tap()
        XCTAssertTrue(app.buttons["history.filter"].waitForExistence(timeout: 3), "everyone: the filter glyph")
        XCTAssertTrue(app.segmentedControls.buttons["Held"].isSelected)

        // Back on Dad's page, today's node opens History on today's sheet.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let node = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history.node.'")).firstMatch
        for _ in 0..<4 where !node.isHittable { app.swipeUp() }
        node.tap()
        let onList = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'On List'")).firstMatch
        XCTAssertTrue(onList.waitForExistence(timeout: 3), "the day sheet: Dad is on today's list")
    }

    /// A Home intention row (browse mode) → its page: the person's name
    /// above, "Print with Dad", back to Home.
    @MainActor
    func testAnIntentionsPageFromHome() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Healing after his surgery'"))
        XCTAssertTrue(row.firstMatch.waitForExistence(timeout: 3))
        row.firstMatch.tap()
        XCTAssertTrue(app.switches["Print with Dad"].firstMatch.waitForExistence(timeout: 3), "its carry card")
        XCTAssertEqual(app.switches["Print with Dad"].firstMatch.value as? String, "1", "Dad prints with it")
        XCTAssertTrue(app.buttons["Dad"].exists, "the person's name above the title")
        attach(app, "intention page")
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

    /// Dad's page → Pray for Dad (the page strips to him, Dad checked) →
    /// Amen → the invitation, finished without the list → the closing sheet
    /// → Done → the History preview fades back: today's node held, the
    /// "your prayers" tile one higher.
    @MainActor
    func testPrayingOnDadsPage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad,'"))
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 3))
        dad.firstMatch.tap()
        let tile = app.buttons["page.history.tile.held"]
        XCTAssertTrue(tile.waitForExistence(timeout: 3), "the tiles, browsing")
        let before = try XCTUnwrap(leadingNumber(tile.label), "the tile's count: \(tile.label)")

        app.buttons["Pray for Dad"].tap()
        let gone = NSPredicate(format: "exists == false")
        wait(for: [expectation(for: gone, evaluatedWith: tile)], timeout: 3)
        XCTAssertFalse(app.switches["Carry onto the list"].firstMatch.exists, "the carry card fades out")
        XCTAssertFalse(app.buttons["Add intention for Dad"].exists, "so does the Intentions ＋")
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel in ‹'s place")
        XCTAssertTrue(app.buttons["page.prayForOthers"].exists, "Pray for others")
        XCTAssertEqual(app.descendants(matching: .any)["page.person"].value as? String, "Held", "Dad, pre-checked")

        sleep(6)
        enabledAmen(app).tap()
        let hold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hold the'")).firstMatch
        XCTAssertTrue(hold.waitForExistence(timeout: 3), "the invitation, on the page")
        enabledAmen(app).tap()

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 3), "the closing sheet")
        XCTAssertTrue(app.buttons["Add to journal"].exists)
        done.tap()

        XCTAssertTrue(tile.waitForExistence(timeout: 3), "the History preview fades back")
        let after = NSPredicate(format: "label BEGINSWITH %@", "\(before + 1)")
        wait(for: [expectation(for: after, evaluatedWith: tile)], timeout: 3)
        let today = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH 'history.node.' AND label BEGINSWITH 'Today.' AND label CONTAINS 'You prayed.'"))
        XCTAssertTrue(today.firstMatch.exists, "today's node, held")
        XCTAssertFalse(app.buttons["Cancel"].exists, "out of prayer")
        XCTAssertTrue(app.buttons["Pray for Dad"].exists, "the capsule is back")
    }

    /// An intention's page → Pray (the intention checked, Dad plain text) →
    /// Pray for others → Home, still praying, the checks kept → Cancel.
    @MainActor
    func testPrayForOthersFromAnIntentionsPage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Healing after his surgery'"))
        XCTAssertTrue(row.firstMatch.waitForExistence(timeout: 3))
        row.firstMatch.tap()
        XCTAssertTrue(app.buttons["Dad"].waitForExistence(timeout: 3), "browsing, Dad's name is a link")

        let pray = app.buttons.matching(NSPredicate(format: "label == 'Pray'")).allElementsBoundByIndex
        try XCTUnwrap(pray.first { $0.isHittable }, "the page's capsule").tap()
        let intention = app.descendants(matching: .any)["page.intention"]
        XCTAssertTrue(app.buttons["page.prayForOthers"].waitForExistence(timeout: 3))
        XCTAssertEqual(intention.value as? String, "Held", "pre-checked")
        XCTAssertFalse(app.buttons["Dad"].exists, "Dad is plain text in prayer")
        XCTAssertFalse(app.switches["Print with Dad"].firstMatch.exists, "the carry card fades out")

        app.buttons["page.prayForOthers"].tap()
        let homeRow = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Healing after his surgery'"))
        XCTAssertTrue(homeRow.firstMatch.waitForExistence(timeout: 3), "back on Home")
        XCTAssertFalse(app.buttons["page.prayForOthers"].waitForExistence(timeout: 1))
        XCTAssertEqual(homeRow.firstMatch.value as? String, "Held", "the check kept")
        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad,'"))
        XCTAssertEqual(dad.firstMatch.value as? String, "Partly held", "his name, held with one of two")
        XCTAssertTrue(app.buttons["Cancel"].exists, "still praying")

        app.buttons["Cancel"].tap()
        XCTAssertEqual(homeRow.firstMatch.value as? String ?? "", "", "browsing again")
    }

    /// Dad's page → Pray for Dad → swipe back from the edge → Home, still
    /// praying, Dad checked.
    @MainActor
    func testSwipeBackWhilePrayingOnAPage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-PPEnvironment", "mock"]
        app.launch()

        let dad = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dad,'"))
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 3))
        dad.firstMatch.tap()
        let pray = app.buttons["Pray for Dad"]
        XCTAssertTrue(pray.waitForExistence(timeout: 3))
        pray.tap()
        XCTAssertTrue(app.buttons["page.prayForOthers"].waitForExistence(timeout: 3))

        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertFalse(app.buttons["page.prayForOthers"].waitForExistence(timeout: 2), "off the page")
        XCTAssertTrue(dad.firstMatch.waitForExistence(timeout: 3), "on Home")
        XCTAssertEqual(dad.firstMatch.value as? String, "Held", "Dad still checked")
        XCTAssertTrue(app.buttons["Cancel"].exists, "still praying")
    }

    /// "14, your prayers" → 14.
    private func leadingNumber(_ label: String) -> Int? {
        Int(label.prefix { $0.isNumber })
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
