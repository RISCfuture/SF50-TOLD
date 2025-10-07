import SwiftUI

public struct InterpolationView<ValueType, Content: View>: View {
  public let value: Value<ValueType>
  public let minimum: ValueType?
  public let maximum: ValueType?
  public let maxCritical: Bool
  public let rangeValidator: ((ValueType, ValueType?, ValueType?) -> Color)?
  public let uncertaintyValidator: ((ValueType, ValueType, ValueType?, ValueType?) -> Color)?

  public let displayValue: (ValueType) -> Content
  public let displayUncertainty: ((ValueType) -> Content)?

  public var body: some View {
    HStack(spacing: 0) {
      switch value {
        case .value(let value):
          displayValue(value)
            .foregroundStyle(color(for: value))
        case .valueWithUncertainty(let value, let uncertainty):
          HStack {
            displayValue(value)
              .foregroundStyle(color(for: value))
            if let displayUncertainty {
              displayUncertainty(uncertainty)
                .foregroundStyle(getUncertaintyColor(value: value, uncertainty: uncertainty))
                .font(.footnote)
            }
          }
        case .invalid:
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
              .accessibilityHidden(true)
            Text("Error")
          }
          .foregroundStyle(.red)
          .bold()
        case .notAvailable:
          Text("N/A")
            .foregroundStyle(.secondary)
            .bold()
        case .notAuthorized:
          Text("Configuration not authorized")
            .foregroundStyle(.red)
            .bold()
        case .offscaleHigh:
          Text("Offscale high")
            .foregroundStyle(.red)
            .bold()
        case .offscaleLow:
          Text("Offscale low")
            .foregroundStyle(.secondary)
            .bold()
      }
    }
  }

  private init(
    value: Value<ValueType>,
    minimum: ValueType? = nil,
    maximum: ValueType? = nil,
    maxCritical: Bool = true,
    rangeValidator: ((ValueType, ValueType?, ValueType?) -> Color)? = nil,
    uncertaintyValidator: ((ValueType, ValueType, ValueType?, ValueType?) -> Color)? = nil,
    displayValue: @escaping (ValueType) -> Content,
    displayUncertainty: ((ValueType) -> Content)? = nil
  ) {
    self.value = value
    self.minimum = minimum
    self.maximum = maximum
    self.maxCritical = maxCritical
    self.rangeValidator = rangeValidator
    self.uncertaintyValidator = uncertaintyValidator
    self.displayValue = displayValue
    self.displayUncertainty = displayUncertainty
  }

  private func color(for value: ValueType) -> Color {
    if let rangeValidator {
      return rangeValidator(value, minimum, maximum)
    }
    return .primary
  }

  private func getUncertaintyColor(value: ValueType, uncertainty: ValueType) -> Color {
    if let uncertaintyValidator {
      return uncertaintyValidator(value, uncertainty, minimum, maximum)
    }
    return .secondary
  }
}

// MARK: - Initializers for Numeric & Comparable Types (with uncertainty validation)
extension InterpolationView where ValueType: Numeric & Comparable {
  /// Initializer for Numeric & Comparable types with range and uncertainty validation
  public init(
    value: Value<ValueType>,
    minimum: ValueType? = nil,
    maximum: ValueType? = nil,
    maxCritical: Bool = true,
    displayValue: @escaping (ValueType) -> Content,
    displayUncertainty: ((ValueType) -> Content)? = nil
  ) {
    self.init(
      value: value,
      minimum: minimum,
      maximum: maximum,
      maxCritical: maxCritical,
      rangeValidator: { value, min, max in
        if let minimum = min, value < minimum {
          return maxCritical ? .secondary : .red
        }
        if let maximum = max, value > maximum {
          return maxCritical ? .red : .secondary
        }
        return .primary
      },
      uncertaintyValidator: { value, uncertainty, min, max in
        // Check if value ± uncertainty would be outside bounds
        if let minimum = min {
          let lowerBound = value - uncertainty
          if lowerBound < minimum {
            return .red
          }
        }

        if let maximum = max {
          let upperBound = value + uncertainty
          if upperBound > maximum {
            return .red
          }
        }

        return .secondary
      },
      displayValue: displayValue,
      displayUncertainty: displayUncertainty
    )
  }
}

// MARK: - Initializers for Measurement Types (with uncertainty validation)
extension InterpolationView where ValueType: Comparable {
  /// Initializer for Measurement types with range and uncertainty validation
  public init<U: Dimension>(
    value: Value<Measurement<U>>,
    minimum: Measurement<U>? = nil,
    maximum: Measurement<U>? = nil,
    maxCritical: Bool = true,
    displayValue: @escaping (Measurement<U>) -> Content,
    displayUncertainty: ((Measurement<U>) -> Content)? = nil
  ) where ValueType == Measurement<U> {
    self.init(
      value: value,
      minimum: minimum,
      maximum: maximum,
      maxCritical: maxCritical,
      rangeValidator: { value, min, max in
        if let minimum = min, value < minimum {
          return maxCritical ? .secondary : .red
        }
        if let maximum = max, value > maximum {
          return maxCritical ? .red : .secondary
        }
        return .primary
      },
      uncertaintyValidator: { value, uncertainty, min, max in
        // Check if value ± uncertainty would be outside bounds
        if let minimum = min {
          let lowerBound = value - uncertainty
          if lowerBound < minimum {
            return .red
          }
        }

        if let maximum = max {
          let upperBound = value + uncertainty
          if upperBound > maximum {
            return .red
          }
        }

        return .secondary
      },
      displayValue: displayValue,
      displayUncertainty: displayUncertainty
    )
  }
}

