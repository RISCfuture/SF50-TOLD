import SF50_Shared
import SwiftUI
import WidgetKit

struct WidgetGridView: View {
  var entry: RunwayWidgetEntry

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  private var runways: [RunwaySnapshot]? {
    guard let entryRunways = entry.runways else { return nil }

    let sortedRunways = entryRunways.sorted(using: RunwaySnapshot.NameComparator())
    return Array(sortedRunways.prefix(8))
  }

  var body: some View {
    LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
      if let runways {
        ForEach(runways, id: \.name) { runway in
          RunwayGridItem(runway: runway, takeoffDistance: entry.takeoffDistances?[runway.name])
        }
      } else {
        // Show realistic-looking fake runway data
        RunwayPlaceholderGridItem(runwayName: "07L", isGreen: true)
        RunwayPlaceholderGridItem(runwayName: "07R", isGreen: false)
        RunwayPlaceholderGridItem(runwayName: "25L", isGreen: true)
        RunwayPlaceholderGridItem(runwayName: "25R", isGreen: true)
      }
    }
  }
}
