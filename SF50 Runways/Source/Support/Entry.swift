import WidgetKit

struct RunwayWidgetEntry: TimelineEntry {
    let date: Date
    let airport: Airport?
    let weather: Weather?
    let takeoffDistances: Dictionary<String, Interpolation>?
}
