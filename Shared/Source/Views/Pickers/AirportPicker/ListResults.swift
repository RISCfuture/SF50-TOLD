import SwiftUI

struct ListResults: View {
    @FetchRequest var airports: FetchedResults<Airport>
    var sort: ((Airport, Airport) -> Bool)? = nil
    
    let onSelect: (Airport) -> Void
    
    private var sortedAiports: Array<Airport> {
        guard let sort = sort else { return Array(airports.prefix(10)) }
        return Array(airports.sorted(by: { sort($0, $1) }).prefix(10))
    }
    
    var body: some View {
        if airports.isEmpty {
            List {
                Text("No results.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else {
            List(sortedAiports) { (airport: Airport) in
                AirportRow(airport: airport, showFavoriteButton: true)
                    .onTapGesture {
                        onSelect(airport)
                    }
                    .accessibility(addTraits: .isButton)
                    .accessibilityIdentifier("airportRow-\(airport.id!)")
            }
        }
    }
}

struct ListResults_Previews: PreviewProvider {
    static var previews: some View {
        ListResults(airports: FetchRequest<Airport>(entity: Airport.entity(),
                                                    sortDescriptors: []),
                    onSelect: { _ in })
    }
}
