import SwiftUI
import CoreData

struct TimeAndPlaceView: View {
    @EnvironmentObject var state: PerformanceState
    
    var moment: String
    var operation: Operation
    
    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    
    private var elevation: Float? { state.runway?.elevation ?? state.airport?.elevation }
    
    var body: some View {
        Section(header: Text(moment)) {
            HStack {
                DatePicker("Date", selection: $state.date)
            }
            
            NavigationLink(destination: AirportPicker()) {
                Label {
                    if let airport = state.airport {
                        AirportRow(airport: airport)
                    } else {
                        Text("Choose Airport").foregroundColor(.accentColor)
                    }
                } icon: {}
            }
            
            if state.airport != nil {
                NavigationLink(destination: RunwayPicker(operation: operation).environmentObject(state)) {
                    Label {
                        if let runway = state.runway {
                            RunwayRow(runway: runway, operation: operation, wind: nil)
                        } else {
                            Text("Choose Runway").foregroundColor(.accentColor)
                        }
                    } icon: {}
                }
                NavigationLink(destination: WeatherPicker(downloadWeather: downloadWeather, cancelDownload: cancelDownload, elevation: elevation)
                                .environmentObject(state.weatherState)) {
                    WeatherRow(elevation: state.elevation)
                        .environmentObject(state.weatherState)
                }
            }
        }
    }
}

struct TimeAndPlaceView_Previews: PreviewProvider {
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
    
    private static var state: PerformanceState {
        let state = PerformanceState()
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
                             operation: .takeoff,
                             downloadWeather: {},
                             cancelDownload: {})
                .environmentObject(state)
        }
    }
}
