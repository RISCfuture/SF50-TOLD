// swiftlint:disable prefer_nimble
import XCTest

final class SF50_TOLDUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  // Helper function to extract numeric value from label text like "1,234 ft"
  private func extractNumericValue(from text: String) -> Double? {
    // Remove commas and extract numbers
    let cleanedText = text.replacingOccurrences(of: ",", with: "")
    let pattern = #"(\d+(?:\.\d+)?)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(
        in: cleanedText,
        range: NSRange(cleanedText.startIndex..., in: cleanedText)
      ),
      let range = Range(match.range(at: 1), in: cleanedText)
    else {
      return nil
    }
    return Double(cleanedText[range])
  }

  // Helper function to complete initial setup
  @MainActor
  private func completeInitialSetup(app: XCUIApplication, emptyWeight: String) {
    // Wait for welcome screen to appear and animate in
    XCTAssertTrue(
      app.buttons["continueButton"].waitForExistence(timeout: 5),
      "Continue button should appear"
    )

    // Set model to G1 (default in unit tests)
    let modelPicker = app.segmentedControls["modelPicker"]
    if modelPicker.waitForExistence(timeout: 2) {
      modelPicker.buttons["G1"].tap()
    }

    // Set empty weight
    let emptyWeightField = app.textFields["emptyWeightField"]
    XCTAssertTrue(
      emptyWeightField.waitForExistence(timeout: 2),
      "Empty weight field should be accessible"
    )
    emptyWeightField.clearAndType(emptyWeight, app: app)

    app.buttons["continueButton"].tap()

    // Wait for main view to appear
    XCTAssertTrue(
      app.textFields["Payload"].waitForExistence(timeout: 5),
      "Payload field should appear after setup"
    )
  }

  // MARK: - Takeoff Tests

  @MainActor
  func testBasicTakeoffFlow() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    // Complete initial setup with empty weight to achieve total weight of 5000 lbs
    // Total weight = empty weight + payload (450) + fuel (0) = 5000
    // Therefore empty weight = 4550
    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Takeoff tab
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Set payload to achieve exact test weight
    let payloadField = app.textFields["Payload"].firstMatch
    XCTAssertTrue(payloadField.waitForExistence(timeout: 5), "Payload field should be accessible")
    payloadField.clearAndType("450", app: app)

    // Set fuel to 0 for exact test conditions
    let fuelField = app.textFields["Takeoff Fuel"].firstMatch
    XCTAssertTrue(fuelField.waitForExistence(timeout: 5), "Fuel field should be accessible")
    fuelField.clearAndType("0", app: app)

    // Select airport
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    // Switch to Search tab
    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(
      airportPicker.waitForExistence(timeout: 2),
      "Airport picker should appear"
    )
    airportPicker.buttons["Search"].tap()

    // Search for OAK
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should appear")
    searchField.tap()
    searchField.typeText("OAK")

    // Wait for search results and select KOAK
    XCTAssertTrue(
      app.buttons["airportRow-OAK"].firstMatch.waitForExistence(timeout: 3),
      "OAK airport should appear in results"
    )
    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    // Select runway
    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    // Select runway 28R
    XCTAssertTrue(
      app.buttons["runwayRow-28R"].firstMatch.waitForExistence(timeout: 2),
      "Runway 28R should appear"
    )
    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather
    let weatherSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["weatherSelector"]
    )
    XCTAssertNotNil(weatherSelector, "Weather selector should be accessible")
    weatherSelector!.tap()
    waitForNavigation()

    // Set wind direction
    let windDirectionField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windDirectionField"]
    )
    XCTAssertNotNil(windDirectionField, "Wind direction field should be accessible")
    windDirectionField!.clearAndType("0", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("0", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("20", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.12", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Wait for calculations to complete
    Thread.sleep(forTimeInterval: 1.0)

    // Verify takeoff distances are displayed
    let takeoffGroundRun = app.staticTexts["takeoffGroundRunValue"]
    let takeoffDistance = app.staticTexts["takeoffDistanceValue"]

    // Scroll to results if needed
    if !takeoffGroundRun.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }

    XCTAssertTrue(
      takeoffGroundRun.waitForExistence(timeout: 2),
      "Takeoff ground run should be displayed"
    )
    XCTAssertTrue(
      takeoffDistance.waitForExistence(timeout: 2),
      "Takeoff distance should be displayed"
    )

    // Extract numeric values and verify they match unit test expectations
    let groundRunValue = extractNumericValue(from: takeoffGroundRun.label)
    let distanceValue = extractNumericValue(from: takeoffDistance.label)

    XCTAssertNotNil(
      groundRunValue,
      "Should be able to extract ground run value from: \(takeoffGroundRun.label)"
    )
    XCTAssertNotNil(
      distanceValue,
      "Should be able to extract distance value from: \(takeoffDistance.label)"
    )

    if let groundRun = groundRunValue {
      XCTAssertEqual(
        groundRun,
        2083,
        accuracy: 1,
        "Ground run should be exactly 2083 ft (±1), got: \(groundRun)"
      )
    }

    if let distance = distanceValue {
      XCTAssertEqual(
        distance,
        2707,
        accuracy: 1,
        "Takeoff distance should be exactly 2707 ft (±1), got: \(distance)"
      )
    }
  }

  // MARK: - Landing Tests

  @MainActor
  func testBasicLandingFlow() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    // Complete initial setup with empty weight to achieve total weight of 4500 lbs
    // Total weight = empty weight + payload (450) + fuel (0) = 4500
    // Therefore empty weight = 4050
    completeInitialSetup(app: app, emptyWeight: "4050")

    // Navigate to Landing tab
    app.tapTab("Landing")
    waitForNavigation()

    // Set payload to achieve exact test weight
    let payloadField = app.textFields["Payload"].firstMatch
    XCTAssertTrue(payloadField.waitForExistence(timeout: 5), "Payload field should be accessible")
    payloadField.clearAndType("450", app: app)

    // Set fuel to 0 for exact test conditions
    let fuelField = app.textFields["Landing Fuel"].firstMatch
    XCTAssertTrue(fuelField.waitForExistence(timeout: 5), "Fuel field should be accessible")
    fuelField.clearAndType("0", app: app)

    // Select airport
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    // Switch to Search tab
    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(
      airportPicker.waitForExistence(timeout: 2),
      "Airport picker should appear"
    )
    airportPicker.buttons["Search"].tap()

    // Search for OAK
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should appear")
    searchField.tap()
    searchField.typeText("OAK")

    // Wait for search results and select KOAK
    XCTAssertTrue(
      app.buttons["airportRow-OAK"].firstMatch.waitForExistence(timeout: 3),
      "OAK airport should appear in results"
    )
    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    // Select runway
    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    // Select runway 28R
    XCTAssertTrue(
      app.buttons["runwayRow-28R"].firstMatch.waitForExistence(timeout: 2),
      "Runway 28R should appear"
    )
    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather
    let weatherSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["weatherSelector"]
    )
    XCTAssertNotNil(weatherSelector, "Weather selector should be accessible")
    weatherSelector!.tap()
    waitForNavigation()

    // Set wind direction
    let windDirectionField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windDirectionField"]
    )
    XCTAssertNotNil(windDirectionField, "Wind direction field should be accessible")
    windDirectionField!.clearAndType("0", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("0", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("20", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.12", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Wait for calculations to complete
    Thread.sleep(forTimeInterval: 1.0)

    // Verify landing distance is displayed
    let landingDistance = app.staticTexts["landingDistanceValue"]

    // Scroll to results if needed
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }

    XCTAssertTrue(
      landingDistance.waitForExistence(timeout: 2),
      "Landing distance should be displayed"
    )

    // Extract numeric value and verify it matches unit test expectations
    let distanceValue = extractNumericValue(from: landingDistance.label)

    XCTAssertNotNil(
      distanceValue,
      "Should be able to extract landing distance value from: \(landingDistance.label)"
    )

    if let distance = distanceValue {
      XCTAssertEqual(
        distance,
        1867,
        accuracy: 1,
        "Landing distance should be exactly 1867 ft (±1), got: \(distance)"
      )
    }
  }

  // MARK: - Additional Conditions Tests

  @MainActor
  func testTakeoffWithDifferentConditions() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    // Complete initial setup with empty weight to achieve total weight of 6000 lbs
    // Total weight = empty weight + payload (1450) + fuel (0) = 6000
    // Therefore empty weight = 4550
    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Takeoff tab
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Set payload to achieve exact test weight
    let payloadField = app.textFields["Payload"].firstMatch
    XCTAssertTrue(payloadField.waitForExistence(timeout: 5), "Payload field should be accessible")
    payloadField.clearAndType("1450", app: app)

    // Set fuel to 0 for exact test conditions
    let fuelField = app.textFields["Takeoff Fuel"].firstMatch
    XCTAssertTrue(fuelField.waitForExistence(timeout: 5), "Fuel field should be accessible")
    fuelField.clearAndType("0", app: app)

    // Select airport (use SQL this time)
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    // Switch to Search tab
    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(
      airportPicker.waitForExistence(timeout: 2),
      "Airport picker should appear"
    )
    airportPicker.buttons["Search"].tap()

    // Search for SQL
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should appear")
    searchField.tap()
    searchField.typeText("SQL")

    // Wait for search results and select KSQL
    XCTAssertTrue(
      app.buttons["airportRow-SQL"].firstMatch.waitForExistence(timeout: 3),
      "SQL airport should appear in results"
    )
    app.buttons["airportRow-SQL"].firstMatch.tap()
    waitForNavigation()

    // Select runway
    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    // Select runway 30
    XCTAssertTrue(
      app.buttons["runwayRow-30"].firstMatch.waitForExistence(timeout: 2),
      "Runway 30 should appear"
    )
    app.buttons["runwayRow-30"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather (hot day scenario)
    let weatherSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["weatherSelector"]
    )
    XCTAssertNotNil(weatherSelector, "Weather selector should be accessible")
    weatherSelector!.tap()
    waitForNavigation()

    // Set wind direction
    let windDirectionField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windDirectionField"]
    )
    XCTAssertNotNil(windDirectionField, "Wind direction field should be accessible")
    windDirectionField!.clearAndType("300", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("8", app: app)

    // Set temperature (hot day)
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("35", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("29.92", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Wait for calculations to complete
    Thread.sleep(forTimeInterval: 1.0)

    // Verify takeoff distances are displayed
    let takeoffGroundRun = app.staticTexts["takeoffGroundRunValue"]
    let takeoffDistance = app.staticTexts["takeoffDistanceValue"]

    // Scroll to results if needed
    if !takeoffGroundRun.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }

    XCTAssertTrue(
      takeoffGroundRun.waitForExistence(timeout: 2),
      "Takeoff ground run should be displayed"
    )
    XCTAssertTrue(
      takeoffDistance.waitForExistence(timeout: 2),
      "Takeoff distance should be displayed"
    )

    // Extract numeric values and verify they match unit test expectations
    let groundRunValue = extractNumericValue(from: takeoffGroundRun.label)
    let distanceValue = extractNumericValue(from: takeoffDistance.label)

    XCTAssertNotNil(
      groundRunValue,
      "Should be able to extract ground run value from: \(takeoffGroundRun.label)"
    )
    XCTAssertNotNil(
      distanceValue,
      "Should be able to extract distance value from: \(takeoffDistance.label)"
    )

    if let groundRun = groundRunValue {
      // Exact value expected: 2231 ft
      XCTAssertEqual(
        groundRun,
        3333,
        accuracy: 1,
        "Ground run should be exactly 3333 ft (±1), got: \(groundRun)"
      )
    }

    if let distance = distanceValue {
      XCTAssertEqual(
        distance,
        4762,
        accuracy: 1,
        "Takeoff distance should be exactly 4762 ft (±1), got: \(distance)"
      )
    }
  }

  @MainActor
  func testLaunchPerformance() throws {
    // This measures how long it takes to launch your application.
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}
// swiftlint:enable prefer_nimble
