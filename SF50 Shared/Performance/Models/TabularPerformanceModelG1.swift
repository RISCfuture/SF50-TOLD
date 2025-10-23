import Foundation

final class TabularPerformanceModelG1: BasePerformanceModel {

  // MARK: - Properties

  private let takeoffRunData: DataTable
  private let takeoffDistanceData: DataTable
  private let takeoffClimbGradientData: DataTable
  private let takeoffClimbRateData: DataTable
  private let vrefData: DataTable
  private let landingRunData: DataTable
  private let landingDistanceData: DataTable

  private let takeoffRun_headwindData: DataTable
  private let takeoffRun_tailwindData: DataTable
  private let takeoffRun_downhillData: DataTable
  private let takeoffRun_uphillData: DataTable
  private let takeoffDistance_headwindData: DataTable
  private let takeoffDistance_tailwindData: DataTable
  private let takeoffDistance_unpavedData: DataTable

  private let landingRun_headwindData: DataTable
  private let landingRun_tailwindData: DataTable
  private let landingRun_downhillData: DataTable
  private let landingRun_uphillData: DataTable
  private let landingDistance_headwindData: DataTable
  private let landingDistance_tailwindData: DataTable
  private let landingDistance_unpavedData: DataTable

  private let contamination_compactSnowData: DataTable
  private let contamination_drySnowData: DataTable
  private let contamination_slushData: DataTable
  private let contamination_waterData: DataTable

  private let enrouteClimb_gradientNormalData: DataTable
  private let enrouteClimb_rateNormalData: DataTable
  private let enrouteClimb_speedNormalData: DataTable
  private let enrouteClimb_gradientIceContaminatedData: DataTable
  private let enrouteClimb_rateIceContaminatedData: DataTable
  private let enrouteClimb_speedIceContaminatedData: DataTable

  private let timeFuelDistanceToClimb_timeData: DataTable
  private let timeFuelDistanceToClimb_fuelData: DataTable
  private let timeFuelDistanceToClimb_distanceData: DataTable

  // MARK: - Outputs

  override var takeoffRunFt: Value<Double> {
    var run = takeoffRunBaseFt
    run *= takeoffRun_headwindAdjustment
    run *= takeoffRun_tailwindAdjustment
    run *= takeoffRun_uphillAdjustment
    run *= takeoffRun_downhillAdjustment
    return run
  }

  override var takeoffDistanceFt: Value<Double> {
    var distance = takeoffDistanceBaseFt
    distance *= takeoffDistance_headwindAdjustment
    distance *= takeoffDistance_tailwindAdjustment
    if runway.isTurf { distance *= takeoffDistance_unpavedAdjustment }
    return distance
  }

  override var takeoffClimbGradientFtNmi: Value<Double> {
    takeoffClimbGradientData.value(for: [weight, altitude, temperature])
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    takeoffClimbRateData.value(for: [weight, altitude, temperature])
  }

  var enrouteClimbGradientFtNmi: Value<Double> {
    let iceContaminated = configuration.iceProtection
    let data =
      iceContaminated ? enrouteClimb_gradientIceContaminatedData : enrouteClimb_gradientNormalData
    return data.value(for: [altitude, temperature, weight])
  }

  var enrouteClimbRateFtMin: Value<Double> {
    let iceContaminated = configuration.iceProtection
    let data = iceContaminated ? enrouteClimb_rateIceContaminatedData : enrouteClimb_rateNormalData
    return data.value(for: [altitude, temperature, weight])
  }

  var enrouteClimbSpeedKIAS: Value<Double> {
    let iceContaminated = configuration.iceProtection
    let data =
      iceContaminated ? enrouteClimb_speedIceContaminatedData : enrouteClimb_speedNormalData
    return data.value(for: [altitude, temperature, weight])
  }

  var timeToClimbMin: Value<Double> {
    timeFuelDistanceToClimb_timeData.value(for: [altitude, temperature, weight])
  }

  var fuelToClimbUsGal: Value<Double> {
    timeFuelDistanceToClimb_fuelData.value(for: [altitude, temperature, weight])
  }

  var distanceToClimbNm: Value<Double> {
    timeFuelDistanceToClimb_distanceData.value(for: [altitude, temperature, weight])
  }

  override var VrefKts: Value<Double> {
    vrefData.value(for: [weight])
  }

  override var landingRunFt: Value<Double> {
    var run = landingRun_contaminationAddition(distance: landingRunBaseFt)
    run *= landingRun_headwindAdjustment
    run *= landingRun_tailwindAdjustment
    run *= landingRun_uphillAdjustment
    run *= landingRun_downhillAdjustment
    return run
  }

