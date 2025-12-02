import SwiftData
import SwiftUI
import WidgetKit

/// Widget displaying takeoff performance for all runways at the selected airport.
///
/// ``SelectedAirportPerformanceWidget`` shows a quick overview of whether takeoff
/// is possible from each runway at the user's selected airport. It uses current
/// weather conditions and the user's configured aircraft weight.
///
/// ## Supported Sizes
///
/// - **Small**: Shows airport name and runway count
/// - **Medium**: Shows individual runway performance details
///
/// ## Updates
///
/// The widget automatically refreshes every 15 minutes for weather updates.
/// Settings changes in the main app trigger immediate refresh.
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
