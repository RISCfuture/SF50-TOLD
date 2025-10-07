import Defaults
import SF50_Shared
import SwiftUI

struct SettingsView: View {
  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @Default(.emptyWeight)
  private var emptyWeight

  @Default(.fuelDensity)
  private var fuelDensity

  @Default(.safetyFactor)
  private var safetyFactor

  @Default(.useAirportLocalTime)
  private var useAirportLocalTime

  var body: some View {
    NavigationView {
      Form {
        Section {
          ModelToggleView()
          LabeledContent("Safety Factor") {
            NumberField(
              "Factor",
              value: $safetyFactor,
              format: .number.rounded(increment: 0.1),
              minimum: 1.0
            )
            .multilineTextAlignment(.trailing)
            .accessibilityIdentifier("safetyFactorField")
          }
        }

        Section {
          VStack(alignment: .leading) {
            Toggle("Use Updated Thrust Schedule", isOn: $updatedThrustSchedule)
              .accessibilityIdentifier("updatedThrustScheduleToggle")
            Text(
              "Turn this setting on when flying a G2+ Vision Jet or one with SB5X-72-01 completed."
            )
            .font(.system(size: 11))
            .fixedSize(horizontal: false, vertical: true)
          }
          LabeledContent("Empty Weight") {
            MeasurementField(
              "Weight",
              value: $emptyWeight,
              unit: .pounds,
              format: .weight,
              minimum: .init(value: 0, unit: .pounds)
            )
            .accessibilityIdentifier("weightField")
          }
          LabeledContent("Fuel Density") {
            MeasurementField(
              "Density",
              value: $fuelDensity,
              unit: .poundsPerGallon,
              format: .fuelDensity,
              minimum: .init(value: 0, unit: .poundsPerGallon)
            )
            .accessibilityIdentifier("fuelDensityField")
          }
        }

        Section {
          Picker("Time Zone Display", selection: $useAirportLocalTime) {
            Text("UTC").tag(false)
            Text("Airport Local").tag(true)
          }
          .accessibilityIdentifier("timeZoneDisplayPicker")
        }
      }.navigationTitle("Settings")
    }.navigationViewStyle(navigationStyle)
  }
}

#Preview {
  SettingsView()
}