  override var landingDistanceFt: Value<Double> {
    // Calculate the increase in landing run due to contamination
    let baseLandingRun = landingRunBaseFt
    let contaminatedLandingRun = landingRun_contaminationAddition(distance: baseLandingRun)

    // Compute the run increase by extracting values
    let runIncrease: Value<Double> =
      switch (baseLandingRun, contaminatedLandingRun) {
        case (.value(let base), .value(let contaminated)):
          .value(contaminated - base)
        case (.valueWithUncertainty(let base, _), .value(let contaminated)):
          .value(contaminated - base)
        case (.value(let base), .valueWithUncertainty(let contaminated, let unc)):
          .valueWithUncertainty(contaminated - base, uncertainty: unc)
        case (.valueWithUncertainty(let base, _), .valueWithUncertainty(let contaminated, let unc)):
          .valueWithUncertainty(contaminated - base, uncertainty: unc)
        default:
          .value(0)  // No contamination or error state
      }

    // Start with base landing distance and add the contamination-induced run increase
    var distance = landingDistanceBaseFt.map { distValue, distUnc in
      switch runIncrease {
        case .value(let inc):
          return (distValue + inc, distUnc)
        case .valueWithUncertainty(let inc, let incUnc):
          let newDist = distValue + inc
          let newUnc =
            if let distUnc {
              sqrt(pow(distUnc, 2) + pow(incUnc, 2))
            } else {
              incUnc
            }
          return (newDist, newUnc)
        default:
          return (distValue, distUnc)
      }
    }

    distance *= landingDistance_headwindAdjustment
    distance *= landingDistance_tailwindAdjustment
    if runway.isTurf { distance *= landingDistance_unpavedAdjustment }
    return distance
  }

  override var meetsGoAroundClimbGradient: Value<Bool> {
    switch landingDistanceFt {
      case .notAvailable: .notAvailable
      case .notAuthorized: .notAuthorized
      case .offscaleHigh: .value(false)
      default: .value(true)
    }
  }

  // MARK: - Base Values

  private var takeoffRunBaseFt: Value<Double> {
    takeoffRunData.value(
      for: [weight, altitude, temperature],
      clamping: [.clampLow, .clampLow, .clampLow]
    )
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    takeoffDistanceData.value(
      for: [weight, altitude, temperature],
      clamping: [.clampLow, .clampLow, .clampLow]
    )
  }

  private var landingRunBaseFt: Value<Double> {
    landingRunData.value(
      for: [weight, altitude, temperature],
      clamping: [.clampLow, .clampLow, .clampLow]
    )
  }

  private var landingDistanceBaseFt: Value<Double> {
    landingDistanceData.value(
      for: [weight, altitude, temperature],
      clamping: [.clampLow, .clampLow, .clampLow]
    )
  }

  // MARK: - Adjustments

  private var landingDistance_flapsUpAdjustment: Double { 1 + 0.38 }
  private var landingDistance_flapsUpIceAdjustment: Double { 1 + 0.52 }

