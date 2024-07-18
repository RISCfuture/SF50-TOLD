import XCTest

extension XCUIElement {
    func clearText() {
        press(forDuration: 1.2)
        XCUIApplication().menuItems["Select All"].tap()
        typeText(XCUIKeyboardKey.delete.rawValue)
    }
}
