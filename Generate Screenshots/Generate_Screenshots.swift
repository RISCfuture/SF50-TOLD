//
//  Generate_Screenshots.swift
//  Generate Screenshots
//
//  Created by Tim Morgan on 10/5/25.
//

import XCTest

final class Generate_Screenshots: XCTestCase {

  override func setUpWithError() throws {
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {
  }

  @MainActor
  func testGenerateScreenshots() throws {
    let app = XCUIApplication()
    app.launchArguments = ["UI-TESTING", "GENERATE-SCREENSHOTS"]
    setupSnapshot(app)
    app.launch()

    // Handle location permission directly via springboard
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    if springboard.alerts.buttons["Allow While Using App"].waitForExistence(timeout: 5) {
      springboard.alerts.buttons["Allow While Using App"].tap()
    }

    // wait for Apple Intelligence banner to self-dismiss
    Thread.sleep(forTimeInterval: 30)

    // Wait for welcome screen to appear (should always appear on first test run)
    if app.buttons["continueButton"].waitForExistence(timeout: 5) {
      // Welcome screen appeared - go through setup flow

      // Set model to G2
      let modelPicker = app.segmentedControls["modelPicker"]
      if modelPicker.waitForExistence(timeout: 2) {
        modelPicker.buttons["G2"].tap()
      }

      // Set empty weight
      let emptyWeightField = app.textFields["emptyWeightField"]
      XCTAssertTrue(
        emptyWeightField.waitForExistence(timeout: 2),
        "Empty weight field should be accessible"
      )
      emptyWeightField.clearAndType("3606", app: app)

      // Dismiss keyboard popover on iPad
      if app.otherElements["PopoverDismissRegion"].exists {
        app.otherElements["PopoverDismissRegion"].tap()
      }

      snapshot("01-aircraft-setup")

      app.buttons["continueButton"].tap()

      // Check if download consent screen appears and tap download button to download live airport data
      if app.buttons["downloadDataButton"].waitForExistence(timeout: 5) {
        app.buttons["downloadDataButton"].tap()

        // Wait for loader to complete and main view to appear (may take 30+ minutes)
        XCTAssertTrue(
          app.textFields["payloadField"].waitForExistence(timeout: 3600),
          "Payload field should appear after airport data download completes"
        )
      } else {
        // Download button didn't appear - data may already be downloaded, just wait for main view
        XCTAssertTrue(
          app.textFields["payloadField"].waitForExistence(timeout: 10),
          "Payload field should appear"
        )
      }
    }

    // Configure takeoff parameters
    let payloadField = app.textFields["payloadField"].firstMatch
    XCTAssertTrue(payloadField.waitForExistence(timeout: 5), "Payload field should be accessible")
    payloadField.clearAndType("530", app: app)

    let fuelField = app.textFields["fuelField"].firstMatch
    XCTAssertTrue(fuelField.waitForExistence(timeout: 5), "Fuel field should be accessible")
    fuelField.clearAndType("212", app: app)

    // Select airport first (needed before weather selector is available)
    let airportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(airportSelector, "Airport selector should be accessible")

    // Tap and ensure navigation (may need double-tap on some devices)
    tapAndEnsureNavigation(
      element: airportSelector!,
      expectedElement: app.segmentedControls["airportListPicker"]
    )
    waitForNavigation()

    // Switch to Search tab
    let airportPicker = app.segmentedControls["airportListPicker"]
    XCTAssertTrue(
      airportPicker.waitForExistence(timeout: 2),
      "Airport picker should appear"
    )
    airportPicker.buttons["Search"].tap()

    // Search for ASE
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search field should appear")
    searchField.tap()
    searchField.typeText("ASE")

    // Select KASE
    let takeoffAirportRow = app.buttons["airportRow-ASE"].firstMatch
    XCTAssertTrue(
      takeoffAirportRow.waitForExistence(timeout: 3),
      "ASE airport should appear in results"
    )
    takeoffAirportRow.tap()
    waitForNavigation()

    // Select runway
    let runwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(runwaySelector, "Runway selector should be accessible")
    runwaySelector!.tap()
    waitForNavigation()

    snapshot("03-runway-selection")

    // Select runway 33
    let takeoffRunwayRow = app.buttons["runwayRow-33"].firstMatch
    XCTAssertTrue(takeoffRunwayRow.waitForExistence(timeout: 2), "Runway 33 should appear")
    takeoffRunwayRow.tap()
    waitForNavigation()

    // Scroll to top to show all configured parameters
    app.scrollToTop()

    snapshot("02-takeoff-params")

    // Now weather selector should be available
    let weatherSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["weatherSelector"]
    )
    XCTAssertNotNil(weatherSelector, "Weather selector should be accessible")
    weatherSelector!.tap()
    waitForNavigation()

    // Screenshot the weather view with download option
    snapshot("04-weather-download")

    // Go back from weather
    app.navigationBars.buttons.element(boundBy: 0).tap()
    waitForNavigation()

    // Verify takeoff distances are displayed
    let takeoffGroundRun = app.staticTexts["takeoffGroundRunValue"]
    let takeoffDistance = app.staticTexts["takeoffDistanceValue"]

    // Scroll to bottom to show results
    let takeoffCollectionView = app.collectionViews.firstMatch
    var takeoffScrollAttempts = 0
    while takeoffScrollAttempts < 3 {
      takeoffCollectionView.swipeUp()
      Thread.sleep(forTimeInterval: 0.3)
      takeoffScrollAttempts += 1
    }

    XCTAssertTrue(
      takeoffGroundRun.waitForExistence(timeout: 2),
      "Takeoff ground run should be displayed"
    )
    XCTAssertTrue(
      takeoffDistance.waitForExistence(timeout: 2),
      "Takeoff distance should be displayed"
    )

    snapshot("05-takeoff-results")

    // Generate takeoff report
    let takeoffReportButton = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["generateTakeoffReportButton"]
    )
    XCTAssertNotNil(takeoffReportButton, "Generate takeoff report button should be accessible")
    takeoffReportButton!.tap()

