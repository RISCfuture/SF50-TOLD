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

  // MARK: - VREF

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

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff climb/gradient"))
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    let value =
      -8.853973e-07 * weight
      - 9.997156e-06 * altitude
      - 4.167365e-06 * temperature
      - 2.158521e-04 * pow(weight, 2)
      + 2.537577e-05 * weight * altitude
      - 8.575276e-03 * weight * temperature
      - 3.607324e-05 * pow(altitude, 2)
      - 2.379917e-03 * altitude * temperature
      - 5.568583e-04 * pow(temperature, 2)
      + 1.964734e-08 * pow(weight, 3)
      - 1.988179e-09 * pow(weight, 2) * altitude
      + 1.139745e-06 * pow(weight, 2) * temperature
      + 2.202196e-10 * weight * pow(altitude, 2)
      + 2.132622e-07 * weight * altitude * temperature
      - 5.258665e-05 * weight * pow(temperature, 2)
      + 2.157280e-09 * pow(altitude, 3)
      - 1.168495e-08 * pow(altitude, 2) * temperature
      + 6.092539e-06 * altitude * pow(temperature, 2)
      + 3.431426e-04 * pow(temperature, 3)
      + 5.527140e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff climb/rate"))
  }

  // MARK: - En Route Climb

  override var enrouteClimbGradientFtNmi_normal: Value<Double> {
    let value =
      -1.750601e-03 * weight
      - 3.930394e-02 * altitude
      - 9.763883e-04 * temperature
      - 7.390428e-05 * pow(weight, 2)
      + 4.577891e-06 * weight * altitude
      - 2.317623e-03 * weight * temperature
      - 9.433411e-07 * pow(altitude, 2)
      - 2.441435e-04 * altitude * temperature
      - 1.405646e-01 * pow(temperature, 2)
      + 6.832811e-09 * pow(weight, 3)
      - 6.563374e-11 * pow(weight, 2) * altitude
      + 2.814662e-07 * pow(weight, 2) * temperature
      - 8.112508e-12 * weight * pow(altitude, 2)
      + 6.346279e-09 * weight * altitude * temperature
      + 8.481172e-06 * weight * pow(temperature, 2)
      + 1.829645e-11 * pow(altitude, 3)
      - 4.838783e-09 * pow(altitude, 2) * temperature
      - 3.070245e-06 * altitude * pow(temperature, 2)
      - 5.098345e-04 * pow(temperature, 3)
      + 1.901930e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/gradient")
    )
  }

  override var enrouteClimbRateFtMin_normal: Value<Double> {
    let value =
      -2.268091e-03 * weight
      - 6.172198e-02 * altitude
      - 3.476516e-03 * temperature
      - 2.275873e-04 * pow(weight, 2)
      + 1.882879e-06 * weight * altitude
      - 1.410535e-02 * weight * temperature
      - 6.312763e-06 * pow(altitude, 2)
      - 1.002386e-03 * altitude * temperature
      - 4.696270e-01 * pow(temperature, 2)
      + 2.115495e-08 * pow(weight, 3)
      + 9.049872e-10 * pow(weight, 2) * altitude
      + 1.768914e-06 * pow(weight, 2) * temperature
      + 7.051625e-11 * weight * pow(altitude, 2)
      + 3.767441e-08 * weight * altitude * temperature
      + 3.149277e-05 * weight * pow(temperature, 2)
      + 1.227435e-10 * pow(altitude, 3)
      - 2.188489e-09 * pow(altitude, 2) * temperature
      - 6.689144e-06 * altitude * pow(temperature, 2)
      - 9.721989e-05 * pow(temperature, 3)
      + 5.846790e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/rate")
    )
  }

  override var enrouteClimbSpeedKIAS_normal: Value<Double> {
    let value =
      -5.209245e-08 * weight
      + 7.530911e-05 * altitude
      - 1.948702e-06 * temperature
      + 3.823449e-07 * pow(weight, 2)
      - 7.169249e-08 * weight * altitude
      - 1.982677e-04 * weight * temperature
      - 2.111809e-07 * pow(altitude, 2)
      - 2.361609e-05 * altitude * temperature
      - 1.721835e-03 * pow(temperature, 2)
      - 9.701535e-12 * pow(weight, 3)
      + 9.588974e-12 * pow(weight, 2) * altitude
      + 1.924604e-08 * pow(weight, 2) * temperature
      - 3.737500e-12 * weight * pow(altitude, 2)
      - 3.414761e-09 * weight * altitude * temperature
      - 1.414580e-06 * weight * pow(temperature, 2)
      + 4.853268e-12 * pow(altitude, 3)
      + 3.361527e-10 * pow(altitude, 2) * temperature
      - 1.976420e-07 * altitude * pow(temperature, 2)
      - 3.870303e-06 * pow(temperature, 3)
      + 1.727692e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/speed")
    )
  }

  override var enrouteClimbGradientFtNmi_iceContaminated: Value<Double> {
    let value =
      -1.313095e-02 * weight
      - 8.724326e-02 * altitude
      - 3.772412e-03 * temperature
      - 9.191146e-05 * pow(weight, 2)
      + 2.219103e-05 * weight * altitude
      - 2.620950e-03 * weight * temperature
      - 3.270628e-06 * pow(altitude, 2)
      - 1.008908e-03 * altitude * temperature
      - 3.518759e-01 * pow(temperature, 2)
      + 8.885957e-09 * pow(weight, 3)
      - 1.627261e-09 * pow(weight, 2) * altitude
      + 3.051025e-07 * pow(weight, 2) * temperature
      + 5.261769e-11 * weight * pow(altitude, 2)
      + 2.674156e-08 * weight * altitude * temperature
      + 9.904180e-06 * weight * pow(temperature, 2)
      + 6.810569e-11 * pow(altitude, 3)
      - 5.250687e-09 * pow(altitude, 2) * temperature
      - 1.238255e-05 * altitude * pow(temperature, 2)
      - 3.857281e-03 * pow(temperature, 3)
      + 2.188203e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/gradient")
    )
  }

  override var enrouteClimbRateFtMin_iceContaminated: Value<Double> {
    let value =
      -3.194275e-02 * weight
      - 1.481729e-01 * altitude
      - 1.338694e-02 * temperature
      - 2.351943e-04 * pow(weight, 2)
      + 4.177221e-05 * weight * altitude
      - 1.011008e-02 * weight * temperature
      - 9.975214e-06 * pow(altitude, 2)
      - 2.625169e-03 * altitude * temperature
      - 9.195617e-01 * pow(temperature, 2)
      + 2.332753e-08 * pow(weight, 3)
      - 3.013181e-09 * pow(weight, 2) * altitude
      + 1.256744e-06 * pow(weight, 2) * temperature
      + 1.939423e-10 * weight * pow(altitude, 2)
      + 6.516931e-08 * weight * altitude * temperature
      + 2.925903e-05 * weight * pow(temperature, 2)
      + 1.800561e-10 * pow(altitude, 3)
      - 1.383394e-08 * pow(altitude, 2) * temperature
      - 3.413996e-05 * altitude * pow(temperature, 2)
      - 9.961493e-03 * pow(temperature, 3)
      + 5.367515e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/rate")
    )
  }

  override var enrouteClimbSpeedKIAS_iceContaminated: Value<Double> {
    let value =
      1.231219e-04 * weight
      + 6.566104e-03 * altitude
      + 8.821829e-06 * temperature
      - 4.357724e-09 * pow(weight, 2)
      - 2.688392e-06 * weight * altitude
      - 1.204098e-04 * weight * temperature
      - 1.840175e-07 * pow(altitude, 2)
      - 3.888821e-05 * altitude * temperature
      - 1.211419e-02 * pow(temperature, 2)
      + 1.538391e-11 * pow(weight, 3)
      + 2.714698e-10 * pow(weight, 2) * altitude
      + 1.876350e-08 * pow(weight, 2) * temperature
      + 1.958776e-11 * weight * pow(altitude, 2)
      + 5.154855e-09 * weight * altitude * temperature
      + 1.548085e-06 * weight * pow(temperature, 2)
      + 2.504486e-12 * pow(altitude, 3)
      + 1.534219e-10 * pow(altitude, 2) * temperature
      - 1.015759e-07 * altitude * pow(temperature, 2)
      - 3.839315e-05 * pow(temperature, 3)
      + 1.355810e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/speed")
    )
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

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/takeoff/ground run"))
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

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/landing/100/ground run"))
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

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g1/landing/50/ground run"))
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
      uncertainty: uncertainty(for: "g1/landing/100/total distance")
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
      uncertainty: uncertainty(for: "g1/landing/50/total distance")
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
      uncertainty: uncertainty(for: "g1/landing/50 ice/total distance")
    )
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
