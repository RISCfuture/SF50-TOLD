import Defaults
import SF50_Shared
import SwiftUI

struct UnitsSettingsView: View {
  @Default(.weightUnit)
  private var weightUnit

  @Default(.fuelVolumeUnit)
  private var fuelVolumeUnit

  @Default(.fuelDensityUnit)
  private var fuelDensityUnit

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  @Default(.distanceUnit)
  private var distanceUnit

  @Default(.heightUnit)
  private var heightUnit

  @Default(.speedUnit)
  private var speedUnit

  @Default(.temperatureUnit)
  private var temperatureUnit

  @Default(.pressureUnit)
  private var pressureUnit

  var body: some View {
    Form {
      Section("Weight & Fuel") {
        Picker("Weight", selection: $weightUnit) {
          Text("Pounds (lb)").tag(UnitMass.pounds)
          Text("Kilograms (kg)").tag(UnitMass.kilograms)
        }
        .accessibilityIdentifier("weightUnitPicker")

        Picker("Fuel Volume", selection: $fuelVolumeUnit) {
          Text("Gallons (gal)").tag(UnitVolume.gallons)
          Text("Liters (L)").tag(UnitVolume.liters)
        }
        .accessibilityIdentifier("fuelVolumeUnitPicker")

        Picker("Fuel Density", selection: $fuelDensityUnit) {
          Text("Pounds per Gallon (lb/gal)").tag(UnitDensity.poundsPerGallon)
          Text("Kilograms per Liter (kg/L)").tag(UnitDensity.kilogramsPerLiter)
        }
        .accessibilityIdentifier("fuelDensityUnitPicker")
      }

      Section("Distance & Length") {
        Picker("Runway Length", selection: $runwayLengthUnit) {
          Text("Feet (ft)").tag(UnitLength.feet)
          Text("Meters (m)").tag(UnitLength.meters)
        }
        .accessibilityIdentifier("runwayLengthUnitPicker")

        Picker("Distance", selection: $distanceUnit) {
          Text("Nautical Miles (Nmi)").tag(UnitLength.nauticalMiles)
          Text("Kilometers (km)").tag(UnitLength.kilometers)
          Text("Statute Miles (mi)").tag(UnitLength.miles)
        }
        .accessibilityIdentifier("distanceUnitPicker")

        Picker("Height", selection: $heightUnit) {
          Text("Feet (ft)").tag(UnitLength.feet)
          Text("Meters (m)").tag(UnitLength.meters)
        }
        .accessibilityIdentifier("heightUnitPicker")
      }

      Section("Weather") {
        Picker("Wind Speed", selection: $speedUnit) {
          Text("Knots (kt)").tag(UnitSpeed.knots)
          Text("Kilometers per Hour (km/h)").tag(UnitSpeed.kilometersPerHour)
          Text("Miles per Hour (mph)").tag(UnitSpeed.milesPerHour)
        }
        .accessibilityIdentifier("speedUnitPicker")

        Picker("Temperature", selection: $temperatureUnit) {
          Text("Celsius (°C)").tag(UnitTemperature.celsius)
          Text("Fahrenheit (°F)").tag(UnitTemperature.fahrenheit)
        }
        .accessibilityIdentifier("temperatureUnitPicker")

        Picker("Pressure", selection: $pressureUnit) {
          Text("Inches of Mercury (inHg)").tag(UnitPressure.inchesOfMercury)
          Text("Hectopascals (hPa)").tag(UnitPressure.hectopascals)
        }
        .accessibilityIdentifier("pressureUnitPicker")
      }
    }
    .navigationTitle("Units")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

#Preview {
  NavigationStack {
    UnitsSettingsView()
  }
}
