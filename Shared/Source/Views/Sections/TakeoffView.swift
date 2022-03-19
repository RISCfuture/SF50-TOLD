import SwiftUI
import Combine
import CoreData

struct TakeoffView: View {
    @ObservedObject var state: SectionState
    
    var body: some View {
        NavigationView {
            Form {
                PerformanceView(state: state.performance,
                                operation: .takeoff,
                                title: "Takeoff", moment: "Departure",
                                maxWeight: maxTakeoffWeight,
                                downloadWeather: {
                    // force a reload of the weather unless we are reverting from custom
                    // to downloaded weather
                    let force = state.performance.weatherState.source != .entered
                    state.downloadWeather(airport: state.performance.airport,
                                          date: state.performance.date,
                                          force: force)
                },
                                cancelDownload: { state.cancelWeatherDownload() })
                
                TakeoffResultsView(state: state.performance)
            }.navigationTitle("Takeoff")
        }.navigationViewStyle(navigationStyle)
    }
}

struct TakeoffView_Previews: PreviewProvider {
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
        let a = Airport(entity: Runway.entity(), insertInto: nil)
        a.id = "SQL"
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    static var state: SectionState {
        let state = SectionState(operation: .takeoff)
        state.performance.airport = SQL
        state.performance.runway = rwy30
        return state
    }
    
    static var previews: some View {
        TakeoffView(state: state)
    }
}
