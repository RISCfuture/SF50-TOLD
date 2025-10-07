import SwiftUI

struct NumberField<Value: BinaryFloatingPoint>: View {
  let label: LocalizedStringKey
  @Binding var value: Value
  let format: FloatingPointFormatStyle<Value>
  let minimum: Value?
  let maximum: Value?

  private var isValid: Bool {
    if let minimum {
      if value < minimum { return false }
    }
    if let maximum {
      if value > maximum { return false }
    }
    return true
  }

  var body: some View {
    TextField(label, value: $value, format: format)
      .decimalField()
      .foregroundStyle(isValid ? Color.primary : Color.red)
      .onSubmit { clampValue() }
  }

  init(
    _ label: LocalizedStringKey,
    value: Binding<Value>,
    format: FloatingPointFormatStyle<Value>,
    minimum: Value? = nil,
    maximum: Value? = nil
  ) {
    self.label = label
    self._value = value
    self.format = format
    self.minimum = minimum
    self.maximum = maximum
  }

  private func clampValue() {
    var clampedValue = value
    if let minimum, value < minimum {
      clampedValue = minimum
    }
    if let maximum, value > maximum {
      clampedValue = maximum
    }
    value = clampedValue
  }
}

#Preview {
  @Previewable @State var value1: Double = 123.45
  @Previewable @State var value2: Double = 123.45
  @Previewable @State var value3: Double = 123.45

  List {
    LabeledContent("Value") {
      NumberField("Value", value: $value1, format: .number.rounded(increment: 0.1))
    }
    LabeledContent("Below Min") {
      NumberField("Value", value: $value2, format: .number, minimum: 200)
    }
    LabeledContent("Above Max") {
      NumberField("Value", value: $value3, format: .number, maximum: 100)
    }
  }
}
