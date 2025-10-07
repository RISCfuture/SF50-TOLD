import Defaults
import SF50_Shared
import SwiftUI
import WidgetKit

// Helper to create sample entries for widget previews
@MainActor
enum PreviewEntries {
  static func airportWithPerformance() -> RunwayWidgetEntry {
    // We can't use PreviewView in timeline closures, so we create sample data directly
    // Use the unsaved() airports which don't require database context
    let airport = AirportBuilder.KSQL.unsaved()
    let conditions = Conditions(
      windDirection: Measurement(value: 280, unit: .degrees),
      windSpeed: Measurement(value: 10, unit: .knots),
      temperature: standardTemperature,
      seaLevelPressure: standardSeaLevelPressure
    )

    let takeoffDistances: [String: Value<Measurement<UnitLength>>] = [
      "30": .value(Measurement(value: 2500, unit: .feet)),
      "12": .value(Measurement(value: 2800, unit: .feet))
    ]

    return RunwayWidgetEntry(
      date: Date(),
      airport: airport,
      conditions: conditions,
      takeoffDistances: takeoffDistances
    )
  }

  static func oakAirportWithPerformance() -> RunwayWidgetEntry {
    let airport = AirportBuilder.KOAK.unsaved()
    let conditions = Conditions(
      windDirection: Measurement(value: 90, unit: .degrees),
      windSpeed: Measurement(value: 28, unit: .knots),
      temperature: Measurement(value: 7, unit: .celsius),
      seaLevelPressure: Measurement(value: 29.12, unit: .inchesOfMercury)
    )

    let takeoffDistances: [String: Value<Measurement<UnitLength>>] = [
      "12": .value(Measurement(value: 3500, unit: .feet)),
      "30": .value(Measurement(value: 2900, unit: .feet)),
      "10L": .value(Measurement(value: 4200, unit: .feet)),
      "28R": .value(Measurement(value: 2600, unit: .feet))
    ]

    return RunwayWidgetEntry(
      date: Date(),
      airport: airport,
      conditions: conditions,
      takeoffDistances: takeoffDistances
    )
  }

  static func airportWithInsufficientDistance() -> RunwayWidgetEntry {
    let airport = AirportBuilder.KSQL.unsaved()
    let conditions = Conditions(
      windDirection: Measurement(value: 0, unit: .degrees),
      windSpeed: Measurement(value: 5, unit: .knots),
      temperature: Measurement(value: 35, unit: .celsius),
      seaLevelPressure: Measurement(value: 29.50, unit: .inchesOfMercury)
    )

    let takeoffDistances: [String: Value<Measurement<UnitLength>>] = [
      "30": .value(Measurement(value: 3500, unit: .feet)),  // Over runway length
      "12": .notAuthorized
    ]

    return RunwayWidgetEntry(
      date: Date(),
      airport: airport,
      conditions: conditions,
      takeoffDistances: takeoffDistances
    )
  }
}

// Widget timeline previews - these work in widget extensions
#Preview("Small Widget - No Airport", as: .systemSmall) {
  SelectedAirportPerformanceWidget()
} timeline: {
  RunwayWidgetEntry.empty()
}

#Preview("Small Widget - With Airport", as: .systemSmall) {
  SelectedAirportPerformanceWidget()
} timeline: {
  PreviewEntries.airportWithPerformance()
}

#Preview("Small Widget - Insufficient Distance", as: .systemSmall) {
  SelectedAirportPerformanceWidget()
} timeline: {
  PreviewEntries.airportWithInsufficientDistance()
}

#Preview("Medium Widget - No Airport", as: .systemMedium) {
  SelectedAirportPerformanceWidget()
} timeline: {
  RunwayWidgetEntry.empty()
}

#Preview("Medium Widget - With Airport", as: .systemMedium) {
  SelectedAirportPerformanceWidget()
} timeline: {
  PreviewEntries.oakAirportWithPerformance()
}

#Preview("Medium Widget - Mixed Status", as: .systemMedium) {
  SelectedAirportPerformanceWidget()
} timeline: {
  PreviewEntries.airportWithInsufficientDistance()
}
