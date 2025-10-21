import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct TakeoffAirportView: View {
  @State private var showNowButton = false
  @State private var showNOTAMView = false

  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  @Environment(WeatherViewModel.self)
  private var weather

  @Environment(\.modelContext)
  private var modelContext

  @Default(.takeoffAirport)
  private var airportID

  @Default(.takeoffRunway)
  private var runwayID

  @Default(.useAirportLocalTime)
  private var useAirportLocalTime

  private let nowVisibilityTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  private var elevation: Measurement<UnitLength> {
    performance.runway?.elevationOrAirportElevation ?? performance.airport?.elevation
      ?? .init(value: 0, unit: .feet)
  }

  private var NOTAMTitle: String {
    return performance.NOTAMCount == 0
      ? String(localized: "NOTAMs")
      : String(localized: "NOTAMs (\(performance.NOTAMCount, format: .count))")
  }

  private var displayTimeZone: TimeZone {
    if useAirportLocalTime {
      return performance.airport?.timeZone ?? .current
    }
    return TimeZone(identifier: "UTC") ?? .current
  }

  private var runwayNOTAM: NOTAM {
    guard let runway = performance.runway else { fatalError("Runway is nil") }
    if let notam = runway.notam { return notam }
    let notam = NOTAM(runway: runway)
    runway.notam = notam
    modelContext.insert(notam)
    return notam
  }

  var body: some View {
    @Bindable var weather = weather

    Section("Takeoff") {
      HStack {
        DatePicker("Date", selection: $weather.time, in: Date()...)
          .environment(\.timeZone, displayTimeZone)
          .accessibilityIdentifier("dateSelector")
        Text(displayTimeZone.abbreviation() ?? displayTimeZone.identifier)
          .font(.caption)
          .foregroundStyle(.secondary)
        if showNowButton {
          Button(action: { weather.time = .now }, label: { Text("Now") })
            .accessibilityIdentifier("dateNowButton")
        }
      }

      NavigationLink(
        destination: AirportPicker(onSelect: { airport in
          airportID = airport.recordID
          runwayID = nil
        })
      ) {
        Label {
          if let airport = performance.airport {
            AirportRow(airport: airport, showFavoriteButton: false)
          } else {
            Text("Choose Airport").foregroundStyle(Color.accentColor)
          }
        } icon: {
        }
      }.accessibilityIdentifier("airportSelector")

      if let airport = performance.airport {
        NavigationLink(
          destination: RunwayPicker(
            airport: airport,
            conditions: weather.conditions,
            onSelect: { runwayID = $0.name }
          )
        ) {
          Label {
            if let runway = performance.runway {
              RunwayRow(
                runway: runway,
                conditions: performance.conditions,
                flapSetting: performance.flapSetting
              )
            } else {
              Text("Choose Runway").foregroundStyle(Color.accentColor)
            }
          } icon: {
          }
        }.accessibilityIdentifier("runwaySelector")
        NavigationLink(destination: WeatherPicker(elevation: elevation)) {
          WeatherRow(elevation: elevation)
        }.accessibilityIdentifier("weatherSelector")
      }

      if performance.runway != nil {
        NavigationLink(
          destination: NOTAMView(notam: runwayNOTAM)
        ) {
          Label {
            Text(NOTAMTitle).foregroundStyle(.primary)
          } icon: {
          }
        }.accessibilityIdentifier("NOTAMsSelector")
      }
    }
    .onReceive(nowVisibilityTimer) { _ in setShowNowButton() }
    .onAppear { setShowNowButton() }
    .onChange(of: weather.time) { _, _ in setShowNowButton() }
    .task { await weather.load() }
  }

  private func setShowNowButton() {
    showNowButton = abs(weather.time.timeIntervalSinceNow) >= 120
  }
}

#Preview("Airport") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return Form {
      TakeoffAirportView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
    .environment(WeatherViewModel(operation: .takeoff, container: preview.container))
  }
}

#Preview("No Airport") {
  PreviewView { preview in
    return Form {
      TakeoffAirportView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
    .environment(WeatherViewModel(operation: .takeoff, container: preview.container))
  }
}
