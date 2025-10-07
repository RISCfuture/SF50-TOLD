import CoreData
import SF50_Shared
import SwiftUI

struct WeatherPicker: View {
  let elevation: Measurement<UnitLength>?

  @Environment(WeatherViewModel.self)
  private var weather

  private var densityAltitude: Measurement<UnitLength>? {
    elevation.map { weather.conditions.densityAltitude(elevation: $0) }
  }

  var body: some View {
    Form {
      if weather.isLoading {
        HStack(spacing: 10) {
          ProgressView().progressViewStyle(CircularProgressViewStyle())
          Text("Loading weather…").foregroundStyle(.secondary)
          Spacer()
          Button("Cancel") { Task { await weather.cancel() } }
            .accessibilityIdentifier("cancelWeatherUpdateButton")
        }
      } else {
        WeatherSource()
        WeatherForm()
        if let densityAltitude {
          Text("Density altitude: \(densityAltitude, format: .height)")
            .foregroundStyle(.secondary)
            .font(.system(size: 14))
        }
      }
    }.navigationTitle("Weather")
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return WeatherPicker(elevation: runway.elevationOrAirportElevation)
      .environment(WeatherViewModel(operation: .takeoff, container: preview.container))
  }
}
