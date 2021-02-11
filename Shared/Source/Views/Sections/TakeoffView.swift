import SwiftUI
import Combine
import CoreData

struct TakeoffView: View {
    @EnvironmentObject var state: SectionState
    @ObservedObject var performance: PerformanceState
        
    private var takeoffRun: Double? {
        guard let run = performance.runway?.takeoffRun else { return nil }
        return Double(run)
    }
    
    private var takeoffDistance: Double? {
        guard let distance = performance.runway?.takeoffDistance else { return nil }
        return Double(distance)
    }
    
    var body: some View {
        NavigationView {
            Form {
                PerformanceView(operation: .takeoff,
                                title: "Takeoff", moment: "Departure",
                                maxWeight: maxTakeoffWeight,
                                maxFuel: maxFuel)
                Section(header: Text("Performance")) {
                    HStack {
                        Text("Ground Roll")
                        Spacer()
                        InterpolationView(interpolation: performance.takeoffRoll,
                                          suffix: "ft.",
                                          maximum: takeoffRun)
                    }

                    HStack {
                        Text("Total Distance")
                        Spacer()
                        InterpolationView(interpolation: performance.takeoffDistance,
                                          suffix: "ft.",
                                          maximum: takeoffDistance)
                    }
                    
                    HStack {
                        Text("Vx Climb Gradient")
                        Spacer()
                        InterpolationView(interpolation: performance.climbGradient,
                                          suffix: "ft/NM",
                                          minimum: 0)
                    }
                    
                    HStack {
                        Text("Vx Climb Rate")
                        Spacer()
                        InterpolationView(interpolation: performance.climbRate,
                                          suffix: "ft/min",
                                          minimum: 0)
                    }
                }
            }.navigationTitle("Takeoff")
        }.navigationViewStyle(navigationStyle)
    }
}

struct TakeoffView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    static let runway = model.entitiesByName["Runway"]!
    static var rwy12 = { () -> Runway in
        let r = Runway(entity: runway, insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 122
        r.elevation = 12
        return r
    }()
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: runway, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        r.elevation = 12
        return r
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: runway, insertInto: nil)
        a.id = "SQL"
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    static var state: AppState {
        let state = AppState()
        return state
    }
    
    static var previews: some View {
        TakeoffView(performance: state.takeoff.performance).environmentObject(state.takeoff)
    }
}
