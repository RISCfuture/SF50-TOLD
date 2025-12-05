import Defaults
import SF50_Shared
import SwiftUI

struct TakeoffLoadoutView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  @Environment(\.aircraftType)
  private var aircraftType

  @Default(.emptyWeight)
  private var emptyWeight

  @Default(.payload)
  private var payload

  @Default(.takeoffFuel)
  private var takeoffFuel

  @Default(.weightUnit)
  private var weightUnit

  @Default(.fuelVolumeUnit)
  private var fuelVolumeUnit

  private var limitations: Limitations.Type {
    aircraftType.limitations
  }

  var body: some View {
    Section("Loading") {
      LabeledContent("Payload") {
        MeasurementField("Payload", value: $payload, unit: weightUnit, format: .weight)
          .accessibilityIdentifier("payloadField")
      }
      LabeledContent("Takeoff Fuel") {
        MeasurementField(
          "Takeoff Fuel",
          value: $takeoffFuel,
          unit: fuelVolumeUnit,
          format: .fuel
        )
        .accessibilityIdentifier("fuelField")
      }
      LabeledContent("Takeoff Weight") {
        Text(performance.weight.converted(to: weightUnit), format: .weight)
          .bold()
          .multilineTextAlignment(.trailing)
          .foregroundStyle(performance.weight > limitations.maxTakeoffWeight ? .red : .primary)
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return Form {
      TakeoffLoadoutView()
        .environment(TakeoffPerformanceViewModel(container: preview.container))
    }
  }
}
