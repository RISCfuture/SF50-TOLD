import Foundation

/// Loads and evaluates regression equations from JSON files.
///
/// ``RegressionEquation`` computes performance values using polynomial regression
/// equations fitted to AFM chart data. Each equation is defined in a JSON file and
/// evaluated for given input conditions (weight, altitude, temperature).
///
/// ## Equation Types
///
/// - **Polynomial**: Multi-variable polynomials (degree 1-3) for performance calculations
/// - **Linear**: Simple y = mx + b equations for reference speeds
/// - **Constant**: Fixed values for adjustment factors
/// - **Piecewise**: Conditional equations with weight breakpoints
/// - **Logistic**: Binary classification for capability checks
///
/// ## Usage
///
/// ```swift
/// let equation = try RegressionEquation(fileURL: url)
/// let result = equation.evaluate(inputs: [
///   "weight": 5500,
///   "altitude": 5000,
///   "temperature": 25
/// ])
/// ```
///
/// ## JSON Format
///
/// Each equation file contains:
/// - `version`: Schema version (currently "1.0")
/// - `name`: Equation identifier
/// - `type`: One of "polynomial", "linear", "constant", "piecewise", "logistic"
/// - `variables`: Array of input variable names
/// - `uncertainty_key`: Optional key for residual error lookup
/// - `equation`: Type-specific equation definition
final class RegressionEquation {

  /// The type of equation
  let type: EquationType

  /// Variable names expected by this equation
  let variables: [String]

  /// Uncertainty key for residual error lookup, if applicable
  let uncertaintyKey: String?

  /// The parsed equation definition
  private let equation: EquationDefinition

  // MARK: - Initialization

  /// Creates a regression equation by loading JSON from a file URL.
  ///
  /// - Parameter fileURL: The URL of the JSON file to load.
  /// - Throws: `Errors.badEncoding` if the file cannot be read,
  ///           `Errors.invalidSchema` if the JSON structure is invalid.
  convenience init(fileURL: URL) throws {
    let data = try Data(contentsOf: fileURL)
    try self.init(json: data)
  }

  /// Creates a regression equation from JSON data.
  ///
  /// - Parameter json: The JSON data to parse.
  /// - Throws: `Errors.invalidSchema` if the JSON structure is invalid.
  init(json: Data) throws {
    let decoder = JSONDecoder()
    let file: EquationFile
    do {
      file = try decoder.decode(EquationFile.self, from: json)
    } catch {
      throw Errors.invalidSchema(error.localizedDescription)
    }

    guard file.version == "1.0" else {
      throw Errors.unsupportedVersion(file.version)
    }

    self.type = file.type
    self.variables = file.variables
    self.uncertaintyKey = file.uncertaintyKey

    // Parse type-specific equation content
    switch file.type {
      case .polynomial:
        guard let poly = file.equation.polynomial else {
          throw Errors.invalidSchema("Missing polynomial equation definition")
        }
        self.equation = .polynomial(poly)

      case .linear:
        guard let linear = file.equation.linear else {
          throw Errors.invalidSchema("Missing linear equation definition")
        }
        self.equation = .linear(linear)

      case .constant:
        guard let constant = file.equation.constant else {
          throw Errors.invalidSchema("Missing constant equation definition")
        }
        self.equation = .constant(constant)

      case .piecewise:
        guard let piecewise = file.equation.piecewise else {
          throw Errors.invalidSchema("Missing piecewise equation definition")
        }
        self.equation = .piecewise(piecewise)

      case .logistic:
        guard let logistic = file.equation.logistic else {
          throw Errors.invalidSchema("Missing logistic equation definition")
        }
        self.equation = .logistic(logistic)
    }
  }

  // MARK: - Evaluation

  /// Evaluates the equation for the given input values.
  ///
  /// - Parameter inputs: Dictionary mapping variable names to values.
  /// - Returns: The calculated result with optional uncertainty from residuals.
  func evaluate(inputs: [String: Double]) -> Value<Double> {
    // Validate all required variables are present
    for variable in variables {
      guard inputs[variable] != nil else {
        return .invalid
      }
    }

    let result: Double

    switch equation {
      case .polynomial(let poly):
        result = evaluatePolynomial(poly, inputs: inputs)

      case .linear(let linear):
        guard let x = inputs[variables.first ?? ""] else { return .invalid }
        result = linear.slope * x + linear.intercept

      case .constant(let constant):
        result = constant.value

      case .piecewise(let piecewise):
        guard let pieceResult = evaluatePiecewise(piecewise, inputs: inputs) else {
          return .invalid
        }
        result = pieceResult

      case .logistic:
        // Logistic equations return bool, not double
        return .invalid
    }

    // Apply uncertainty if available
    if let key = uncertaintyKey {
      let rmse = ResidualErrorCalculator.RMSE(for: key, binParameters: inputs)
      return .valueWithUncertainty(result, uncertainty: rmse)
    }
    return .value(result)
  }

