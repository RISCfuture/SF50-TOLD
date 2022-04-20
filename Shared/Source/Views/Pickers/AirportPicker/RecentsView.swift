import SwiftUI
import Defaults

struct RecentsView: View {
    var onSelect: (Airport) -> Void
    
    private var predicate: NSPredicate {
        .init(format: "%@ contains[c] id", Defaults[.recentAirports])
    }
    
    private var fetchAirports: FetchRequest<Airport> {
        .init(entity: Airport.entity(), sortDescriptors: [
            .init(keyPath: \Airport.id, ascending: true)
        ],
              predicate: predicate)
    }
    
    var body: some View {
        ListResults(airports: fetchAirports, onSelect: { airport in
            onSelect(airport)
        })
    }
}

struct RecentsView_Previews: PreviewProvider {
    static var previews: some View {
        RecentsView() { _ in }
    }
}
