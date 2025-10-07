import SwiftData
import SwiftUI
import WidgetKit

struct SelectedAirportPerformanceWidget: Widget {
  let kind: String = "SF50_SelectedAirport"

  var body: some WidgetConfiguration {
    return StaticConfiguration(
      kind: kind,
      provider: TOLDProvider()
    ) { entry in
      SelectedAirportWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("SF50 Selected Airport Performance")
    .description(
      "Displays all runways at the takeoff airport, and whether a takeoff is possible from each runway. Uses the last supplied runway, payload, and fuel data, with current weather."
    )
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview("Small", as: .systemSmall) {
  SelectedAirportPerformanceWidget()
} timeline: {
  RunwayWidgetEntry.empty()
}

#Preview("Medium", as: .systemMedium) {
  SelectedAirportPerformanceWidget()
} timeline: {
  RunwayWidgetEntry.empty()
}
