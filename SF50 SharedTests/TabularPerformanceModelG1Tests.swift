import Foundation
import Testing

@testable import SF50_Shared

struct TabularPerformanceModelG1Tests {

  // MARK: - Takeoff Ground Run Tests

  @Test
  func takeoffGroundRun_exactMatch() {
    // Test exact values from ground run.csv (after removing ISA values)
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 1780),
      (6000, 0, -10, 1851),
      (6000, 0, 0, 1924),
      (6000, 0, 10, 1999),
      (6000, 0, 20, 2231),
      (6000, 0, 30, 2757),
      (6000, 0, 40, 3418),
      (6000, 0, 50, 4284),
      (6000, 1000, 20, 2386),
      (6000, 2000, 20, 2586),
      (6000, 3000, 20, 2806),
      (6000, 4000, 20, 3048),
      (6000, 5000, 20, 3289),
      (6000, 6000, 20, 3585),
      (6000, 7000, 20, 3960),
      (6000, 8000, 20, 4429),
      (5500, 0, -20, 1632),
      (5500, 0, -10, 1697),
      (5500, 0, 0, 1763),
      (5500, 0, 10, 1833),
      (5500, 0, 20, 2045),
      (5500, 0, 30, 2528),
      (5500, 0, 40, 3133),
      (5500, 0, 50, 3927),
      (5000, 0, -20, 1483),
      (5000, 0, -10, 1542),
      (5000, 0, 0, 1603),
      (5000, 0, 10, 1666),
      (5000, 0, 20, 1859),
      (5000, 0, 30, 2298),
      (5000, 0, 40, 2848),
      (5000, 0, 50, 3570)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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

    let model = TabularPerformanceModelG1(
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
    #expect(value > 1854)  // 5500 lb at 0 ft, 20°C
    #expect(value < 3029)  // 6000 lb at 3000 ft, 20°C
  }

