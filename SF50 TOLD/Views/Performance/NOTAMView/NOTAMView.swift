import SF50_Shared
import Sentry
import SwiftUI

struct NOTAMView: View {
  @Bindable var notam: NOTAM
  @State private var error: Error?
  @State private var errorSheetPresented = false

  @Environment(\.operation)
  private var operation

  @Environment(\.presentationMode)
  private var presentationMode

  @Environment(\.modelContext)
  private var modelContext

  var body: some View {
    Form {
      RunwayShorteningView(notam: notam)
      if operation == .takeoff { ObstacleView(notam: notam) }
      if operation == .landing {
        ContaminationView(contamination: $notam.contamination)
      }

      Button("Clear NOTAMs") {
        notam.clearFor(operation: operation)
        presentationMode.wrappedValue.dismiss()
      }.accessibilityIdentifier("clearNOTAMsButton")
    }.navigationTitle("NOTAMs")
      .onDisappear {
        do {
          try modelContext.save()
        } catch {
          SentrySDK.capture(error: error)
          self.error = error
          errorSheetPresented = true
        }
      }
      .alert(
        "Couldn’t Save NOTAM",
        isPresented: $errorSheetPresented,
        actions: {
          Button("OK") {
            errorSheetPresented = false
            error = nil
          }
        },
        message: {
          Text(error?.localizedDescription ?? "<no error>")
        }
      )
  }
}

#Preview("Takeoff") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "30")!
    let notam = try preview.addNOTAM(
      to: runway,
      shortenTakeoff: 500.0,
      obstacleHeight: 75,
      obstacleDistance: 0.25
    )

    return NOTAMView(notam: notam)
      .environment(\.operation, .takeoff)
  }
}

#Preview("Landing") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "30")!
    let notam = try preview.addNOTAM(
      to: runway,
      shortenLanding: 500.0,
      contamination:
        .waterOrSlush(depth: .init(value: 0.2, unit: .inches))
    )

    return NOTAMView(notam: notam)
      .environment(\.operation, .landing)
  }
}
