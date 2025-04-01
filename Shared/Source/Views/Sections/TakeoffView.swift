import Combine
import CoreData
import SwiftUI

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

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let rwy12 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 122
        r.elevation = 12
        return r
    }()
    let rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        r.elevation = 12
        return r
    }()
    let SQL = { () -> Airport in
        let a = Airport(entity: model.entitiesByName["Airport"]!, insertInto: nil)
        a.id = "SQL"
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    var state: SectionState {
        let state = SectionState(operation: .takeoff)
        state.performance.airport = SQL
        state.performance.runway = rwy30
        return state
    }

    return TakeoffView(state: state)
}
