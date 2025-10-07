import SwiftUI

struct LocationPermissionPromptView: View {
  var body: some View {
    VStack(spacing: 32) {
      Text("Location Access Needed")
        .font(.title)

      Text("To show nearby airports, SF50 TOLD needs access to your location.")
        .foregroundStyle(.secondary)
    }.padding()
  }
}

#Preview {
  LocationPermissionPromptView()
}
