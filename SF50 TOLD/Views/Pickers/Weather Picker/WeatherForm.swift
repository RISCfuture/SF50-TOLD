import Foundation
import SF50_Shared
import SwiftUI

struct WeatherForm: View {
  @State private var windDirection: Measurement<UnitAngle> = .init(value: 0, unit: .degrees)
  @State private var windSpeed: Measurement<UnitSpeed> = .init(value: 0, unit: .knots)
  @State private var temperature: Measurement<UnitTemperature> = standardTemperature
  @State private var altimeter: Measurement<UnitPressure> = standardSeaLevelPressure

  @Environment(WeatherViewModel.self)
  private var weather

  var body: some View {
    Section("Customize Weather") {
      LabeledContent("Winds") {
        HStack {
          MeasurementField(
            "Direction",
            value: $windDirection,
            unit: defaultHeadingUnit,
            format: .heading
          )
          .accessibilityIdentifier("windDirectionField")
          .onSubmit { updateWeatherIfChanged() }
          Text("@", comment: "Wind direction/speed separator").foregroundStyle(.secondary)
          MeasurementField(
            "Speed",
            value: $windSpeed,
            unit: defaultSpeedUnit,
            format: .speed
          )
          .frame(maxWidth: 70)
          .accessibilityIdentifier("windSpeedField")
          .onSubmit { updateWeatherIfChanged() }
        }
      }

      LabeledContent("Temperature") {
        MeasurementField(
          "Temperature",
          value: $temperature,
          unit: defaultTemperatureUnit,
          format: .temperature
        )
        .multilineTextAlignment(.trailing)
        .accessibilityIdentifier("tempField")
        .onSubmit { updateWeatherIfChanged() }
      }

      LabeledContent("Altimeter") {
        MeasurementField(
          "Altimeter",
          value: $altimeter,
          unit: defaultAirPressureUnit,
          format: .airPressure
        )
        .accessibilityIdentifier("altimeterField")
        .onSubmit { updateWeatherIfChanged() }
      }
    }
    .onAppear {
      windDirection = weather.conditions.windDirection ?? .init(value: 0, unit: .degrees)
      windSpeed = weather.conditions.windSpeed ?? .init(value: 0, unit: .knots)
      temperature = weather.conditions.temperature ?? standardTemperature
      altimeter = weather.conditions.seaLevelPressure ?? standardSeaLevelPressure
    }
    .onChange(of: windDirection) { _, _ in updateWeatherIfChanged() }
    .onChange(of: windSpeed) { _, _ in updateWeatherIfChanged() }
    .onChange(of: temperature) { _, _ in updateWeatherIfChanged() }
    .onChange(of: altimeter) { _, _ in updateWeatherIfChanged() }
  }

  private func updateWeatherIfChanged() {
    // Check if any value has actually changed from the weather conditions
    let directionChanged =
      windDirection != (weather.conditions.windDirection ?? .init(value: 0, unit: .degrees))
    let speedChanged = windSpeed != (weather.conditions.windSpeed ?? .init(value: 0, unit: .knots))
    let tempChanged =
      temperature != (weather.conditions.temperature ?? standardTemperature)
    let altimeterChanged =
      altimeter != (weather.conditions.seaLevelPressure ?? standardSeaLevelPressure)

    if directionChanged || speedChanged || tempChanged || altimeterChanged {
      let conditions = weather.conditions.userModified(
        with: .init(
          windDirection: directionChanged ? windDirection : nil,
          windSpeed: speedChanged ? windSpeed : nil,
          temperature: tempChanged ? temperature : nil,
          seaLevelPressure: altimeterChanged ? altimeter : nil
        )
      )
      weather.conditions = conditions
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return Form { WeatherForm() }
      .environment(WeatherViewModel(operation: .takeoff, container: preview.container))
  }
}