    snapshot("06-takeoff-report")

    // Close the report sheet by swiping down from top
    let sheet = app.otherElements.containing(.webView, identifier: nil).firstMatch
    if sheet.exists {
      // Swipe down to dismiss
      let start = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
      let end = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
      start.press(forDuration: 0.1, thenDragTo: end)
    }

    // Wait for sheet to fully dismiss
    Thread.sleep(forTimeInterval: 2.0)

    // Navigate to Landing tab
    app.tapTab("Landing")
    waitForNavigation()

    // Configure landing parameters
    let landingPayloadField = app.textFields["payloadField"].firstMatch
    XCTAssertTrue(
      landingPayloadField.waitForExistence(timeout: 5),
      "Payload field should be accessible"
    )
    landingPayloadField.clearAndType("530", app: app)

    let landingFuelField = app.textFields["fuelField"].firstMatch
    XCTAssertTrue(landingFuelField.waitForExistence(timeout: 5), "Fuel field should be accessible")
    landingFuelField.clearAndType("75", app: app)

    // Select airport for landing
    let landingAirportSelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["airportSelector"]
    )
    XCTAssertNotNil(landingAirportSelector, "Landing airport selector should be accessible")

    // Tap and ensure navigation (may need double-tap on some devices)
    tapAndEnsureNavigation(
      element: landingAirportSelector!,
      expectedElement: app.segmentedControls["airportListPicker"]
    )
    waitForNavigation()

    // Search for ASE
    let landingAirportPicker = app.segmentedControls["airportListPicker"]
    if landingAirportPicker.waitForExistence(timeout: 2) {
      landingAirportPicker.buttons["Search"].tap()
    }

    let landingSearchField = app.searchFields.firstMatch
    if landingSearchField.waitForExistence(timeout: 2) {
      landingSearchField.tap()
      landingSearchField.typeText("ASE")
      Thread.sleep(forTimeInterval: 0.5)
    }

    // Select KASE
    let landingAirportRow = app.buttons["airportRow-ASE"].firstMatch
    if landingAirportRow.waitForExistence(timeout: 3) {
      landingAirportRow.tap()
      waitForNavigation()
    }

    // Select runway for landing
    let landingRunwaySelector = app.collectionViews.firstMatch.makeVisible(
      element: app.buttons["runwaySelector"]
    )
    XCTAssertNotNil(landingRunwaySelector, "Landing runway selector should be accessible")
    landingRunwaySelector!.tap()
    waitForNavigation()

    // Select runway 15
    let landingRunwayRow = app.buttons["runwayRow-15"].firstMatch
    if landingRunwayRow.waitForExistence(timeout: 2) {
      landingRunwayRow.tap()
      waitForNavigation()
    }

    // Scroll to top to show configured parameters
    app.scrollToTop()
    Thread.sleep(forTimeInterval: 0.5)

    snapshot("07-landing-params")

    // Verify landing distance is displayed
    let landingDistance = app.staticTexts["landingDistanceValue"]

    // Scroll to bottom to show results
    let collectionView = app.collectionViews.firstMatch
    var scrollAttempts = 0
    while scrollAttempts < 3 {
      collectionView.swipeUp()
      Thread.sleep(forTimeInterval: 0.3)
      scrollAttempts += 1
    }

    XCTAssertTrue(
      landingDistance.waitForExistence(timeout: 2),
      "Landing distance should be displayed"
    )

    snapshot("08-landing-results")

    // Generate landing report
    let landingReportButton = collectionView.makeVisible(
      element: app.buttons["generateLandingReportButton"]
    )
    XCTAssertNotNil(landingReportButton, "Generate landing report button should be accessible")
    landingReportButton!.tap()

    Thread.sleep(forTimeInterval: 1.0)
    snapshot("09-landing-report")

    // Close the report sheet by swiping down
    let landingSheet = app.otherElements.containing(.webView, identifier: nil).firstMatch
    if landingSheet.exists {
      // Swipe down to dismiss
      let start = landingSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
      let end = landingSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
      start.press(forDuration: 0.1, thenDragTo: end)
    }

    // Navigate to Climb tab
    app.tapTab("Climb")
    waitForNavigation()

    snapshot("10-climb")

    // Navigate to Settings tab
    app.tapTab("Settings")
    waitForNavigation()

    snapshot("11-settings")
  }
}
