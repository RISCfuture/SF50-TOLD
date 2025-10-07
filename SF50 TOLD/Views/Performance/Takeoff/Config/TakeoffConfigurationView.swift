import SF50_Shared
import SwiftUI

struct TakeoffConfigurationView: View {
  var body: some View {
    Section("Configuration") {
      LabeledContent("Flaps") {
        Text("50%", comment: "flap setting")
      }
      LabeledContent("Engine IPS") {
        Text("As Required", comment: "engine IPS as required")
      }
    }
  }
}

#Preview {
  List { TakeoffConfigurationView() }
}
