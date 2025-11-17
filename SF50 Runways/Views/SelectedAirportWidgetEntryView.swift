import SF50_Shared
import SwiftUI
import WidgetKit

struct SelectedAirportWidgetEntryView: View {
  @Environment(\.widgetFamily)
  var family

  var entry: TOLDProvider.Entry

  @ViewBuilder var body: some View {
    if let airportName = entry.airportName {
      VStack(alignment: .leading, spacing: 10) {
        WidgetAirportView(name: airportName)
        switch family {
          case .systemSmall:
            WidgetGridView(entry: entry)
          default:
            WidgetListView(entry: entry)
        }
      }
      .containerBackground(.background, for: .widget)
    } else {
      WidgetNoAirportView()
    }
  }
}
