import Foundation

/// Shared SF50-specific performance calculations used by both G1 and G2+ models.
/// Contains identical regression formulas and adjustment factors that are common across SF50 variants.
class BaseSF50RegressionPerformanceModel: BaseRegressionPerformanceModel {

  // MARK: - En Route Climb

  var enrouteClimbGradientFtNmi: Value<Double> {
    let iceContaminated = configuration.iceProtection
    return iceContaminated
      ? enrouteClimbGradientFtNmi_iceContaminated : enrouteClimbGradientFtNmi_normal
  }

  var enrouteClimbRateFtMin: Value<Double> {
    let iceContaminated = configuration.iceProtection
    return iceContaminated ? enrouteClimbRateFtMin_iceContaminated : enrouteClimbRateFtMin_normal
  }

  var enrouteClimbSpeedKIAS: Value<Double> {
    let iceContaminated = configuration.iceProtection
    return iceContaminated ? enrouteClimbSpeedKIAS_iceContaminated : enrouteClimbSpeedKIAS_normal
  }

  var timeToClimbMin: Value<Double> {
    let value =
      -2.243463e-03 * altitude
      - 6.566427e-01 * temperature
      - 5.209780e-03 * weight
      + 6.899496e-08 * pow(altitude, 2)
      + 4.888891e-05 * altitude * temperature
      + 3.525456e-07 * altitude * weight
      + 9.399166e-03 * pow(temperature, 2)
      + 7.091640e-05 * temperature * weight
      + 3.333333e-07 * pow(weight, 2)
      + 1.988250e+01

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/time fuel distance to climb/time")
    )
  }

  var fuelToClimbUsGal: Value<Double> {
    let value =
      -2.053557e-03 * altitude
      - 6.401662e-01 * temperature
      - 8.059767e-03 * weight
      + 4.948570e-08 * pow(altitude, 2)
      + 3.830252e-05 * altitude * temperature
      + 4.555275e-07 * altitude * weight
      + 6.892845e-03 * pow(temperature, 2)
      + 8.520627e-05 * temperature * weight
      + 6.078431e-07 * pow(weight, 2)
      + 2.642853e+01

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/time fuel distance to climb/fuel")
    )
  }

  var distanceToClimbNm: Value<Double> {
    let value =
      -6.301291e-03 * altitude
      - 1.697859e+00 * temperature
      - 1.652207e-02 * weight
      + 1.848660e-07 * pow(altitude, 2)
      + 1.219525e-04 * altitude * temperature
      + 9.851330e-07 * altitude * weight
      + 2.397326e-02 * pow(temperature, 2)
      + 1.820277e-04 * temperature * weight
      + 1.098039e-06 * pow(weight, 2)
      + 6.127238e+01

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/time fuel distance to climb/distance")
    )
  }

  private var enrouteClimbGradientFtNmi_normal: Value<Double> {
    let value =
      -4.874237e-01 * weight
      - 4.572337e-02 * altitude
      - 7.814000e+00 * temperature
      + 2.744079e-05 * pow(weight, 2)
      + 3.310746e-06 * weight * altitude
      + 4.925860e-04 * weight * temperature
      - 8.036127e-08 * pow(altitude, 2)
      - 2.068553e-04 * altitude * temperature
      - 1.013158e-01 * pow(temperature, 2)
      + 2.671258e+03  // intercept

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/gradient")
    )
  }

  private var enrouteClimbRateFtMin_normal: Value<Double> {
    let value =
      -1.497864e+00 * weight
      - 1.470839e-01 * altitude
      - 4.725863e+01 * temperature
      + 8.515789e-05 * pow(weight, 2)
      + 1.161424e-05 * weight * altitude
      + 4.098812e-03 * weight * temperature
      - 6.218664e-07 * pow(altitude, 2)
      - 6.453944e-04 * altitude * temperature
      - 3.469414e-01 * pow(temperature, 2)
      + 8.280391e+03  // intercept

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/rate")
    )
  }

  private var enrouteClimbSpeedKIAS_normal: Value<Double> {
    let value =
      1.710676e-03 * weight
      - 2.508275e-03 * altitude
      - 6.211115e-01 * temperature
      + 6.578947e-09 * pow(weight, 2)
      + 3.771845e-08 * weight * altitude
      + 1.005578e-05 * weight * temperature
      - 2.467251e-08 * pow(altitude, 2)
      - 2.635929e-05 * altitude * temperature
      - 1.040358e-02 * pow(temperature, 2)
      + 1.777981e+02  // intercept

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/normal/speed")
    )
  }

  private var enrouteClimbGradientFtNmi_iceContaminated: Value<Double> {
    let value =
      -4.044019e-01 * weight
      - 7.499937e-02 * altitude
      - 1.096410e+01 * temperature
      + 1.616279e-05 * pow(weight, 2)
      + 6.128100e-06 * weight * altitude
      + 6.382823e-04 * weight * temperature
      - 1.301104e-07 * pow(altitude, 2)
      - 3.260372e-04 * altitude * temperature
      - 1.500103e-01 * pow(temperature, 2)
      + 2.571454e+03  // intercept

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/gradient")
    )
  }

  private var enrouteClimbRateFtMin_iceContaminated: Value<Double> {
    let value =
      -1.519474e-01 * altitude
      - 3.828843e+01 * temperature
      - 9.878698e-01 * weight
      - 1.219831e-06 * pow(altitude, 2)
      - 8.122230e-04 * altitude * temperature
      + 1.247279e-05 * altitude * weight
      - 4.009787e-01 * pow(temperature, 2)
      + 2.547891e-03 * temperature * weight
      + 4.126357e-05 * pow(weight, 2)
      + 6.212608e+03

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/rate")
    )
  }

  private var enrouteClimbSpeedKIAS_iceContaminated: Value<Double> {
    let value =
      -2.115789e-02 * weight
      - 2.837160e-03 * altitude
      - 4.431100e-01 * temperature
      + 2.186047e-06 * pow(weight, 2)
      + 4.056213e-07 * weight * altitude
      + 6.342230e-05 * weight * temperature
      + 8.800500e-09 * pow(altitude, 2)
      - 1.347270e-06 * altitude * temperature
      - 1.544318e-03 * pow(temperature, 2)
      + 1.891283e+02  // intercept

    return .valueWithUncertainty(
      value,
      uncertainty: uncertainty(for: "g1/enroute climb/ice contaminated/speed")
    )
  }

  // MARK: Landing

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

  var landingRun_headwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps100: 0.08
        default: 0.07
      }
    return PerformanceAdjustments.landingRunHeadwindAdjustment(factor: factor, headwind: headwind)
  }

  var landingDistance_headwindAdjustment: Double {
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

  var landingRun_tailwindAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps100: 0.49
        case .flaps50Ice, .flapsUpIce: 0.37
        case .flaps50, .flapsUp: 0.42
      }
    return PerformanceAdjustments.landingRunTailwindAdjustment(factor: factor, tailwind: tailwind)
  }

  var landingDistance_tailwindAdjustment: Double {
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

  var landingRun_uphillAdjustment: Double {
    let factor =
      switch configuration.flapSetting {
        case .flaps50Ice, .flapsUpIce: 0.06
        default: 0.05
      }
    return PerformanceAdjustments.landingRunUphillAdjustment(factor: factor, uphill: uphill)
  }

  var landingRun_downhillAdjustment: Double {
    let factor = 0.06
    return PerformanceAdjustments.landingRunDownhillAdjustment(factor: factor, downhill: downhill)
  }

  var landingDistance_unpavedAdjustment: Double {
    let factor = 0.2
    return PerformanceAdjustments.landingDistanceUnpavedAdjustment(factor: factor)
  }

  // MARK: - Abstract Properties (to be implemented by subclasses)

  /// Landing run base distance before adjustments (contamination is applied in landingRunFt)
  var landingRunBaseFt: Value<Double> {
    fatalError("Subclasses must implement landingRunBaseFt")
  }

  /// Landing distance base before adjustments and contamination
  var landingDistanceBaseFt: Value<Double> {
    fatalError("Subclasses must implement landingDistanceBaseFt")
  }
}
