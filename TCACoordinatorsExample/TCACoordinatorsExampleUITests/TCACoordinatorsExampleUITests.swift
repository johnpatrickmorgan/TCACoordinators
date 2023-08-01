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
    app.buttons["Show double"].tap()
    XCTAssertTrue(app.navigationBars["Number 4"].waitForExistence(timeout: navigationTimeout))

    // Ensures increment will have happened off-screen.
    Thread.sleep(forTimeInterval: 3)

    app.navigationBars["Number 4"].swipeDown(velocity: .fast)
    XCTAssertTrue(app.navigationBars["Number 3"].waitForExistence(timeout: navigationTimeout))
  }
}
