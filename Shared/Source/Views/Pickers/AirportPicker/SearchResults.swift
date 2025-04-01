import CoreData
import Defaults
import SwiftUI

struct SearchResults: View {
    @FetchRequest var airports: FetchedResults<Airport>
    @Binding var filterText: String
    var sort: ((Airport, Airport) -> Bool)?

    let onSelect: (Airport) -> Void

    private var sortedAiports: [Airport] {
        guard let sort else { return Array(airports) }
        return airports.sorted(by: { sort($0, $1) })
    }

    var body: some View {
        if (1...2).contains(filterText.count) {
            List {
                Text("Keep typing…")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else if airports.isEmpty {
            List {
                Text("No results.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else {
            List(sortedAiports) { (airport: Airport) in
                AirportRow(airport: airport, showFavoriteButton: true).onTapGesture {
                    onSelect(airport)
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("airportRow-\(airport.id!)")
            }
        }
    }
}

#Preview {
    SearchResults(airports: FetchRequest<Airport>(entity: Airport.entity(),
                                                  sortDescriptors: []),
                  filterText: .constant("Filter"),
                  onSelect: { _ in })
}
