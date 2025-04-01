import SwiftUI
import WidgetKit

@main
struct SF50_Widgets: WidgetBundle {
    @WidgetBundleBuilder var body: some Widget {
        SelectedAirportPerformanceWidget()
        NearestAirportPerformanceWidget()
    }
}
