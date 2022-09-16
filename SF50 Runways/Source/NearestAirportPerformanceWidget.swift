import SwiftUI
import WidgetKit

struct NearestAirportPerformanceWidget: Widget {
    let kind: String = "SF50_NearestAirport"
    
    var body: some WidgetConfiguration {
        return StaticConfiguration(kind: kind,
                                   provider: Provider(airport: .nearest,
                                                      managedObjectContext: PersistentContainer.shared.viewContext)) { entry in
            NearestAirportWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SF50 Nearest Airport Performance")
        .description("Displays all runways at the nearest airport, and whether a takeoff is possible from each runway. Uses the last supplied payload and fuel data, with current weather.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
