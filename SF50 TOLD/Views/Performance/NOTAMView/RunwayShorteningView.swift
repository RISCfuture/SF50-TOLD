import Defaults
import SF50_Shared
import SwiftUI

struct RunwayShorteningView: View {
  @Bindable var notam: NOTAM

  @Environment(\.operation)
  private var operation

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  private var shortenPrompt: String {
    switch operation {
      case .takeoff: return String(localized: "Shorten takeoff distance by:")
      case .landing: return String(localized: "Shorten landing distance by:")
    }
  }

  private var shortenBinding: Binding<Measurement<UnitLength>> {
    switch operation {
      case .takeoff: return $notam.takeoffDistanceShortening
      case .landing: return $notam.landingDistanceShortening
    }
  }

  var body: some View {
    Section("Runway Shortening") {
      HStack {
        Text(shortenPrompt)
        Spacer()
        MeasurementField(
          "Distance",
          value: shortenBinding,
          unit: runwayLengthUnit,
          format: .length
        )
        .accessibilityIdentifier("distanceField")
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    let notam = try preview.addNOTAM(to: runway, shortenTakeoff: 400)

    return List {
      RunwayShorteningView(notam: notam)
    }.environment(\.operation, .takeoff)
  }
}
