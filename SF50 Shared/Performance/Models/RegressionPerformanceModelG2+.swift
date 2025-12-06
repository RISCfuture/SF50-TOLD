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
    let value =
      -1.104804e-03 * weight
      - 1.348839e-02 * altitude
      - 5.237401e-04 * temperature
      - 1.467286e-04 * pow(weight, 2)
      + 1.284247e-05 * weight * altitude
      - 1.578604e-03 * weight * temperature
      - 2.304159e-05 * pow(altitude, 2)
      - 1.429872e-03 * altitude * temperature
      - 2.383993e-01 * pow(temperature, 2)
      + 1.317727e-08 * pow(weight, 3)
      - 6.208062e-10 * pow(weight, 2) * altitude
      + 2.331900e-07 * pow(weight, 2) * temperature
      + 3.042921e-10 * weight * pow(altitude, 2)
      + 1.276207e-07 * weight * altitude * temperature
      + 1.509774e-05 * weight * pow(temperature, 2)
      + 1.334273e-09 * pow(altitude, 3)
      - 1.725930e-09 * pow(altitude, 2) * temperature
      + 1.038540e-06 * altitude * pow(temperature, 2)
      - 1.381741e-03 * pow(temperature, 3)
      + 3.702403e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff climb/gradient"))
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    let value =
      -5.363335e-07 * weight
      + 3.730917e-06 * altitude
      - 2.512473e-06 * temperature
      - 2.350229e-04 * pow(weight, 2)
      + 3.166296e-05 * weight * altitude
      - 5.536021e-03 * weight * temperature
      - 3.749162e-05 * pow(altitude, 2)
      - 2.493500e-03 * altitude * temperature
      - 3.320853e-04 * pow(temperature, 2)
      + 2.178602e-08 * pow(weight, 3)
      - 2.757289e-09 * pow(weight, 2) * altitude
      + 7.829701e-07 * pow(weight, 2) * temperature
      + 4.701240e-10 * weight * pow(altitude, 2)
      + 2.527011e-07 * weight * altitude * temperature
      - 4.045648e-05 * weight * pow(temperature, 2)
      + 2.138443e-09 * pow(altitude, 3)
      - 1.613311e-08 * pow(altitude, 2) * temperature
      - 9.625873e-07 * altitude * pow(temperature, 2)
      - 2.014487e-03 * pow(temperature, 3)
      + 5.765940e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff climb/rate"))
  }

  // MARK: - En Route Climb
  // Note: G2+ uses G2 enroute climb data (no supplement data available)

  override var enrouteClimbGradientFtNmi_normal: Value<Double> {
    let value =
      -1.548018e-03 * weight
      - 4.066650e-02 * altitude
      - 8.511068e-04 * temperature
      - 7.292719e-05 * pow(weight, 2)
      + 3.748834e-06 * weight * altitude
      - 2.309444e-03 * weight * temperature
      - 5.032559e-07 * pow(altitude, 2)
      - 2.506574e-04 * altitude * temperature
      - 1.367854e-01 * pow(temperature, 2)
      + 6.725837e-09 * pow(weight, 3)
      - 3.299422e-12 * pow(weight, 2) * altitude
      + 2.783269e-07 * pow(weight, 2) * temperature
      - 3.305496e-12 * weight * pow(altitude, 2)
      + 8.934834e-09 * weight * altitude * temperature
      + 7.932477e-06 * weight * pow(temperature, 2)
      + 5.074706e-12 * pow(altitude, 3)
      - 6.150921e-09 * pow(altitude, 2) * temperature
      - 3.113033e-06 * altitude * pow(temperature, 2)
      - 4.759955e-04 * pow(temperature, 3)
      + 1.894292e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/normal/gradient")
    )
  }

  override var enrouteClimbRateFtMin_normal: Value<Double> {
    let value =
      -2.137420e-03 * weight
      - 7.223147e-02 * altitude
      - 3.034660e-03 * temperature
      - 2.236266e-04 * pow(weight, 2)
      - 1.260135e-06 * weight * altitude
      - 1.412357e-02 * weight * temperature
      - 4.091829e-06 * pow(altitude, 2)
      - 9.475656e-04 * altitude * temperature
      - 4.531692e-01 * pow(temperature, 2)
      + 2.070414e-08 * pow(weight, 3)
      + 1.200978e-09 * pow(weight, 2) * altitude
      + 1.762378e-06 * pow(weight, 2) * temperature
      + 5.687059e-11 * weight * pow(altitude, 2)
      + 4.427110e-08 * weight * altitude * temperature
      + 2.849956e-05 * weight * pow(temperature, 2)
      + 6.183017e-11 * pow(altitude, 3)
      - 9.351345e-09 * pow(altitude, 2) * temperature
      - 6.258104e-06 * altitude * pow(temperature, 2)
      + 7.011059e-06 * pow(temperature, 3)
      + 5.827837e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/normal/rate")
    )
  }

  override var enrouteClimbSpeedKIAS_normal: Value<Double> {
    let value =
      -3.094502e-07 * weight
      + 2.640230e-05 * altitude
      - 8.817761e-07 * temperature
      + 4.789414e-07 * pow(weight, 2)
      - 1.635184e-07 * weight * altitude
      - 2.046726e-04 * weight * temperature
      - 1.738770e-07 * pow(altitude, 2)
      - 1.351052e-05 * altitude * temperature
      - 8.947682e-04 * pow(temperature, 2)
      - 1.855901e-11 * pow(weight, 3)
      + 1.550687e-11 * pow(weight, 2) * altitude
      + 2.015050e-08 * pow(weight, 2) * temperature
      - 3.498736e-12 * weight * pow(altitude, 2)
      - 4.445965e-09 * weight * altitude * temperature
      - 1.623336e-06 * weight * pow(temperature, 2)
      + 3.776894e-12 * pow(altitude, 3)
      + 1.466729e-10 * pow(altitude, 2) * temperature
      - 1.545896e-07 * altitude * pow(temperature, 2)
      - 6.511008e-06 * pow(temperature, 3)
      + 1.720619e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/normal/speed")
    )
  }

  override var enrouteClimbGradientFtNmi_iceContaminated: Value<Double> {
    let value =
      -1.111398e-02 * weight
      - 8.746798e-02 * altitude
      - 3.525703e-03 * temperature
      - 9.259814e-05 * pow(weight, 2)
      + 2.203189e-05 * weight * altitude
      - 2.488509e-03 * weight * temperature
      - 3.091713e-06 * pow(altitude, 2)
      - 9.685169e-04 * altitude * temperature
      - 3.297447e-01 * pow(temperature, 2)
      + 8.940904e-09 * pow(weight, 3)
      - 1.592305e-09 * pow(weight, 2) * altitude
      + 2.890423e-07 * pow(weight, 2) * temperature
      + 2.976518e-11 * weight * pow(altitude, 2)
      + 2.487891e-08 * weight * altitude * temperature
      + 8.841836e-06 * weight * pow(temperature, 2)
      + 6.455154e-11 * pow(altitude, 3)
      - 8.832760e-09 * pow(altitude, 2) * temperature
      - 1.270231e-05 * altitude * pow(temperature, 2)
      - 3.658222e-03 * pow(temperature, 3)
      + 2.188256e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/ice contaminated/gradient")
    )
  }

  override var enrouteClimbRateFtMin_iceContaminated: Value<Double> {
    let value =
      -2.055339e-02 * weight
      - 1.511295e-01 * altitude
      - 7.649318e-03 * temperature
      - 2.339923e-04 * pow(weight, 2)
      + 4.051438e-05 * weight * altitude
      - 9.197211e-03 * weight * temperature
      - 9.032662e-06 * pow(altitude, 2)
      - 2.566703e-03 * altitude * temperature
      - 8.122865e-01 * pow(temperature, 2)
      + 2.299128e-08 * pow(weight, 3)
      - 2.814859e-09 * pow(weight, 2) * altitude
      + 1.126450e-06 * pow(weight, 2) * temperature
      + 1.224891e-10 * weight * pow(altitude, 2)
      + 6.448299e-08 * weight * altitude * temperature
      + 2.061212e-05 * weight * pow(temperature, 2)
      + 1.584825e-10 * pow(altitude, 3)
      - 2.495055e-08 * pow(altitude, 2) * temperature
      - 3.572160e-05 * altitude * pow(temperature, 2)
      - 9.279631e-03 * pow(temperature, 3)
      + 5.329390e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/ice contaminated/rate")
    )
  }

  override var enrouteClimbSpeedKIAS_iceContaminated: Value<Double> {
    let value =
      -3.358233e-04 * weight
      + 6.186431e-03 * altitude
      + 3.461116e-05 * temperature
      + 2.990603e-07 * pow(weight, 2)
      - 2.665471e-06 * weight * altitude
      - 1.075504e-04 * weight * temperature
      - 1.470230e-07 * pow(altitude, 2)
      - 3.857089e-05 * altitude * temperature
      - 1.161424e-02 * pow(temperature, 2)
      - 2.228199e-11 * pow(weight, 3)
      + 2.797940e-10 * pow(weight, 2) * altitude
      + 1.645237e-08 * pow(weight, 2) * temperature
      + 1.340912e-11 * weight * pow(altitude, 2)
      + 5.149468e-09 * weight * altitude * temperature
      + 1.404002e-06 * weight * pow(temperature, 2)
      + 2.308318e-12 * pow(altitude, 3)
      + 1.141856e-10 * pow(altitude, 2) * temperature
      - 1.073388e-07 * altitude * pow(temperature, 2)
      - 4.499695e-05 * pow(temperature, 3)
      + 1.352363e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2/enroute climb/ice contaminated/speed")
    )
  }

  private var takeoffRunBaseFt: Value<Double> {
    let value =
      3.476901e-02 * weight
      + 1.270510e-01 * altitude
      + 6.267214e-03 * temperature
      + 3.747970e-05 * pow(weight, 2)
      - 2.647409e-05 * weight * altitude
      + 3.717396e-04 * weight * temperature
      + 1.759261e-05 * pow(altitude, 2)
      + 3.986585e-03 * altitude * temperature
      + 5.668318e-01 * pow(temperature, 2)
      + 2.951091e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff/ground run"))
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    let value =
      5.040864e-02 * weight
      + 1.055348e-01 * altitude
      + 6.202499e-03 * temperature
      + 7.338826e-05 * pow(weight, 2)
      - 2.685188e-05 * weight * altitude
      + 5.230742e-04 * weight * temperature
      + 2.768462e-05 * pow(altitude, 2)
      + 6.181815e-03 * altitude * temperature
      + 8.649045e-01 * pow(temperature, 2)
      - 1.847324e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff/total distance"))
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
    let value =
      -1.267176e-08 * weight
      + 2.791289e-09 * altitude
      + 3.826883e-07 * temperature
      - 7.178504e-11 * pow(weight, 2)
      + 1.713241e-05 * weight * altitude
      + 9.515331e-04 * weight * temperature
      - 6.962821e-06 * pow(altitude, 2)
      - 6.358478e-06 * altitude * temperature
      + 7.275801e-06 * pow(temperature, 2)
      + 3.652139e-09 * pow(weight, 3)
      - 9.670031e-10 * pow(weight, 2) * altitude
      + 1.603950e-08 * pow(weight, 2) * temperature
      + 6.826600e-10 * weight * pow(altitude, 2)
      + 3.253036e-08 * weight * altitude * temperature
      - 1.054262e-06 * weight * pow(temperature, 2)
      + 4.801241e-10 * pow(altitude, 3)
      + 9.126650e-09 * pow(altitude, 2) * temperature
      + 1.389617e-07 * altitude * pow(temperature, 2)
      + 7.371243e-05 * pow(temperature, 3)
      + 9.096613e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/landing/100/ground run"))
  }

  private var landingRunBaseFt_flaps50: Value<Double> {
    let value =
      9.862583e-09 * weight
      + 6.640413e-09 * altitude
      + 5.127551e-07 * temperature
      - 5.301031e-10 * pow(weight, 2)
      + 2.416910e-05 * weight * altitude
      + 1.273651e-03 * weight * temperature
      - 1.019615e-05 * pow(altitude, 2)
      - 1.920419e-05 * altitude * temperature
      + 1.944679e-05 * pow(temperature, 2)
      + 4.833396e-09 * pow(weight, 3)
      - 1.502953e-09 * pow(weight, 2) * altitude
      + 1.201095e-08 * pow(weight, 2) * temperature
      + 9.900763e-10 * weight * pow(altitude, 2)
      + 4.575631e-08 * weight * altitude * temperature
      + 6.750089e-09 * weight * pow(temperature, 2)
      + 6.700305e-10 * pow(altitude, 3)
      + 1.505788e-08 * pow(altitude, 2) * temperature
      - 5.207780e-07 * altitude * pow(temperature, 2)
      + 2.299348e-05 * pow(temperature, 3)
      + 1.197782e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/landing/50/ground run"))
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
      -8.584552e-09 * weight
      + 6.446245e-09 * altitude
      + 4.692654e-07 * temperature
      + 2.407316e-05 * weight * altitude
      + 1.165875e-03 * weight * temperature
      - 1.095190e-05 * pow(altitude, 2)
      + 1.167463e-05 * altitude * temperature
      + 1.043312e-05 * pow(temperature, 2)
      + 8.463618e-09 * pow(weight, 3)
      - 1.750721e-09 * pow(weight, 2) * altitude
      + 1.560459e-08 * pow(weight, 2) * temperature
      + 1.192101e-09 * weight * pow(altitude, 2)
      + 4.256125e-08 * weight * altitude * temperature
      - 8.195089e-07 * weight * pow(temperature, 2)
      + 6.705525e-10 * pow(altitude, 3)
      + 1.085803e-08 * pow(altitude, 2) * temperature
      + 1.547236e-07 * altitude * pow(temperature, 2)
      + 8.135301e-05 * pow(temperature, 3)
      + 9.791445e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2+/landing/100/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50: Value<Double> {
    let value =
      6.543096e-09 * weight
      + 1.059271e-08 * altitude
      + 5.472857e-07 * temperature
      - 5.725388e-10 * pow(weight, 2)
      + 3.244893e-05 * weight * altitude
      + 1.359402e-03 * weight * temperature
      - 1.634023e-05 * pow(altitude, 2)
      - 8.115107e-05 * altitude * temperature
      + 1.738051e-05 * pow(temperature, 2)
      + 1.051691e-08 * pow(weight, 3)
      - 2.298293e-09 * pow(weight, 2) * altitude
      + 5.489684e-08 * pow(weight, 2) * temperature
      + 1.826560e-09 * weight * pow(altitude, 2)
      + 7.593255e-08 * weight * altitude * temperature
      + 4.485535e-07 * weight * pow(temperature, 2)
      + 9.176604e-10 * pow(altitude, 3)
      + 1.899606e-08 * pow(altitude, 2) * temperature
      - 8.218165e-07 * altitude * pow(temperature, 2)
      + 2.308458e-05 * pow(temperature, 3)
      + 1.258733e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2+/landing/50/total distance")
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
