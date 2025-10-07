import Foundation
import RegexBuilder
import SF50_Shared
import SwiftUI

struct MeasurementField<Unit: Dimension>: View {
  let label: LocalizedStringKey
  @Binding var value: Measurement<Unit>
  private let unit: Unit

  let format: Measurement<Unit>.FormatStyle
  let showSuffix = true
  let minimum: Measurement<Unit>?
  let maximum: Measurement<Unit>?

  private var numberFormat: FloatingPointFormatStyle<Double> {
    format.numberFormatStyle ?? .number
  }

  private var prefixSuffix: [Substring] {
    let dummyValue = Measurement(value: 1, unit: unit)
    let valueWithUnit = format.format(dummyValue)
    let valueWithoutUnit = format.numberFormatStyle?.format(1) ?? "1"
    return valueWithUnit.split(
      maxSplits: 2,
      omittingEmptySubsequences: false,
      separator: {
        valueWithoutUnit
      }
    )
  }

  private var prefix: String? {
    prefixSuffix.first.map { String($0) }
  }

  private var suffix: String? {
    prefixSuffix.last.map { String($0) }
  }

  private var isValid: Bool {
    if let minimum {
      if value < minimum { return false }
    }
    if let maximum {
      if value > maximum { return false }
    }
    return true
  }

  private var valueBinding: Binding<Double> {
    .init(
      get: { value.converted(to: unit).value },
      set: { value = .init(value: $0, unit: unit) }
    )
  }

  var body: some View {
    HStack(spacing: 0) {
      if let prefix, showSuffix {
        Text(verbatim: prefix).foregroundStyle(.secondary)
      }

      TextField(label, value: valueBinding, format: numberFormat)
        .decimalField()
        .foregroundStyle(isValid ? Color.primary : Color.red)

      if let suffix, showSuffix {
        Text(verbatim: suffix).foregroundStyle(.secondary)
      }
    }
  }

  init(
    _ label: LocalizedStringKey,
    value: Binding<Measurement<Unit>>,
    unit: Unit? = nil,
    format: Measurement<Unit>.FormatStyle,
    minimum: Measurement<Unit>? = nil,
    maximum: Measurement<Unit>? = nil
  ) {
    self.label = label
    self._value = value
    self.unit = unit ?? value.wrappedValue.unit
    self.format = format
    self.minimum = minimum
    self.maximum = maximum
  }
}

#Preview {
  @Previewable @State var weight = Measurement(value: 1000, unit: UnitMass.kilograms)
  @Previewable @State var temperature = Measurement(value: 15, unit: UnitTemperature.celsius)
  @Previewable @State var altimeter = Measurement(value: 1, unit: UnitPressure.bars)

  Form {
    LabeledContent("Weight") {
      MeasurementField(
        "Weight",
        value: $weight,
        unit: .pounds,
        format: .weight,
        maximum: .init(value: 6000, unit: .pounds)
      )
    }
    LabeledContent("Temperature") {
      MeasurementField(
        "Temperature",
        value: $temperature,
        format: .temperature
      )
    }
    LabeledContent("Altimeter") {
      MeasurementField(
        "Altimeter",
        value: $altimeter,
        unit: .inchesOfMercury,
        format: .airPressure
      )
    }
  }
}
