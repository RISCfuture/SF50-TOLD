import SwiftUI
import Defaults

struct FavoritesView: View {
    var onSelect: (Airport) -> Void
    
    private var predicate: NSPredicate {
        .init(format: "%@ contains[c] id", Defaults[.favoriteAirports])
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

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView() { _ in }
    }
}
