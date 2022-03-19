import SwiftUI
import CoreData

struct TimeAndPlaceView: View {
    @ObservedObject var state: PerformanceState
    
    var moment: String
    var operation: Operation
    
    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    var onChangeAirport: (Airport) -> Void
    
    private static let numberFormatter = NumberFormatter()
    
    private var elevation: Float? { state.runway?.elevation ?? state.airport?.elevation }
    
    private var formattedNOTAMCount: String {
        Self.numberFormatter.string(from: NSNumber(value: state.notamCount))!
    }
    
    private var NOTAMTitle: String {
        state.notamCount == 0 ? "NOTAMs" : "NOTAMs (\(formattedNOTAMCount))"
    }
    
    var body: some View {
        Section(header: Text(moment)) {
            HStack {
                DatePicker("Date", selection: $state.date)
            }
            
            NavigationLink(destination: AirportPicker(onSelect: onChangeAirport)) {
                Label {
                    if let airport = state.airport {
                        AirportRow(airport: airport)
                    } else {
                        Text("Choose Airport").foregroundColor(.accentColor)
                    }
                } icon: {}
            }
            
            if let airport = state.airport {
                NavigationLink(destination: RunwayPicker(airport: airport,
                                                         weather: state.weatherState,
                                                         flaps: $state.flaps,
                                                         operation: operation,
                                                         onSelect: { runway in
                    state.runway = runway
                })) {
                    Label {
                        if let runway = state.runway {
                            RunwayRow(runway: runway, operation: operation, wind: .calm)
                        } else {
                            Text("Choose Runway").foregroundColor(.accentColor)
                        }
                    } icon: {}
                }
                NavigationLink(destination: WeatherPicker(state: state.weatherState,
                                                          downloadWeather: downloadWeather,
                                                          cancelDownload: cancelDownload,
                                                          elevation: elevation)) {
                    WeatherRow(conditions: state.weatherState, elevation: state.elevation)
                }
            }
            
            if state.runway != nil {
                NavigationLink(destination: NOTAMView(operation: state.operation, notam: runwayNOTAM)) {
                    Label {
                        Text(NOTAMTitle).foregroundColor(.primary)
                    } icon: {}
                }
            }
        }
    }
    
    private var runwayNOTAM: NOTAM {
        guard let runway = state.runway else { fatalError("Runway is nil") }
        if let notam = runway.notam { return notam }
        let notam = NOTAM(entity: NOTAM.entity(), insertInto: PersistentContainer.shared.viewContext)
        notam.runway = runway
        return notam
    }
}

struct TimeAndPlaceView_Previews: PreviewProvider {
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
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        a.addToRunways(rwy12)
        a.addToRunways(rwy30)
        return a
    }()
    
    private static var state: PerformanceState {
        let state = PerformanceState(operation: .takeoff)
        state.airport = SQL
        
        state.weatherState.temperature = .value(9)
        state.weatherState.altimeter = 29.97
        state.weatherState.source = .downloaded
        
        return state
    }
    
    static var previews: some View {
        Form {
            TimeAndPlaceView(state: state,
                             moment: "Takeoff",
                             operation: .takeoff,
                             downloadWeather: {},
                             cancelDownload: {},
                             onChangeAirport: { _ in })
        }
    }
}
