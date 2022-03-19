import SwiftUI
import CoreData

struct RunwayPicker: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject var state: PerformanceState
    
    var operation: Operation
    
    var runways: Array<Runway> {
        guard let airport = state.airport else { return [] }
        return (airport.runways!.allObjects as! Array<Runway>)
            .sorted { $0.name!.localizedCompare($1.name!) == .orderedAscending }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List(runways, id: \.name) { runway in
                RunwayRow(runway: runway,
                          operation: operation,
                          wind: state.weather.wind,
                          crosswindLimit: crosswindLimitForFlapSetting(state.flaps),
                          tailwindLimit: tailwindLimit).onTapGesture {
                    state.runway = runway
                    self.mode.wrappedValue.dismiss()
                }
            }
        }.padding(.all, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        .navigationTitle("Runway")
    }
}

struct RunwayPicker_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: Runway.entity(), insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2600
        r.heading = 302
        return r
    }()
    static var rwy12 = { () -> Runway in
        let r = Runway(entity: Runway.entity(), insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2600
        r.heading = 122
        return r
    }()
    
    static var state: PerformanceState {
        let state = PerformanceState()
        state.airport = Airport(entity: Airport.entity(), insertInto: nil)
        state.airport!.addToRunways(rwy12)
        state.airport!.addToRunways(rwy30)
        return state
    }
    
    static var previews: some View {
        RunwayPicker(operation: .takeoff)
            .environmentObject(state)
    }
}
