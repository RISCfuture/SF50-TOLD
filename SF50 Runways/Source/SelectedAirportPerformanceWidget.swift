import SwiftUI
import WidgetKit

struct SelectedAirportPerformanceWidget: Widget {
    let kind: String = "SR22G2_SelectedAirport"
    
    var body: some WidgetConfiguration {
        return StaticConfiguration(kind: kind,
                                   provider: TOLDProvider(managedObjectContext: PersistentContainer.shared.viewContext)) { entry in
            SelectedAirportWidgetEntryView(entry: entry)
        }
         .configurationDisplayName("SR22-G2 Selected Airport Performance")
         .description("Displays all runways at the takeoff airport, and whether a takeoff is possible from each runway. Uses the last supplied runway, payload, and fuel data, with current weather.")
         .supportedFamilies([.systemSmall, .systemMedium])
    }
}
