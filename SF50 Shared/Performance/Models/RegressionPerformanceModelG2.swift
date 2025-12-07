import Foundation

/// Regression-based performance model for second-generation SF50 Vision Jet (G2).
///
/// ``RegressionPerformanceModelG2`` calculates takeoff and landing performance using
/// polynomial regression equations derived from AFM table data. This model provides
/// smoother interpolation than the tabular model and includes statistical uncertainty.
///
/// The G2 model uses the original thrust schedule for performance calculations.
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
/// - G2 without updated thrust (SB5X-72-01 not completed)
final class RegressionPerformanceModelG2: BaseSF50RegressionPerformanceModel {

  // MARK: - Equations

  // Takeoff Equations
  private let takeoffRunEquation: RegressionEquation
  private let takeoffDistanceEquation: RegressionEquation
  private let takeoffClimbGradientEquation: RegressionEquation
  private let takeoffClimbRateEquation: RegressionEquation

  // Landing Equations
  private let landingRunFlaps100Equation: RegressionEquation
  private let landingRunFlaps50Equation: RegressionEquation
  private let landingRunFlaps50IceEquation: RegressionEquation
  private let landingDistanceFlaps100Equation: RegressionEquation
  private let landingDistanceFlaps50Equation: RegressionEquation
  private let landingDistanceFlaps50IceEquation: RegressionEquation

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
    let factor = 0.06
    return PerformanceAdjustments.takeoffDistanceHeadwindAdjustment(
      factor: factor,
      headwind: headwind
    )
  }

  private var takeoffRun_tailwindAdjustment: Double {
    let factor = 0.4
    return PerformanceAdjustments.takeoffRunTailwindAdjustment(factor: factor, tailwind: tailwind)
  }

  private var takeoffDistance_tailwindAdjustment: Double {
    let factor =
      switch weight {
        case ...5500: 0.36
        default: max(0.470000 + -2.000000e-05 * weight, 0.1)  // Ensure factor stays positive, min 0.1
      }
    return PerformanceAdjustments.takeoffDistanceTailwindAdjustment(
      factor: factor,
      tailwind: tailwind
    )
  }

  private var takeoffRun_uphillAdjustment: Double {
    let factor = 0.02 + 2.000000e-05 * weight
    return PerformanceAdjustments.takeoffRunUphillAdjustment(factor: factor, uphill: uphill)
  }

  private var takeoffRun_downhillAdjustment: Double {
    let factor =
      switch weight {
        case ...5500: 0.01
        default: max(min(-0.1 + 2.000000e-05 * weight, 0.1), -0.1)  // Clamp between -0.1 and 0.1
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
      4.869268e-02,  // w
      -1.168657e+00,  // a
      -9.966391e-01,  // t
      -4.661816e-02,  // w^2
      -3.582346e-01,  // w a
      -4.236130e-01,  // w t
      -3.480137e+00,  // a^2
      7.908706e-01,  // a t
      -3.614055e+00  // t^2
    ]

    let intercept = 5.759350e+00

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

  override var landingDistance_tailwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps50, .flapsUp:
          0.432857 + -9.523810e-06 * weight
        case .flaps50Ice, .flapsUpIce:
          0.382857 + -9.523810e-06 * weight
        case .flaps100:
          0.492857 + -9.523810e-06 * weight
      }
    return PerformanceAdjustments.landingDistanceTailwindAdjustment(
      factor: factor,
      tailwind: tailwind
    )
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
