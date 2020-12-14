import SwiftUI

struct RunwayRow: View {
    var runway: Runway
    var operation: Operation
    var wind: Wind?
    var crosswindLimit: UInt? = nil
    var tailwindLimit: UInt? = nil
    
    var body: some View {
        HStack {
            Text(runway.name!).bold()
            RunwayDistances(runway: runway, operation: operation)
            if wind != nil {
                Spacer()
                WindComponents(runway: runway,
                               wind: wind,
                               crosswindLimit: crosswindLimit,
                               tailwindLimit: tailwindLimit)
            }
        }.contentShape(Rectangle())
    }
}

struct RunwayRow_Previews: PreviewProvider {
    static let runway = AppState().persistentContainer.managedObjectModel.entitiesByName["Runway"]!
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: runway, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        return r
    }()
    
    static var previews: some View {
        RunwayRow(runway: rwy30, operation: .takeoff, wind: Wind(direction: 280, speed: 15))
    }
}
