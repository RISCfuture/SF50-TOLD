import SwiftUI
import Defaults

struct AirportRow: View {
    var showIcon = false
    var action: (() -> Void)? = nil
    
    @EnvironmentObject var state: AirportState
    
    private var airport: Airport { state.airport }
    
    private var AirportNameAndID: some View {
        HStack {
            Text(airport.lid ?? "<UNK>").bold()
            Text(airport.name?.localizedCapitalized ?? "<unknown>")
            Spacer()
        }
    }
    
    var body: some View {
        ErrorView(error: state.error) {
            HStack {
                if let action = action {
                    AirportNameAndID
                        .contentShape(Rectangle())
                        .onTapGesture(perform: action)
                } else {
                    AirportNameAndID
                }
                Spacer()
                
                if showIcon {
                    Button { self.state.toggleFavorite() } label: {
                        if airport.favorite {
                            Label("", systemImage: "pin.fill")
                        } else {
                            Label("", systemImage: "pin")
                        }
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
}

struct AirportRow_Previews: PreviewProvider {
    private static let entity = AppState().persistentContainer.managedObjectModel.entitiesByName["Airport"]!
    private static let SQL = { () -> Airport in
        let a = Airport(entity: entity, insertInto: nil)
        a.id = "abc123"
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        AirportRow(showIcon: true) { print(123) }
            .environmentObject(AirportState(airport: SQL))
    }
}
