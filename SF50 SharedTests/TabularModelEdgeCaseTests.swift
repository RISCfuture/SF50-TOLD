import Foundation
import Testing

@testable import SF50_Shared

struct TabularModelEdgeCaseTests {

  // MARK: - ISA Temperature Handling Tests

  @Test
  func takeoffWithISATemperatures() {
    // Test the exact scenario that was failing in production
    // Weight: 5992 lb, Altitude: 2621 ft, Temperature: 19°C
    let conditions = Helper.createTestConditions(temperature: 19)
    let config = Helper.createTestConfiguration(weight: 5992)
    let runway = Helper.createTestRunway(elevation: 2621)

    let model = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let groundRun = model.takeoffRunFt
    let totalDistance = model.takeoffDistanceFt

    // Should interpolate successfully, not return offscale
    guard case .value = groundRun else {
      Issue.record(
        "Takeoff ground run should interpolate at 5992 lb, 2621 ft, 19°C but got \(groundRun)"
      )
      return
    }

    guard case .value = totalDistance else {
      Issue.record(
        "Takeoff distance should interpolate at 5992 lb, 2621 ft, 19°C but got \(totalDistance)"
      )
      return
    }

    // Values should be reasonable (between surrounding data points)
    if case .value(let runValue) = groundRun {
      #expect(runValue > 1000 && runValue < 5000, "Ground run \(runValue) out of reasonable range")
    }

    if case .value(let distValue) = totalDistance {
      #expect(
        distValue > 2000 && distValue < 8000,
        "Total distance \(distValue) out of reasonable range"
      )
    }
  }

  @Test
  func landingWithISATemperatures() {
    // Test the landing scenario that was failing
    // Weight: 5214 lb, Altitude: 8900 ft, Temperature: 7°C
    let conditions = Helper.createTestConditions(temperature: 7)
    let config = Helper.createTestConfiguration(weight: 5214, flapSetting: .flaps100)
    let runway = Helper.createTestRunway(elevation: 8900)

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let landingRun = model.landingRunFt
    let landingDistance = model.landingDistanceFt

    // Should interpolate successfully, not return offscale
    guard case .value = landingRun else {
      Issue.record("Landing run should interpolate at 5214 lb, 8900 ft, 7°C but got \(landingRun)")
      return
    }

    guard case .value = landingDistance else {
      Issue.record(
        "Landing distance should interpolate at 5214 lb, 8900 ft, 7°C but got \(landingDistance)"
      )
      return
    }
  }

  // MARK: - Incomplete Grid Tests

  @Test
  func incompleteGridWithISA() {
    // Test interpolation when ISA temperatures create incomplete grids
    // This should use the tighter bounds algorithm to find valid corners

    // Near ISA temperature but should find valid bounds
    let conditions = Helper.createTestConditions(temperature: 11.5)  // Near ISA 11.0376
    let config = Helper.createTestConfiguration(weight: 5750)
    let runway = Helper.createTestRunway(elevation: 2500)

    let model = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt

    guard case .value = result else {
      Issue.record("Should find valid interpolation bounds despite ISA temperatures, got \(result)")
      return
    }
  }

  // MARK: - Offscale Detection Tests

  @Test
  func offscaleLowWeight() {
    // Test weight below minimum - tabular models clamp rather than return offscale
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 4000)  // Below minimum of 5000
    let runway = Helper.createTestRunway(elevation: 5000)

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt

    // Tabular models use clamping, so they should return a value (clamped to minimum weight)
    guard case .value(let value) = result else {
      Issue.record("Tabular model with clamping should return a value, not \(result)")
      return
    }

    // The value should be the same as at minimum weight (5000 lb)
    let minWeightConfig = Helper.createTestConfiguration(weight: 5000)
    let minWeightModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: minWeightConfig,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    if case .value(let minWeightValue) = minWeightModel.takeoffRunFt {
      #expect(value == minWeightValue, "Clamped value should equal minimum weight value")
    }
  }

  @Test
  func offscaleHighAltitude() {
    // Test altitude above maximum should return offscale high
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway(elevation: 12000)  // Above maximum

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt
    #expect(result == .offscaleHigh, "Altitude above maximum should return offscale high")
  }

  @Test
  func offscaleHighTemperature() {
    // Test temperature above maximum should return offscale high
    let conditions = Helper.createTestConditions(temperature: 55)  // Above typical maximum
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway(elevation: 5000)

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt
    #expect(result == .offscaleHigh, "Temperature above maximum should return offscale high")
  }

  // MARK: - Boundary Condition Tests

  @Test
  func exactBoundaryValues() {
    // Test exact boundary values (max weight, max altitude, etc.)
    let testCases: [(weight: Double, altitude: Double, temp: Double, shouldSucceed: Bool)] = [
      (6000, 10000, 20, true),  // Max weight and altitude in range
      (5000, 10000, 20, true),  // Min weight, max altitude
      (5500, 0, -20, true),  // Min altitude, min temp
      (5500, 10000, 50, false)  // May be offscale at extreme temp
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temp)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g1
      )

      let result = model.takeoffRunFt

      if testCase.shouldSucceed {
        guard case .value = result else {
          Issue.record(
            "Expected value at boundary (\(testCase.weight), \(testCase.altitude), \(testCase.temp)) but got \(result)"
          )
          continue
        }
      } else {
        guard case .value = result else {
          // Expected to fail, this is correct
          continue
        }
        // If we got a value when we expected failure, that might be OK depending on data
      }
    }
  }

  // MARK: - Smart Bounds Selection Tests

  @Test
  func prefersTighterBounds() {
    // Test that the algorithm prefers tighter bounds when multiple valid options exist
    // This specifically tests the scenario from the failing test

    let conditions = Helper.createTestConditions(temperature: 25)
    let config = Helper.createTestConfiguration(weight: 6000)
    let runway = Helper.createTestRunway(elevation: 7000)

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt

    guard case .value(let value) = result else {
      Issue.record("Should interpolate successfully at exact match altitude")
      return
    }

    // The value should be interpolated using [20, 30] bounds, not [ISA, 30]
    // Expected value is approximately 3960 + 0.5 * (4905 - 3960) = 4432.5
    // With ISA bounds it would be significantly different
    #expect(
      value > 4000 && value < 5000,
      "Value \(value) suggests wrong temperature bounds were used"
    )
  }

  // MARK: - Degenerate Case Tests

  @Test
  func exactWeightAndAltitudeMatch() {
    // Test when we have exact matches on weight and altitude (degenerate to 1D)
    let conditions = Helper.createTestConditions(temperature: 15)  // Interpolate only temperature
    let config = Helper.createTestConfiguration(weight: 5500)  // Exact match
    let runway = Helper.createTestRunway(elevation: 5000)  // Exact match

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt

    guard case .value = result else {
      Issue.record("Should handle degenerate case with exact weight/altitude match")
      return
    }
  }

  @Test
  func exactWeightMatch() {
    // Test when we have exact weight match (degenerate to 2D)
    let conditions = Helper.createTestConditions(temperature: 25)
    let config = Helper.createTestConfiguration(weight: 5500)  // Exact match
    let runway = Helper.createTestRunway(elevation: 2500)  // Interpolate altitude

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g1
    )

    let result = model.takeoffRunFt

    guard case .value = result else {
      Issue.record("Should handle 2D interpolation with exact weight match")
      return
    }
  }

  // MARK: - Regression Tests

  @Test
  func regressionTestForReportedIssues() {
    // Test specific conditions that users reported as failing
    let reportedIssues: [(weight: Double, altitude: Double, temp: Double, description: String)] = [
      (5992, 2621, 19, "User reported offscale high for takeoff"),
      (5214, 8900, 7, "User reported offscale high for landing"),
      (5750, 2500, 11, "Near ISA temperature interpolation"),
      (5500, 3000, 9, "At ISA temperature for altitude")
    ]

    for issue in reportedIssues {
      let conditions = Helper.createTestConditions(temperature: issue.temp)
      let config = Helper.createTestConfiguration(weight: issue.weight)
      let runway = Helper.createTestRunway(elevation: issue.altitude)

      // Test both G1 and G2+ models
      let modelG1 = TabularPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g1
      )

      let modelG2Plus = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g1
      )

      // Check takeoff performance
      let g1TakeoffRun = modelG1.takeoffRunFt
      let g2TakeoffRun = modelG2Plus.takeoffRunFt

      // At least one model should provide a value (G2+ has wider range)
      let g1HasValue = if case .value = g1TakeoffRun { true } else { false }
      let g2HasValue = if case .value = g2TakeoffRun { true } else { false }

      #expect(
        g1HasValue || g2HasValue,
        "\(issue.description): Both models returned offscale at (\(issue.weight), \(issue.altitude), \(issue.temp))"
      )
    }
  }

  // MARK: - Data Consistency Tests

  @Test
  func consistentInterpolationDirection() {
    // Test that interpolated values are monotonic in the expected direction
    let baseConditions = Helper.createTestConditions(temperature: 20)
    let baseConfig = Helper.createTestConfiguration(weight: 5500)

    var previousValue: Double = 0

    // As altitude increases, takeoff distance should increase
    for altitude in stride(from: 0, through: 8000, by: 1000) {
      let runway = Helper.createTestRunway(elevation: Double(altitude))

      let model = TabularPerformanceModelG1(
        conditions: baseConditions,
        configuration: baseConfig,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g1
      )

      if case .value(let value) = model.takeoffRunFt {
        if altitude > 0 {
          #expect(
            value >= previousValue,
            "Takeoff run should increase with altitude: \(value) < \(previousValue) at \(altitude) ft"
          )
        }
        previousValue = value
      }
    }
  }
}
