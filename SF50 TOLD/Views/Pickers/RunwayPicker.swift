import SF50_Shared
import SwiftData
import SwiftUI

struct RunwayPicker: View {
  var airport: Airport
  var conditions: Conditions
  var crosswindLimit: Measurement<UnitSpeed>?
  var tailwindLimit: Measurement<UnitSpeed>?
  var onSelect: (Runway) -> Void

  @Environment(\.presentationMode)
  private var mode

  @Environment(\.operation)
  private var operation

  private var runways: [Runway] {
    airport.runways.sorted(using: Runway.NameComparator())
  }

  var body: some View {
    VStack(alignment: .leading) {
      List(runways, id: \.name) { runway in
        RunwayRow(
          runway: runway,
          conditions: conditions
        )
        .onTapGesture {
          onSelect(runway)
          mode.wrappedValue.dismiss()
        }
        .accessibility(addTraits: .isButton)
        .accessibilityIdentifier("runwayRow-\(runway.name)")
      }
    }
    .navigationTitle("Runway")
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let OAK = try preview.load(locationID: "OAK")!

    return RunwayPicker(
      airport: OAK,
      conditions: preview.lightWinds
    ) { _ in }
    .environment(\.operation, .takeoff)
  }
}
