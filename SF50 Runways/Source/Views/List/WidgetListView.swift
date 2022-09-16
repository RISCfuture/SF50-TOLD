import SwiftUI
import WidgetKit

struct WidgetListView: View {
    var entry: RunwayWidgetEntry
    
    private var runways: Array<Runway>? {
        guard let airport = entry.airport,
              let runways = airport.runways else { return nil }
        return runways.sortedArray(using: [.init(key: "takeoffRun", ascending: false)]) as? Array<Runway>
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
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
