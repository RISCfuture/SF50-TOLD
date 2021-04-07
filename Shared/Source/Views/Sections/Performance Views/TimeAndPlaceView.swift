import SwiftUI
import CoreData
import Defaults

struct TimeAndPlaceView: View {
    @EnvironmentObject var state: PerformanceState
    @Environment(\.managedObjectContext) var viewContext: NSManagedObjectContext

    var moment: String

    var downloadWeather: () -> Void

    private var elevation: Float? { state.runway?.elevation ?? state.airport?.elevation }

    private var picker: some View {
        AirportPicker { self.setAirport($0) }
            .environmentObject(AirportPickerState())
    }

    var body: some View {
        ErrorView(error: state.error) {
            Section(header: Text(moment)) {
                HStack {
                    DatePicker("Date", selection: $state.date)
                }

                NavigationLink(destination: picker) {
                    Label {
                        if let airport = state.airport {
                            AirportRow()
                                .environmentObject(AirportState(airport: airport))
                        } else {
                            Text("Choose Airport").foregroundColor(.accentColor)
                        }
                    } icon: {}.contentShape(Rectangle())
                }
                NavigationLink(destination: WeatherPicker(downloadWeather: downloadWeather, elevation: elevation)
                                .environmentObject(state.weatherState)) {
                    WeatherRow(elevation: state.elevation)
                        .environmentObject(state.weatherState)
                }
            }
        }
    }

    private func setAirport(_ airport: Airport) {
        state.airportID = airport.id
        airport.lastUsed = Date()
        do {
            if viewContext.hasChanges { try viewContext.save() }
        } catch (let error) {
            state.error = error
        }
    }
}

struct TimeAndPlaceView_Previews: PreviewProvider {
    static let model = AppState().persistentContainer.managedObjectModel
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
        a.id = "abc123"
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()

    private static var state: PerformanceState {
        let state = PerformanceState(operation: .takeoff)
        state.airport = SQL
        state.weatherState = WeatherState(wind: .calm,
                                          temperature: .value(9),
                                          altimeter: 29.97,
                                          source: .downloaded,
                                          observation: nil,
                                          forecast: nil,
                                          draft: false)
        return state
    }

    static var previews: some View {
        Form {
            TimeAndPlaceView(moment: "Takeoff",
                             downloadWeather: {})
                .environmentObject(state)
        }
    }
}
