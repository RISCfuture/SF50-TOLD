import Defaults
import SwiftUI

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

#Preview {
    FavoritesView { _ in }
}
