import WidgetKit
import SwiftUI

@main
struct SR22G2_RunwaysBundle: WidgetBundle {
    init() {
        configureLogLevel()
        reloadOnAirportChange()
    }
    
    var body: some Widget {
        SelectedAirportPerformanceWidget()
    }
}
