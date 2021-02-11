import SwiftUI
import Defaults

struct ConfigurationView: View {
    @ObservedObject var state: PerformanceState
    @Default(.airConditioning) var airConditioning
    var operation: Operation
        
    var body: some View {
        Section(header: Text("Configuration")) {
            if operation == .takeoff {
                HStack {
                    Text("Air Conditioning")
                    Spacer()
                    Toggle("", isOn: $airConditioning)
                }
            }
            HStack {
                Text("Flaps")
                Spacer()
                switch operation {
                    case .takeoff: Text("50%")
                    case .landing: Text("100%")
                }
            }
        }
    }
}

struct LandingConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ConfigurationView(state: PerformanceState(operation: .landing),
                              operation: .takeoff)
        }
    }
}