  @Test
  func takeoffGroundRun_interpolation_nearISA() {
    // Test case from user bug report: 5684 lb at sea level, 14°C
    // Expected: ~1982 ft (interpolated between 5500/6000 lb and 10/20°C)
    // After removing ISA values, interpolation now happens on regular 10°C grid
    // 5500 lb at 0 ft, 10°C: 1833 ft
    // 5500 lb at 0 ft, 20°C: 2045 ft
    // 6000 lb at 0 ft, 10°C: 1999 ft
    // 6000 lb at 0 ft, 20°C: 2231 ft
    let conditions = Helper.createTestConditions(temperature: 14)
    let config = Helper.createTestConfiguration(weight: 5684)
    let runway = Helper.createTestRunway(elevation: 0)

    let model = TabularPerformanceModelG1(
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

    // Manual calculation:
    // At 14°C (0.4 between 10 and 20):
    //   5500 lb: 1833 + 0.4 * (2045 - 1833) = 1917.8 ft
    //   6000 lb: 1999 + 0.4 * (2231 - 1999) = 2091.8 ft
    // At 5684 lb (0.368 between 5500 and 6000):
    //   1917.8 + 0.368 * (2091.8 - 1917.8) = 1981.9 ft
    let expected = 1982.0
    let tolerance = 10.0

    #expect(abs(value - expected) < tolerance, "Ground run should be ~1982 ft, got \(value) ft")
  }

  @Test
  func takeoffDistance_interpolation_nearISA() {
    // Test case from user bug report: 5684 lb at sea level, 14°C
    // After removing ISA values, interpolation now happens on regular 10°C grid
    // 5500 lb at 0 ft, 10°C: 2761 ft
    // 5500 lb at 0 ft, 20°C: 3099 ft
    // 6000 lb at 0 ft, 10°C: 3133 ft
    // 6000 lb at 0 ft, 20°C: 3519 ft
    let conditions = Helper.createTestConditions(temperature: 14)
    let config = Helper.createTestConfiguration(weight: 5684)
    let runway = Helper.createTestRunway(elevation: 0)

    let model = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    let result = model.takeoffDistanceFt
    guard case .value(let value) = result else {
      Issue.record("Expected interpolated value, got \(result)")
      return
    }

    // Manual calculation:
    // At 14°C (0.4 between 10 and 20):
    //   5500 lb: 2761 + 0.4 * (3099 - 2761) = 2896.2 ft
    //   6000 lb: 3133 + 0.4 * (3519 - 3133) = 3287.4 ft
    // At 5684 lb (0.368 between 5500 and 6000):
    //   2896.2 + 0.368 * (3287.4 - 2896.2) = 3040.2 ft
    let expected = 3040.0
    let tolerance = 10.0

    #expect(abs(value - expected) < tolerance)
  }

  @Test
  func takeoffGroundRun_3D_interpolation() {
    // Tests 3D trilinear interpolation with regular temperature grid
    // After removing ISA values, the temperature grid is perfectly regular (10°C intervals)
    // This allows guaranteed 8-corner cuboids and true trilinear interpolation
    //
    // Test case: 5684 lb, 5 ft elevation, 14°C
    // Weight interpolates between 5500 and 6000 lb
    // Altitude interpolates between 0 and 1000 ft
    // Temperature interpolates between 10 and 20°C (both exist at all altitudes)
    //
    // Expected: ~1922 ft ground run
    let conditions = Helper.createTestConditions(temperature: 14)
    let config = Helper.createTestConfiguration(weight: 5684)
    let runway = Helper.createTestRunway(elevation: 5)

    let model = TabularPerformanceModelG1(
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

    let expected = 1982.3
    let tolerance = 10.0

    #expect(abs(value - expected) < tolerance, "Ground run should be ~1982 ft, got \(value) ft")
  }

  // MARK: - Takeoff Distance Tests

  @Test
  func takeoffDistance_exactMatch() {
    // Test exact values from total distance.csv (after removing ISA values)
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 2789),
      (6000, 0, -10, 2900),
      (6000, 0, 0, 3014),
      (6000, 0, 10, 3133),
      (6000, 0, 20, 3519),
      (6000, 0, 30, 4415),
      (6000, 0, 40, 5561),
      (6000, 0, 50, 7093),
      (6000, 1000, 20, 3773),
      (6000, 2000, 20, 4104),
      (6000, 3000, 20, 4471),
      (6000, 4000, 20, 4875),
      (6000, 5000, 20, 5278),
      (6000, 6000, 20, 5778),
      (6000, 7000, 20, 6416),
      (6000, 8000, 20, 7216)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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
    // Test exact values from gradient.csv
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 1230),
      (6000, 0, -10, 1239),
      (6000, 0, 0, 1227),
      (6000, 0, 10, 1223),
      (6000, 0, 20, 1123),
      (6000, 0, 30, 923),
      (6000, 0, 40, 746),
      (6000, 0, 50, 584),
      (5500, 0, -20, 1419),
      (5500, 0, -10, 1418),
      (5500, 0, 0, 1415),
      (5500, 0, 10, 1411),
      (5500, 0, 20, 1302),
      (5500, 0, 30, 1084),
      (5500, 0, 40, 891),
      (5500, 0, 50, 714),
      (5000, 0, -20, 1638),
      (5000, 0, -10, 1637),
      (5000, 0, 0, 1634),
      (5000, 0, 10, 1629),
      (5000, 0, 20, 1509),
      (5000, 0, 30, 1269),
      (5000, 0, 40, 1057),
      (5000, 0, 50, 862)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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
    // Test exact values from rate.csv
    let testCases: [(weight: Double, altitude: Double, temperature: Double, expected: Double)] = [
      (6000, 0, -20, 2012),
      (6000, 0, -10, 1972),
      (6000, 0, 0, 1933),
      (6000, 0, 10, 1892),
      (6000, 0, 20, 1707),
      (6000, 0, 30, 1381),
      (6000, 0, 40, 1097),
      (6000, 0, 50, 846),
      (5500, 0, -20, 2321),
      (5500, 0, -10, 2275),
      (5500, 0, 0, 2229),
      (5500, 0, 10, 2183),
      (5500, 0, 20, 1979),
      (5500, 0, 30, 1621),
      (5500, 0, 40, 1310),
      (5500, 0, 50, 1033),
      (5000, 0, -20, 2679),
      (5000, 0, -10, 2626),
      (5000, 0, 0, 2574),
      (5000, 0, 10, 2521),
      (5000, 0, 20, 2295),
      (5000, 0, 30, 1899),
      (5000, 0, 40, 1554),
      (5000, 0, 50, 1248)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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

  // MARK: - VREF Tests

  @Test
  func vref_exactMatch() {
    // Test VREF values for different flap settings
    let testCases: [(weight: Double, flapSetting: FlapSetting, expected: Double)] = [
      // Flaps 50
      (4500, .flaps50, 87),
      (5000, .flaps50, 91),
      (5500, .flaps50, 96),
      (6000, .flaps50, 100),
      // Flaps 100
      (4500, .flaps100, 76),
      (5000, .flaps100, 81),
      (5500, .flaps100, 85),
      (6000, .flaps100, 89),
      // Flaps UP
      (4500, .flapsUp, 95),
      (5000, .flapsUp, 100),
      (5500, .flapsUp, 104),
      (6000, .flapsUp, 109),
      // Flaps 50 Ice
      (4500, .flaps50Ice, 104),
      (5000, .flaps50Ice, 110),
      (5500, .flaps50Ice, 115),
      (6000, .flaps50Ice, 120),
      // Flaps UP Ice
      (4500, .flapsUpIce, 122),
      (5000, .flapsUpIce, 128),
      (5500, .flapsUpIce, 135),
      (6000, .flapsUpIce, 140)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions()
      let config = Helper.createTestConfiguration(
        weight: testCase.weight,
        flapSetting: testCase.flapSetting
      )
      let runway = Helper.createTestRunway()

      let model = TabularPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: RunwayInput(from: runway, airport: runway.airport),
        notam: nil
      )

      let result = model.VrefKts
      guard case .value(let value) = result else {
        Issue.record(
          "Expected value for weight: \(testCase.weight), flaps: \(testCase.flapSetting), got \(result)"
        )
        continue
      }

      #expect(value == testCase.expected)
    }
  }

  // MARK: - Landing Ground Run Tests

  @Test
  func landingGroundRun_exactMatch_flaps50() {
    // Test exact values from landing ground run.csv for flaps 50
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

      let model = TabularPerformanceModelG1(
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
    // Test exact values from landing ground run.csv for flaps 100
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
      (5550, 0, 40, 1762)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps100)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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
    // Test exact values from landing total distance.csv for flaps 50
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

      let model = TabularPerformanceModelG1(
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
    // Test exact values from landing total distance.csv for flaps 100
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
      (5550, 0, 40, 2704)
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temperature)
      let config = Helper.createTestConfiguration(weight: testCase.weight, flapSetting: .flaps100)
      let runway = Helper.createTestRunway(elevation: testCase.altitude)

      let model = TabularPerformanceModelG1(
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

    let modelNoWind = TabularPerformanceModelG1(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    let modelHeadwind = TabularPerformanceModelG1(
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
  func takeoffRun_tailwindAdjustment() {
    // Test with 10 kt tailwind
    let conditionsNoWind = Helper.createTestConditions(temperature: 20)
    let conditionsTailwind = Helper.createTestConditions(
      temperature: 20,
      windDirection: 180,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration()
    let runway = Helper.createTestRunway(heading: 360)

    let modelNoWind = TabularPerformanceModelG1(
      conditions: conditionsNoWind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    let modelTailwind = TabularPerformanceModelG1(
      conditions: conditionsTailwind,
      configuration: config,
      runway: RunwayInput(from: runway, airport: runway.airport),
      notam: nil
    )

    guard case .value(let noWindValue) = modelNoWind.takeoffRunFt,
      case .value(let tailwindValue) = modelTailwind.takeoffRunFt
    else {
      Issue.record("Expected values for wind adjustment test")
      return
    }

    // Tailwind should increase takeoff run
    #expect(tailwindValue > noWindValue)
  }

  // MARK: - Slope Adjustment Tests

  @Test
  func takeoffRun_uphillAdjustment() {
    // Test with 2% uphill slope
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration()
    let runwayFlat = Helper.createTestRunway(slope: 0)
    let runwayUphill = Helper.createTestRunway(slope: 2)

    let modelFlat = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayFlat, airport: runwayFlat.airport),
      notam: nil
    )

    let modelUphill = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUphill, airport: runwayUphill.airport),
      notam: nil
    )

    guard case .value(let flatValue) = modelFlat.takeoffRunFt,
      case .value(let uphillValue) = modelUphill.takeoffRunFt
    else {
      Issue.record("Expected values for slope adjustment test")
      return
    }

    // Uphill should increase takeoff run
    #expect(uphillValue > flatValue)
  }

  @Test
  func takeoffRun_downhillAdjustment() {
    // Test with 2% downhill slope
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration()
    let runwayFlat = Helper.createTestRunway(slope: 0)
    let runwayDownhill = Helper.createTestRunway(slope: -2)

    let modelFlat = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayFlat, airport: runwayFlat.airport),
      notam: nil
    )

    let modelDownhill = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayDownhill, airport: runwayDownhill.airport),
      notam: nil
    )

    guard case .value(let flatValue) = modelFlat.takeoffRunFt,
      case .value(let downhillValue) = modelDownhill.takeoffRunFt
    else {
      Issue.record("Expected values for slope adjustment test")
      return
    }

    // Downhill should decrease takeoff run
    #expect(downhillValue < flatValue)
  }

  // MARK: - Surface Adjustment Tests

  @Test
  func takeoffDistance_unpavedAdjustment() {
    // Test unpaved runway adjustment
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration()
    let runwayPaved = Helper.createTestRunway(isTurf: false)
    let runwayUnpaved = Helper.createTestRunway(isTurf: true)

    let modelPaved = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayPaved, airport: runwayPaved.airport),
      notam: nil
    )

    let modelUnpaved = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: RunwayInput(from: runwayUnpaved, airport: runwayUnpaved.airport),
      notam: nil
    )

    guard case .value(let pavedValue) = modelPaved.takeoffDistanceFt,
      case .value(let unpavedValue) = modelUnpaved.takeoffDistanceFt
    else {
      Issue.record("Expected values for surface adjustment test")
      return
    }

    // Unpaved should increase takeoff distance
    #expect(unpavedValue > pavedValue)
  }
}
