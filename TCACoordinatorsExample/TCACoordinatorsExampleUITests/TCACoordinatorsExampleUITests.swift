import XCTest

class TCACoordinatorsExampleUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testIdentifiedCoordinator() {
    launchAndRunTests(tabTitle: "Identified", app: XCUIApplication())
  }

  func testIndexedCoordinator() {
    launchAndRunTests(tabTitle: "Indexed", app: XCUIApplication())
  }

  func launchAndRunTests(tabTitle: String, app: XCUIApplication) {
    let navigationTimeout = 1.5
    app.launch()

    XCTAssertTrue(app.tabBars.buttons[tabTitle].waitForExistence(timeout: 3))
    app.tabBars.buttons[tabTitle].tap()

    XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 2))
    app.buttons["Start"].tap()

    XCTAssertTrue(app.navigationBars["Numbers"].waitForExistence(timeout: navigationTimeout))

    app.buttons["2"].tap()
    XCTAssertTrue(app.navigationBars["Number 2"].waitForExistence(timeout: navigationTimeout))

    app.buttons["Increment after delay"].tap()
    app.buttons["Show double (4)"].tap()
    XCTAssertTrue(app.navigationBars["Number 4"].waitForExistence(timeout: navigationTimeout))

    // Ensures increment will have happened off-screen.
    Thread.sleep(forTimeInterval: 3)

    app.navigationBars["Number 4"].swipeSheetDown()
    XCTAssertTrue(app.navigationBars["Number 3"].waitForExistence(timeout: navigationTimeout))

    app.buttons["Show double (6)"].tap()
    XCTAssertTrue(app.navigationBars["Number 6"].waitForExistence(timeout: navigationTimeout))

    app.buttons["Show double (12)"].tap()
    XCTAssertTrue(app.navigationBars["Number 12"].waitForExistence(timeout: navigationTimeout))

    app.buttons["Go back to root from 12"].tap()
    XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: navigationTimeout * 3))
  }
}

extension XCUIElement {
  func swipeSheetDown() {
    if #available(iOS 17.0, *) {
      // This doesn't work in iOS 16
      self.swipeDown(velocity: .fast)
    } else {
      let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
      let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 5))
      start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0.0)
    }
  }
}
