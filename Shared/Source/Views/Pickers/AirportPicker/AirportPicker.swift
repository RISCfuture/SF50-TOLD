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
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State fileprivate var tabIndex: AirportPickerTabs = .favorites
    
    var onSelect: (Airport) -> Void
    

    var body: some View {
        VStack(alignment: .leading) {
            Picker("Tab", selection: $tabIndex) {
                Text("Favorites").tag(AirportPickerTabs.favorites)
                Text("Recents").tag(AirportPickerTabs.recents)
                if CLLocationManager.locationServicesEnabled() {
                    Text("Nearest").tag(AirportPickerTabs.nearest)
                }
                Text("Search").tag(AirportPickerTabs.search)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            switch (tabIndex) {
                case .favorites: FavoritesView(onSelect: selectAndDismiss)
                case .recents: RecentsView(onSelect: selectAndDismiss)
                case .nearest: NearestView(onSelect: selectAndDismiss)
                case .search: SearchView(onSelect: selectAndDismiss)
            }
        }
    }
    
    private func selectAndDismiss(airport: Airport) {
        onSelect(airport)
        mode.wrappedValue.dismiss()
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
    
    static var previews: some View {
        AirportPicker() { _ in }
    }
}
