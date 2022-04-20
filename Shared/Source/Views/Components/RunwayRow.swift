import SwiftUI
import Combine
import CoreData

struct RunwayRow: View {
    @ObservedObject var runway: Runway
    
    var operation: Operation
    var wind: Wind
    var crosswindLimit: UInt? = nil
    var tailwindLimit: UInt? = nil
    
    private var notamWillChange: ObservableObjectPublisher {
        runway.notam?.objectWillChange ?? ObservableObjectPublisher()
    }
    
    var body: some View {
        HStack {
            Text(runway.name!).bold()
            RunwayDistances(runway: runway, operation: operation)
            if runway.turf {
                Text("(turf)")
            }
            
            Spacer()
            
            WindComponents(runway: runway,
                           wind: wind,
                           crosswindLimit: crosswindLimit,
                           tailwindLimit: tailwindLimit)
        }.contentShape(Rectangle())
            .onReceive(notamWillChange) {
                runway.objectWillChange.send()
            }
    }
}

struct RunwayRow_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        r.turf = true
        return r
    }()
    
    static var previews: some View {
        List {
            RunwayRow(runway: rwy30, operation: .takeoff, wind: Wind(direction: 280, speed: 15))
        }
    }
}
