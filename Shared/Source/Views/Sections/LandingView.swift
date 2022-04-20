import SwiftUI
import Combine
import CoreData

struct LandingView: View {
    @ObservedObject var state: SectionState
        
    var body: some View {
        NavigationView {
            Form {
                PerformanceView(state: state.performance,
                                operation: .landing,
                                title: "Landing", moment: "Arrival",
                                maxWeight: maxLandingWeight,
                                downloadWeather: {
                    // force a reload of the weather unless we are reverting from custom
                    // to downloaded weather
                    let force = state.performance.weatherState.source != .entered
                    state.downloadWeather(airport: state.performance.airport,
                                          date: state.performance.date,
                                          force: force)
                    
                },
                                cancelDownload: { state.cancelWeatherDownload() })
                
                LandingResultsView(state: state.performance)
            }.navigationTitle("Landing")
        }.navigationViewStyle(navigationStyle)
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView(state: .init(operation: .landing))
    }
}
