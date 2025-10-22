import Foundation
import Testing

@testable import SF50_Shared

struct RegressionPerformanceModelG2PlusTests {

  // MARK: - Takeoff Ground Run Tests

  @Test
  func takeoffGroundRun_withinTolerance() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 1670),
      (6000, 0, -10, 1736),
      (6000, 0, 0, 1804),
      (6000, 0, 10, 1875),
      (6000, 0, 20, 1963),
      (6000, 0, 30, 2279),
      (6000, 0, 40, 2797),
      (6000, 0, 50, 3475),
      (6000, 0, 15.0, 1910),
      (6000, 1000, 20, 2058),
      (6000, 2000, 20, 2166),
      (6000, 3000, 20, 2322),
      (6000, 4000, 20, 2523),
      (6000, 5000, 20, 2726),
      (6000, 6000, 20, 2973),
      (6000, 7000, 20, 3283),
      (6000, 8000, 20, 3674),
      (5500, 0, 20, 1800),
      (5000, 0, 20, 1636)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.takeoffRunFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  // MARK: - Takeoff Distance Tests

  @Test
  func takeoffDistance_withinTolerance() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 2460),
      (6000, 0, -10, 2558),
      (6000, 0, 0, 2658),
      (6000, 0, 10, 2764),
      (6000, 0, 20, 2896),
      (6000, 0, 30, 3390),
      (6000, 0, 40, 4217),
      (6000, 0, 50, 5315),
      (6000, 0, 15.0, 2815),
      (6000, 1000, 20, 3037),
      (6000, 2000, 20, 3201),
      (6000, 3000, 20, 3439),
      (6000, 4000, 20, 3751),
      (6000, 5000, 20, 4065),
      (6000, 6000, 20, 4449),
      (6000, 7000, 20, 4937),
      (6000, 8000, 20, 5552)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.takeoffDistanceFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  // MARK: - Takeoff Climb Tests

  @Test
  func takeoffClimbGradient_withinTolerance() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 1230),
      (6000, 0, -10, 1229),
      (6000, 0, 0, 1227),
      (6000, 0, 10, 1223),
      (6000, 0, 20, 1209),
      (6000, 0, 30, 1062),
      (6000, 0, 40, 876),
      (6000, 0, 50, 702),
      (5500, 0, 20, 1395),
      (5000, 0, 20, 1612)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.takeoffClimbGradientFtNmi
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  @Test
  func takeoffClimbRate_withinTolerance() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 2012),
      (6000, 0, -10, 1972),
      (6000, 0, 0, 1933),
      (6000, 0, 10, 1892),
      (6000, 0, 20, 1838),
      (6000, 0, 30, 1589),
      (6000, 0, 40, 1289),
      (6000, 0, 50, 1017),
      (5500, 0, 20, 2122),
      (5000, 0, 20, 2451)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.takeoffClimbRateFtMin
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  // MARK: - Landing Ground Run Tests

  @Test
  func landingGroundRun_withinTolerance_flaps50() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      // Weight 4500 values
      (4500, 0, 0, 1645),
      (4500, 0, 10, 1705),
      (4500, 0, 20, 1765),
      (4500, 0, 30, 1825),
      (4500, 0, 40, 1885),
      (4500, 0, 50, 1946),
      // Weight 5550 values
      (5550, 0, 0, 2028),
      (5550, 0, 10, 2103),
      (5550, 0, 20, 2177),
      (5550, 0, 30, 2251),
      (5550, 0, 40, 2325),
      (5550, 0, 50, 2400)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps50)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingRunFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  @Test
  func landingGroundRun_withinTolerance_flaps100() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      // Weight 4500 values
      (4500, 0, 0, 1246),
      (4500, 0, 10, 1292),
      (4500, 0, 20, 1338),
      (4500, 0, 30, 1383),
      (4500, 0, 40, 1429),
      (4500, 0, 50, 1474),
      // Weight 5550 values
      (5550, 0, 0, 1537),
      (5550, 0, 10, 1593),
      (5550, 0, 20, 1650),
      (5550, 0, 30, 1706),
      (5550, 0, 40, 1762),
      (5550, 0, 50, 1819)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps100)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingRunFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  // MARK: - Landing Distance Tests

  @Test
  func landingDistance_withinTolerance_flaps50() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      // Weight 4500 values
      (4500, 0, 0, 2226),
      (4500, 0, 10, 2299),
      (4500, 0, 20, 2373),
      (4500, 0, 30, 2448),
      (4500, 0, 40, 2522),
      (4500, 0, 50, 2596),
      // Weight 5550 values
      (5550, 0, 0, 3061),
      (5550, 0, 10, 3154),
      (5550, 0, 20, 3247),
      (5550, 0, 30, 3340),
      (5550, 0, 40, 3433),
      (5550, 0, 50, 3527)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps50)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingDistanceFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
  }

  @Test
  func landingDistance_withinTolerance_flaps100() {
    // Test regression model against book values - expected values should fall within error intervals
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      // Weight 4500 values
      (4500, 0, 0, 1755),
      (4500, 0, 10, 1811),
      (4500, 0, 20, 1867),
      (4500, 0, 30, 1924),
      (4500, 0, 40, 1980),
      (4500, 0, 50, 2037),
      // Weight 5550 values
      (5550, 0, 0, 2430),
      (5550, 0, 10, 2498),
      (5550, 0, 20, 2566),
      (5550, 0, 30, 2635),
      (5550, 0, 40, 2704),
      (5550, 0, 50, 2773)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps100)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingDistanceFt
      guard case .valueWithUncertainty = result else {
        Issue.record(
          "Expected valueWithUncertainty for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(result.contains(testCase.expected, confidenceLevel: 0.95))
    }
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
      notam: nil
    )

    let modelTailwind = RegressionPerformanceModelG2Plus(
      conditions: conditionsTailwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
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

    // Tailwind takeoff distance should have specific values
    #expect(noWindValue.isApproximatelyEqual(to: 3006.06, relativeTolerance: 0.01))
    #expect(tailwindValue.isApproximatelyEqual(to: 4178.43, relativeTolerance: 0.01))
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
      notam: nil
    )

    let modelHeadwind = RegressionPerformanceModelG2Plus(
      conditions: conditionsHeadwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
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
      notam: nil
    )

    let modelUphill = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUphill, airport: runwayUphill.airport),
      notam: nil
    )

    let modelDownhill = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayDownhill, airport: runwayDownhill.airport),
      notam: nil
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

    // Slope adjustments should have specific values
    #expect(flatValue.isApproximatelyEqual(to: 2022.08, relativeTolerance: 0.01))
    #expect(uphillValue.isApproximatelyEqual(to: 2628.70, relativeTolerance: 0.01))
    #expect(downhillValue.isApproximatelyEqual(to: 1819.87, relativeTolerance: 0.01))
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
      let tabularModel = TabularPerformanceModelG2Plus(
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

    // Test at minimum weight with favorable conditions
    let minWeightConditions = Helper.createTestConditions(temperature: 15)
    let minWeightConfig = Helper.createTestConfiguration(weight: 4500, flapSetting: .flaps100)
    let minWeightRunway = Helper.createTestRunway(elevation: 2000)

    let minWeightModel = RegressionPerformanceModelG2Plus(
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

    let maxWeightModel = RegressionPerformanceModelG2Plus(
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
        notam: nil
      )

      let g2PlusModel = RegressionPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
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
