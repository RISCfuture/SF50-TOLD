import SwiftUI
import CoreData

struct RunwayPicker: View {
    @ObservedObject var airport: Airport
    @ObservedObject var weather: WeatherState
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @Binding var flaps: FlapSetting?
    
    var operation: Operation
    var onSelect: (Runway) -> Void
    
    var runways: Array<Runway> {
        return (airport.runways!.allObjects as! Array<Runway>)
            .sorted { $0.name!.localizedCompare($1.name!) == .orderedAscending }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List(runways, id: \.name) { runway in
                RunwayRow(runway: runway,
                          operation: operation,
                          wind: weather.wind,
                          crosswindLimit: crosswindLimitForFlapSetting(flaps),
                          tailwindLimit: tailwindLimit).onTapGesture {
                    onSelect(runway)
                    self.mode.wrappedValue.dismiss()
                }
            }
        }.padding(.all, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        .navigationTitle("Runway")
    }
}

struct RunwayPicker_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        RunwayPicker(airport: SQL,
                     weather: WeatherState(),
                     flaps: .constant(.flaps100),
                     operation: .landing,
                     onSelect: { _ in })
    }
}
