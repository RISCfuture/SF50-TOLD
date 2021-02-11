import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var state: PerformanceState
    var operation: Operation
        
    var body: some View {
        Section(header: Text("Configuration")) {
            switch operation {
                case .takeoff:
                    HStack {
                        Text("Flaps")
                        Spacer()
                        Text("50%")
                    }
                case .landing:
                    HStack {
                        Picker("Flaps", selection: $state.flaps) {
                            Text("Flaps 100%").tag(FlapSetting.flaps100 as FlapSetting?)
                            Text("Flaps 50%").tag(FlapSetting.flaps50 as FlapSetting?)
                            Text("Flaps Up").tag(FlapSetting.flapsUp as FlapSetting?)
                                .foregroundColor(.red)
                            Text("Flaps 50% ICE").tag(FlapSetting.flaps50Ice as FlapSetting?)
                            Text("Flaps Up ICE").tag(FlapSetting.flapsUpIce as FlapSetting?)
                                .foregroundColor(.red)
                        }
                    }
            }
        }
    }
}

struct LandingConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ConfigurationView(operation: .landing).environmentObject(PerformanceState())
        }
    }
}
