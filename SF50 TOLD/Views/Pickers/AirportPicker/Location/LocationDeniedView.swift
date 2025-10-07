import SwiftUI

struct LocationDeniedView: View {
  var body: some View {
    VStack(spacing: 32) {
      Text("Location Access Denied")
        .font(.title)

      Text("To show nearby airports, please enable location access in Settings.")
        .foregroundStyle(.secondary)

      if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        Button("Open Settings") {
          UIApplication.shared.open(settingsUrl)
        }
      }
    }.padding()
  }
}

#Preview {
  LocationDeniedView()
}
