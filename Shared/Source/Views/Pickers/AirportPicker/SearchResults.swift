import SwiftUI
import CoreData
import Defaults

struct SearchResults: View {
    @FetchRequest var airports: FetchedResults<Airport>
    @Binding var filterText: String
    var sort: ((Airport, Airport) -> Bool)? = nil
    
    let onSelect: (Airport) -> Void
    
    private var sortedAiports: Array<Airport> {
        guard let sort = sort else { return Array(airports) }
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
            }
        }
    }
}
