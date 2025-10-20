import XCTest

extension XCUIElement {
  var isVisible: Bool {
    guard self.exists && !self.frame.isEmpty else { return false }
    return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
  }

  func toggleOn() {
    guard switches["0"].exists else { return }
    switches["0"].firstMatch.tap()
  }

  func toggleOff() {
    guard switches["1"].exists else { return }
    switches["1"].firstMatch.tap()
  }

  func makeVisible(element: XCUIElement) -> XCUIElement? {
    if self.elementType == .scrollView || self.elementType == .collectionView
      || self.elementType == .table
    {
      let visible = self.scroll(to: element) || self.swipe(to: element)
      return visible ? element : nil
    }
    return self.swipe(to: element) ? element : nil
  }

  // Use the collection view's scrollToItem method via coordinate-based scrolling
  private func scroll(to element: XCUIElement) -> Bool {
    var attempts = 0

    while !element.isVisible && attempts < 10 {
      let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
      let endCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
      startCoordinate.press(forDuration: 0.01, thenDragTo: endCoordinate)
      attempts += 1
    }

    return element.isVisible
  }

  // Fallback to swipe-based scrolling with limits
  private func swipe(to element: XCUIElement) -> Bool {
    var attempts = 0

    while !element.isVisible && attempts < 10 {
      swipeUp()
      attempts += 1
    }

    return element.isVisible
  }
}

extension XCUIApplication {
  func scrollToTop() {
    let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    for bar in springboardApp.statusBars.allElementsBoundByIndex { bar.tap() }
  }

  // Tap tab by label (works on both iPhone tab bar and iPad top tabs)
  func tapTab(_ label: String) {
    // Try tab bar first (iPhone)
    if tabBars.buttons[label].exists {
      tabBars.buttons[label].tap()
    } else {
      // Fall back to direct button (iPad) - use firstMatch to handle duplicates
      buttons[label].firstMatch.tap()
    }
  }
}

// Helper function for clearing and typing text in fields
extension XCUIElement {
  func clearAndType(_ text: String, app: XCUIApplication) {
    tap()

    // Wait a moment for field to be focused and keyboard/popover to appear
    Thread.sleep(forTimeInterval: 0.2)

    // Dismiss keyboard popover on iPad if present
    if app.otherElements["PopoverDismissRegion"].exists {
      app.otherElements["PopoverDismissRegion"].tap()
    }

    // Triple tap to select all
    tap(withNumberOfTaps: 3, numberOfTouches: 1)

    // Small delay for selection
    Thread.sleep(forTimeInterval: 0.1)

    // Type new text (will replace selection)
    typeText(text)
  }
}

// Helper for waiting
func waitForNavigation() {
  Thread.sleep(forTimeInterval: 0.5)
}

// Helper to tap element and ensure navigation occurred
@MainActor
func tapAndEnsureNavigation(
  element: XCUIElement,
  expectedElement: XCUIElement,
  timeout: TimeInterval = 2
) {
  element.tap()

  // If expected element doesn't appear, tap again (needed on some devices)
  if !expectedElement.waitForExistence(timeout: timeout) {
    element.tap()
  }
}
