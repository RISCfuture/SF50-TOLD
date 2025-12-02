import Foundation

/// Calculates statistical uncertainty for regression model predictions.
///
/// ``ResidualErrorCalculator`` provides RMSE (Root Mean Square Error) values for
/// regression model outputs. These values represent the statistical uncertainty
/// from the curve-fitting process and are used to generate confidence intervals.
///
/// ## Residual Data
///
/// RMSE values are loaded from a bundled JSON file (`residuals.json`) that contains:
///
/// - Overall RMSE for each regression table
/// - Binned RMSE values for different input ranges (weight, altitude, temperature)
///
/// ## Binned Errors
///
/// When inputs are provided, the calculator looks up RMSE values for the specific
/// bins containing those inputs. Multiple bin matches are combined using
/// root-sum-square for proper statistical combination.
///
/// ## Usage
///
/// ```swift
/// let rmse = ResidualErrorCalculator.RMSE(
///     for: "g1/takeoff/ground run",
///     binParameters: [
///         "weight": 5500,
///         "altitude": 5000,
///         "temperature": 25
///     ]
/// )
/// ```
enum ResidualErrorCalculator {
  private static let residualDataCache: [String: ResidualData] = {
    guard
      let url = Bundle(for: BasePerformanceModel.self)
        .url(forResource: "residuals", withExtension: "json", subdirectory: "Data")
    else {
      fatalError("Could not find residuals.json")
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      return try decoder.decode([String: ResidualData].self, from: data)
    } catch {
      fatalError("Could not load residuals.json: \(error)")
    }
  }()

  static func RMSE(for table: String, binParameters: [String: Double] = [:]) -> Double {
    guard let residualData = residualDataCache[table] else {
      fatalError("No residual data found for table: \(table)")
    }

    // If no bin parameters provided, return overall RMSE
    if binParameters.isEmpty {
      return residualData.overallRMSE
    }

    // Collect all matching bin RMSEs
    var matchingRmses: [Double] = []

    for (binName, value) in binParameters {
      guard let bins = residualData.bins[binName] else { continue }

      for bin in bins {
        if bin.range.count >= 2 && value >= bin.range[0] && value < bin.range[1] {
          matchingRmses.append(bin.RMSE)
          break  // Only take first matching bin per parameter
        }
      }
    }

    // Combine RMSEs using root-sum-square for proper statistical combination
    if matchingRmses.isEmpty {
      return residualData.overallRMSE
    }
    if matchingRmses.count == 1 {
      return matchingRmses[0]
    }
    // Root-sum-square combination: sqrt(sum(rmse_i^2))
    let sumSquares = matchingRmses.reduce(0) { $0 + $1 * $1 }
    return sqrt(sumSquares)
  }

  static func maxError(for table: String, binParameters: [String: Double] = [:]) -> Double {
    guard let residualData = residualDataCache[table] else {
      fatalError("No residual data found for table: \(table)")
    }

    // If no bin parameters provided, return overall max error
    if binParameters.isEmpty {
      return residualData.overallMaxError
    }

    // Find the appropriate bin
    for (binName, value) in binParameters {
      guard let bins = residualData.bins[binName] else { continue }

      for bin in bins {
        if bin.range.count >= 2 && value >= bin.range[0] && value < bin.range[1] {
          return bin.maxError
        }
      }
    }

    // If no matching bin found, return overall max error
    return residualData.overallMaxError
  }

  // Convenience method to get RMSE for contamination adjustments
  static func contaminationRMSE(
    for contaminationType: String,
    distance: Double? = nil,
    depth: Double? = nil
  ) -> Double {
    var binParams: [String: Double] = [:]
    if let distance {
      binParams["distance"] = distance
    }
    if let depth {
      binParams["depth"] = depth
    }

    return RMSE(for: "g1/landing/contamination/\(contaminationType)", binParameters: binParams)
  }

  struct ResidualData: Decodable, Sendable {
    let overallRMSE: Double
    let overallMaxError: Double
    let bins: [String: [Bin]]

    struct Bin: Decodable {
      let range: [Double]
      let RMSE: Double
      let maxError: Double

      enum CodingKeys: String, CodingKey {
        case range
        case RMSE = "rmse"
        case maxError = "max_error"
      }
    }

    enum CodingKeys: String, CodingKey {
      case overallRMSE = "overall_rmse"
      case overallMaxError = "overall_max_error"
      case bins
    }
  }
}
