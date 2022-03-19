import SwiftUI
import Combine
import CoreData

struct PerformanceView: View {
    @ObservedObject var state: PerformanceState
    
    
    var operation: Operation
    var title: String
    var moment: String
    var maxWeight: Double
    
    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    
    var body: some View {
        LoadoutView(state: state, title: title, maxWeight: maxWeight)
        
        ConfigurationView(state: state, operation: operation)
        
        TimeAndPlaceView(state: state,
                         moment: moment,
                         operation: operation,
                         downloadWeather: downloadWeather,
                         cancelDownload: cancelDownload,
                         onChangeAirport: { airport in
            state.airportID = airport.id!
        })
    }
}

struct PerformanceView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    static var rwy12 = { () -> Runway in
        let r = Runway(entity: Runway.entity(), insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 122
        r.elevation = 12
        return r
    }()
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: Runway.entity(), insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        r.elevation = 12
        return r
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    
    static var state: PerformanceState {
        let state = PerformanceState(operation: .takeoff)
        state.airport = SQL
        state.runway = rwy30
        return state
    }
    
    static var previews: some View {
        Form {
            PerformanceView(state: state,
                            operation: .takeoff,
                            title: "Takeoff",
                            moment: "Departure",
                            maxWeight: maxTakeoffWeight,
                            downloadWeather: {},
                            cancelDownload: {})
        }
    }
}