  private var takeoffRun_headwindAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffRunHeadwindAdjustment(
      data: takeoffRun_headwindData,
      weight: weight,
      headwind: headwind
    )
  }

  private var takeoffDistance_headwindAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffDistanceHeadwindAdjustment(
      data: takeoffDistance_headwindData,
      weight: weight,
      headwind: headwind
    )
  }

  private var takeoffRun_tailwindAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffRunTailwindAdjustment(
      data: takeoffRun_tailwindData,
      weight: weight,
      tailwind: tailwind
    )
  }

  private var takeoffDistance_tailwindAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffDistanceTailwindAdjustment(
      data: takeoffDistance_tailwindData,
      weight: weight,
      tailwind: tailwind
    )
  }

  private var takeoffRun_uphillAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffRunUphillAdjustment(
      data: takeoffRun_uphillData,
      weight: weight,
      uphill: uphill
    )
  }

  private var takeoffRun_downhillAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffRunDownhillAdjustment(
      data: takeoffRun_downhillData,
      weight: weight,
      downhill: downhill
    )
  }

  private var takeoffDistance_unpavedAdjustment: Value<Double> {
    PerformanceAdjustments.takeoffDistanceUnpavedAdjustment(
      data: takeoffDistance_unpavedData,
      weight: weight
    )
  }

  private var landingRun_headwindAdjustment: Value<Double> {
    PerformanceAdjustments.landingRunHeadwindAdjustment(
      data: landingRun_headwindData,
      weight: weight,
      headwind: headwind
    )
  }

  private var landingDistance_headwindAdjustment: Value<Double> {
    PerformanceAdjustments.landingDistanceHeadwindAdjustment(
      data: landingDistance_headwindData,
      weight: weight,
      headwind: headwind
    )
  }

  private var landingRun_tailwindAdjustment: Value<Double> {
    PerformanceAdjustments.landingRunTailwindAdjustment(
      data: landingRun_tailwindData,
      weight: weight,
      tailwind: tailwind
    )
  }

  private var landingDistance_tailwindAdjustment: Value<Double> {
    PerformanceAdjustments.landingDistanceTailwindAdjustment(
      data: landingDistance_tailwindData,
      weight: weight,
      tailwind: tailwind
    )
  }

  private var landingRun_uphillAdjustment: Value<Double> {
    PerformanceAdjustments.landingRunUphillAdjustment(
      data: landingRun_uphillData,
      weight: weight,
      uphill: uphill
    )
  }

  private var landingRun_downhillAdjustment: Value<Double> {
    PerformanceAdjustments.landingRunDownhillAdjustment(
      data: landingRun_downhillData,
      weight: weight,
      downhill: downhill
    )
  }

  private var landingDistance_unpavedAdjustment: Value<Double> {
    PerformanceAdjustments.landingDistanceUnpavedAdjustment(
      data: landingDistance_unpavedData,
      weight: weight
    )
  }

  // MARK: - Initializers

  // swiftlint:disable force_try
  override init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMSnapshot?
  ) {
    let loader = DataTableLoader(modelType: .g1)
    let vrefPrefix = BasePerformanceModel(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam
    ).vrefPrefix(for: configuration.flapSetting)
    let landingPrefix = BasePerformanceModel(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam
    ).landingPrefix(for: configuration.flapSetting)

    takeoffRunData = try! loader.loadTakeoffRunData()
    takeoffDistanceData = try! loader.loadTakeoffDistanceData()
    takeoffClimbGradientData = try! loader.loadTakeoffClimbGradientData()
    takeoffClimbRateData = try! loader.loadTakeoffClimbRateData()
    vrefData = try! loader.loadVrefData(vrefPrefix: vrefPrefix)
    landingRunData = try! loader.loadLandingRunData(landingPrefix: landingPrefix)
    landingDistanceData = try! loader.loadLandingDistanceData(landingPrefix: landingPrefix)

    takeoffRun_headwindData = try! loader.loadTakeoffRunHeadwindData()
    takeoffRun_tailwindData = try! loader.loadTakeoffRunTailwindData()
    takeoffRun_downhillData = try! loader.loadTakeoffRunDownhillData()
    takeoffRun_uphillData = try! loader.loadTakeoffRunUphillData()
    takeoffDistance_headwindData = try! loader.loadTakeoffDistanceHeadwindData()
    takeoffDistance_tailwindData = try! loader.loadTakeoffDistanceTailwindData()
    takeoffDistance_unpavedData = try! loader.loadTakeoffDistanceUnpavedData()

    landingRun_headwindData = try! loader.loadLandingRunHeadwindData(landingPrefix: landingPrefix)
    landingRun_tailwindData = try! loader.loadLandingRunTailwindData(landingPrefix: landingPrefix)
    landingRun_downhillData = try! loader.loadLandingRunDownhillData(landingPrefix: landingPrefix)
    landingRun_uphillData = try! loader.loadLandingRunUphillData(landingPrefix: landingPrefix)
    landingDistance_headwindData = try! loader.loadLandingDistanceHeadwindData(
      landingPrefix: landingPrefix
    )
    landingDistance_tailwindData = try! loader.loadLandingDistanceTailwindData(
      landingPrefix: landingPrefix
    )
    landingDistance_unpavedData = try! loader.loadLandingDistanceUnpavedData(
      landingPrefix: landingPrefix
    )

    contamination_compactSnowData = try! loader.loadContaminationCompactSnowData()
    contamination_drySnowData = try! loader.loadContaminationDrySnowData()
    contamination_slushData = try! loader.loadContaminationSlushData()
    contamination_waterData = try! loader.loadContaminationWaterData()

    enrouteClimb_gradientNormalData = try! loader.loadEnrouteClimbGradientData(
      iceContaminated: false
    )
    enrouteClimb_rateNormalData = try! loader.loadEnrouteClimbRateData(iceContaminated: false)
    enrouteClimb_speedNormalData = try! loader.loadEnrouteClimbSpeedData(iceContaminated: false)
    enrouteClimb_gradientIceContaminatedData = try! loader.loadEnrouteClimbGradientData(
      iceContaminated: true
    )
    enrouteClimb_rateIceContaminatedData = try! loader.loadEnrouteClimbRateData(
      iceContaminated: true
    )
    enrouteClimb_speedIceContaminatedData = try! loader.loadEnrouteClimbSpeedData(
      iceContaminated: true
    )

    timeFuelDistanceToClimb_timeData = try! loader.loadTimeFuelDistanceTimeData()
    timeFuelDistanceToClimb_fuelData = try! loader.loadTimeFuelDistanceFuelData()
    timeFuelDistanceToClimb_distanceData = try! loader.loadTimeFuelDistanceDistanceData()

    super.init(conditions: conditions, configuration: configuration, runway: runway, notam: notam)
  }
  // swiftlint:enable force_try

  // MARK: - Functions

  private func landingRun_contaminationAddition(distance: Value<Double>) -> Value<Double> {
    ContaminationCalculator.landingRunContaminationAddition(
      distance: distance,
      contamination: notam?.contamination,
      compactSnowData: contamination_compactSnowData,
      drySnowData: contamination_drySnowData,
      slushData: contamination_slushData,
      waterData: contamination_waterData
    )
  }
}
