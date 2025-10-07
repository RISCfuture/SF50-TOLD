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
        notam: nil
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
      notam: nil
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
        notam: nil
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
        notam: nil
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
        notam: nil
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

  // MARK: - Landing Ground Run Tests

  @Test
  func landingGroundRun_exactMatch_flaps50() {
    // Test exact values from g2+/landing/50/ground run.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingRunFt
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
  func landingGroundRun_exactMatch_flaps100() {
    // Test exact values from g2+/landing/100/ground run.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingRunFt
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), altitude: \(testCase.altitude), temp: \(testCase.temperature), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  // MARK: - Landing Distance Tests

  @Test
  func landingDistance_exactMatch_flaps50() {
    // Test exact values from g2+/landing/50/total distance.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingDistanceFt
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
  func landingDistance_exactMatch_flaps100() {
    // Test exact values from g2+/landing/100/total distance.csv
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

      let model = TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.landingDistanceFt
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
      notam: nil
    )

    let modelHeadwind = TabularPerformanceModelG2Plus(
      conditions: conditionsHeadwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
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
      notam: nil
    )

    let modelTailwind = TabularPerformanceModelG2Plus(
      conditions: conditionsTailwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
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

    // Tailwind should increase landing run
    #expect(tailwindValue > noWindValue)
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
      notam: nil
    )

    let modelDownhill = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayDownhill, airport: runwayDownhill.airport),
      notam: nil
    )

    guard case .value(let flatValue) = modelFlat.landingRunFt,
      case .value(let downhillValue) = modelDownhill.landingRunFt
    else {
      Issue.record(
        "Expected values for slope adjustment test, got modelFlat = \(modelFlat.landingRunFt), modelDownhill = \(modelDownhill.landingRunFt)"
      )
      return
    }

    // Downhill should increase landing run
    #expect(downhillValue > flatValue)
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
      notam: nil
    )

    let modelUnpaved = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUnpaved, airport: runwayUnpaved.airport),
      notam: nil
    )

    guard case .value(let pavedValue) = modelPaved.landingDistanceFt,
      case .value(let unpavedValue) = modelUnpaved.landingDistanceFt
    else {
      Issue.record(
        "Expected values for surface adjustment test, got modelPaved = \(modelPaved.landingDistanceFt), modelUnpaved = \(modelUnpaved.landingDistanceFt)"
      )
      return
    }

    // Unpaved should increase landing distance
    #expect(unpavedValue > pavedValue)
  }
}