  /// Evaluates a logistic equation returning a boolean.
  ///
  /// - Parameter inputs: Dictionary mapping variable names to values.
  /// - Returns: The boolean result based on probability threshold.
  func evaluateBool(inputs: [String: Double]) -> Value<Bool> {
    guard case .logistic(let logistic) = equation else {
      return .invalid
    }

    // Validate all required variables are present
    for variable in variables {
      guard inputs[variable] != nil else {
        return .invalid
      }
    }

    // Normalize inputs
    var normalized: [String: Double] = [:]
    for (variable, value) in inputs {
      if let norm = logistic.normalization[variable] {
        normalized[variable] = (value - norm.offset) / norm.scale
      } else {
        normalized[variable] = value
      }
    }

    // Map variable names to short form
    let shortNames: [String: String] = ["weight": "w", "altitude": "a", "temperature": "t"]
    var shortNormalized: [String: Double] = [:]
    for (variable, value) in normalized {
      let short = shortNames[variable] ?? variable
      shortNormalized[short] = value
    }

    // Calculate logit
    var logit = logistic.intercept

    for term in logistic.coefficients {
      var featureValue = 1.0
      for feature in term.features {
        guard let value = shortNormalized[feature] else { return .invalid }
        featureValue *= value
      }
      logit += term.coefficient * featureValue
    }

    // Sigmoid function
    let probability = 1.0 / (1.0 + exp(-logit))

    return .value(probability > logistic.threshold)
  }

  // MARK: - Private Evaluation Helpers

  private func evaluatePolynomial(_ poly: PolynomialEquation, inputs: [String: Double]) -> Double {
    var result = poly.intercept

    for term in poly.terms {
      var termValue = term.coefficient

      // Apply each power
      for (index, power) in term.powers.enumerated() {
        guard index < variables.count else { continue }
        let variable = variables[index]
        guard let value = inputs[variable] else { continue }

        if power > 0 {
          termValue *= pow(value, Double(power))
        }
      }

      result += termValue
    }

    return result
  }

  private func evaluatePiecewise(
    _ piecewise: PiecewiseEquation,
    inputs: [String: Double]
  ) -> Double? {
    for breakpoint in piecewise.breakpoints {
      guard let inputValue = inputs[breakpoint.condition.variable] else {
        return nil
      }

      let conditionMet: Bool
      switch breakpoint.condition.operator {
        case .lessThan:
          conditionMet = inputValue < breakpoint.condition.value
        case .lessThanOrEqual:
          conditionMet = inputValue <= breakpoint.condition.value
        case .greaterThan:
          conditionMet = inputValue > breakpoint.condition.value
        case .greaterThanOrEqual:
          conditionMet = inputValue >= breakpoint.condition.value
      }

      if conditionMet {
        switch breakpoint.result {
          case .constant(let value):
            return value

          case .linear(let slope, let intercept, let minValue, let maxValue):
            var result = slope * inputValue + intercept
            if let min = minValue {
              result = Swift.max(result, min)
            }
            if let max = maxValue {
              result = Swift.min(result, max)
            }
            return result
        }
      }
    }

    return nil
  }

  // MARK: - Types

  /// The type of equation stored in the JSON file.
  enum EquationType: String, Codable, Sendable {
    /// Multi-variable polynomial equation (degree 1-3)
    case polynomial
    /// Simple linear equation (y = mx + b)
    case linear
    /// Single constant value
    case constant
    /// Conditional equation with breakpoints
    case piecewise
    /// Logistic regression for boolean outputs
    case logistic
  }

  /// Errors that can occur during equation loading or evaluation.
  enum Errors: Error {
    /// The file data could not be decoded.
    case badEncoding
    /// The JSON schema is invalid.
    case invalidSchema(String)
    /// The schema version is not supported.
    case unsupportedVersion(String)
    /// A required input variable is missing.
    case missingVariable(String)
    /// The equation type doesn't match the expected type.
    case typeMismatch(expected: EquationType, got: EquationType)
  }
}

// MARK: - Codable Structures

/// Root structure for equation JSON files.
private struct EquationFile: Codable {
  let version: String
  let name: String
  let description: String?
  let type: RegressionEquation.EquationType
  let variables: [String]
  let uncertaintyKey: String?
  let equation: EquationContainer

  enum CodingKeys: String, CodingKey {
    case version, name, description, type, variables
    case uncertaintyKey = "uncertainty_key"
    case equation
  }
}

