import Foundation
import Testing

@testable import SF50_Shared

struct TabularPerformanceModelG2PlusTests {

  // MARK: - Takeoff Ground Run Tests

  @Test
  func takeoffGroundRun_exactMatch() {
    // Test exact values from g2+/takeoff/ground run.csv (after removing ISA values)
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 1670),
      (6000, 0, -10, 1736),
      (6000, 0, 0, 1804),
      (6000, 0, 10, 1875),
      (6000, 0, 20, 1963),
      (6000, 0, 30, 2279),
      (6000, 0, 40, 2797),
      (6000, 0, 50, 3475),
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      let result = model.takeoffRunFt
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  @Test
  func takeoffGroundRun_interpolation() {
    // Test interpolation between known values
    let conditions = Helper.createTestConditions(temperature: 25)  // Between 20 and 30
    let config = Helper.createTestConfiguration(weight: 5750)  // Between 5500 and 6000
    let runway = Helper.createTestRunway(elevation: 500)  // Between 0 and 1000

    let model = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let result = model.takeoffRunFt
    guard case .value(let value) = result else {
      Issue.record("Expected interpolated value, got \(result)")
      return
    }

    // Value should be between the surrounding values
    #expect(value > 1602)  // 5500 lb at 0 ft, 20°C
    #expect(value < 2625)  // 6000 lb at 3000 ft, 20°C
  }

  // MARK: - Takeoff Distance Tests

  @Test
  func takeoffDistance_exactMatch() {
    // Test exact values from g2+/takeoff/total distance.csv (after removing ISA values)
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 2460),
      (6000, 0, -10, 2558),
      (6000, 0, 0, 2658),
      (6000, 0, 10, 2764),
      (6000, 0, 20, 2896),
      (6000, 0, 30, 3390),
      (6000, 0, 40, 4217),
      (6000, 0, 50, 5315),
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      let result = model.takeoffDistanceFt
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  // MARK: - Takeoff Climb Tests

  @Test
  func takeoffClimbGradient_exactMatch() {
    // Test exact values from g2+/takeoff climb/gradient.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      let result = model.takeoffClimbGradientFtNmi
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  @Test
  func takeoffClimbRate_exactMatch() {
    // Test exact values from g2+/takeoff climb/rate.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil,
        aircraftType: .g2Plus
      )

      let result = model.takeoffClimbRateFtMin
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  // MARK: - Wind Adjustment Tests

  @Test
  func takeoffRun_headwindAdjustment() {
    // Test with 10 kt headwind
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsHeadwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 360,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration()
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = TabularPerformanceModelG2Plus(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelHeadwind = TabularPerformanceModelG2Plus(
      conditions: conditionsHeadwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .value(let noWindValue) = modelNoWind.takeoffRunFt,
      case .value(let headwindValue) = modelHeadwind.takeoffRunFt
    else {
      Issue.record("Expected values for wind adjustment test")
      return
    }

    // Headwind should reduce takeoff run
    #expect(headwindValue < noWindValue)
  }

  @Test
  func landingRun_tailwindAdjustment() {
    // Test with 10 kt tailwind for landing
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsTailwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 180,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = TabularPerformanceModelG2Plus(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelTailwind = TabularPerformanceModelG2Plus(
      conditions: conditionsTailwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .value(let noWindValue) = modelNoWind.landingRunFt,
      case .value(let tailwindValue) = modelTailwind.landingRunFt
    else {
      Issue
        .record(
          "Expected values for wind adjustment test, got modelNoWind = \(modelNoWind.landingRunFt), modelTailwind = \(modelTailwind.landingRunFt)"
        )
      return
    }

    // Tailwind landing run should have specific values
    #expect(noWindValue.isApproximatelyEqual(to: 2177.0, relativeTolerance: 0.01))
    #expect(tailwindValue.isApproximatelyEqual(to: 3091.34, relativeTolerance: 0.01))
  }

  // MARK: - Slope Adjustment Tests

  @Test
  func landingRun_downhillAdjustment() {
    // Test with 2% downhill slope for landing
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runwayFlat = Helper.createTestRunway(slope: 0)
    let runwayDownhill = Helper.createTestRunway(slope: -2)

    let modelFlat = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayFlat, airport: runwayFlat.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelDownhill = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayDownhill, airport: runwayDownhill.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .value(let flatValue) = modelFlat.landingRunFt,
      case .value(let downhillValue) = modelDownhill.landingRunFt
    else {
      Issue.record(
        "Expected values for slope adjustment test, got modelFlat = \(modelFlat.landingRunFt), modelDownhill = \(modelDownhill.landingRunFt)"
      )
      return
    }

    // Downhill landing run should have specific values
    #expect(flatValue.isApproximatelyEqual(to: 2177.0, relativeTolerance: 0.01))
    #expect(downhillValue.isApproximatelyEqual(to: 2438.24, relativeTolerance: 0.01))
  }

  // MARK: - Surface Adjustment Tests

  @Test
  func landingDistance_unpavedAdjustment() {
    // Test unpaved runway adjustment for landing
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runwayPaved = Helper.createTestRunway(isTurf: false)
    let runwayUnpaved = Helper.createTestRunway(isTurf: true)

    let modelPaved = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayPaved, airport: runwayPaved.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    let modelUnpaved = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUnpaved, airport: runwayUnpaved.airport),
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .value(let pavedValue) = modelPaved.landingDistanceFt,
      case .value(let unpavedValue) = modelUnpaved.landingDistanceFt
    else {
      Issue.record(
        "Expected values for surface adjustment test, got modelPaved = \(modelPaved.landingDistanceFt), modelUnpaved = \(modelUnpaved.landingDistanceFt)"
      )
      return
    }

    // Unpaved landing distance should have specific values
    #expect(pavedValue.isApproximatelyEqual(to: 3247.0, relativeTolerance: 0.01))
    #expect(unpavedValue.isApproximatelyEqual(to: 3896.40, relativeTolerance: 0.01))
  }
}
