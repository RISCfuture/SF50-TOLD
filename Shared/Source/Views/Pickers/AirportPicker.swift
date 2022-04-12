import SwiftUI
import CoreData
import Defaults

struct AirportPicker: View {
    @State var filter = ""
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var onSelect: (Airport) -> Void
    
    private var fetchAirportsPredicate: NSPredicate {
        .init(format: "lid ==[c] %@ OR icao ==[c] %@ OR name CONTAINS[cd] %@ OR city CONTAINS[cd] %@",
              filter, filter, filter, filter)
    }
    
    private var fetchFavoritesAndRecentsPredicate: NSPredicate {
        NSPredicate(format: "%@ contains[c] id", favoriteAndRecentIDs)
    }
    
    private var favoriteAndRecentIDs: Set<String> {
        return Set(Defaults[.favoriteAirports] + Defaults[.recentAirports])
    }
    
    private var fetchPredicate: NSPredicate {
        filter.count < 3 ? fetchFavoritesAndRecentsPredicate : fetchAirportsPredicate
    }
    
    private var fetchAirports: FetchRequest<Airport> {
        .init(entity: Airport.entity(),
              sortDescriptors: [
                .init(keyPath: \Airport.lid, ascending: true)
              ],
              predicate: fetchPredicate)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            SearchField(placeholder: "Find Airport", text: $filter)
            AirportPickerResults(airports: fetchAirports, filterText: $filter, onSelect: { airport in
                onSelect(airport)
                self.mode.wrappedValue.dismiss()
            })
        }
    }
}

struct AirportPicker_Previews: PreviewProvider {
    private static let OAK = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        return a
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    private static let state = SectionState(operation: .takeoff)
    
    static var previews: some View {
        AirportPicker() { _ in }
    }
}
