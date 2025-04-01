import WidgetKit

struct RunwayWidgetEntry: TimelineEntry {
    let date: Date
    let airport: Airport?
    let weather: Weather?
    let takeoffDistances: [String: Interpolation]?

    static func empty() -> Self {
        return .init(date: Date(), airport: nil, weather: nil, takeoffDistances: nil)
    }
}
