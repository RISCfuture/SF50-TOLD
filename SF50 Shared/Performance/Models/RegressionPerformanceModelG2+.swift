import Foundation

/// Regression-based performance model for second-generation SF50 Vision Jet (G2/G2+).
///
/// ``RegressionPerformanceModelG2Plus`` calculates takeoff and landing performance using
/// polynomial regression equations derived from AFM table data. This model provides
/// smoother interpolation than the tabular model and includes statistical uncertainty.
///
/// The G2+ model uses the updated thrust schedule which provides improved takeoff
/// performance compared to the G1.
///
/// ## Regression Approach
///
/// Each performance output (ground run, distance, climb rate, etc.) is computed using
/// a polynomial equation with weight, altitude, and temperature as inputs. The
/// coefficients were fitted to AFM table data with residual errors providing
/// uncertainty bounds.
///
/// ## Usage
///
/// This model is selected automatically when the user has:
/// - Regression model enabled in settings
/// - G2/G2+ thrust schedule selected (updated thrust)
final class RegressionPerformanceModelG2Plus: BaseSF50RegressionPerformanceModel {

  // MARK: - Equations

  // Takeoff Equations
  private let takeoffRunEquation: RegressionEquation
  private let takeoffDistanceEquation: RegressionEquation
  private let takeoffClimbGradientEquation: RegressionEquation
  private let takeoffClimbRateEquation: RegressionEquation

  // En Route Climb Equations
  private let enrouteClimbGradientNormalEquation: RegressionEquation
  private let enrouteClimbRateNormalEquation: RegressionEquation
  private let enrouteClimbSpeedNormalEquation: RegressionEquation
  private let enrouteClimbGradientIceEquation: RegressionEquation
  private let enrouteClimbRateIceEquation: RegressionEquation
  private let enrouteClimbSpeedIceEquation: RegressionEquation

  // Landing Equations
  private let landingRunFlaps100Equation: RegressionEquation
  private let landingRunFlaps50Equation: RegressionEquation
  private let landingRunFlaps50IceEquation: RegressionEquation
  private let landingDistanceFlaps100Equation: RegressionEquation
  private let landingDistanceFlaps50Equation: RegressionEquation
  private let landingDistanceFlaps50IceEquation: RegressionEquation

  // MARK: - VREF
  // Note: G2+ uses G2 VREF data (no supplement data available)

  override var VrefKts: Value<Double> {
    let value =
      switch configuration.flapSetting {
        case .flapsUp:
          1.000000e-02 * weight + 4.900000e+01
        case .flapsUpIce:
          1.250000e-02 * weight + 6.500000e+01
        case .flaps50:
          9.000000e-03 * weight + 4.600000e+01
        case .flaps50Ice:
          1.100000e-02 * weight + 5.400000e+01
        case .flaps100:
          9.000000e-03 * weight + 3.500000e+01
      }
    return .value(value)
  }

