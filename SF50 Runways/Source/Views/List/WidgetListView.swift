import SwiftUI
import WidgetKit

struct WidgetListView: View {
    var entry: RunwayWidgetEntry
    
    private var runways: [Runway]? {
        guard let airport = entry.airport,
              let runwaySet = airport.runways as? Set<Runway> else { return nil }
        
        let sortedRunways = runwaySet.sorted(by: Runway.sortedList)
        return Array(sortedRunways.prefix(4))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let runways = runways {
                ForEach(runways, id: \.name) { runway in
                    RunwayListItem(runway: runway,
                                   takeoffDistance: entry.takeoffDistances?[runway.name!],
                                   wind: entry.weather?.wind)
                }
            } else {
                ForEach(1...4, id: \.self) { _ in
                    RunwayPlaceholderListItem()
                }
            }
        }
    }
}

struct WidgetListView_Previews: PreviewProvider {
    private static let wind = Wind(direction: 260, speed: 10)
    private static let weather = Weather(wind: wind, temperature: .ISA, altimeter: standardSLP, source: .downloaded)
    
    static var previews: some View {
        WidgetListView(entry: .init(date: Date(),
                                    airport: nil,
                                    weather: weather,
                                    takeoffDistances: [:]))
        .containerBackground(for: .widget) { Color("WidgetBackground") }
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
