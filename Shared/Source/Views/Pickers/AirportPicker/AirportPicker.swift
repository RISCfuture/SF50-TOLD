import SwiftUI
import CoreData
import Defaults
import CoreLocation

fileprivate enum AirportPickerTabs {
    case favorites
    case recents
    case nearest
    case search
}

struct AirportPicker: View {
    @Environment(\.presentationMode) var mode
    @State fileprivate var tabIndex: AirportPickerTabs = .favorites
    @StateObject fileprivate var nearestAirport = NearestAirportPublisher()
    
    var onSelect: (Airport) -> Void
    
#if os(macOS)
    let isAuthorized = { (status: CLAuthorizationStatus) in status == .authorizedAlways }
#else
    let isAuthorized = { (status: CLAuthorizationStatus) in status == .authorizedAlways || status == .authorizedWhenInUse }
#endif
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Tab", selection: $tabIndex) {
                Text("Favorites").tag(AirportPickerTabs.favorites)
                Text("Recents").tag(AirportPickerTabs.recents)
                if let authStatus = nearestAirport.authorizationStatus {
                    if isAuthorized(authStatus) {
                        Text("Nearest").tag(AirportPickerTabs.nearest)
                    }
                }
                Text("Search").tag(AirportPickerTabs.search)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .accessibilityIdentifier("airportListPicker")
            
            switch (tabIndex) {
                case .favorites: FavoritesView(onSelect: selectAndDismiss)
                case .recents: RecentsView(onSelect: selectAndDismiss)
                case .nearest: NearestView(nearestAirport: nearestAirport, onSelect: selectAndDismiss)
                case .search: SearchView(onSelect: selectAndDismiss)
            }
        }.onAppear {
            
        }
    }
    
    private func selectAndDismiss(airport: Airport) {
        onSelect(airport)
        mode.wrappedValue.dismiss()
    }
}

#Preview {
    let OAK = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        return a
    }()
    let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    return AirportPicker() { _ in }
}