/// Container for type-specific equation definitions.
private struct EquationContainer: Codable {
  // Polynomial fields
  let intercept: Double?
  let terms: [PolynomialTerm]?

  // Linear fields
  let slope: Double?
  // intercept is shared with polynomial

  // Constant fields
  let value: Double?

  // Piecewise fields
  let breakpoints: [Breakpoint]?

  // Logistic fields
  let normalization: [String: Normalization]?
  let polynomialDegree: Int?
  let coefficients: [LogisticTerm]?
  let threshold: Double?

  var polynomial: PolynomialEquation? {
    guard let intercept, let terms else { return nil }
    return PolynomialEquation(intercept: intercept, terms: terms)
  }

  var linear: LinearEquation? {
    guard let slope, let intercept else { return nil }
    return LinearEquation(slope: slope, intercept: intercept)
  }

  var constant: ConstantEquation? {
    guard let value else { return nil }
    return ConstantEquation(value: value)
  }

  var piecewise: PiecewiseEquation? {
    guard let breakpoints else { return nil }
    return PiecewiseEquation(breakpoints: breakpoints)
  }

  var logistic: LogisticEquation? {
    guard let normalization, let intercept, let coefficients, let threshold else { return nil }
    return LogisticEquation(
      normalization: normalization,
      polynomialDegree: polynomialDegree ?? 2,
      intercept: intercept,
      coefficients: coefficients,
      threshold: threshold
    )
  }

  enum CodingKeys: String, CodingKey {
    case intercept, terms, slope, value, breakpoints
    case normalization, coefficients, threshold
    case polynomialDegree = "polynomial_degree"
  }
}

// MARK: - Equation Type Structures

/// Internal representation of parsed equations
private enum EquationDefinition {
  case polynomial(PolynomialEquation)
  case linear(LinearEquation)
  case constant(ConstantEquation)
  case piecewise(PiecewiseEquation)
  case logistic(LogisticEquation)
}

private struct PolynomialEquation {
  let intercept: Double
  let terms: [PolynomialTerm]
}

private struct PolynomialTerm: Codable {
  let coefficient: Double
  let powers: [Int]
}

private struct LinearEquation {
  let slope: Double
  let intercept: Double
}

private struct ConstantEquation {
  let value: Double
}

private struct PiecewiseEquation {
  let breakpoints: [Breakpoint]
}

private struct Breakpoint: Codable {
  let condition: Condition
  let result: BreakpointResult
}

private struct Condition: Codable {
  let variable: String
  let `operator`: ComparisonOperator
  let value: Double
}

private enum ComparisonOperator: String, Codable {
  case lessThan = "<"
  case lessThanOrEqual = "<="
  case greaterThan = ">"
  case greaterThanOrEqual = ">="
}

private enum BreakpointResult: Codable {
  case constant(Double)
  case linear(slope: Double, intercept: Double, minValue: Double?, maxValue: Double?)

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
      case "constant":
        let value = try container.decode(Double.self, forKey: .value)
        self = .constant(value)

      case "linear":
        let slope = try container.decode(Double.self, forKey: .slope)
        let intercept = try container.decode(Double.self, forKey: .intercept)
        let minValue = try container.decodeIfPresent(Double.self, forKey: .minValue)
        let maxValue = try container.decodeIfPresent(Double.self, forKey: .maxValue)
        self = .linear(slope: slope, intercept: intercept, minValue: minValue, maxValue: maxValue)

      default:
        throw DecodingError.dataCorruptedError(
          forKey: .type,
          in: container,
          debugDescription: "Unknown result type: \(type)"
        )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .constant(let value):
        try container.encode("constant", forKey: .type)
        try container.encode(value, forKey: .value)

      case .linear(let slope, let intercept, let minValue, let maxValue):
        try container.encode("linear", forKey: .type)
        try container.encode(slope, forKey: .slope)
        try container.encode(intercept, forKey: .intercept)
        try container.encodeIfPresent(minValue, forKey: .minValue)
        try container.encodeIfPresent(maxValue, forKey: .maxValue)
    }
  }

  enum CodingKeys: String, CodingKey {
    case type, value, slope, intercept
    case minValue = "min_value"
    case maxValue = "max_value"
  }
}

private struct LogisticEquation {
  let normalization: [String: Normalization]
  let polynomialDegree: Int
  let intercept: Double
  let coefficients: [LogisticTerm]
  let threshold: Double
}

private struct Normalization: Codable {
  let offset: Double
  let scale: Double
}

private struct LogisticTerm: Codable {
  let features: [String]
  let coefficient: Double
}
