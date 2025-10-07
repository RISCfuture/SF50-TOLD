import SF50_Shared
import SwiftUI

struct LandingConfigurationView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  private var approvedFlapSetting: Bool {
    performance.flapSetting != .flapsUp && performance.flapSetting != .flapsUpIce
  }

  var body: some View {
    @Bindable var performance = performance

    Section("Configuration") {
      Picker("Flaps", selection: $performance.flapSetting) {
        Text("Flaps 100%").tag(FlapSetting.flaps100)
        Text("Flaps 50%").tag(FlapSetting.flaps50)
        Text("Flaps Up").tag(FlapSetting.flapsUp)
          .foregroundStyle(.red)
        Text("Flaps 50% ICE").tag(FlapSetting.flaps50Ice)
        Text("Flaps Up ICE").tag(FlapSetting.flapsUpIce)
          .foregroundStyle(.red)
      }.pickerStyle(.menu)
        .tint(approvedFlapSetting ? .accentColor : .red)
    }
  }
}

#Preview {
  PreviewView { preview in
    Form {
      LandingConfigurationView()
        .environment(LandingPerformanceViewModel(container: preview.container))
    }
  }
}
