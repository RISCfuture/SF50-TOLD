import SwiftUI
import Combine
import CoreData

struct PerformanceView: View {
    @EnvironmentObject var state: SectionState
    
    var operation: Operation
    var title: String
    var moment: String
    var maxWeight: Double
    
    var body: some View {
        LoadoutView(title: title, maxWeight: maxWeight)
            .environmentObject(state.performance)
        ConfigurationView(operation: operation).environmentObject(state.performance)
        TimeAndPlaceView(moment: moment, operation: operation, downloadWeather: {
            // force a reload of the weather unless we are reverting from custom
            // to downloaded weather
            let force = state.performance.weather.source != .entered
            state.downloadWeather(airport: state.performance.airport,
                                  date: state.performance.date,
                                  force: force)
        }, cancelDownload: { state.cancelWeatherDownload() })
            .environmentObject(state.performance)
    }
}

struct PerformanceView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    static var rwy12 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 122
        r.elevation = 12
        return r
    }()
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        r.elevation = 12
        return r
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: model.entitiesByName["Airport"]!, insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    
    static var state: AppState { AppState() }
    
    static var previews: some View {
        Form {
            PerformanceView(operation: .takeoff,
                            title: "Takeoff",
                            moment: "Departure",
                            maxWeight: maxTakeoffWeight)
                .environmentObject(state.takeoff)
        }
    }
}
