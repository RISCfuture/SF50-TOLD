import Foundation

final class RegressionPerformanceModelG2Plus: BaseSF50RegressionPerformanceModel {

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
      -1.059609e+00 * weight
      - 8.985792e-02 * altitude
      - 1.139856e+01 * temperature
      + 5.899360e-05 * pow(weight, 2)
      + 9.865366e-06 * weight * altitude
      + 1.457815e-03 * weight * temperature
      - 1.473818e-06 * pow(altitude, 2)
      - 7.444685e-04 * altitude * temperature
      - 1.684028e-01 * pow(temperature, 2)
      + 5.544933e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff climb/gradient"))
  }

  override var takeoffClimbRateFtMin: Value<Double> {
    let value =
      -1.734136e+00 * weight
      - 7.843993e-02 * altitude
      - 2.912187e+01 * temperature
      + 9.840073e-05 * pow(weight, 2)
      + 8.834531e-06 * weight * altitude
      + 3.673469e-03 * weight * temperature
      - 3.059130e-06 * pow(altitude, 2)
      - 1.289497e-03 * altitude * temperature
      - 2.412158e-01 * pow(temperature, 2)
      + 8.924359e+03

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff climb/rate"))
  }

  private var takeoffRunBaseFt: Value<Double> {
    let value =
      -1.664237e-08 * weight
      - 6.414724e-06 * altitude
      - 5.899857e-07 * temperature
      + 5.426535e-05 * pow(weight, 2)
      + 3.834371e-05 * weight * altitude
      - 8.725648e-04 * weight * temperature
      - 3.242364e-05 * pow(altitude, 2)
      - 4.691836e-03 * altitude * temperature
      - 6.154317e-04 * pow(temperature, 2)
      - 3.147269e-09 * pow(weight, 3)
      - 3.765581e-09 * pow(weight, 2) * altitude
      + 3.168768e-07 * pow(weight, 2) * temperature
      + 3.238695e-09 * weight * pow(altitude, 2)
      + 8.230564e-07 * weight * altitude * temperature
      + 2.854585e-05 * weight * pow(temperature, 2)
      + 2.040017e-09 * pow(altitude, 3)
      + 3.691849e-07 * pow(altitude, 2) * temperature
      + 6.814143e-05 * altitude * pow(temperature, 2)
      + 7.491665e-03 * pow(temperature, 3)
      + 4.966923e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/takeoff/ground run"))
  }

  private var takeoffDistanceBaseFt: Value<Double> {
    let value =
      -2.707056e-08 * weight
      - 4.570476e-06 * altitude
      - 1.868615e-06 * temperature
      + 6.011329e-05 * pow(weight, 2)
      + 6.250908e-05 * weight * altitude
      - 3.827400e-03 * weight * temperature
      - 6.285684e-05 * pow(altitude, 2)
      - 1.093824e-02 * altitude * temperature
      - 1.476193e-03 * pow(temperature, 2)
      - 4.332344e-10 * pow(weight, 3)
      - 6.637295e-09 * pow(weight, 2) * altitude
      + 9.080090e-07 * pow(weight, 2) * temperature
      + 7.240890e-09 * weight * pow(altitude, 2)
      + 1.896026e-06 * weight * altitude * temperature
      + 4.275419e-05 * weight * pow(temperature, 2)
      + 3.157928e-09 * pow(altitude, 3)
      + 6.011825e-07 * pow(altitude, 2) * temperature
      + 1.111599e-04 * altitude * pow(temperature, 2)
      + 1.196539e-02 * pow(temperature, 3)
      + 5.433427e+02

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
      2.434469e-09 * weight
      - 3.348425e-02 * altitude
      - 7.693079e-05 * temperature
      + 2.706466e-05 * pow(weight, 2)
      + 1.372191e-05 * weight * altitude
      + 1.043040e-03 * weight * temperature
      + 3.545624e-06 * pow(altitude, 2)
      + 2.075397e-04 * altitude * temperature
      - 2.861116e-03 * pow(temperature, 2)
      + 7.109555e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/landing/100/ground run"))
  }

  private var landingRunBaseFt_flaps50: Value<Double> {
    let value =
      3.405472e-09 * weight
      - 5.181749e-02 * altitude
      - 4.936765e-04 * temperature
      + 3.552107e-05 * pow(weight, 2)
      + 1.892616e-05 * weight * altitude
      + 1.384600e-03 * weight * temperature
      + 5.036444e-06 * pow(altitude, 2)
      + 3.074883e-04 * altitude * temperature
      - 6.295286e-03 * pow(temperature, 2)
      + 9.472107e+02

    return .valueWithUncertainty(value, uncertainty: uncertainty(for: "g2+/landing/50/ground run"))
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
      5.933151e-09 * weight
      - 4.777326e-02 * altitude
      - 4.866623e-05 * temperature
      + 6.288556e-05 * pow(weight, 2)
      + 1.755392e-05 * weight * altitude
      + 1.263536e-03 * weight * temperature
      + 4.883410e-06 * pow(altitude, 2)
      + 2.785548e-04 * altitude * temperature
      - 1.653392e-03 * pow(temperature, 2)
      + 5.014757e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2+/landing/100/total distance")
    )
  }

  private var landingDistanceBaseFt_flaps50: Value<Double> {
    let value =
      7.530012e-09 * weight
      - 8.875695e-02 * altitude
      - 1.846481e-03 * temperature
      + 7.776802e-05 * pow(weight, 2)
      + 2.776196e-05 * weight * altitude
      + 1.769375e-03 * weight * temperature
      + 6.832825e-06 * pow(altitude, 2)
      + 3.974697e-04 * altitude * temperature
      - 1.127533e-02 * pow(temperature, 2)
      + 6.791733e+02

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g2+/landing/50/total distance")
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

  // MARK: - Initializer

  init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMSnapshot?
  ) {
    super.init(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam,
      modelType: .g2Plus
    )
  }
}
