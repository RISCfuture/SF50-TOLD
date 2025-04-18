import CoreData
import SwiftUI

struct RunwayPicker: View {
    @ObservedObject var airport: Airport
    @ObservedObject var weather: WeatherState
    @Environment(\.presentationMode)
    var mode

    @Binding var flaps: FlapSetting?

    var operation: Operation
    var onSelect: (Runway) -> Void

    var runways: [Runway] {
        return (airport.runways!.allObjects as! [Runway])
            .sorted { $0.name!.localizedCompare($1.name!) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading) {
            List(runways, id: \.name) { runway in
                RunwayRow(runway: runway,
                          operation: operation,
                          wind: weather.wind,
                          crosswindLimit: crosswindLimitForFlapSetting(flaps),
                          tailwindLimit: tailwindLimit)
                .onTapGesture {
                    onSelect(runway)
                    mode.wrappedValue.dismiss()
                }
                .accessibility(addTraits: .isButton)
                .accessibilityIdentifier("runwayRow-\(runway.name ?? "unk")")
            }
        }
        .navigationTitle("Runway")
    }
}

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()
    let rwy12 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "12"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()
    let SQL = { () -> Airport in
        let a = Airport(entity: model.entitiesByName["Airport"]!, insertInto: nil)
        a.id = "SQL"
        a.lid = "SQL"
        a.name = "San Carlos"
        a.runways = [rwy30, rwy12]
        return a
    }()

    return RunwayPicker(airport: SQL,
                        weather: WeatherState(),
                        flaps: .constant(.flaps100),
                        operation: .landing,
                        onSelect: { _ in })
}
