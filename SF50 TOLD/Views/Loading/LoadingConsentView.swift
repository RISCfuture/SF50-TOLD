import SF50_Shared
import SwiftData
import SwiftUI

struct LoadingConsentView: View {
  @Environment(AirportLoaderViewModel.self)
  private var loader

  @Environment(\.modelContext)
  private var context

  var titleString: String {
    if loader.canSkip {
      return String(localized: "Your airport database is out of date. Would you like to update it?")
    }
    return String(localized: "You need to download airport data before you can use this app.")
  }

  var body: some View {
    VStack(alignment: .center, spacing: 20) {
      Image("Logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 200, alignment: .center)
        .accessibilityHidden(true)

      Text(titleString)
        .multilineTextAlignment(.center)

      Text(
        "This process can take around 30 minutes to complete. It must be done the first time the app launches, and approximately once a month as new navigation data is released. I recommend you keep \(localizedModel()) plugged into a power source."
      )
      .font(.footnote)
      .padding(.horizontal, 20)
      .multilineTextAlignment(.leading)

      if loader.networkIsExpensive {
        Text("Warning: You are on a slow or metered network.")
          .foregroundStyle(.red)
          .font(.footnote)
          .padding(.horizontal, 20)
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 20) {
        Button("Download Airport Data") {
          Task { loader.load() }
        }.accessibilityIdentifier("downloadDataButton")
        if loader.canSkip {
          Button("Defer Until Later") {
            Task { loader.loadLater() }
          }.accessibilityIdentifier("deferDataButton")
        }
      }
    }.padding()
  }
}

#Preview("No data") {
  PreviewView { preview in
    return LoadingConsentView()
      .environment(AirportLoaderViewModel(container: preview.container))
  }
}

#Preview("Out of date") {
  PreviewView(insert: .KSQL) { preview in
    preview.setOutOfDate()

    return LoadingConsentView()
      .environment(AirportLoaderViewModel(container: preview.container))
  }
}
