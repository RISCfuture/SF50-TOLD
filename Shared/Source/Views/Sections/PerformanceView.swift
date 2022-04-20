import SwiftUI
import Combine
import CoreData

struct PerformanceView: View {
    @ObservedObject var state: PerformanceState
    
    
    var operation: Operation
    var title: String
    var moment: String
    var maxWeight: Double
    
    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    
    var body: some View {
        LoadoutView(state: state, title: title, maxWeight: maxWeight)
        
        ConfigurationView(state: state, operation: operation)
        
        TimeAndPlaceView(state: state,
                         moment: moment,
                         operation: operation,
                         downloadWeather: downloadWeather,
                         cancelDownload: cancelDownload,
                         onChangeAirport: { airport in
            state.airportID = airport.id!
        })
    }
}

struct PerformanceView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            PerformanceView(state: .init(operation: .takeoff),
                            operation: .takeoff,
                            title: "Takeoff",
                            moment: "Departure",
                            maxWeight: maxTakeoffWeight,
                            downloadWeather: {},
                            cancelDownload: {})
        }
    }
}
