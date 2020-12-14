import SwiftUI
import Combine
import CoreData

struct LandingView: View {
    @EnvironmentObject var state: SectionState
    @ObservedObject var performance: PerformanceState
        
    private var landingDistance: Double? {
        guard let run = performance.runway?.landingDistance else { return nil }
        return Double(run)
    }
    
    var body: some View {
        NavigationView {
            Form {
                PerformanceView(operation: .landing,
                                title: "Landing", moment: "Arrival",
                                maxWeight: maxLandingWeight,
                                maxFuel: maxFuel)
            
                Section(header: Text("Performance")) {
                    HStack {
                        Text("VREF")
                        Spacer()
                        InterpolationView(interpolation: performance.vref, suffix: "kts.")
                    }
                    
                    HStack {
                        Text("Ground Roll")
                        Spacer()
                        InterpolationView(interpolation: performance.landingRoll,
                                          suffix: "ft.",
                                          maximum: landingDistance)
                    }

                    HStack {
                        Text("Total Distance")
                        Spacer()
                        InterpolationView(interpolation: performance.landingDistance,
                                          suffix: "ft.",
                                          maximum: landingDistance)
                    }
                    
                    if let meets = performance.meetsGoAroundClimbGradient {
                        HStack {
                            Text("Meets Go-Around Climb Gradient")
                            Spacer()
                            if meets {
                                Text("Yes").bold()
                            } else {
                                Text("No").bold().foregroundColor(.red)
                            }
                        }
                    }
                }
            }.navigationTitle("Landing")
        }.navigationViewStyle(navigationStyle)
    }
}

struct LandingView_Previews: PreviewProvider {
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
        LandingView(performance: state.landing.performance).environmentObject(state.landing)
    }
}
