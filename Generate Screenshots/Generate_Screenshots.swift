//
//  Generate_Screenshots.swift
//  Generate Screenshots
//
//  Created by Tim Morgan on 7/14/24.
//

import XCTest

final class Generate_Screenshots: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor func testScreenshots() throws {
        let app = XCUIApplication()
        let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        setupSnapshot(app, waitForAnimations: true)
        app.launch()
        
        XCTAssert(app.collectionViews.switches["g3WingToggle"].waitForExistence(timeout: 5))
        snapshot("5-welcome")
        app/*@START_MENU_TOKEN@*/.buttons["continueButton"]/*[[".buttons[\"Continue\"]",".buttons[\"continueButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        app/*@START_MENU_TOKEN@*/.buttons["downloadDataButton"]/*[[".buttons[\"Download Airport Data\"]",".buttons[\"downloadDataButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        XCTAssert(app.textFields["payloadField"].waitForExistence(timeout: 300))
        app.textFields["payloadField"].doubleTap()
        app.textFields["payloadField"].typeText("425")
        
        app.textFields["fuelField"].doubleTap()
        app.textFields["fuelField"].typeText("47")
        
        app.buttons["airportSelector"].tap()
        if springboardApp.alerts.buttons["Allow While Using App"].waitForExistence(timeout: 5) {
            springboardApp.alerts.buttons["Allow While Using App"].tap()
        }
        app/*@START_MENU_TOKEN@*/.buttons["Search"]/*[[".otherElements[\"mainTabView\"]",".segmentedControls[\"airportListPicker\"].buttons[\"Search\"]",".buttons[\"Search\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.searchFields["searchAirportsField"].tap()
        app.searchFields["searchAirportsField"].typeText("SQL")
        app.buttons.matching(identifier: "airportRow-02160.1*A").firstMatch.tap()
        
        XCTAssert(app.staticTexts["weatherSummary"].waitForExistence(timeout: 60))
        
        app.buttons["runwaySelector"].tap()
        snapshot("6-runways")
        app.buttons.matching(identifier: "runwayRow-30").firstMatch.tap()
        
        snapshot("1-takeoff")
        
        app.buttons["weatherSelector"].tap()
        snapshot("3-weather")
        app.navigationBars["Weather"].buttons["Takeoff"].tap()
        
        app/*@START_MENU_TOKEN@*/.tabBars["Tab Bar"]/*[[".otherElements[\"mainTabView\"].tabBars[\"Tab Bar\"]",".tabBars[\"Tab Bar\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Landing"].tap()
        
        app.textFields["fuelField"].doubleTap()
        app.textFields["fuelField"].typeText("24")
        
        app.buttons["airportSelector"].tap()
        app/*@START_MENU_TOKEN@*/.buttons["Search"]/*[[".otherElements[\"mainTabView\"]",".segmentedControls[\"airportListPicker\"].buttons[\"Search\"]",".buttons[\"Search\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.searchFields["searchAirportsField"].tap()
        app.searchFields["searchAirportsField"].typeText("SEZ")
        app.buttons.matching(identifier: "airportRow-00788.3*A").firstMatch.tap()
        
        app.buttons["runwaySelector"].tap()
        app.buttons.matching(identifier: "runwayRow-03").firstMatch.tap()
        
        app.buttons["NOTAMsSelector"].tap()
        
        app.textFields["distanceField"].doubleTap()
        app.textFields["distanceField"].typeText("250")
        app.switches["wetToggle"].tap()
        snapshot("4-notams")
        
        app.navigationBars["NOTAMs"].buttons["Landing"].tap()
        snapshot("2-landing")
        
        app/*@START_MENU_TOKEN@*/.tabBars["Tab Bar"]/*[[".otherElements[\"mainTabView\"].tabBars[\"Tab Bar\"]",".tabBars[\"Tab Bar\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Settings"].tap()
        snapshot("7-settings")
    }
}
