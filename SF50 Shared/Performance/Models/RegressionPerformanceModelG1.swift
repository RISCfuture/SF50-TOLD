import Foundation

/// Regression-based performance model for first-generation SF50 Vision Jet (G1).
///
/// ``RegressionPerformanceModelG1`` calculates takeoff and landing performance using
/// polynomial regression equations derived from AFM table data. This model provides
/// smoother interpolation than the tabular model and includes statistical uncertainty.
///
/// The G1 model uses the original thrust schedule for performance calculations.
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
/// - G1 thrust schedule selected (not updated thrust)
final class RegressionPerformanceModelG1: BaseSF50RegressionPerformanceModel {

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
    let value =
      -9.679627e-01 * weight
      - 8.797440e-02 * altitude
      - 1.482886e+01 * temperature
      + 5.156758e-05 * pow(weight, 2)
      + 8.729313e-06 * weight * altitude
      + 1.734973e-03 * weight * temperature
      - 1.265253e-06 * pow(altitude, 2)
      - 7.593253e-04 * altitude * temperature
      - 1.772246e-01 * pow(temperature, 2)
      + 5.234772e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff climb/gradient"))
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    let value =
      -1.593479e+00 * weight
      - 7.809528e-02 * altitude
      - 3.412035e+01 * temperature
      + 8.690843e-05 * pow(weight, 2)
      + 7.398389e-06 * weight * altitude
      + 4.068048e-03 * weight * temperature
      - 2.762589e-06 * pow(altitude, 2)
      - 1.350987e-03 * altitude * temperature
      - 2.516661e-01 * pow(temperature, 2)
      + 8.450814e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff climb/rate"))
  }

  private var takeoffRunBaseFt: Value<Double> {
    let value =
      1.103418e-01 * weight
      - 1.486829e-01 * altitude
      - 1.410806e-01 * temperature
      + 2.924272e-05 * pow(weight, 2)
      + 2.173964e-05 * weight * altitude
      - 1.841685e-04 * weight * temperature
      + 2.150097e-05 * pow(altitude, 2)
      + 6.299339e-03 * altitude * temperature
      + 9.185721e-01 * pow(temperature, 2)
      + 2.096770e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff/ground run"))
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    let value =
      -9.981555e-09 * weight
      + 4.097431e-06 * altitude
      - 1.927710e-06 * temperature
      + 6.375723e-05 * pow(weight, 2)
      + 5.704139e-05 * weight * altitude
      - 4.862208e-03 * weight * temperature
      - 6.427629e-05 * pow(altitude, 2)
      - 1.045557e-02 * altitude * temperature
      - 6.477677e-04 * pow(temperature, 2)
      - 1.712046e-10 * pow(weight, 3)
      - 3.763884e-09 * pow(weight, 2) * altitude
      + 1.331791e-06 * pow(weight, 2) * temperature
      + 6.451272e-09 * weight * pow(altitude, 2)
      + 2.005913e-06 * weight * altitude * temperature
      + 1.411999e-04 * weight * pow(temperature, 2)
      + 3.801160e-09 * pow(altitude, 3)
      + 7.857283e-07 * pow(altitude, 2) * temperature
      + 1.203680e-04 * altitude * pow(temperature, 2)
      + 8.687972e-03 * pow(temperature, 3)
      + 5.995362e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff/total distance"))
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
    let value =
      2.775330e-09 * weight
      - 3.098031e-02 * altitude
      - 3.157310e-05 * temperature
      + 2.719964e-05 * pow(weight, 2)
      + 1.330756e-05 * weight * altitude
      + 1.040523e-03 * weight * temperature
      + 3.490447e-06 * pow(altitude, 2)
      + 2.053043e-04 * altitude * temperature
      - 3.061748e-03 * pow(temperature, 2)
      + 7.073789e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/landing/100/ground run"))
  }

  private var landingRunBaseFt_flaps50: Value<Double> {
    let value =
      3.497198e-09 * weight
      - 4.921147e-02 * altitude
      - 4.739407e-04 * temperature
      + 3.565969e-05 * pow(weight, 2)
      + 1.861655e-05 * weight * altitude
      + 1.376133e-03 * weight * temperature
      + 4.930553e-06 * pow(altitude, 2)
      + 2.996259e-04 * altitude * temperature
      - 4.640237e-03 * pow(temperature, 2)
      + 9.424229e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/landing/50/ground run"))
  }

  private var landingRunBaseFt_flaps50Ice: Value<Double> {
    let value =
      4.797773e-09 * weight
      - 5.671105e-02 * altitude
      - 2.508229e-04 * temperature
      + 5.073784e-05 * pow(weight, 2)
      + 2.449179e-05 * weight * altitude
      + 1.860140e-03 * weight * temperature
      + 6.583339e-06 * pow(altitude, 2)
      + 4.734046e-04 * altitude * temperature
      + 1.303330e-03 * pow(temperature, 2)
      + 1.332123e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/landing/50 ice/ground run")
    )
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
    let value =
      6.367162e-09 * weight
      - 4.398670e-02 * altitude
      - 8.046716e-06 * temperature
      + 6.309703e-05 * pow(weight, 2)
      + 1.693317e-05 * weight * altitude
      + 1.263443e-03 * weight * temperature
      + 4.800004e-06 * pow(altitude, 2)
      + 2.735636e-04 * altitude * temperature
      - 2.084334e-03 * pow(temperature, 2)
      + 4.956557e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/landing/100/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50: Value<Double> {
    let value =
      7.651288e-09 * weight
      - 8.429529e-02 * altitude
      - 1.588030e-03 * temperature
      + 7.797669e-05 * pow(weight, 2)
      + 2.718658e-05 * weight * altitude
      + 1.761105e-03 * weight * temperature
      + 6.676567e-06 * pow(altitude, 2)
      + 3.819460e-04 * altitude * temperature
      - 9.341252e-03 * pow(temperature, 2)
      + 6.720116e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/landing/50/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50Ice: Value<Double> {
    let value =
      1.060979e-08 * weight
      - 1.567205e-01 * altitude
      - 2.849387e-03 * temperature
      + 1.165651e-04 * pow(weight, 2)
      + 4.831958e-05 * weight * altitude
      + 2.563588e-03 * weight * temperature
      + 9.507242e-06 * pow(altitude, 2)
      + 6.444080e-04 * altitude * temperature
      + 9.480970e-03 * pow(temperature, 2)
      + 9.070002e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/landing/50 ice/total distance")
    )
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

  override init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMInput?,
    aircraftType: AircraftType
  ) {
    super.init(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam,
      aircraftType: aircraftType
    )
  }
}
