import CoreData
import SwiftUI

struct TimeAndPlaceView: View {
    private static let numberFormatter = NumberFormatter()

    @ObservedObject var state: PerformanceState
    @State private var showNowButton = false

    var moment: String
    var operation: Operation

    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    var onChangeAirport: (Airport) -> Void

    private let nowVisibilityTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var elevation: Float? { state.runway?.elevation ?? state.airport?.elevation }

    private var formattedNOTAMCount: String {
        Self.numberFormatter.string(from: NSNumber(value: state.notamCount))!
    }

    private var NOTAMTitle: String {
        state.notamCount == 0 ? "NOTAMs" : "NOTAMs (\(formattedNOTAMCount))"
    }

    private var runwayNOTAM: NOTAM {
        guard let runway = state.runway else { fatalError("Runway is nil") }
        if let notam = runway.notam { return notam }
        let notam = NOTAM(entity: NOTAM.entity(), insertInto: PersistentContainer.shared.viewContext)
        notam.runway = runway
        return notam
    }

    var body: some View {
        Section(header: Text(moment)) {
            HStack {
                DatePicker("Date", selection: $state.date, in: Date()...)
                    .accessibilityIdentifier("dateSelector")
                if showNowButton {
                    Button(action: { state.setDateToNow() }, label: { Text("Now") })
                        .accessibilityIdentifier("dateNowButton")
                }
            }

            NavigationLink(destination: AirportPicker(onSelect: onChangeAirport)) {
                Label {
                    if let airport = state.airport {
                        AirportRow(airport: airport, showFavoriteButton: false)
                    } else {
                        Text("Choose Airport").foregroundColor(.accentColor)
                    }
                } icon: {}
            }.accessibilityIdentifier("airportSelector")

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
                }.accessibilityIdentifier("runwaySelector")
                NavigationLink(destination: WeatherPicker(state: state.weatherState,
                                                          downloadWeather: downloadWeather,
                                                          cancelDownload: cancelDownload,
                                                          elevation: elevation)) {
                    WeatherRow(conditions: state.weatherState, elevation: state.elevation)
                }.accessibilityIdentifier("weatherSelector")
            }

            if state.runway != nil {
                NavigationLink(destination: NOTAMView(operation: state.operation, notam: runwayNOTAM)) {
                    Label {
                        Text(NOTAMTitle).foregroundColor(.primary)
                    } icon: {}
                }.accessibilityIdentifier("NOTAMsSelector")
            }
        }
        .onReceive(nowVisibilityTimer) { _ in setShowNowButton() }
        .onAppear { setShowNowButton() }
    }

    private func setShowNowButton() {
        showNowButton = abs(state.date.timeIntervalSinceNow) >= 120
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
    var state: PerformanceState {
        let state = PerformanceState(operation: .takeoff)
        state.date = Date(timeIntervalSinceNow: 3600)
        state.airport = SQL

        state.weatherState.temperature = .value(9)
        state.weatherState.altimeter = 29.97
        state.weatherState.source = .downloaded

        return state
    }

    return Form {
        TimeAndPlaceView(state: state,
                         moment: "Takeoff",
                         operation: .takeoff,
                         downloadWeather: {},
                         cancelDownload: {},
                         onChangeAirport: { _ in })
    }
}
