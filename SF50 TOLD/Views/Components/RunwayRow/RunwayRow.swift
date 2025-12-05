import SF50_Shared
import SwiftUI

struct RunwayRow: View {
  var runway: Runway
  var notam: NOTAM?
  var conditions: Conditions
  var flapSetting: FlapSetting?

  @Environment(\.operation)
  private var operation

  @Environment(\.aircraftType)
  private var aircraftType

  private var limitations: Limitations.Type {
    aircraftType.limitations
  }

  private var crosswindLimit: Measurement<UnitSpeed>? {
    switch flapSetting {
      case .flapsUp, .flapsUpIce, nil: nil
      case .flaps50, .flaps50Ice: limitations.maxCrosswind_flaps50
      case .flaps100: limitations.maxCrosswind_flaps100
    }
  }

  var body: some View {
    HStack {
      Text(runway.name).bold()
      RunwayDistances(runway: runway)
      if runway.isTurf {
        Text("(turf)")
      }

      Spacer()

      WindComponents(
        runway: runway,
        conditions: conditions,
        crosswindLimit: crosswindLimit,
        tailwindLimit: limitations.maxTailwind
      )
    }.contentShape(Rectangle())
  }
}

#Preview {
  PreviewView(insert: .KSQL, .K1C9) { preview in
    let paved = try preview.load(airportID: "SQL", runway: "30")!
    let turf = try preview.load(airportID: "1C9", runway: "5")!

    return List {
      Section("Paved") {
        RunwayRow(runway: paved, conditions: preview.lightWinds, flapSetting: .flaps100)
      }
      Section("Turf") {
        RunwayRow(runway: turf, conditions: preview.lightWinds, flapSetting: .flaps100)
      }
    }
  }
}
