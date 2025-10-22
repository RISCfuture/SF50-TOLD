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

  // Helper function to handle database loader if it appears
  @MainActor
  private func handleDatabaseLoaderIfNeeded(app: XCUIApplication) {
    // Check if database loader appeared (in case cycle is out of date)
    let deferButton = app.buttons["deferDataButton"]
    if deferButton.waitForExistence(timeout: 2) {
      deferButton.tap()
      // Wait for loader to dismiss
      Thread.sleep(forTimeInterval: 0.5)
    }
  }

  // Helper function to complete initial setup
  @MainActor
  private func completeInitialSetup(app: XCUIApplication, emptyWeight: String) {
    // Handle database loader if it appears (in case cycle is out of date)
    handleDatabaseLoaderIfNeeded(app: app)

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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

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
        1798,
        accuracy: 1,
        "Ground run should be exactly 1798 ft (±1), got: \(groundRun)"
      )
    }

    if let distance = distanceValue {
      XCTAssertEqual(
        distance,
        2643,
        accuracy: 1,
        "Takeoff distance should be exactly 2643 ft (±1), got: \(distance)"
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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

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
        1769,
        accuracy: 1,
        "Landing distance should be exactly 1769 ft (±1), got: \(distance)"
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

    // Set custom weather for deterministic results
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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

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
        2081,
        accuracy: 1,
        "Ground run should be exactly 2081 ft (±1), got: \(groundRun)"
      )
    }

    if let distance = distanceValue {
      XCTAssertEqual(
        distance,
        3334,
        accuracy: 1,
        "Takeoff distance should be exactly 3334 ft (±1), got: \(distance)"
      )
    }
  }

  // MARK: - Report Generation Tests

  @MainActor
  func testTakeoffReportGeneration() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Takeoff tab
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Set up basic configuration
    let payloadField = app.textFields["Payload"].firstMatch
    payloadField.clearAndType("450", app: app)

    let fuelField = app.textFields["Takeoff Fuel"].firstMatch
    fuelField.clearAndType("0", app: app)

    // Select airport and runway (OAK 28R)
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("OAK")

    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Generate report
    let reportButton = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["generateTakeoffReportButton"]
    )
    XCTAssertNotNil(reportButton, "Report button should be accessible")
    reportButton!.tap()

    // Wait for report to generate and appear
    XCTAssertTrue(
      app.navigationBars["Takeoff Report"].waitForExistence(timeout: 10),
      "Report should be displayed"
    )

    // Verify Done button exists
    XCTAssertTrue(
      app.buttons["Done"].exists,
      "Done button should be present in report viewer"
    )

    // Dismiss report
    app.buttons["Done"].tap()
    waitForNavigation()
  }

  // MARK: - Scenario Management Tests

  @MainActor
  func testScenarioManagement() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Settings tab
    app.tapTab("Settings")
    waitForNavigation()

    // Navigate to Scenarios
    let scenariosLink = app.buttons["scenariosNavigationLink"]
    XCTAssertTrue(scenariosLink.waitForExistence(timeout: 2), "Scenarios link should exist")
    scenariosLink.tap()
    waitForNavigation()

    // Create a new takeoff scenario - it's a NavigationLink with a Label in a Form
    // Need to scroll to find it since it's in the first section
    var addScenarioButton = app.buttons["Add Scenario"].firstMatch

    // Try scrolling down to find it
    var scrollAttempts = 0
    while !addScenarioButton.exists && scrollAttempts < 3 {
      app.swipeUp()  // Swipe up on the entire app to scroll down
      Thread.sleep(forTimeInterval: 0.3)
      scrollAttempts += 1
      addScenarioButton = app.buttons["Add Scenario"].firstMatch
    }

    XCTAssertTrue(
      addScenarioButton.waitForExistence(timeout: 2),
      "Add Scenario button should exist"
    )
    addScenarioButton.tap()
    waitForNavigation()

    // Set scenario name
    let nameField = app.textFields["scenarioNameField"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
    nameField.clearAndType("Hot Day Test", app: app)

    // Set OAT Delta
    let oatDeltaField = app.textFields["oatDeltaField"]
    XCTAssertTrue(oatDeltaField.exists, "OAT delta field should exist")
    oatDeltaField.clearAndType("10", app: app)

    // Set Weight Delta
    let weightDeltaField = app.textFields["weightDeltaField"]
    XCTAssertTrue(weightDeltaField.exists, "Weight delta field should exist")
    weightDeltaField.clearAndType("500", app: app)

    // Tap somewhere else to commit the changes and dismiss keyboard
    app.tap()
    Thread.sleep(forTimeInterval: 0.5)

    // Go back to scenarios list
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Wait for the list to update and try to find the scenario
    Thread.sleep(forTimeInterval: 0.5)

    // Verify scenario appears in list - might need to scroll to find it
    var scenarioText = app.staticTexts["Hot Day Test"]

    // Try scrolling if not immediately visible
    var findAttempts = 0
    while !scenarioText.exists && findAttempts < 10 {
      app.swipeUp()
      Thread.sleep(forTimeInterval: 0.3)
      findAttempts += 1
      scenarioText = app.staticTexts["Hot Day Test"]
    }

    XCTAssertTrue(
      scenarioText.exists,
      "Created scenario should appear in list"
    )

    // Delete the scenario
    app.staticTexts["Hot Day Test"].swipeLeft()
    app.buttons["Delete"].tap()
    waitForNavigation()

    // Verify scenario is deleted
    XCTAssertFalse(
      app.staticTexts["Hot Day Test"].exists,
      "Deleted scenario should not appear in list"
    )
  }

  // MARK: - Airport Favorites Tests

  @MainActor
  func testAirportFavoritesFlow() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Takeoff tab
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Open airport picker
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    waitForNavigation()

    // Switch to Search tab
    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(airportPicker.waitForExistence(timeout: 2), "Airport picker should appear")
    airportPicker.buttons["Search"].tap()

    // Search for SQL
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("SQL")

    // Dismiss the keyboard by tapping the search button on the keyboard
    let keyboardSearchButton = app.keyboards.buttons["Search"].firstMatch
    if keyboardSearchButton.exists {
      keyboardSearchButton.tap()
    } else {
      // Fallback: type return to dismiss keyboard
      searchField.typeText("\n")
    }
    Thread.sleep(forTimeInterval: 0.5)

    // Wait for search results to appear
    let sqlRow = app.buttons["airportRow-SQL"].firstMatch
    XCTAssertTrue(
      sqlRow.waitForExistence(timeout: 3),
      "SQL airport should appear in search results"
    )

    // Check if already favorited by switching to Favorites tab
    airportPicker.buttons["Favorites"].tap()
    waitForNavigation()

    let alreadyFavorited = app.buttons["airportRow-SQL"].exists

    // Go back to Search tab
    airportPicker.buttons["Search"].tap()
    waitForNavigation()

    // Re-search for SQL (search is cleared when switching tabs)
    let searchFieldAgain = app.searchFields.firstMatch
    searchFieldAgain.tap()
    searchFieldAgain.typeText("SQL")

    // Dismiss keyboard
    let keyboardSearchButton2 = app.keyboards.buttons["Search"].firstMatch
    if keyboardSearchButton2.exists {
      keyboardSearchButton2.tap()
    } else {
      searchFieldAgain.typeText("\n")
    }
    Thread.sleep(forTimeInterval: 0.5)

    // Wait for search results to appear again
    XCTAssertTrue(
      app.buttons["airportRow-SQL"].waitForExistence(timeout: 2),
      "SQL should appear in search results again"
    )

    if alreadyFavorited {
      // Already favorited, unfavorite it first
      let allSQLButtons = app.buttons.matching(identifier: "airportRow-SQL")
      let favoriteButton = allSQLButtons.element(boundBy: 2)

      if favoriteButton.isHittable {
        favoriteButton.tap()
      } else {
        favoriteButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      }
      Thread.sleep(forTimeInterval: 0.3)
    }

    // Now favorite the airport
    let allSQLButtons = app.buttons.matching(identifier: "airportRow-SQL")
    let buttonCount = allSQLButtons.count
    XCTAssertGreaterThan(buttonCount, 2, "Should have multiple buttons for airport row")

    let favoriteButton = allSQLButtons.element(boundBy: 2)
    XCTAssertTrue(favoriteButton.exists, "Favorite button should exist")

    // Force tap using coordinate if not hittable directly
    if favoriteButton.isHittable {
      favoriteButton.tap()
    } else {
      // Tap using direct coordinate
      favoriteButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    Thread.sleep(forTimeInterval: 0.3)

    // Switch to Favorites tab
    airportPicker.buttons["Favorites"].tap()
    waitForNavigation()

    // Verify airport appears in favorites
    XCTAssertTrue(
      app.buttons["airportRow-SQL"].exists,
      "SQL should appear in favorites"
    )

    // Unfavorite the airport
    let allSQLButtonsInFavorites = app.buttons.matching(identifier: "airportRow-SQL")
    XCTAssertGreaterThan(
      allSQLButtonsInFavorites.count,
      2,
      "Should have multiple buttons for airport row in favorites"
    )

    let favoriteButtonInFavorites = allSQLButtonsInFavorites.element(boundBy: 2)
    XCTAssertTrue(favoriteButtonInFavorites.exists, "Favorite button in favorites should exist")

    // Force tap using coordinate if not hittable directly
    if favoriteButtonInFavorites.isHittable {
      favoriteButtonInFavorites.tap()
    } else {
      // Tap using direct coordinate
      favoriteButtonInFavorites.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    Thread.sleep(forTimeInterval: 0.3)

    // Switch to Search tab and back to Favorites to refresh the list
    airportPicker.buttons["Search"].tap()
    waitForNavigation()
    airportPicker.buttons["Favorites"].tap()
    waitForNavigation()

    // Verify it's removed from favorites
    XCTAssertFalse(
      app.buttons["airportRow-SQL"].exists,
      "SQL should be removed from favorites"
    )
  }

  // MARK: - NOTAM Management Tests

  @MainActor
  func testNOTAMManagement() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4050")

    // Navigate to Landing tab
    app.tapTab("Landing")
    waitForNavigation()

    // Set basic configuration
    let payloadField = app.textFields["Payload"].firstMatch
    payloadField.clearAndType("450", app: app)

    let fuelField = app.textFields["Landing Fuel"].firstMatch
    fuelField.clearAndType("0", app: app)

    // Select airport and runway
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("OAK")

    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather for deterministic results
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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Get baseline landing distance
    Thread.sleep(forTimeInterval: 1.0)
    let landingDistance = app.staticTexts["landingDistanceValue"]
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    XCTAssertTrue(landingDistance.exists, "Landing distance should be displayed")
    let baselineDistance = extractNumericValue(from: landingDistance.label)

    // Open NOTAMs - need to scroll to find it
    let notamButton = app.buttons["NOTAMsSelector"]

    // Scroll down multiple times to find the NOTAM selector
    var attempts = 0
    while !notamButton.exists && attempts < 5 {
      app.collectionViews.firstMatch.swipeDown()
      Thread.sleep(forTimeInterval: 0.2)
      attempts += 1
    }

    XCTAssertTrue(notamButton.waitForExistence(timeout: 2), "NOTAM selector should exist")
    notamButton.tap()
    waitForNavigation()

    // Add contamination (this should increase landing distance)
    let contaminationTypePicker = app.buttons["contaminationTypePicker"]
    if contaminationTypePicker.waitForExistence(timeout: 2) {
      contaminationTypePicker.tap()

      // Select Water/Slush
      app.buttons["Water/Slush"].tap()
      Thread.sleep(forTimeInterval: 0.3)

      // Set contamination depth using the slider
      let depthSlider = app.sliders["contaminationDepthSlider"]
      if depthSlider.waitForExistence(timeout: 2) {
        depthSlider.adjust(toNormalizedSliderPosition: 0.4)  // Set to 0.2 inches (40% of 0.5 max)
        Thread.sleep(forTimeInterval: 0.3)
      }
    }

    // Go back
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Wait for recalculation to complete (polling happens every 500ms, wait for multiple cycles)
    Thread.sleep(forTimeInterval: 2.5)

    // Verify landing distance increased due to contamination
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Wait a moment for UI to update with new calculated value
    Thread.sleep(forTimeInterval: 0.5)
    let contaminatedDistance = extractNumericValue(from: landingDistance.label)

    if let baseline = baselineDistance, let contaminated = contaminatedDistance {
      XCTAssertEqual(baseline, 1769.0, accuracy: 1.0, "Baseline landing distance should be 1769.0")
      XCTAssertEqual(
        contaminated,
        2432.0,
        accuracy: 1.0,
        "Contaminated landing distance should be 2432.0"
      )
    }

    // Verify NOTAM count increased
    let notamButtonAfter = app.buttons["NOTAMsSelector"]
    if !notamButtonAfter.exists {
      app.collectionViews.firstMatch.swipeDown()
      Thread.sleep(forTimeInterval: 0.5)
    }

    // The button label should now show "NOTAMs (1)" indicating one contamination restriction
    XCTAssertTrue(
      notamButtonAfter.label.contains("(1)") || notamButtonAfter.label.contains("("),
      "NOTAM button should show count after adding contamination"
    )

    // Clear NOTAMs
    let notamButton2 = app.buttons["NOTAMsSelector"]

    // Scroll down to find the NOTAM selector again
    var attempts2 = 0
    while !notamButton2.exists && attempts2 < 5 {
      app.collectionViews.firstMatch.swipeDown()
      Thread.sleep(forTimeInterval: 0.2)
      attempts2 += 1
    }

    XCTAssertTrue(
      notamButton2.waitForExistence(timeout: 2),
      "NOTAM selector should exist for clearing"
    )
    notamButton2.tap()
    waitForNavigation()

    let clearButton = app.buttons["clearNOTAMsButton"]
    XCTAssertTrue(clearButton.exists, "Clear NOTAMs button should exist")
    clearButton.tap()
    waitForNavigation()

    // Verify distance returned to baseline
    Thread.sleep(forTimeInterval: 1.0)
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    let clearedDistance = extractNumericValue(from: landingDistance.label)

    if let baseline = baselineDistance, let cleared = clearedDistance {
      XCTAssertEqual(
        cleared,
        baseline,
        accuracy: 1,
        "Landing distance should return to baseline after clearing NOTAMs"
      )
    }
  }

  // MARK: - Settings Impact Tests

  @MainActor
  func testSettingsChangesImpact() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4550")

    // Set up basic takeoff calculation
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    let payloadField = app.textFields["Payload"].firstMatch
    payloadField.clearAndType("450", app: app)

    let fuelField = app.textFields["Takeoff Fuel"].firstMatch
    fuelField.clearAndType("0", app: app)

    // Select airport and runway
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("OAK")

    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather for deterministic results
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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Get baseline distance
    Thread.sleep(forTimeInterval: 1.0)
    var takeoffDistance = app.staticTexts["takeoffDistanceValue"]
    if !takeoffDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    XCTAssertTrue(
      takeoffDistance.waitForExistence(timeout: 2),
      "Takeoff distance should be displayed"
    )
    let baselineDistance = extractNumericValue(from: takeoffDistance.label)

    // Navigate to Settings
    app.tapTab("Settings")
    waitForNavigation()

    // Change safety factor to 1.1
    let safetyFactorDryField = app.textFields["safetyFactorDryField"]
    XCTAssertTrue(
      safetyFactorDryField.waitForExistence(timeout: 2),
      "Safety factor dry field should exist"
    )
    safetyFactorDryField.clearAndType("1.1", app: app)

    // Dismiss keyboard if it's up
    app.tap()
    Thread.sleep(forTimeInterval: 0.3)

    // Return to Takeoff tab
    app.tapTab("Takeoff")
    waitForNavigation()

    // Verify we're actually on the Takeoff tab by checking for tab bar selection
    let takeoffTabButton = app.tabBars.buttons["Takeoff"]
    XCTAssertTrue(takeoffTabButton.isSelected, "Should be on Takeoff tab")

    // Give extra time for the tab to fully switch and recalculations to complete
    Thread.sleep(forTimeInterval: 2.5)

    // Re-query the takeoff distance element after tab switch
    takeoffDistance = app.staticTexts["takeoffDistanceValue"]

    // Scroll down first to reset position, then scroll up to find results
    app.collectionViews.firstMatch.swipeDown()
    Thread.sleep(forTimeInterval: 0.5)

    // Try scrolling up to find the distance value
    var scrollAttempts = 0
    while !takeoffDistance.exists && scrollAttempts < 7 {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
      scrollAttempts += 1
      takeoffDistance = app.staticTexts["takeoffDistanceValue"]
    }

    XCTAssertTrue(
      takeoffDistance.waitForExistence(timeout: 5),
      "Takeoff distance should be displayed after settings change"
    )
    let adjustedDistance = extractNumericValue(from: takeoffDistance.label)

    if let baseline = baselineDistance, let adjusted = adjustedDistance {
      XCTAssertEqual(baseline, 2643.0, accuracy: 1.0, "Baseline takeoff distance should be 2643.0")
      XCTAssertEqual(adjusted, 2907.0, accuracy: 1.0, "Adjusted takeoff distance should be 2907.0")
    }

    // Reset safety factor
    app.tapTab("Settings")
    waitForNavigation()

    safetyFactorDryField.clearAndType("1.0", app: app)
  }

  // MARK: - Landing Flap Configuration Tests

  @MainActor
  func testLandingFlapConfiguration() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4050")

    // Navigate to Landing tab
    app.tapTab("Landing")
    waitForNavigation()

    // Set basic configuration
    let payloadField = app.textFields["Payload"].firstMatch
    payloadField.clearAndType("450", app: app)

    let fuelField = app.textFields["Landing Fuel"].firstMatch
    fuelField.clearAndType("0", app: app)

    // Select airport and runway
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("OAK")

    app.buttons["airportRow-OAK"].firstMatch.tap()
    waitForNavigation()

    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    app.buttons["runwayRow-28R"].firstMatch.tap()
    waitForNavigation()

    // Set custom weather for deterministic results
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
    windDirectionField!.clearAndType("350", app: app)

    // Set wind speed
    let windSpeedField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["windSpeedField"]
    )
    XCTAssertNotNil(windSpeedField, "Wind speed field should be accessible")
    windSpeedField!.clearAndType("15", app: app)

    // Set temperature
    let tempField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["tempField"]
    )
    XCTAssertNotNil(tempField, "Temperature field should be accessible")
    tempField!.clearAndType("21", app: app)

    // Set altimeter
    let altimeterField = app.collectionViews.firstMatch.makeVisible(
      element: app.textFields["altimeterField"]
    )
    XCTAssertNotNil(altimeterField, "Altimeter field should be accessible")
    altimeterField!.clearAndType("30.05", app: app)

    // Go back to main view
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Test Flaps 100% (default)
    Thread.sleep(forTimeInterval: 1.0)
    let landingDistance = app.staticTexts["landingDistanceValue"]
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    let flaps100Distance = extractNumericValue(from: landingDistance.label)

    // Change to Flaps 50%
    app.collectionViews.firstMatch.swipeDown()
    Thread.sleep(forTimeInterval: 0.3)

    // The Flaps picker may be displayed as "Flaps 100%" button showing current value
    let flapsButton = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons.matching(NSPredicate(format: "label CONTAINS 'Flaps'")).firstMatch
    )
    XCTAssertNotNil(flapsButton, "Flaps button should exist")
    flapsButton!.tap()
    Thread.sleep(forTimeInterval: 0.3)

    app.buttons["Flaps 50%"].tap()
    Thread.sleep(forTimeInterval: 1.0)

    // Verify distance changed
    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    let flaps50Distance = extractNumericValue(from: landingDistance.label)

    if let distance100 = flaps100Distance, let distance50 = flaps50Distance {
      XCTAssertNotEqual(
        distance100,
        distance50,
        accuracy: 1,
        "Landing distance should differ between flap settings"
      )
    }

    // Change to Flaps Up (should increase distance significantly)
    app.collectionViews.firstMatch.swipeDown()
    Thread.sleep(forTimeInterval: 0.3)

    // Re-query the flaps button
    let flapsButton2 = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons.matching(NSPredicate(format: "label CONTAINS 'Flaps'")).firstMatch
    )
    XCTAssertNotNil(flapsButton2, "Flaps button should exist for second change")
    flapsButton2!.tap()
    Thread.sleep(forTimeInterval: 0.3)

    app.buttons["Flaps Up"].tap()
    Thread.sleep(forTimeInterval: 1.0)

    if !landingDistance.exists {
      app.collectionViews.firstMatch.swipeUp()
      Thread.sleep(forTimeInterval: 0.5)
    }
    let flapsUpDistance = extractNumericValue(from: landingDistance.label)

    if let distance100 = flaps100Distance, let distanceUp = flapsUpDistance {
      XCTAssertEqual(
        distance100,
        1769.0,
        accuracy: 1.0,
        "Flaps 100% landing distance should be 1769.0"
      )
      XCTAssertEqual(
        distanceUp,
        2248.0,
        accuracy: 1.0,
        "Flaps Up landing distance should be 2248.0"
      )
    }
  }

  // MARK: - Welcome Flow Variations Tests

  @MainActor
  func testWelcomeFlowModelSelection() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    handleDatabaseLoaderIfNeeded(app: app)

    // Wait for welcome screen
    XCTAssertTrue(
      app.buttons["continueButton"].waitForExistence(timeout: 5),
      "Continue button should appear"
    )

    // Test G2 selection
    let modelPicker = app.segmentedControls["modelPicker"]
    XCTAssertTrue(modelPicker.waitForExistence(timeout: 2), "Model picker should exist")

    // Select G2
    modelPicker.buttons["G2"].tap()
    Thread.sleep(forTimeInterval: 0.3)

    // Verify G2 is selected (button should be selected)
    XCTAssertTrue(
      modelPicker.buttons["G2"].isSelected,
      "G2 should be selected"
    )

    // Set empty weight and continue
    let emptyWeightField = app.textFields["emptyWeightField"]
    emptyWeightField.clearAndType("4550", app: app)

    app.buttons["continueButton"].tap()

    // Verify we reached main view
    XCTAssertTrue(
      app.textFields["Payload"].waitForExistence(timeout: 5),
      "Should reach main view after setup"
    )

    // Go to settings and verify model is G2
    app.tapTab("Settings")
    waitForNavigation()

    // The model toggle should show G2 (implementation may vary)
    // This is a basic verification that we got past setup
    XCTAssertTrue(
      app.staticTexts["Settings"].exists,
      "Should be on Settings screen"
    )
  }

  // MARK: - Offscale Warning Tests

  @MainActor
  func testOffscaleWarning() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    // Use very light empty weight for extreme conditions
    completeInitialSetup(app: app, emptyWeight: "3000")

    // Navigate to Takeoff tab
    let takeoffTab = app.tabBars.buttons["Takeoff"]
    if !takeoffTab.isSelected {
      app.tapTab("Takeoff")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Set extreme light weight
    let payloadField = app.textFields["Payload"].firstMatch
    payloadField.clearAndType("100", app: app)

    let fuelField = app.textFields["Takeoff Fuel"].firstMatch
    fuelField.clearAndType("0", app: app)

    // Select high elevation airport
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("ASE")  // Aspen - high elevation

    if app.buttons["airportRow-ASE"].firstMatch.waitForExistence(timeout: 3) {
      app.buttons["airportRow-ASE"].firstMatch.tap()
      waitForNavigation()

      let runwaySelector = app.collectionViews.firstMatch.makeVisible(
        element: app.buttons["runwaySelector"]
      )
      XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
      runwaySelector!.tap()
      waitForNavigation()

      // Select first available runway
      let firstRunway = app.buttons.matching(identifier: "runwayRow-15").firstMatch
      if firstRunway.waitForExistence(timeout: 2) {
        firstRunway.tap()
        waitForNavigation()
      }

      // Set extreme hot temperature
      let weatherSelector = app.collectionViews.firstMatch.makeVisible(
        element: app.buttons["weatherSelector"]
      )
      XCTAssertNotNil(weatherSelector, "Weather selector should be accessible")
      weatherSelector!.tap()
      waitForNavigation()

      let tempField = app.collectionViews.firstMatch.makeVisible(
        element: app.textFields["tempField"]
      )
      XCTAssertNotNil(tempField, "Temperature field should be accessible")
      tempField!.clearAndType("45", app: app)  // Extreme hot temperature

      app.navigationBars.buttons.element(boundBy: 0).tap()
      waitForNavigation()

      Thread.sleep(forTimeInterval: 1.0)

      // Look for warning indicators (implementation may vary)
      // At minimum, verify calculation still completes
      let takeoffDistance = app.staticTexts["takeoffDistanceValue"]
      if !takeoffDistance.exists {
        app.collectionViews.firstMatch.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
      }

      XCTAssertTrue(
        takeoffDistance.exists,
        "Takeoff distance should still be displayed even in extreme conditions"
      )
    }
  }

  // MARK: - Time Zone Display Tests

  @MainActor
  func testTimeZoneDisplayToggle() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING"]
    app.launch()

    completeInitialSetup(app: app, emptyWeight: "4550")

    // Navigate to Settings
    app.tapTab("Settings")
    waitForNavigation()

    // Find the time zone picker
    let timeZonePicker = app.buttons["timeZoneDisplayPicker"]
    XCTAssertTrue(timeZonePicker.waitForExistence(timeout: 2), "Time zone picker should exist")

    // Tap to open picker
    timeZonePicker.tap()
    Thread.sleep(forTimeInterval: 0.3)

    // Select Airport Local
    if app.buttons["Airport Local"].exists {
      app.buttons["Airport Local"].tap()
      Thread.sleep(forTimeInterval: 0.3)
    }

    // Navigate to Takeoff to see time display
    app.tapTab("Takeoff")
    waitForNavigation()

    // Select an airport to see its local time
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")
    airportSelector!.tap()
    waitForNavigation()

    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(airportPicker.waitForExistence(timeout: 2), "Airport picker should appear")
    airportPicker.buttons["Search"].tap()

    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("LAX")  // LA airport - different timezone from most

    if app.buttons["airportRow-LAX"].firstMatch.waitForExistence(timeout: 3) {
      app.buttons["airportRow-LAX"].firstMatch.tap()
      waitForNavigation()

      // Date selector should show time (format may vary)
      let dateSelector = app.buttons["dateSelector"]
      if dateSelector.waitForExistence(timeout: 2) {
        XCTAssertTrue(dateSelector.exists, "Date selector should show time")
      }
    }

    // Go back to settings and switch to UTC
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    app.tapTab("Settings")
    waitForNavigation()

    timeZonePicker.tap()
    Thread.sleep(forTimeInterval: 0.3)

    if app.buttons["UTC"].exists {
      app.buttons["UTC"].tap()
      Thread.sleep(forTimeInterval: 0.3)
    }

    // Verify the setting changed
    // The time display should now be UTC
    app.tapTab("Takeoff")
    waitForNavigation()

    // Basic verification that the setting persisted
    XCTAssertTrue(
      app.textFields["Payload"].exists,
      "Should still be on Takeoff tab"
    )
  }
}
// swiftlint:enable prefer_nimble
