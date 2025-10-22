import Foundation
import Testing

@testable import SF50_Shared

@Suite("Regression Model Offscale Detection")
struct RegressionModelOffscaleTests {

  // MARK: - Landing Weight Tests

  @Test("G1 landing weight below minimum sets landingInputsOffscaleLow flag")
  func g1LandingWeightTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 3550)  // Below 4500 lbs minimum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Regression models should still return computed values, not .offscaleLow
    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    // But the flag should be set
    #expect(model.landingInputsOffscaleLow == true)
    #expect(model.landingInputsOffscaleHigh == false)
  }

  @Test("G1 landing weight above maximum sets landingInputsOffscaleHigh flag")
  func g1LandingWeightTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 5650)  // Above 5550 lbs maximum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Regression models should still return computed values, not .offscaleHigh
    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    // But the flag should be set
    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == true)
  }

  @Test("G2+ landing weight below minimum sets landingInputsOffscaleLow flag")
  func g2PlusLandingWeightTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 4000)  // Below 4500 lbs minimum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Regression models should still return computed values
    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == true)
    #expect(model.landingInputsOffscaleHigh == false)
  }

  @Test("G2+ landing weight above maximum sets landingInputsOffscaleHigh flag")
  func g2PlusLandingWeightTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 5700)  // Above 5550 lbs maximum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Regression models should still return computed values
    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == true)
  }

  // MARK: - Takeoff Weight Tests

  @Test("G1 takeoff weight below minimum sets takeoffInputsOffscaleLow flag")
  func g1TakeoffWeightTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 4800)  // Below 5000 lbs minimum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == true)
    #expect(model.takeoffInputsOffscaleHigh == false)
  }

  @Test("G1 takeoff weight above maximum sets takeoffInputsOffscaleHigh flag")
  func g1TakeoffWeightTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 6100)  // Above 6000 lbs maximum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == false)
    #expect(model.takeoffInputsOffscaleHigh == true)
  }

  @Test("G2+ takeoff weight below minimum sets takeoffInputsOffscaleLow flag")
  func g2PlusTakeoffWeightTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 4900)  // Below 5000 lbs minimum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == true)
    #expect(model.takeoffInputsOffscaleHigh == false)
  }

  @Test("G2+ takeoff weight above maximum sets takeoffInputsOffscaleHigh flag")
  func g2PlusTakeoffWeightTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 6050)  // Above 6000 lbs maximum
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == false)
    #expect(model.takeoffInputsOffscaleHigh == true)
  }

  // MARK: - Temperature Tests

  @Test("G1 landing temperature below minimum sets landingInputsOffscaleLow flag")
  func g1LandingTemperatureTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: -5)  // Below 0°C minimum for flaps 100
    let config = Helper.createTestConfiguration(weight: 5200, flapSetting: .flaps100)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == true)
    #expect(model.landingInputsOffscaleHigh == false)
  }

  @Test("G1 landing temperature above maximum sets landingInputsOffscaleHigh flag")
  func g1LandingTemperatureTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 55)  // Above 50°C maximum for flaps 100
    let config = Helper.createTestConfiguration(weight: 5200, flapSetting: .flaps100)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == true)
  }

  @Test("G1 takeoff temperature below minimum sets takeoffInputsOffscaleLow flag")
  func g1TakeoffTemperatureTooLow() throws {
    let conditions = Helper.createTestConditions(temperature: -25)  // Below -20°C minimum
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == true)
    #expect(model.takeoffInputsOffscaleHigh == false)
  }

  @Test("G1 takeoff temperature above maximum sets takeoffInputsOffscaleHigh flag")
  func g1TakeoffTemperatureTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 55)  // Above 50°C maximum
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == false)
    #expect(model.takeoffInputsOffscaleHigh == true)
  }

  // MARK: - Altitude Tests

  @Test("G1 landing altitude above maximum sets landingInputsOffscaleHigh flag")
  func g1LandingAltitudeTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 5200)
    let runway = Helper.createTestRunway(elevation: 11000)  // Above 10000 ft maximum
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == true)
  }

  @Test("G1 takeoff altitude above maximum sets takeoffInputsOffscaleHigh flag")
  func g1TakeoffAltitudeTooHigh() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway(elevation: 10500)  // Above 10000 ft maximum
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.takeoffRunFt)")
    }

    #expect(model.takeoffInputsOffscaleLow == false)
    #expect(model.takeoffInputsOffscaleHigh == true)
  }

  // MARK: - Within Bounds Tests

  @Test("G1 landing within bounds returns valid values and no offscale flags")
  func g1LandingWithinBounds() throws {
    let conditions = Helper.createTestConditions(temperature: 15)
    let config = Helper.createTestConfiguration(weight: 5200)  // Within 4500-5550 lbs
    let runway = Helper.createTestRunway(elevation: 5000)  // Within 0-10000 ft
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Should return actual values, not offscale
    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected valid value, got \(model.landingRunFt)")
    }

    switch model.landingDistanceFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected valid value, got \(model.landingDistanceFt)")
    }

    // Flags should not be set
    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == false)
  }

  @Test("G1 takeoff within bounds returns valid values and no offscale flags")
  func g1TakeoffWithinBounds() throws {
    let conditions = Helper.createTestConditions(temperature: 25)
    let config = Helper.createTestConfiguration(weight: 5500)  // Within 5000-6000 lbs
    let runway = Helper.createTestRunway(elevation: 3000)  // Within 0-10000 ft
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    // Should return actual values, not offscale
    switch model.takeoffRunFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected valid value, got \(model.takeoffRunFt)")
    }

    switch model.takeoffDistanceFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected valid value, got \(model.takeoffDistanceFt)")
    }

    // Flags should not be set
    #expect(model.takeoffInputsOffscaleLow == false)
    #expect(model.takeoffInputsOffscaleHigh == false)
  }

  // MARK: - Flap Setting Specific Tests

  @Test("G1 landing flaps 50 ice temperature bounds are different")
  func g1LandingFlaps50IceTemperatureBounds() throws {
    // Flaps 50 ice has temperature range -20°C to 10°C (different from flaps 100)
    let conditions = Helper.createTestConditions(temperature: 15)  // Above 10°C max for flaps 50 ice
    let config = Helper.createTestConfiguration(weight: 5200, flapSetting: .flaps50Ice)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected computed value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == true)
  }

  @Test("G1 landing flaps 50 ice within temperature bounds returns valid values and no flags")
  func g1LandingFlaps50IceWithinTemperatureBounds() throws {
    let conditions = Helper.createTestConditions(temperature: 5)  // Within -20°C to 10°C
    let config = Helper.createTestConfiguration(weight: 5200, flapSetting: .flaps50Ice)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let model = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil
    )

    switch model.landingRunFt {
      case .value, .valueWithUncertainty:
        break  // Expected
      case .offscaleLow, .offscaleHigh, .notAvailable, .invalid, .notAuthorized:
        Issue.record("Expected valid value, got \(model.landingRunFt)")
    }

    #expect(model.landingInputsOffscaleLow == false)
    #expect(model.landingInputsOffscaleHigh == false)
  }
}
