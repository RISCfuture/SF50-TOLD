import WidgetKit
import SwiftUI

@main
struct SF50_RunwaysBundle: WidgetBundle {
    init() {
        configureLogLevel()
        reloadOnAirportChange()
    }
    
    var body: some Widget {
        SelectedAirportPerformanceWidget()
    }
}
