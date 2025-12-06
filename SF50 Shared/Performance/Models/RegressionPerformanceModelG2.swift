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
      -1.297871e-03 * weight
      - 2.593667e-02 * altitude
      - 1.001035e-03 * temperature
      - 1.395744e-04 * pow(weight, 2)
      + 1.367556e-05 * weight * altitude
      - 3.518765e-03 * weight * temperature
      - 2.225065e-05 * pow(altitude, 2)
      - 1.387819e-03 * altitude * temperature
      - 2.774593e-01 * pow(temperature, 2)
      + 1.239396e-08 * pow(weight, 3)
      - 6.111878e-10 * pow(weight, 2) * altitude
      + 4.573351e-07 * pow(weight, 2) * temperature
      + 1.942515e-10 * weight * pow(altitude, 2)
      + 1.112957e-07 * weight * altitude * temperature
      + 1.408688e-05 * weight * pow(temperature, 2)
      + 1.341070e-09 * pow(altitude, 3)
      + 2.599273e-09 * pow(altitude, 2) * temperature
      + 5.927559e-06 * altitude * pow(temperature, 2)
      + 1.269860e-04 * pow(temperature, 3)
      + 3.606597e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/takeoff climb/gradient"))
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    let value =
      -8.575431e-07 * weight
      - 1.053722e-05 * altitude
      - 4.156913e-06 * temperature
      - 2.163308e-04 * pow(weight, 2)
      + 2.488408e-05 * weight * altitude
      - 8.523092e-03 * weight * temperature
      - 3.577199e-05 * pow(altitude, 2)
      - 2.397259e-03 * altitude * temperature
      - 5.587642e-04 * pow(temperature, 2)
      + 1.970311e-08 * pow(weight, 3)
      - 1.880382e-09 * pow(weight, 2) * altitude
      + 1.131326e-06 * pow(weight, 2) * temperature
      + 1.548475e-10 * weight * pow(altitude, 2)
      + 2.134670e-07 * weight * altitude * temperature
      - 5.238331e-05 * weight * pow(temperature, 2)
      + 2.157574e-09 * pow(altitude, 3)
      - 1.006350e-08 * pow(altitude, 2) * temperature
      + 6.046660e-06 * altitude * pow(temperature, 2)
      + 3.186831e-04 * pow(temperature, 3)
      + 5.531120e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/takeoff climb/rate"))
  }

  private var takeoffRunBaseFt: Value<Double> {
    let value =
      1.913163e-09 * weight
      - 6.563788e-07 * altitude
      - 9.038001e-08 * temperature
      + 5.910296e-05 * pow(weight, 2)
      + 3.358402e-05 * weight * altitude
      - 1.072438e-04 * weight * temperature
      - 2.985046e-05 * pow(altitude, 2)
      - 3.567002e-03 * altitude * temperature
      - 1.135403e-04 * pow(temperature, 2)
      - 3.728022e-09 * pow(weight, 3)
      - 2.082088e-09 * pow(weight, 2) * altitude
      + 3.389479e-07 * pow(weight, 2) * temperature
      + 2.376516e-09 * weight * pow(altitude, 2)
      + 7.206248e-07 * weight * altitude * temperature
      + 7.858924e-05 * weight * pow(temperature, 2)
      + 2.290470e-09 * pow(altitude, 3)
      + 4.526740e-07 * pow(altitude, 2) * temperature
      + 7.133712e-05 * altitude * pow(temperature, 2)
      + 5.189073e-03 * pow(temperature, 3)
      + 5.273758e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/takeoff/ground run"))
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    let value =
      -6.574304e-09 * weight
      + 2.859644e-07 * altitude
      - 1.896867e-06 * temperature
      + 7.172035e-05 * pow(weight, 2)
      + 5.349364e-05 * weight * altitude
      - 4.759607e-03 * weight * temperature
      - 6.321473e-05 * pow(altitude, 2)
      - 1.039287e-02 * altitude * temperature
      - 6.203422e-04 * pow(temperature, 2)
      - 9.233707e-10 * pow(weight, 3)
      - 3.388453e-09 * pow(weight, 2) * altitude
      + 1.339559e-06 * pow(weight, 2) * temperature
      + 6.391390e-09 * weight * pow(altitude, 2)
      + 1.975763e-06 * weight * altitude * temperature
      + 1.323345e-04 * weight * pow(temperature, 2)
      + 3.787568e-09 * pow(altitude, 3)
      + 7.831313e-07 * pow(altitude, 2) * temperature
      + 1.243363e-04 * altitude * pow(temperature, 2)
      + 9.073682e-03 * pow(temperature, 3)
      + 5.170649e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/takeoff/total distance"))
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
      -8.262997e-09 * weight
      + 2.567265e-09 * altitude
      + 4.055561e-07 * temperature
      - 1.724544e-10 * pow(weight, 2)
      + 1.700862e-05 * weight * altitude
      + 1.006425e-03 * weight * temperature
      - 6.777038e-06 * pow(altitude, 2)
      - 6.876755e-05 * altitude * temperature
      + 9.367554e-06 * pow(temperature, 2)
      + 3.662431e-09 * pow(weight, 3)
      - 9.668792e-10 * pow(weight, 2) * altitude
      + 1.514967e-10 * pow(weight, 2) * temperature
      + 6.805458e-10 * weight * pow(altitude, 2)
      + 4.721025e-08 * weight * altitude * temperature
      + 4.501395e-07 * weight * pow(temperature, 2)
      + 4.671315e-10 * pow(altitude, 3)
      + 9.661607e-09 * pow(altitude, 2) * temperature
      - 2.774676e-07 * altitude * pow(temperature, 2)
      - 3.103097e-05 * pow(temperature, 3)
      + 9.088300e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/landing/100/ground run"))
  }

  private var landingRunBaseFt_flaps50: Value<Double> {
    let value =
      -1.750568e-08 * weight
      + 6.885170e-09 * altitude
      + 5.167229e-07 * temperature
      - 4.645560e-11 * pow(weight, 2)
      + 2.378922e-05 * weight * altitude
      + 1.283325e-03 * weight * temperature
      - 9.897534e-06 * pow(altitude, 2)
      - 5.906576e-05 * altitude * temperature
      + 1.293255e-05 * pow(temperature, 2)
      + 4.831502e-09 * pow(weight, 3)
      - 1.455806e-09 * pow(weight, 2) * altitude
      + 1.130927e-08 * pow(weight, 2) * temperature
      + 9.689944e-10 * weight * pow(altitude, 2)
      + 5.245523e-08 * weight * altitude * temperature
      - 3.290784e-07 * weight * pow(temperature, 2)
      + 6.573127e-10 * pow(altitude, 3)
      + 1.453876e-08 * pow(altitude, 2) * temperature
      - 2.260539e-07 * altitude * pow(temperature, 2)
      + 3.991170e-05 * pow(temperature, 3)
      + 1.198426e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2/landing/50/ground run"))
  }

  private var landingRunBaseFt_flaps50Ice: Value<Double> {
    let value =
      -9.047556e-09 * weight
      + 1.311885e-08 * altitude
      + 6.464410e-07 * temperature
      - 9.847442e-10 * pow(weight, 2)
      + 3.261620e-05 * weight * altitude
      + 1.606545e-03 * weight * temperature
      - 1.278795e-05 * pow(altitude, 2)
      + 1.836965e-05 * altitude * temperature
      - 3.210352e-06 * pow(temperature, 2)
      + 6.904665e-09 * pow(weight, 3)
      - 1.977793e-09 * pow(weight, 2) * altitude
      + 5.688912e-08 * pow(weight, 2) * temperature
      + 1.330853e-09 * weight * pow(altitude, 2)
      + 4.853797e-08 * weight * altitude * temperature
      - 2.186938e-07 * weight * pow(temperature, 2)
      + 8.594080e-10 * pow(altitude, 3)
      + 2.300161e-08 * pow(altitude, 2) * temperature
      + 3.750013e-07 * altitude * pow(temperature, 2)
      + 1.111142e-04 * pow(temperature, 3)
      + 1.694792e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/landing/50 ice/ground run")
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
      -5.711109e-09 * weight
      + 6.611118e-09 * altitude
      + 4.802346e-07 * temperature
      - 1.157431e-10 * pow(weight, 2)
      + 2.367138e-05 * weight * altitude
      + 1.192298e-03 * weight * temperature
      - 1.060215e-05 * pow(altitude, 2)
      - 2.234508e-05 * altitude * temperature
      + 1.040193e-05 * pow(temperature, 2)
      + 8.471363e-09 * pow(weight, 3)
      - 1.713450e-09 * pow(weight, 2) * altitude
      + 2.472552e-09 * pow(weight, 2) * temperature
      + 1.181133e-09 * weight * pow(altitude, 2)
      + 5.476543e-08 * weight * altitude * temperature
      + 1.229553e-06 * weight * pow(temperature, 2)
      + 6.490110e-10 * pow(altitude, 3)
      + 1.102072e-08 * pow(altitude, 2) * temperature
      - 6.801341e-07 * altitude * pow(temperature, 2)
      - 4.100578e-05 * pow(temperature, 3)
      + 9.790539e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/landing/100/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50: Value<Double> {
    let value =
      -1.186551e-08 * weight
      + 1.056264e-08 * altitude
      + 5.501203e-07 * temperature
      + 7.918619e-11 * pow(weight, 2)
      + 3.171583e-05 * weight * altitude
      + 1.366452e-03 * weight * temperature
      - 1.582492e-05 * pow(altitude, 2)
      - 1.239979e-04 * altitude * temperature
      + 1.245209e-05 * pow(temperature, 2)
      + 1.051153e-08 * pow(weight, 3)
      - 2.198252e-09 * pow(weight, 2) * altitude
      + 5.513397e-08 * pow(weight, 2) * temperature
      + 1.784134e-09 * weight * pow(altitude, 2)
      + 8.354244e-08 * weight * altitude * temperature
      - 5.120626e-08 * weight * pow(temperature, 2)
      + 8.979622e-10 * pow(altitude, 3)
      + 1.783943e-08 * pow(altitude, 2) * temperature
      - 4.274917e-07 * altitude * pow(temperature, 2)
      + 4.934371e-05 * pow(temperature, 3)
      + 1.260087e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/landing/50/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50Ice: Value<Double> {
    let value =
      -3.113921e-09 * weight
      + 1.643303e-08 * altitude
      + 3.783311e-07 * temperature
      - 4.744081e-10 * pow(weight, 2)
      + 4.076925e-05 * weight * altitude
      + 9.402421e-04 * weight * temperature
      - 2.342663e-05 * pow(altitude, 2)
      - 7.365268e-05 * altitude * temperature
      - 2.012834e-06 * pow(temperature, 2)
      + 1.600132e-08 * pow(weight, 3)
      - 1.963078e-09 * pow(weight, 2) * altitude
      + 3.155120e-07 * pow(weight, 2) * temperature
      + 2.901082e-09 * weight * pow(altitude, 2)
      + 9.548564e-08 * weight * altitude * temperature
      - 4.815675e-07 * weight * pow(temperature, 2)
      + 1.239736e-09 * pow(altitude, 3)
      + 3.038285e-08 * pow(altitude, 2) * temperature
      + 6.725432e-07 * altitude * pow(temperature, 2)
      + 7.393735e-05 * pow(temperature, 3)
      + 1.744147e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/landing/50 ice/total distance")
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
