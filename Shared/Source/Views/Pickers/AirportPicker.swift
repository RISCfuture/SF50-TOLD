import SwiftUI
import CoreData
import Defaults

struct AirportPicker: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject var state: AirportPickerState
    
    var setAirport: (Airport) -> Void
    
    private var predicate: NSPredicate {
        let text = state.airportFilterText
        return NSPredicate(format: "lid ==[c] %@ OR icao ==[c] %@ OR name CONTAINS[cd] %@ OR city CONTAINS[cd] %@", text, text, text, text)
    }
    
    lazy var fetchRequest = FetchRequest<Airport>(entity: Airport.entity(),
                                         sortDescriptors: [],
                                         predicate: predicate)
    
    private mutating func matchingAirports() -> Array<Airport> {
        fetchRequest.wrappedValue
            .sorted { $0.name!.localizedCompare($1.name!) == .orderedAscending }
    }
    
    var body: some View {
        ErrorView(error: state.error) {
            VStack(alignment: .leading) {
                SearchField(placeholder: "Find Airport", text: $state.airportFilterText)
                if state.matchingAirports.isEmpty && state.favoriteAndRecentAirports.isEmpty {
                    List {
                        Text("No results.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                } else if state.matchingAirports.isEmpty {
                    List(state.favoriteAndRecentAirports) { (airport: Airport) in
                        AirportRow(showIcon: true) {
                            self.setAirport(airport)
                            self.mode.wrappedValue.dismiss()
                        }.environmentObject(AirportState(airport: airport))
                    }
                } else {
                    List(state.matchingAirports) { (airport: Airport) in
                        AirportRow(showIcon: true) {
                            self.setAirport(airport)
                            self.mode.wrappedValue.dismiss()
                        }.environmentObject(AirportState(airport: airport))
                    }
                }
                
                Spacer()
            }.navigationTitle("Airport")
        }
    }
}

struct AirportPicker_Previews: PreviewProvider {
    private static let entity = AppState().persistentContainer.managedObjectModel.entitiesByName["Airport"]!
    private static let OAK = { () -> Airport in
        let a = Airport(entity: entity, insertInto: nil)
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        return a
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: entity, insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        AirportPicker(setAirport: { _ in }).environmentObject(AirportPickerState())
    }
}
