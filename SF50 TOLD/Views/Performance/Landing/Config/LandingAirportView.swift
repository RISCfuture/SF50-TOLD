import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct LandingAirportView: View {
  @State private var showNowButton = false
  @State private var showNOTAMView = false

  @Environment(LandingPerformanceViewModel.self)
  private var performance

  @Environment(WeatherViewModel.self)
  private var weather

  @Environment(\.modelContext)
  private var modelContext

  @Default(.landingAirport)
  private var airportID

  @Default(.landingRunway)
  private var runwayID

  @Default(.useAirportLocalTime)
  private var useAirportLocalTime

  private let nowVisibilityTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  private var elevation: Measurement<UnitLength> {
    performance.runway?.elevationOrAirportElevation ?? performance.airport?.elevation
      ?? .init(value: 0, unit: .feet)
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
    // Insert into the same context that owns the runway to avoid cross-context issues
    runway.modelContext?.insert(notam)
    return notam
  }

  var body: some View {
    @Bindable var weather = weather

    Section("Landing") {
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
          destination: NOTAMView(
            notam: runwayNOTAM,
            downloadedNOTAMs: performance.downloadedNOTAMs,
            plannedTime: weather.time,
            isLoadingNOTAMs: performance.isLoadingNOTAMs
          )
        ) {
          HStack {
            Text("NOTAMs").foregroundStyle(.primary)
            Spacer()
            NOTAMBadge(
              configuredCount: performance.configuredNOTAMCount,
              availableCount: performance.downloadedNOTAMCount,
              isLoading: performance.isLoadingNOTAMs,
              hasAttemptedFetch: performance.hasAttemptedNOTAMFetch
            )
          }
        }.accessibilityIdentifier("NOTAMsSelector")
      }
    }
    .onReceive(nowVisibilityTimer) { _ in setShowNowButton() }
    .onAppear { setShowNowButton() }
    .onChange(of: weather.time) { _, newTime in
      setShowNowButton()
      // Refetch NOTAMs when time changes
      Task {
        await performance.fetchNOTAMs(plannedTime: newTime)
        await parseAndApplyNOTAMs()
      }
    }
    .task(id: weather.airport?.persistentModelID) { await weather.load() }
    .task(id: performance.runway?.persistentModelID) {
      // Fetch NOTAMs when view appears or runway changes
      guard performance.airport != nil, performance.runway != nil else { return }
      await performance.fetchNOTAMs(plannedTime: weather.time)
      await parseAndApplyNOTAMs()
    }
  }

  private func setShowNowButton() {
    showNowButton = abs(weather.time.timeIntervalSinceNow) >= 120
  }

  /// Parses downloaded NOTAMs using the trained adapter and applies results
  private func parseAndApplyNOTAMs() async {
    guard #available(iOS 26.0, macOS 26.0, *) else { return }
    guard let runway = performance.runway else { return }
    guard !performance.downloadedNOTAMs.isEmpty else { return }

    let interpretedNOTAMs = await NOTAMInterpreter.shared.parse(
      performance.downloadedNOTAMs,
      for: runway.name
    )

    // Apply parsed data to the runway's NOTAM on the main actor
    guard !interpretedNOTAMs.isEmpty else { return }

    for parsed in interpretedNOTAMs where !parsed.isEmpty {
      parsed.apply(to: runwayNOTAM, for: .landing)
    }
  }
}

#Preview("Airport") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setLanding(runway: runway)

    return Form {
      LandingAirportView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
    .environment(WeatherViewModel(operation: .landing, container: preview.container))
  }
}

#Preview("No Airport") {
  PreviewView { preview in
    return Form {
      LandingAirportView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
    .environment(WeatherViewModel(operation: .landing, container: preview.container))
  }
}
