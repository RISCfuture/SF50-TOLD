import SwiftUI
import CoreData
import Defaults

struct AirportPicker: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject var state: SectionState
    
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
        VStack(alignment: .leading) {
            SearchField(placeholder: "Find Airport", text: $state.airportFilterText)
            
            if state.matchingAirports.isEmpty && state.airportFilterText.isEmpty {
                List {
                    Text("No results.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            } else {
                List(state.matchingAirports) { (airport: Airport) in
                    AirportRow(airport: airport).onTapGesture {
                        state.airportID = airport.id!
                        self.mode.wrappedValue.dismiss()
                    }
                }
            }
            
            Spacer()
        }.navigationTitle("Airport")
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
        AirportPicker().environmentObject(SectionState(operation: .takeoff, persistentContainer: AppState().persistentContainer))
    }
}
