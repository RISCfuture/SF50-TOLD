import Foundation
import Testing

@testable import SF50_Shared

struct RegressionPerformanceModelG1Tests {

  // MARK: - Takeoff Ground Run Tests

  @Test
  func takeoffGroundRun_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/takeoff/ground run.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.takeoffRunFt },
      testName: "takeoffGroundRun"
    )
  }

  // MARK: - Takeoff Distance Tests

  @Test
  func takeoffDistance_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/takeoff/total distance.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.takeoffDistanceFt },
      testName: "takeoffDistance"
    )
  }

  // MARK: - Takeoff Climb Tests

  @Test
  func takeoffClimbGradient_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/takeoff climb/gradient.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.takeoffClimbGradientFtNmi },
      testName: "takeoffClimbGradient"
    )
  }

  @Test
  func takeoffClimbRate_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/takeoff climb/rate.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.takeoffClimbRateFtMin },
      testName: "takeoffClimbRate"
    )
  }

  // MARK: - VREF Tests

  @Test
  func vref_withinTolerance() throws {
    // Test VREF values for different flap settings against DataTable values
    let baseURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/vref")

    let flapConfigs: [(file: String, flapSetting: FlapSetting)] = [
      ("50.csv", .flaps50),
      ("100.csv", .flaps100),
      ("up.csv", .flapsUp),
      ("50 ice.csv", .flaps50Ice),
      ("up ice.csv", .flapsUpIce)
    ]

    for config in flapConfigs {
      let csvURL = baseURL.appending(component: config.file)
      let dataTable = try DataTable(fileURL: csvURL)

      for row in dataTable.rows {
        let inputs = dataTable.inputs(from: row)
        let expected = dataTable.output(from: row)

        let weight = inputs[0]

        let conditions = Helper.createTestConditions()
        let testConfig = Helper.createTestConfiguration(
          weight: weight,
          flapSetting: config.flapSetting
        )
        let runway = Helper.createTestRunway()

        let model = RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: testConfig,
          runway: RunwayInput(from: runway, airport: runway.airport),
          notam: nil
        )

        let result = model.VrefKts

        // Vref is a simple linear formula, not a regression model, so it must return a plain value
        guard case .value(let value) = result else {
          Issue.record("Vref should return a plain value, got \(result)")
          continue
        }

        // Check that the value is within 2% tolerance of expected
        #expect(value.isApproximatelyEqual(to: expected, relativeTolerance: 0.02))
      }
    }
  }

  // MARK: - Landing Ground Run Tests

  @Test
  func landingGroundRun_withinTolerance_flaps50() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/landing/50/ground run.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, flapSetting: .flaps50)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.landingRunFt },
      testName: "landingGroundRun_flaps50"
    )
  }

  @Test
  func landingGroundRun_withinTolerance_flaps100() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/landing/100/ground run.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, flapSetting: .flaps100)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.landingRunFt },
      testName: "landingGroundRun_flaps100"
    )
  }

  // MARK: - Landing Distance Tests

  @Test
  func landingDistance_withinTolerance_flaps50() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/landing/50/total distance.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, flapSetting: .flaps50)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.landingDistanceFt },
      testName: "landingDistance_flaps50"
    )
  }

  @Test
  func landingDistance_withinTolerance_flaps100() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/landing/100/total distance.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, flapSetting: .flaps100)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.landingDistanceFt },
      testName: "landingDistance_flaps100"
    )
  }

  // MARK: - Enroute Climb Tests - Normal

  @Test
  func enrouteClimbGradient_normal_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/normal/gradient.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, iceProtection: false)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbGradientFtNmi },
      testName: "enrouteClimbGradient_normal"
    )
  }

  @Test
  func enrouteClimbRate_normal_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/normal/rate.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, iceProtection: false)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbRateFtMin },
      testName: "enrouteClimbRate_normal"
    )
  }

  @Test
  func enrouteClimbSpeed_normal_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/normal/speed.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in
        Helper.createTestConfiguration(weight: weight, iceProtection: false)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbSpeedKIAS },
      testName: "enrouteClimbSpeed_normal"
    )
  }

  // MARK: - Enroute Climb Tests - Ice Contaminated

  @Test
  func enrouteClimbGradient_iceContaminated_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/ice contaminated/gradient.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in Helper.createTestConfiguration(weight: weight, iceProtection: true)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbGradientFtNmi },
      testName: "enrouteClimbGradient_iceContaminated"
    )
  }

  @Test
  func enrouteClimbRate_iceContaminated_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/ice contaminated/rate.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in Helper.createTestConfiguration(weight: weight, iceProtection: true)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbRateFtMin },
      testName: "enrouteClimbRate_iceContaminated"
    )
  }

  @Test
  func enrouteClimbSpeed_iceContaminated_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/enroute climb/ice contaminated/speed.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      configBuilder: { weight in Helper.createTestConfiguration(weight: weight, iceProtection: true)
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.enrouteClimbSpeedKIAS },
      testName: "enrouteClimbSpeed_iceContaminated"
    )
  }

  // MARK: - Time/Fuel/Distance to Climb Tests

  @Test
  func timeToClimb_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/time fuel distance to climb/time.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.timeToClimbMin },
      testName: "timeToClimb"
    )
  }

  @Test
  func fuelToClimb_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/time fuel distance to climb/fuel.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.fuelToClimbUsGal },
      testName: "fuelToClimb"
    )
  }

  @Test
  func distanceToClimb_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g1/time fuel distance to climb/distance.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      inputExtractor: { inputs in (weight: inputs[2], altitude: inputs[0], temperature: inputs[1])
      },
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil
        )
      },
      valueExtractor: { $0.distanceToClimbNm },
      testName: "distanceToClimb"
    )
  }

  // MARK: - Wind Adjustment Tests

  @Test
  func takeoffRun_headwindAdjustment_regression() {
    // Test with 10 kt headwind for regression model
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsHeadwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 360,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration()
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = RegressionPerformanceModelG1(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    let modelHeadwind = RegressionPerformanceModelG1(
      conditions: conditionsHeadwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    // Extract values from the results (which may include uncertainty)
    let noWindValue: Double
    let headwindValue: Double

    switch (modelNoWind.takeoffRunFt, modelHeadwind.takeoffRunFt) {
      case (.value(let nw), .value(let hw)):
        noWindValue = nw
        headwindValue = hw
      case (.valueWithUncertainty(let nw, _), .valueWithUncertainty(let hw, _)):
        noWindValue = nw
        headwindValue = hw
      case (.value(let nw), .valueWithUncertainty(let hw, _)):
        noWindValue = nw
        headwindValue = hw
      case (.valueWithUncertainty(let nw, _), .value(let hw)):
        noWindValue = nw
        headwindValue = hw
      default:
        Issue.record("Unexpected value types for wind adjustment test")
        return
    }

    // Headwind should reduce takeoff run
    #expect(headwindValue < noWindValue)
  }

  @Test
  func landingDistance_unpavedAdjustment_regression() {
    // Test unpaved runway adjustment for regression model
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration()
    let runwayPaved = Helper.createTestRunway(isTurf: false)
    let runwayUnpaved = Helper.createTestRunway(isTurf: true)

    let modelPaved = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayPaved, airport: runwayPaved.airport),
      notam: nil
    )

    let modelUnpaved = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUnpaved, airport: runwayUnpaved.airport),
      notam: nil
    )

    // Extract values from the results (which may include uncertainty)
    let pavedValue: Double
    let unpavedValue: Double

    switch (modelPaved.landingDistanceFt, modelUnpaved.landingDistanceFt) {
      case (.value(let pv), .value(let uv)):
        pavedValue = pv
        unpavedValue = uv
      case (.valueWithUncertainty(let pv, _), .valueWithUncertainty(let uv, _)):
        pavedValue = pv
        unpavedValue = uv
      case (.value(let pv), .valueWithUncertainty(let uv, _)):
        pavedValue = pv
        unpavedValue = uv
      case (.valueWithUncertainty(let pv, _), .value(let uv)):
        pavedValue = pv
        unpavedValue = uv
      default:
        Issue.record("Unexpected value types for surface adjustment test")
        return
    }

    // Unpaved landing distance should have specific value
    #expect(pavedValue.isApproximatelyEqual(to: 3686.74, relativeTolerance: 0.01))
    #expect(unpavedValue.isApproximatelyEqual(to: 4424.08, relativeTolerance: 0.01))
  }

  // MARK: - Go-Around Climb Gradient Tests

  @Test
  func meetsGoAroundClimbGradient_matchesTabularOffscale() {
    // Test that regression model's meetsGoAroundClimbGradient aligns with
    // tabular model's offscale behavior for landing distance

    let testCases:
      [(
        weight: Double, altitude: Double, temperature: Double, flapSetting: FlapSetting,
        expectedMeets: Bool
      )] = [
        // Cases where tabular model should NOT be offscale (gradient should be met)
        // Using only exact data points (weights 4500 or 5550, altitudes in 1000 ft increments, temps in 10°C increments)
        (4500, 0, 20, .flaps100, true),
        (4500, 2000, 20, .flaps100, true),
        (4500, 5000, 10, .flaps100, true),
        (5550, 0, 20, .flaps100, true),
        (5550, 3000, 0, .flaps100, true),

        // Cases near the edge but still within data bounds
        (5550, 7000, 20, .flaps100, true),  // Max temp at 7000 ft is 20°C for weight 5550
        (5550, 8000, 20, .flaps100, true),  // Max temp at 8000 ft is 20°C for weight 5550
        (4500, 7000, 30, .flaps100, true)  // Weight 4500 has data at 7000 ft, 30°C
      ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(
        weight: testCase.weight,
        flapSetting: testCase.flapSetting
      )
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      // Test regression model
      let regressionModel = RegressionPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let regressionResult = regressionModel.meetsGoAroundClimbGradient

      guard case .value(let meetsGradient) = regressionResult else {
        Issue.record(
          "Expected .value for regression model at weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature)"
        )
        continue
      }

      #expect(
        meetsGradient == testCase.expectedMeets,
        "Weight: \(testCase.weight), Alt: \(testCase.altitude), Temp: \(testCase.temperature), Flaps: \(testCase.flapSetting) - Expected: \(testCase.expectedMeets), Got: \(meetsGradient)"
      )

      // Also verify against tabular model
      let tabularModel = TabularPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let tabularLandingDistance = tabularModel.landingDistanceFt
      let tabularGoAround = tabularModel.meetsGoAroundClimbGradient

      // When tabular landing distance is offscale high, go-around should be false
      if case .offscaleHigh = tabularLandingDistance {
        guard case .value(false) = tabularGoAround else {
          Issue.record(
            "Tabular model should return false for go-around when landing distance is offscale high"
          )
          continue
        }
      }

      // Regression and tabular should generally agree
      if case .value(let tabularMeets) = tabularGoAround {
        #expect(
          meetsGradient == tabularMeets,
          "Regression and tabular models disagree at weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature)"
        )
      }
    }
  }

  @Test
  func meetsGoAroundClimbGradient_boundaryConditions() {
    // Test boundary conditions for the go-around climb gradient

    // Test at minimum weight
    let minWeightConditions = Helper.createTestConditions(temperature: 15)
    let minWeightConfig = Helper.createTestConfiguration(weight: 4500, flapSetting: .flaps100)
    let minWeightRunway = Helper.createTestRunway(elevation: 2000)

    let minWeightModel = RegressionPerformanceModelG1(
      conditions: minWeightConditions,
      configuration: minWeightConfig,
      runway: RunwayInput(from: minWeightRunway, airport: minWeightRunway.airport),
      notam: nil
    )

    guard case .value(let minWeightMeets) = minWeightModel.meetsGoAroundClimbGradient else {
      Issue.record("Expected .value for minimum weight test")
      return
    }
    #expect(
      minWeightMeets == true,
      "Should meet gradient at minimum weight with moderate conditions"
    )

    // Test at maximum weight with challenging conditions
    let maxWeightConditions = Helper.createTestConditions(temperature: 45)
    let maxWeightConfig = Helper.createTestConfiguration(weight: 6000, flapSetting: .flaps100)
    let maxWeightRunway = Helper.createTestRunway(elevation: 9000)

    let maxWeightModel = RegressionPerformanceModelG1(
      conditions: maxWeightConditions,
      configuration: maxWeightConfig,
      runway: RunwayInput(from: maxWeightRunway, airport: maxWeightRunway.airport),
      notam: nil
    )

    guard case .value(let maxWeightMeets) = maxWeightModel.meetsGoAroundClimbGradient else {
      Issue.record("Expected .value for maximum weight test")
      return
    }
    #expect(
      maxWeightMeets == false,
      "Should not meet gradient at maximum weight with challenging conditions"
    )
  }
}
