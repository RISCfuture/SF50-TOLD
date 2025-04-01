import CoreData
import SwiftUI
import WidgetKit

struct SelectedAirportWidgetEntryView : View {
    @Environment(\.widgetFamily)
    var family

    var entry: TOLDProvider.Entry

    @ViewBuilder var body: some View {
        if let airport = entry.airport {
            VStack(alignment: .leading, spacing: 10) {
                WidgetAirportView(name: airport.name!)
                switch family {
                    case .systemSmall:
                        WidgetGridView(entry: entry)
                    default:
                        WidgetListView(entry: entry)
                }
            }
            .containerBackground(for: .widget) { Color("WidgetBackground") }
        } else {
            WidgetNoAirportView()
        }
    }
}

struct SelectedAirportWidgetEntryView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!

    static var rwy28L = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "28L"
        r.takeoffRun = 6213
        r.takeoffDistance = 6213
        r.heading = 278
        return r
    }()
    static var rwy28R = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "28R"
        r.takeoffRun = 5458
        r.takeoffDistance = 5458
        r.heading = 278
        return r
    }()
    static var rwy33 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "33"
        r.takeoffRun = 3376
        r.takeoffDistance = 3376
        r.heading = 330
        return r
    }()
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 10520
        r.takeoffDistance = 10520
        r.heading = 296
        return r
    }()

    private static let OAK = { () -> Airport in
        let a = Airport(entity: model.entitiesByName["Airport"]!, insertInto: nil)
        a.id = "OAK"
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        a.runways = [rwy28L, rwy28R, rwy33, rwy30]
        return a
    }()

    private static let takeoffDistances: [String: Interpolation] = [
        "28L": .value(3400, offscale: .none),
        "28R": .value(3400, offscale: .none),
        "33": .value(3400, offscale: .none),
        "30": .value(3400, offscale: .high)
    ]

    private static let wind = Wind(direction: 260, speed: 10)
    private static let weather = Weather(wind: wind, temperature: .ISA, altimeter: standardSLP, source: .downloaded)

    static var previews: some View {
        Group {
            SelectedAirportWidgetEntryView(entry: .init(date: Date(),
                                                        airport: OAK,
                                                        weather: weather,
                                                        takeoffDistances: takeoffDistances))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            SelectedAirportWidgetEntryView(entry: .init(date: Date(),
                                                        airport: OAK,
                                                        weather: weather,
                                                        takeoffDistances: takeoffDistances))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
