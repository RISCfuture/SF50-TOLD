import SF50_Shared
import SwiftUI
import WidgetKit

struct WidgetListView: View {
  var entry: RunwayWidgetEntry

  private var runways: [Runway]? {
    guard let airport = entry.airport else { return nil }

    let sortedRunways = airport.runways.sorted(using: Runway.NameComparator())
    return Array(sortedRunways.prefix(4))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let runways {
        ForEach(runways, id: \.name) { runway in
          RunwayListItem(
            runway: runway,
            takeoffDistance: entry.takeoffDistances?[runway.name],
            conditions: entry.conditions
          )
        }
      } else {
        // Show realistic-looking fake runway data
        RunwayPlaceholderListItem(
          runwayName: "07L",
          headwind: "6",
          tailwind: "1",
          distance: "2,987′",
          available: "5,253′",
          isGreen: true
        )
        RunwayPlaceholderListItem(
          runwayName: "07R",
          headwind: "6",
          tailwind: "1",
          distance: "2,989′",
          available: "2,699′",
          isGreen: false
        )
        RunwayPlaceholderListItem(
          runwayName: "25L",
          headwind: "1",
          tailwind: "6",
          distance: "2,377′",
          available: "2,699′",
          isGreen: true
        )
        RunwayPlaceholderListItem(
          runwayName: "25R",
          headwind: "1",
          tailwind: "6",
          distance: "2,378′",
          available: "5,253′",
          isGreen: true
        )
      }
    }
  }
}