  // MARK: - Takeoff

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
    evaluate(takeoffClimbGradientEquation)
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    evaluate(takeoffClimbRateEquation)
  }

  // MARK: - En Route Climb
  // Note: G2+ uses G2 enroute climb data (no supplement data available)

  override var enrouteClimbGradientFtNmi_normal: Value<Double> {
    evaluate(enrouteClimbGradientNormalEquation)
  }

  override var enrouteClimbRateFtMin_normal: Value<Double> {
    evaluate(enrouteClimbRateNormalEquation)
  }

  override var enrouteClimbSpeedKIAS_normal: Value<Double> {
    evaluate(enrouteClimbSpeedNormalEquation)
  }

  override var enrouteClimbGradientFtNmi_iceContaminated: Value<Double> {
    evaluate(enrouteClimbGradientIceEquation)
  }

  override var enrouteClimbRateFtMin_iceContaminated: Value<Double> {
    evaluate(enrouteClimbRateIceEquation)
  }

  override var enrouteClimbSpeedKIAS_iceContaminated: Value<Double> {
    evaluate(enrouteClimbSpeedIceEquation)
  }

  private var takeoffRunBaseFt: Value<Double> {
    evaluate(takeoffRunEquation)
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    evaluate(takeoffDistanceEquation)
  }

  private var takeoffRun_headwindAdjustment: Double {
    let factor = 0.07
    return PerformanceAdjustments.takeoffRunHeadwindAdjustment(factor: factor, headwind: headwind)
  }

  private var takeoffDistance_headwindAdjustment: Double {
    let factor = 0.07
    return PerformanceAdjustments.takeoffDistanceHeadwindAdjustment(
      factor: factor,
      headwind: headwind
    )
  }

  private var takeoffRun_tailwindAdjustment: Double {
    let factor = 0.44
    return PerformanceAdjustments.takeoffRunTailwindAdjustment(factor: factor, tailwind: tailwind)
  }

  private var takeoffDistance_tailwindAdjustment: Double {
    let factor =
      switch weight {
        case ...5500: 0.4
        default: 0.51 + -2.000000e-05 * weight
      }
    return PerformanceAdjustments.takeoffDistanceTailwindAdjustment(
      factor: factor,
      tailwind: tailwind
    )
  }

  private var takeoffRun_uphillAdjustment: Double {
    let factor = 0.03 + 2.000000e-05 * weight
    return PerformanceAdjustments.takeoffRunUphillAdjustment(factor: factor, uphill: uphill)
  }

  private var takeoffRun_downhillAdjustment: Double {
    let factor =
      switch weight {
        case ...5500: 0.04
        default: max(min(-0.07 + 2.000000e-05 * weight, 0.1), -0.1)  // Clamp between -0.1 and 0.1
      }
    return PerformanceAdjustments.takeoffRunDownhillAdjustment(factor: factor, downhill: downhill)
  }

  private var takeoffDistance_unpavedAdjustment: Double {
    let factor = 0.21
    return PerformanceAdjustments.takeoffDistanceUnpavedAdjustment(factor: factor)
  }

  // MARK: Landing

  override var landingRunFt: Value<Double> {
    var run = landingRun_contaminationAddition(distance: landingRunBaseFt)
    run *= landingRun_headwindAdjustment
    run *= landingRun_tailwindAdjustment
    run *= landingRun_uphillAdjustment
    run *= landingRun_downhillAdjustment
    return run
  }

  override var meetsGoAroundClimbGradient: Value<Bool> {
    // Logistic regression with polynomial features
    let w = (weight - 5000) / 500
    let a = altitude / 10000
    let t = temperature / 50

    // Polynomial features (degree 2)
    let features = [
      w,  // w
      a,  // a
      t,  // t
      w * w,  // w^2
      w * a,  // w*a
      w * t,  // w*t
      a * a,  // a^2
      a * t,  // a*t
      t * t  // t^2
    ]

    let coefficients = [
      1.079048e-02,  // w
      -1.099903e+00,  // a
      -8.847584e-01,  // t
      -1.057192e-01,  // w^2
      -2.604333e-01,  // w a
      -2.908171e-01,  // w t
      -3.599073e+00,  // a^2
      1.033181e+00,  // a t
      -3.652266e+00  // t^2
    ]

    let intercept = 5.906422e+00

    // Calculate logit
    var logit = intercept
    for i in 0..<features.count {
      logit += coefficients[i] * features[i]
    }

    // Convert to probability using sigmoid function
    let probability = 1.0 / (1.0 + exp(-logit))

    return .value(probability > 0.5)
  }

  override var landingRunBaseFt: Value<Double> {
    switch configuration.flapSetting {
      case .flaps100: landingRunBaseFt_flaps100
      case .flaps50, .flapsUp: landingRunBaseFt_flaps50
      case .flaps50Ice, .flapsUpIce: landingRunBaseFt_flaps50Ice
    //            case .flapsUp: landingRunBaseFt_flaps50*1.38
    //            case .flapsUpIce: landingRunBaseFt_flaps50Ice*1.52
    }
  }

  private var landingRunBaseFt_flaps100: Value<Double> {
    evaluate(landingRunFlaps100Equation)
  }

  private var landingRunBaseFt_flaps50: Value<Double> {
    evaluate(landingRunFlaps50Equation)
  }

  private var landingRunBaseFt_flaps50Ice: Value<Double> {
    evaluate(landingRunFlaps50IceEquation)
  }

  override var landingDistanceBaseFt: Value<Double> {
    switch configuration.flapSetting {
      case .flaps100: landingDistanceBaseFt_flaps100
      case .flaps50: landingDistanceBaseFt_flaps50
      case .flaps50Ice: landingDistanceBaseFt_flaps50Ice
      case .flapsUp: landingDistanceBaseFt_flaps50 * 1.38
      case .flapsUpIce: landingDistanceBaseFt_flaps50Ice * 1.52
    }
  }

  private var landingDistanceBaseFt_flaps100: Value<Double> {
    evaluate(landingDistanceFlaps100Equation)
  }

  private var landingDistanceBaseFt_flaps50: Value<Double> {
    evaluate(landingDistanceFlaps50Equation)
  }

  private var landingDistanceBaseFt_flaps50Ice: Value<Double> {
    evaluate(landingDistanceFlaps50IceEquation)
  }

  override var landingRun_headwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps100: 0.08
        default: 0.07
      }
    return PerformanceAdjustments.landingRunHeadwindAdjustment(factor: factor, headwind: headwind)
  }

  override var landingDistance_headwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps50, .flapsUp:
          max(0.112857 + -9.523810e-06 * weight, 0.01)  // Ensure positive, min 0.01
        case .flaps50Ice, .flapsUpIce: 0.06
        case .flaps100: 0.07
      }
    return PerformanceAdjustments.landingDistanceHeadwindAdjustment(
      factor: factor,
      headwind: headwind
    )
  }

  override var landingRun_tailwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps100: 0.49
        case .flaps50Ice, .flapsUpIce: 0.37
        case .flaps50, .flapsUp: 0.42
      }
    return PerformanceAdjustments.landingRunTailwindAdjustment(factor: factor, tailwind: tailwind)
  }

  override var landingDistance_tailwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps50, .flapsUp:
          max(0.432857 + -9.523810e-06 * weight, 0.1)  // Ensure positive, min 0.1
        case .flaps50Ice, .flapsUpIce:
          max(0.382857 + -9.523810e-06 * weight, 0.1)  // Ensure positive, min 0.1
        case .flaps100:
          max(0.492857 + -9.523810e-06 * weight, 0.1)  // Ensure positive, min 0.1
      }
    return PerformanceAdjustments.landingDistanceTailwindAdjustment(
      factor: factor,
      tailwind: tailwind
    )
  }

  override var landingRun_uphillAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps50Ice, .flapsUpIce: 0.06
        default: 0.05
      }
    return PerformanceAdjustments.landingRunUphillAdjustment(factor: factor, uphill: uphill)
  }

  override var landingRun_downhillAdjustment: Double {
    let factor = 0.06
    return PerformanceAdjustments.landingRunDownhillAdjustment(factor: factor, downhill: downhill)
  }

  override var landingDistance_unpavedAdjustment: Double {
    let factor = 0.2
    return PerformanceAdjustments.landingDistanceUnpavedAdjustment(factor: factor)
  }

  // MARK: - Initializer

  // swiftlint:disable force_try
  override init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMInput?,
    aircraftType: AircraftType
  ) {
    let loader = RegressionEquationLoader(aircraftType: aircraftType)

    // Load takeoff equations
    takeoffRunEquation = try! loader.loadTakeoffRunEquation()
    takeoffDistanceEquation = try! loader.loadTakeoffDistanceEquation()
    takeoffClimbGradientEquation = try! loader.loadTakeoffClimbGradientEquation()
    takeoffClimbRateEquation = try! loader.loadTakeoffClimbRateEquation()

    // Load en route climb equations
    enrouteClimbGradientNormalEquation = try! loader.loadEnrouteClimbGradientEquation(
      iceContaminated: false
    )
    enrouteClimbRateNormalEquation = try! loader.loadEnrouteClimbRateEquation(
      iceContaminated: false
    )
    enrouteClimbSpeedNormalEquation = try! loader.loadEnrouteClimbSpeedEquation(
      iceContaminated: false
    )
    enrouteClimbGradientIceEquation = try! loader.loadEnrouteClimbGradientEquation(
      iceContaminated: true
    )
    enrouteClimbRateIceEquation = try! loader.loadEnrouteClimbRateEquation(iceContaminated: true)
    enrouteClimbSpeedIceEquation = try! loader.loadEnrouteClimbSpeedEquation(iceContaminated: true)

    // Load landing equations
    landingRunFlaps100Equation = try! loader.loadLandingRunEquation(flapSetting: .flaps100)
    landingRunFlaps50Equation = try! loader.loadLandingRunEquation(flapSetting: .flaps50)
    landingRunFlaps50IceEquation = try! loader.loadLandingRunEquation(flapSetting: .flaps50Ice)
    landingDistanceFlaps100Equation = try! loader.loadLandingDistanceEquation(
      flapSetting: .flaps100
    )
    landingDistanceFlaps50Equation = try! loader.loadLandingDistanceEquation(flapSetting: .flaps50)
    landingDistanceFlaps50IceEquation = try! loader.loadLandingDistanceEquation(
      flapSetting: .flaps50Ice
    )

    super.init(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam,
      aircraftType: aircraftType
    )
  }
  // swiftlint:enable force_try
}
