import Defaults
import SwiftUI

struct ModelToggleView: View {
  @Default(.useRegressionModel)
  var useRegressionModel

  var body: some View {
    VStack(alignment: .leading) {
      Picker("Performance Model", selection: $useRegressionModel) {
        Text("Tabular").tag(false)
        Text("Regression").tag(true)
      }
      .pickerStyle(MenuPickerStyle())
      .accessibilityIdentifier("selectModelToggle")

      VStack(alignment: .leading, spacing: 8) {
        if useRegressionModel {
          HStack {
            Image(systemName: "x.circle")
              .foregroundStyle(.red)
              .accessibilityLabel("Disadvantage")
            Text("Will have small deviations from book values (generally less than 100 ft)")
          }
          HStack {
            Image(systemName: "checkmark.circle")
              .foregroundStyle(.green)
              .accessibilityLabel("Advantage")
            Text(
              "Will provide estimates even when flying outside of published AFM weights, altitudes, and temperatures"
            )
          }
        } else {
          HStack {
            Image(systemName: "checkmark.circle")
              .foregroundStyle(.green)
              .accessibilityLabel("Advantage")
            Text("Will match book values exactly")
          }
          HStack {
            Image(systemName: "x.circle")
              .foregroundStyle(.red)
              .accessibilityLabel("Disadvantage")
            Text(
              "Will not extrapolate: You will see “Offscale” errors when above or below published AFM weights, altitudes, and temperatures"
            )
          }
        }
      }.font(.system(size: 11))
    }
  }
}

#Preview {
  Form {
    ModelToggleView()
  }
}
