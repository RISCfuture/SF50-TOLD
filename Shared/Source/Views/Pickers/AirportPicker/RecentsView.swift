import Defaults
import SwiftUI

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

#Preview {
    RecentsView { _ in }
}
