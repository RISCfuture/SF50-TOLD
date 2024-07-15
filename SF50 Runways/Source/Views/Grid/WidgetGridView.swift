import SwiftUI
import CoreData
import WidgetKit

struct WidgetGridView: View {
    var entry: RunwayWidgetEntry
    
    private let columns = [GridItem(.flexible()),
                           GridItem(.flexible())]
    
    private var runways: [Runway]? {
        guard let airport = entry.airport,
              let runwaySet = airport.runways as? Set<Runway> else { return nil }
        
        let sortedRunways = runwaySet.sorted { ($0.takeoffRun) > ($1.takeoffRun) }
        return Array(sortedRunways.prefix(8))
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            if let runways = runways {
                ForEach(runways, id: \.name) { runway in
                    RunwayGridItem(runway: runway, takeoffDistance: entry.takeoffDistances?[runway.name!])
                }
            } else {
                ForEach(1...4, id: \.self) { _ in
                    RunwayPlaceholderGridItem()
                }
            }
        }
    }
}

struct WidgetGridView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    static var rwy28L = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "28L"
        r.takeoffRun = 6213
        r.takeoffDistance = 6213
        return r
    }()
    static var rwy28R = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "28R"
        r.takeoffRun = 5458
        r.takeoffDistance = 5458
        return r
    }()
    static var rwy33 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "33"
        r.takeoffRun = 3376
        r.takeoffDistance = 3376
        return r
    }()
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 10520
        r.takeoffDistance = 10520
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
    
    static var previews: some View {
        WidgetGridView(entry: .init(date: Date(),
                                    airport: OAK,
                                    weather: nil,
                                    takeoffDistances: [:]))
        .containerBackground(for: .widget) { Color("WidgetBackground") }
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
