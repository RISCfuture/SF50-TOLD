import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct RecentsView: View {
  private static var predicate: Predicate<Airport> {
    let recents = Defaults[.recentAirports]
    return #Predicate { recents.contains($0.recordID) }
  }

  var onSelect: (Airport) -> Void

  @Query(filter: predicate, sort: \Airport.locationID)
  private var airports: [Airport]

  var body: some View {
    if airports.isEmpty {
      List {
        Text("No results.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
      }
    } else {
      List(airports) { (airport: Airport) in
        AirportRow(airport: airport, showFavoriteButton: true)
          .onTapGesture {
            onSelect(airport)
          }
          .accessibility(addTraits: .isButton)
          .accessibilityIdentifier("airportRow-\(airport.displayID)")
      }
    }
  }
}

#Preview("Airports") {
  PreviewView(insert: .KOAK, .K1C9, .KSQL) { _ in
    Defaults[.recentAirports] = ["1C9", "OAK", "SQL"]

    return RecentsView { _ in }
  }
}

#Preview("No Airports") {
  PreviewView { _ in
    Defaults[.recentAirports] = []

    return RecentsView { _ in }
  }
}
