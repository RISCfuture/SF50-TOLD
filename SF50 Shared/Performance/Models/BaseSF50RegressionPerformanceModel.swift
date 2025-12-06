import Foundation

/// SF50-specific regression model with calculations shared across G1 and G2+ variants.
///
/// ``BaseSF50RegressionPerformanceModel`` provides polynomial regression formulas and
/// adjustment factors that are identical between SF50 Vision Jet generations. This includes:
///
/// - En route climb performance (gradient, rate, speed)
/// - Time/fuel/distance to climb calculations
/// - Landing Vref calculations
/// - Landing distance calculations with wind and surface adjustments
///
/// ## En Route Climb
///
/// The en route climb calculations provide performance during cruise climb after
/// departure, including ice-contaminated variants for flight in icing conditions.
///
/// ## Adjustment Factors
///
/// Landing performance is adjusted for wind and surface conditions using factors
/// derived from AFM data:
///
/// - Headwind/tailwind adjustments reduce/increase distances
/// - Gradient adjustments account for runway slope
/// - Unpaved surface adjustments add margin for grass runways
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

  // Abstract properties - subclasses must override
  var enrouteClimbGradientFtNmi_normal: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbGradientFtNmi_normal")
  }

  var enrouteClimbRateFtMin_normal: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbRateFtMin_normal")
  }

  var enrouteClimbSpeedKIAS_normal: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbSpeedKIAS_normal")
  }

  var enrouteClimbGradientFtNmi_iceContaminated: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbGradientFtNmi_iceContaminated")
  }

  var enrouteClimbRateFtMin_iceContaminated: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbRateFtMin_iceContaminated")
  }

  var enrouteClimbSpeedKIAS_iceContaminated: Value<Double> {
    fatalError("Subclasses must implement enrouteClimbSpeedKIAS_iceContaminated")
  }

  // MARK: Landing

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

  // Abstract properties - subclasses must override with variant-specific factors
  var landingRun_headwindAdjustment: Double {
    fatalError("Subclasses must implement landingRun_headwindAdjustment")
  }

  var landingDistance_headwindAdjustment: Double {
    fatalError("Subclasses must implement landingDistance_headwindAdjustment")
  }

  var landingRun_tailwindAdjustment: Double {
    fatalError("Subclasses must implement landingRun_tailwindAdjustment")
  }

  var landingDistance_tailwindAdjustment: Double {
    fatalError("Subclasses must implement landingDistance_tailwindAdjustment")
  }

  var landingRun_uphillAdjustment: Double {
    fatalError("Subclasses must implement landingRun_uphillAdjustment")
  }

  var landingRun_downhillAdjustment: Double {
    fatalError("Subclasses must implement landingRun_downhillAdjustment")
  }

  var landingDistance_unpavedAdjustment: Double {
    fatalError("Subclasses must implement landingDistance_unpavedAdjustment")
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
