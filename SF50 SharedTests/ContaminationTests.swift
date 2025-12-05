import Foundation
import Testing

@testable import SF50_Shared

/// Comprehensive tests for runway contamination effects on landing performance.
///
/// This test suite verifies that contamination correctly increases landing distances
/// according to the performance data in the AFM. Tests cover all contamination types
/// (water, slush, dry snow, compact snow) across both tabular and regression models.
struct ContaminationTests {

  // MARK: - Contamination Increases Landing Run

  @Test("Water contamination increases landing run - Tabular G1")
  func waterContamination_increasesLandingRun_tabularG1() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Model without contamination
    let cleanModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    let cleanRun: Double
    switch cleanModel.landingRunFt {
      case .value(let val):
        cleanRun = val
      case .valueWithUncertainty(let val, _):
        cleanRun = val
      default:
        Issue.record("Expected clean landing run value")
        return
    }

    // Model with water contamination (0.25 inches)
    let waterContamination = Contamination.waterOrSlush(depth: .init(value: 0.25, unit: .inches))
    let contaminatedNotam = NOTAMInput(
      contaminationType: waterContamination.type,
      contaminationDepth: .init(value: waterContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    guard case .value(let contaminatedRun) = contaminatedModel.landingRunFt else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Water contamination should have specific values
    #expect(cleanRun.isApproximatelyEqual(to: 1961.19, relativeTolerance: 0.01))
    #expect(contaminatedRun.isApproximatelyEqual(to: 2946.79, relativeTolerance: 0.01))
  }

  @Test("Slush contamination increases landing run - Tabular G2+")
  func slushContamination_increasesLandingRun_tabularG2Plus() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    let cleanRun: Double
    switch cleanModel.landingRunFt {
      case .value(let val):
        cleanRun = val
      case .valueWithUncertainty(let val, _):
        cleanRun = val
      default:
        Issue.record("Expected clean landing run value")
        return
    }

    // Model with slush contamination (0.5 inches)
    let slushContamination = Contamination.slushOrWetSnow(depth: .init(value: 0.5, unit: .inches))
    let contaminatedNotam = NOTAMInput(
      contaminationType: slushContamination.type,
      contaminationDepth: .init(value: slushContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    guard case .value(let contaminatedRun) = contaminatedModel.landingRunFt else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Slush contamination should have specific values
    #expect(cleanRun.isApproximatelyEqual(to: 1961.19, relativeTolerance: 0.01))
    #expect(contaminatedRun.isApproximatelyEqual(to: 2725.67, relativeTolerance: 0.01))
  }

  @Test("Dry snow contamination increases landing run - Regression G1")
  func drySnowContamination_increasesLandingRun_regressionG1() {
    let conditions = Helper.createTestConditions(temperature: -5)  // Cold for snow
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    guard case .valueWithUncertainty(let cleanRun, _) = cleanModel.landingRunFt else {
      Issue.record("Expected clean landing run value")
      return
    }

    let drySnowContamination = Contamination.drySnow
    let contaminatedNotam = NOTAMInput(
      contaminationType: drySnowContamination.type,
      contaminationDepth: .init(value: drySnowContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    guard case .valueWithUncertainty(let contaminatedRun, _) = contaminatedModel.landingRunFt
    else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Dry snow contamination should have specific values
    #expect(cleanRun.isApproximatelyEqual(to: 1983.17, relativeTolerance: 0.01))
    #expect(contaminatedRun.isApproximatelyEqual(to: 2640.79, relativeTolerance: 0.01))
  }

  @Test("Compact snow contamination increases landing run - Regression G2+")
  func compactSnowContamination_increasesLandingRun_regressionG2Plus() {
    let conditions = Helper.createTestConditions(temperature: -10)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .valueWithUncertainty(let cleanRun, _) = cleanModel.landingRunFt else {
      Issue.record("Expected clean landing run value")
      return
    }

    let compactSnowContamination = Contamination.compactSnow
    let contaminatedNotam = NOTAMInput(
      contaminationType: compactSnowContamination.type,
      contaminationDepth: .init(value: compactSnowContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    guard case .valueWithUncertainty(let contaminatedRun, _) = contaminatedModel.landingRunFt
    else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Compact snow contamination should have specific values
    #expect(cleanRun.isApproximatelyEqual(to: 1765.38, relativeTolerance: 0.01))
    #expect(contaminatedRun.isApproximatelyEqual(to: 2792.71, relativeTolerance: 0.01))
  }

  // MARK: - Contamination Increases Total Landing Distance

  @Test("Water contamination increases total landing distance - Tabular G1")
  func waterContamination_increasesTotalLandingDistance_tabularG1() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    let cleanDistance: Double
    switch cleanModel.landingDistanceFt {
      case .value(let val):
        cleanDistance = val
      case .valueWithUncertainty(let val, _):
        cleanDistance = val
      default:
        Issue.record("Expected clean landing distance value")
        return
    }

    let waterContamination3 = Contamination.waterOrSlush(depth: .init(value: 0.5, unit: .inches))
    let contaminatedNotam = NOTAMInput(
      contaminationType: waterContamination3.type,
      contaminationDepth: .init(value: waterContamination3.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    guard case .value(let contaminatedDistance) = contaminatedModel.landingDistanceFt else {
      Issue.record("Expected contaminated landing distance value")
      return
    }

    // Water contamination total landing distance should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2789.19, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 3347.55, relativeTolerance: 0.01))
  }

  @Test("Slush contamination increases total landing distance - Tabular G2+")
  func slushContamination_increasesTotalLandingDistance_tabularG2Plus() {
    let conditions = Helper.createTestConditions(temperature: 5)
    let config = Helper.createTestConfiguration(weight: 5500, flapSetting: .flaps100)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    let cleanDistance: Double
    switch cleanModel.landingDistanceFt {
      case .value(let val):
        cleanDistance = val
      case .valueWithUncertainty(let val, _):
        cleanDistance = val
      default:
        Issue.record("Expected clean landing distance value")
        return
    }

    let slushContamination2 = Contamination.slushOrWetSnow(depth: .init(value: 0.75, unit: .inches))
    let contaminatedNotam = NOTAMInput(
      contaminationType: slushContamination2.type,
      contaminationDepth: .init(value: slushContamination2.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    guard case .value(let contaminatedDistance) = contaminatedModel.landingDistanceFt else {
      Issue.record("Expected contaminated landing distance value")
      return
    }

    // Slush contamination total landing distance should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2431.57, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 3034.39, relativeTolerance: 0.01))
  }

  @Test("Dry snow contamination increases total landing distance - Regression G1")
  func drySnowContamination_increasesTotalLandingDistance_regressionG1() {
    let conditions = Helper.createTestConditions(temperature: -5)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    guard case .valueWithUncertainty(let cleanDistance, _) = cleanModel.landingDistanceFt else {
      Issue.record("Expected clean landing distance value")
      return
    }

    let drySnowContamination2 = Contamination.drySnow
    let contaminatedNotam = NOTAMInput(
      contaminationType: drySnowContamination2.type,
      contaminationDepth: .init(value: drySnowContamination2.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    guard
      case .valueWithUncertainty(let contaminatedDistance, _) = contaminatedModel
        .landingDistanceFt
    else {
      Issue.record("Expected contaminated landing distance value")
      return
    }

    // Dry snow contamination total landing distance should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2577.18, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 3174.35, relativeTolerance: 0.01))
  }

  @Test("Compact snow contamination increases total landing distance - Regression G2+")
  func compactSnowContamination_increasesTotalLandingDistance_regressionG2Plus() {
    let conditions = Helper.createTestConditions(temperature: -10)
    let config = Helper.createTestConfiguration(weight: 5500)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .valueWithUncertainty(let cleanDistance, _) = cleanModel.landingDistanceFt else {
      Issue.record("Expected clean landing distance value")
      return
    }

    let compactSnowContamination2 = Contamination.compactSnow
    let contaminatedNotam = NOTAMInput(
      contaminationType: compactSnowContamination2.type,
      contaminationDepth: .init(value: compactSnowContamination2.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    guard
      case .valueWithUncertainty(let contaminatedDistance, _) = contaminatedModel
        .landingDistanceFt
    else {
      Issue.record("Expected contaminated landing distance value")
      return
    }

    // Compact snow contamination total landing distance should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2933.23, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 4064.51, relativeTolerance: 0.01))
  }

  // MARK: - Contamination Depth Effects

  @Test("Greater water depth increases contamination effect")
  func greaterWaterDepth_increasesContaminationEffect() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Shallow water (0.25 inches)
    let shallowWaterContamination = Contamination.waterOrSlush(
      depth: .init(value: 0.25, unit: .inches)
    )
    let shallowNotam = NOTAMInput(
      contaminationType: shallowWaterContamination.type,
      contaminationDepth: .init(value: shallowWaterContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let shallowModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: shallowNotam,
      aircraftType: .g1
    )

    // Deep water (0.75 inches)
    let deepWaterContamination = Contamination.waterOrSlush(
      depth: .init(value: 0.75, unit: .inches)
    )
    let deepNotam = NOTAMInput(
      contaminationType: deepWaterContamination.type,
      contaminationDepth: .init(value: deepWaterContamination.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let deepModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: deepNotam,
      aircraftType: .g1
    )

    let shallowRun: Double
    let deepRun: Double

    switch shallowModel.landingRunFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        shallowRun = val
      default:
        Issue.record("Expected landing run values")
        return
    }

    switch deepModel.landingRunFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        deepRun = val
      default:
        Issue.record("Expected landing run values")
        return
    }

    // Water depth should have specific values
    #expect(shallowRun.isApproximatelyEqual(to: 2946.79, relativeTolerance: 0.01))
    #expect(deepRun.isApproximatelyEqual(to: 2519.55, relativeTolerance: 0.01))
  }

  // MARK: - Contamination with Other Factors

  @Test("Contamination combined with headwind")
  func contamination_combinedWithHeadwind() {
    let headwindConditions = Helper.createTestConditions(
      temperature: 20,
      windDirection: 360,
      windSpeed: 10
    )
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway(heading: 360)
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG1(
      conditions: headwindConditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    let waterContamination4 = Contamination.waterOrSlush(depth: .init(value: 0.5, unit: .inches))
    let contaminatedNotam = NOTAMInput(
      contaminationType: waterContamination4.type,
      contaminationDepth: .init(value: waterContamination4.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG1(
      conditions: headwindConditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    let cleanDistance: Double
    let contaminatedDistance: Double

    switch cleanModel.landingDistanceFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        cleanDistance = val
      default:
        Issue.record("Expected landing distance values")
        return
    }

    switch contaminatedModel.landingDistanceFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        contaminatedDistance = val
      default:
        Issue.record("Expected landing distance values")
        return
    }

    // Contamination with headwind should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2607.23, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 3129.16, relativeTolerance: 0.01))
  }

  @Test("Contamination combined with uphill slope")
  func contamination_combinedWithUphillSlope() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5000)
    let runway = Helper.createTestRunway(slope: 1.0)  // 1% uphill
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    let compactSnowContamination3 = Contamination.compactSnow
    let contaminatedNotam = NOTAMInput(
      contaminationType: compactSnowContamination3.type,
      contaminationDepth: .init(value: compactSnowContamination3.depth ?? 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    let cleanDistance: Double
    let contaminatedDistance: Double

    switch cleanModel.landingDistanceFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        cleanDistance = val
      default:
        Issue.record("Expected landing distance values")
        return
    }

    switch contaminatedModel.landingDistanceFt {
      case .value(let val), .valueWithUncertainty(let val, _):
        contaminatedDistance = val
      default:
        Issue.record("Expected landing distance values")
        return
    }

    // Contamination with uphill slope should have specific values
    #expect(cleanDistance.isApproximatelyEqual(to: 2789.19, relativeTolerance: 0.01))
    #expect(contaminatedDistance.isApproximatelyEqual(to: 3927.85, relativeTolerance: 0.01))
  }

  // MARK: - Wet Runway Tests (G2/G2+ AFM Reissue A)

  @Test("Wet runway contamination increases landing run by 15% - Tabular G2+")
  func wetRunwayContamination_increasesLandingRun_tabularG2Plus() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Model without contamination
    let cleanModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    let cleanRun: Double
    switch cleanModel.landingRunFt {
      case .value(let val):
        cleanRun = val
      case .valueWithUncertainty(let val, _):
        cleanRun = val
      default:
        Issue.record("Expected clean landing run value")
        return
    }

    // Model with wet runway contamination
    let wetRunwayContamination = Contamination.wetRunway
    let contaminatedNotam = NOTAMInput(
      contaminationType: wetRunwayContamination.type,
      contaminationDepth: .init(value: 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    let contaminatedRun: Double
    switch contaminatedModel.landingRunFt {
      case .value(let val):
        contaminatedRun = val
      case .valueWithUncertainty(let val, _):
        contaminatedRun = val
      default:
        Issue.record("Expected contaminated landing run value")
        return
    }

    // Wet runway should increase landing run by 15%
    let expectedRun = cleanRun * 1.15
    #expect(contaminatedRun.isApproximatelyEqual(to: expectedRun, relativeTolerance: 0.01))
  }

  @Test("Wet runway contamination increases landing run by 15% - Regression G2+")
  func wetRunwayContamination_increasesLandingRun_regressionG2Plus() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Model without contamination
    let cleanModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    guard case .valueWithUncertainty(let cleanRun, _) = cleanModel.landingRunFt else {
      Issue.record("Expected clean landing run value")
      return
    }

    // Model with wet runway contamination
    let wetRunwayContamination = Contamination.wetRunway
    let contaminatedNotam = NOTAMInput(
      contaminationType: wetRunwayContamination.type,
      contaminationDepth: .init(value: 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    guard case .valueWithUncertainty(let contaminatedRun, _) = contaminatedModel.landingRunFt else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Wet runway should increase landing run by 15%
    let expectedRun = cleanRun * 1.15
    #expect(contaminatedRun.isApproximatelyEqual(to: expectedRun, relativeTolerance: 0.01))
  }

  @Test("Wet runway contamination has no effect on G1 - Tabular")
  func wetRunwayContamination_noEffectOnG1_tabular() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Model without contamination
    let cleanModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    let cleanRun: Double
    switch cleanModel.landingRunFt {
      case .value(let val):
        cleanRun = val
      case .valueWithUncertainty(let val, _):
        cleanRun = val
      default:
        Issue.record("Expected clean landing run value")
        return
    }

    // Model with wet runway contamination
    let wetRunwayContamination = Contamination.wetRunway
    let contaminatedNotam = NOTAMInput(
      contaminationType: wetRunwayContamination.type,
      contaminationDepth: .init(value: 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    let contaminatedRun: Double
    switch contaminatedModel.landingRunFt {
      case .value(let val):
        contaminatedRun = val
      case .valueWithUncertainty(let val, _):
        contaminatedRun = val
      default:
        Issue.record("Expected contaminated landing run value")
        return
    }

    // Wet runway should have no effect on G1
    #expect(contaminatedRun.isApproximatelyEqual(to: cleanRun, relativeTolerance: 0.001))
  }

  @Test("Wet runway contamination increases landing run by 15% - Regression G1")
  func wetRunwayContamination_increasesLandingRun_regressionG1() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    // Model without contamination
    let cleanModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g1
    )

    guard case .valueWithUncertainty(let cleanRun, _) = cleanModel.landingRunFt else {
      Issue.record("Expected clean landing run value")
      return
    }

    // Model with wet runway contamination
    let wetRunwayContamination = Contamination.wetRunway
    let contaminatedNotam = NOTAMInput(
      contaminationType: wetRunwayContamination.type,
      contaminationDepth: .init(value: 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = RegressionPerformanceModelG1(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g1
    )

    guard case .valueWithUncertainty(let contaminatedRun, _) = contaminatedModel.landingRunFt else {
      Issue.record("Expected contaminated landing run value")
      return
    }

    // Regression model: Wet runway should increase landing run by 15% for all aircraft
    let expectedRun = cleanRun * 1.15
    #expect(contaminatedRun.isApproximatelyEqual(to: expectedRun, relativeTolerance: 0.01))
  }

  @Test("Wet runway contamination increases total landing distance - G2+")
  func wetRunwayContamination_increasesTotalLandingDistance_G2Plus() {
    let conditions = Helper.createTestConditions(temperature: 20)
    let config = Helper.createTestConfiguration(weight: 5550)
    let runway = Helper.createTestRunway()
    let runwayInput = RunwayInput(from: runway, airport: runway.airport)

    let cleanModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: nil,
      aircraftType: .g2Plus
    )

    let cleanDistance: Double
    switch cleanModel.landingDistanceFt {
      case .value(let val):
        cleanDistance = val
      case .valueWithUncertainty(let val, _):
        cleanDistance = val
      default:
        Issue.record("Expected clean landing distance value")
        return
    }

    let wetRunwayContamination = Contamination.wetRunway
    let contaminatedNotam = NOTAMInput(
      contaminationType: wetRunwayContamination.type,
      contaminationDepth: .init(value: 0, unit: .meters),
      takeoffDistanceShortening: .init(value: 0, unit: .feet),
      landingDistanceShortening: .init(value: 0, unit: .feet),
      obstacleHeight: .init(value: 0, unit: .feet),
      obstacleDistance: .init(value: 0, unit: .nauticalMiles)
    )

    let contaminatedModel = TabularPerformanceModelG2Plus(
      conditions: conditions,
      configuration: config,
      runway: runwayInput,
      notam: contaminatedNotam,
      aircraftType: .g2Plus
    )

    let contaminatedDistance: Double
    switch contaminatedModel.landingDistanceFt {
      case .value(let val):
        contaminatedDistance = val
      case .valueWithUncertainty(let val, _):
        contaminatedDistance = val
      default:
        Issue.record("Expected contaminated landing distance value")
        return
    }

    // Total landing distance should also increase (run increase propagates)
    #expect(contaminatedDistance > cleanDistance)
  }

  // MARK: - Logical Consistency Tests

  @Test("Landing run never exceeds total landing distance")
  func landingRun_neverExceedsTotalDistance() {
    let testCases: [(contamination: Contamination?, weight: Double, temp: Double)] = [
      (.waterOrSlush(depth: .init(value: 0.5, unit: .inches)), 6000, 20),
      (.slushOrWetSnow(depth: .init(value: 0.75, unit: .inches)), 5500, 10),
      (.drySnow, 5000, -5),
      (.compactSnow, 5500, -10),
      (nil, 6000, 15)  // Clean runway as control
    ]

    for testCase in testCases {
      let conditions = Helper.createTestConditions(temperature: testCase.temp)
      let config = Helper.createTestConfiguration(weight: testCase.weight)
      let runway = Helper.createTestRunway()
      let runwayInput = RunwayInput(from: runway, airport: runway.airport)

      let notam: NOTAMInput? =
        if let contamination = testCase.contamination {
          NOTAMInput(
            contaminationType: contamination.type,
            contaminationDepth: .init(value: contamination.depth ?? 0, unit: .meters),
            takeoffDistanceShortening: .init(value: 0, unit: .feet),
            landingDistanceShortening: .init(value: 0, unit: .feet),
            obstacleHeight: .init(value: 0, unit: .feet),
            obstacleDistance: .init(value: 0, unit: .nauticalMiles)
          )
        } else {
          nil
        }

      let model = TabularPerformanceModelG1(
        conditions: conditions,
        configuration: config,
        runway: runwayInput,
        notam: notam,
        aircraftType: .g1
      )

      if case .value(let run) = model.landingRunFt,
        case .value(let distance) = model.landingDistanceFt
      {
        // Landing run should never exceed total landing distance
        #expect(
          run <= distance,
          "Landing run (\(run) ft) should not exceed total distance (\(distance) ft) with \(testCase.contamination?.type ?? "clean runway")"
        )
      }
    }
  }
}
