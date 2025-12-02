import Foundation

/// Calculates landing distance increases due to runway contamination.
///
/// ``ContaminationCalculator`` provides methods to adjust landing ground run distances
/// when runways are contaminated with water, slush, or snow. The AFM provides specific
/// adjustment factors for different contamination types and depths.
///
/// ## Supported Contamination Types
///
/// - **Water or slush**: Standing water up to specified depth
/// - **Slush or wet snow**: Depth-dependent adjustment
/// - **Dry snow**: Fixed percentage increase
/// - **Compact snow**: Fixed percentage increase (largest impact)
///
/// ## Calculation Methods
///
/// Two calculation approaches are supported:
///
/// 1. **Tabular**: Uses ``DataTable`` interpolation for exact AFM values
/// 2. **Regression**: Uses polynomial formulas with uncertainty estimates
///
/// The regression approach includes RMSE uncertainty from curve fitting, propagated
/// through to the final result.
enum ContaminationCalculator {

  // MARK: - Tabular Model Contamination (using DataTable)

  static func landingRunContaminationAddition(
    distance: Value<Double>,
    contamination: Contamination?,
    compactSnowData: DataTable,
    drySnowData: DataTable,
    slushData: DataTable,
    waterData: DataTable
  ) -> Value<Double> {
    guard let contamination else { return distance }

    return distance.flatMap { distance in
      switch contamination {
        case .waterOrSlush(let depth):
          waterData.value(
            for: [distance, depth.converted(to: .inches).value],
            clamping: [.clampBoth, .clampBoth]
          )
        case .slushOrWetSnow(let depth):
          slushData.value(
            for: [distance, depth.converted(to: .inches).value],
            clamping: [.clampBoth, .clampBoth]
          )
        case .drySnow:
          drySnowData.value(for: [distance], clamping: [.clampBoth])
        case .compactSnow:
          compactSnowData.value(for: [distance], clamping: [.clampBoth])
      }
    }
  }

  // MARK: - Regression Model Contamination (using formulas)

  static func landingRunContaminationAddition(
    distance: Value<Double>,
    contamination: Contamination?
  ) -> Value<Double> {
    guard let contamination else { return distance }

    switch contamination {
      case .waterOrSlush(let depth):
        let depthInches = depth.converted(to: .inches).value

        return distance.map { distanceValue, existingUncertainty in
          let newDistance =
            1.406974e+00 * distanceValue
            + 1.076892e-03 * depthInches
            + 1.371359e+01

          let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
            for: "water",
            distance: distanceValue,
            depth: depthInches
          )

          // Combine existing uncertainty with contamination uncertainty in quadrature
          let newUncertainty =
            if let existingUncertainty {
              sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
            } else {
              contaminationUncertainty
            }

          return (newDistance, newUncertainty)
        }

      case .slushOrWetSnow(let depth):
        let depthInches = depth.converted(to: .inches).value

        return distance.map { distanceValue, existingUncertainty in
          let newDistance =
            1.692337e+00 * distanceValue
            - 2.335086e-03 * depthInches
            + 3.409392e-07 * pow(distanceValue, 2)
            - 6.240405e-01 * distanceValue * depthInches
            + 1.113034e-01 * pow(depthInches, 2)
            + 7.443967e+00

          let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
            for: "slush, wet snow",
            distance: distanceValue,
            depth: depthInches
          )

          let newUncertainty =
            if let existingUncertainty {
              sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
            } else {
              contaminationUncertainty
            }

          return (newDistance, newUncertainty)
        }

      case .drySnow:
        return distance.map { distanceValue, existingUncertainty in
          let newDistance =
            1.328947e+00 * distanceValue
            + 5.263158e+00

          let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
            for: "dry snow",
            distance: distanceValue
          )

          let newUncertainty =
            if let existingUncertainty {
              sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
            } else {
              contaminationUncertainty
            }

          return (newDistance, newUncertainty)
        }

      case .compactSnow:
        return distance.map { distanceValue, existingUncertainty in
          let newDistance =
            1.578947e+00 * distanceValue
            + 5.263158e+00

          let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
            for: "compact snow",
            distance: distanceValue
          )

          let newUncertainty =
            if let existingUncertainty {
              sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
            } else {
              contaminationUncertainty
            }

          return (newDistance, newUncertainty)
        }
    }
  }
}