// MARK: - Initializers for Non-Comparable Types (no range validation)
extension InterpolationView {
  /// Initializer for non-Comparable types without range validation
  public init(
    value: Value<ValueType>,
    displayValue: @escaping (ValueType) -> Content,
    displayUncertainty: ((ValueType) -> Content)? = nil
  ) {
    self.init(
      value: value,
      minimum: nil,
      maximum: nil,
      maxCritical: true,
      rangeValidator: nil,
      uncertaintyValidator: nil,
      displayValue: displayValue,
      displayUncertainty: displayUncertainty
    )
  }
}

// Non-comparable type example for preview
private struct CustomType {
  let name: String
  let id: Int
}

#Preview {
  List {
    Section("Basic Values") {
      LabeledContent("Scalar") {
        InterpolationView(value: .value(12345)) { value in
          Text(value, format: .number)
        }
      }
      LabeledContent("Measurement") {
        InterpolationView(value: .value(Measurement(value: 1234, unit: UnitMass.pounds))) { value in
          Text(value, format: .measurement(width: .abbreviated))
        }
      }
      LabeledContent("Custom Type") {
        InterpolationView(value: .value(CustomType(name: "Test", id: 123))) { custom in
          Text("\(custom.name) (\(custom.id))")
        }
      }
    }

    Section("Range Validation") {
      LabeledContent("Below min") {
        InterpolationView(value: .value(123), minimum: 200) { value in
          Text(value, format: .number)
        }
      }
      LabeledContent("Above max") {
        InterpolationView(value: .value(123), maximum: 100) { value in
          Text(value, format: .number)
        }
      }
      LabeledContent("Below min (min critical)") {
        InterpolationView(value: .value(123), minimum: 200, maxCritical: false) { value in
          Text(value, format: .number)
        }
      }
      LabeledContent("Above max (min critical)") {
        InterpolationView(value: .value(123), maximum: 100, maxCritical: false) { value in
          Text(value, format: .number)
        }
      }
    }

    Section("Uncertainty Display") {
      LabeledContent("Scalar (within bounds)") {
        InterpolationView(
          value: .valueWithUncertainty(100, uncertainty: 5),
          minimum: 90,
          maximum: 110
        ) { value in
          Text(value, format: .number)
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .number)")
        }
      }
      LabeledContent("Scalar (exceeds max)") {
        InterpolationView(
          value: .valueWithUncertainty(100, uncertainty: 15),
          minimum: 90,
          maximum: 110
        ) { value in
          Text(value, format: .number)
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .number)")
        }
      }
      LabeledContent("Scalar (exceeds min)") {
        InterpolationView(
          value: .valueWithUncertainty(95, uncertainty: 10),
          minimum: 90,
          maximum: 110
        ) { value in
          Text(value, format: .number)
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .number)")
        }
      }
      LabeledContent("Measurement (within)") {
        InterpolationView(
          value: .valueWithUncertainty(
            Measurement(value: 5000, unit: UnitMass.pounds),
            uncertainty: Measurement(value: 100, unit: UnitMass.pounds)
          ),
          minimum: Measurement(value: 4500, unit: UnitMass.pounds),
          maximum: Measurement(value: 5500, unit: UnitMass.pounds)
        ) { value in
          Text(value, format: .measurement(width: .abbreviated))
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .measurement(width: .abbreviated))")
        }
      }
      LabeledContent("Measurement (exceeds)") {
        InterpolationView(
          value: .valueWithUncertainty(
            Measurement(value: 5000, unit: UnitMass.pounds),
            uncertainty: Measurement(value: 600, unit: UnitMass.pounds)
          ),
          minimum: Measurement(value: 4500, unit: UnitMass.pounds),
          maximum: Measurement(value: 5500, unit: UnitMass.pounds)
        ) { value in
          Text(value, format: .measurement(width: .abbreviated))
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .measurement(width: .abbreviated))")
        }
      }

      LabeledContent("Simple Measurement") {
        InterpolationView(
          value: .valueWithUncertainty(
            Measurement(value: 100, unit: UnitLength.meters),
            uncertainty: Measurement(value: 20, unit: UnitLength.meters)
          ),
          minimum: Measurement(value: 90, unit: UnitLength.meters),
          maximum: Measurement(value: 105, unit: UnitLength.meters)
        ) { value in
          Text(value, format: .measurement(width: .abbreviated))
        } displayUncertainty: { uncertainty in
          Text("± \(uncertainty, format: .measurement(width: .abbreviated))")
        }
      }
    }

    Section("Error States") {
      LabeledContent("Invalid") {
        InterpolationView(value: Value<Double>.invalid) { Text($0, format: .number) }
      }
      LabeledContent("Not Authorized") {
        InterpolationView(value: Value<Double>.notAuthorized) { Text($0, format: .number) }
      }
      LabeledContent("Not Available") {
        InterpolationView(value: Value<Double>.notAvailable) { Text($0, format: .number) }
      }
      LabeledContent("Offscale High") {
        InterpolationView(value: Value<Double>.offscaleHigh) { Text($0, format: .number) }
      }
      LabeledContent("Offscale Low") {
        InterpolationView(value: Value<Double>.offscaleLow) { Text($0, format: .number) }
      }
    }
  }
}
