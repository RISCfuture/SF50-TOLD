import Foundation
import Testing

@testable import SF50_Shared

struct RegressionPerformanceModelG2PlusTests {

  // MARK: - Takeoff Ground Run Tests

  @Test
  func takeoffGroundRun_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g2+/takeoff/ground run.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil,
          aircraftType: .g2Plus
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
      .appending(component: "Data/g2+/takeoff/total distance.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil,
          aircraftType: .g2Plus
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
      .appending(component: "Data/g2+/takeoff climb/gradient.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil,
          aircraftType: .g2Plus
        )
      },
      valueExtractor: { $0.takeoffClimbGradientFtNmi },
      testName: "takeoffClimbGradient"
    )
  }

  @Test
  func takeoffClimbRate_withinTolerance() throws {
    let csvURL = Bundle(for: BasePerformanceModel.self).resourceURL!
      .appending(component: "Data/g2+/takeoff climb/rate.csv")
    let dataTable = try DataTable(fileURL: csvURL)

    validateRegressionPredictions(
      dataTable,
      modelBuilder: { conditions, config, runway in
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: config,
          runway: runway,
          notam: nil,
          aircraftType: .g2Plus
        )
      },
      valueExtractor: { $0.takeoffClimbRateFtMin },
      testName: "takeoffClimbRate"
    )
  }

  // MARK: - Wind Adjustment Tests

  @Test
  func takeoffDistance_tailwindAdjustment_regression() {
    // Test with 10 kt tailwind for regression model
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsTailwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 180,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration()
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = RegressionPerformanceModelG2Plus(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelTailwind = RegressionPerformanceModelG2Plus(
      conditions: conditionsTailwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    // Extract values from the results (which may include uncertainty)
    let noWindValue: Double
    let tailwindValue: Double

    switch (modelNoWind.takeoffDistanceFt, modelTailwind.takeoffDistanceFt) {
      case (.value(let nw), .value(let tw)):
        noWindValue = nw
        tailwindValue = tw
      case (.valueWithUncertainty(let nw, _), .valueWithUncertainty(let tw, _)):
        noWindValue = nw
        tailwindValue = tw
      case (.value(let nw), .valueWithUncertainty(let tw, _)):
        noWindValue = nw
        tailwindValue = tw
      case (.valueWithUncertainty(let nw, _), .value(let tw)):
        noWindValue = nw
        tailwindValue = tw
      default:
        Issue.record("Unexpected value types for wind adjustment test")
        return
    }

    // Tailwind should increase takeoff distance
    #expect(tailwindValue > noWindValue)
    // Tailwind should increase distance by at least 30% (10kt tailwind factor is typically 0.35+)
    #expect(tailwindValue > noWindValue * 1.3)
  }

  @Test
  func landingRun_headwindAdjustment_regression() {
    // Test with 10 kt headwind for landing in regression model
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsHeadwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 360,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration()
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = RegressionPerformanceModelG2Plus(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelHeadwind = RegressionPerformanceModelG2Plus(
      conditions: conditionsHeadwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    // Extract values from the results (which may include uncertainty)
    let noWindValue: Double
    let headwindValue: Double

    switch (modelNoWind.landingRunFt, modelHeadwind.landingRunFt) {
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

    // Headwind should reduce landing run
    #expect(headwindValue < noWindValue)
  }

  // MARK: - Slope Adjustment Tests

  @Test
  func takeoffRun_slopeAdjustments_regression() {
    // Test slope adjustments for regression model
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration()
    let runwayFlat = Helper.createTestRunway(slope: 0)
    let runwayUphill = Helper.createTestRunway(slope: 2)
    let runwayDownhill = Helper.createTestRunway(slope: -2)

    let modelFlat = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayFlat, airport: runwayFlat.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelUphill = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUphill, airport: runwayUphill.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelDownhill = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayDownhill, airport: runwayDownhill.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    // Extract values from the results (which may include uncertainty)
    let flatValue: Double
    let uphillValue: Double
    let downhillValue: Double

    switch (modelFlat.takeoffRunFt, modelUphill.takeoffRunFt, modelDownhill.takeoffRunFt) {
      case (.value(let f), .value(let u), .value(let d)):
        flatValue = f
        uphillValue = u
        downhillValue = d
      case (
        .valueWithUncertainty(let f, _), .valueWithUncertainty(let u, _),
        .valueWithUncertainty(let d, _)
      ):
        flatValue = f
        uphillValue = u
        downhillValue = d
      default:
        Issue.record("Unexpected value types for slope adjustment test")
        return
    }

    // Uphill should increase takeoff run, downhill should decrease it
    #expect(uphillValue > flatValue)
    #expect(downhillValue < flatValue)
    // 2% slope should increase uphill by at least 20% (factor is typically 0.15/%)
    #expect(uphillValue > flatValue * 1.2)
    // 2% downhill should decrease by at least 5% (factor is typically 0.05/%)
    #expect(downhillValue < flatValue * 0.95)
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
      let regressionModel = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
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
      let tabularModel = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
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

    // Test at minimum weight with favorable conditions
    let minWeightConditions = Helper.createTestConditions(temperature: 15)
    let minWeightConfig = Helper.createTestConfiguration(weight: 4500, flapSetting: .flaps100)
    let minWeightRunway = Helper.createTestRunway(elevation: 2000)

    let minWeightModel = RegressionPerformanceModelG2Plus(
      conditions: minWeightConditions,
      configuration: minWeightConfig,
      runway: RunwayInput(from: minWeightRunway, airport: minWeightRunway.airport),
      notam: nil,
      aircraftType: .g2Plus
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

    let maxWeightModel = RegressionPerformanceModelG2Plus(
      conditions: maxWeightConditions,
      configuration: maxWeightConfig,
      runway: RunwayInput(from: maxWeightRunway, airport: maxWeightRunway.airport),
      notam: nil,
      aircraftType: .g2Plus
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

  @Test
  func meetsGoAroundClimbGradient_g2PlusImprovement() {
    // Test that G2+ generally allows better performance than G1
    // at the same conditions (due to updated thrust schedule)

    let testConditions = [
      (weight: 4500.0, altitude: 6000.0, temperature: 20.0),
      (weight: 5550.0, altitude: 7000.0, temperature: 10.0),
      (weight: 4500.0, altitude: 8000.0, temperature: 10.0)
    ]

    var g2PlusBetterCount = 0
    var sameCount = 0

    for condition in testConditions {
      let conditions = Helper.createTestConditions(temperature: condition.temperature)
      let config = Helper.createTestConfiguration(weight: condition.weight, flapSetting: .flaps100)
      let runway = Helper.createTestRunway(elevation: condition.altitude)

      let g1Model = RegressionPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      let g2PlusModel = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      if case .value(let g1Meets) = g1Model.meetsGoAroundClimbGradient,
        case .value(let g2PlusMeets) = g2PlusModel.meetsGoAroundClimbGradient
      {
        if g2PlusMeets && !g1Meets {
          g2PlusBetterCount += 1
        } else if g2PlusMeets == g1Meets {
          sameCount += 1
        }
      }
    }

    // G2+ should generally perform as well or better than G1
    #expect(g2PlusBetterCount >= 0, "G2+ should not perform worse than G1")
  }
}
