import Defaults
import SF50_Shared
import SwiftUI

struct RunwayDistances: View {
  var runway: Runway

  @Environment(\.operation)
  private var operation

  var body: some View {
    switch operation {
      case .takeoff:
        if runway.notamedTakeoffRun == runway.notamedTakeoffDistance {
          RunwayDistance(
            distance: runway.notamedTakeoffRun,
            NOTAMed: runway.hasTakeoffDistanceNOTAM
          )
        } else {
          HStack {
            HStack(alignment: .bottom, spacing: 3) {
              RunwayDistance(
                distance: runway.notamedTakeoffRun,
                NOTAMed: runway.hasTakeoffDistanceNOTAM
              )
              Text("TORA").font(.system(size: 9)).padding(.bottom, 2)
            }
            HStack(alignment: .bottom, spacing: 3) {
              RunwayDistance(
                distance: runway.notamedTakeoffDistance,
                NOTAMed: runway.hasTakeoffDistanceNOTAM
              )
              Text("TODA").font(.system(size: 9)).padding(.bottom, 2)
            }
          }
        }
      case .landing:
        RunwayDistance(
          distance: runway.notamedLandingDistance,
          NOTAMed: runway.hasLandingDistanceNOTAM
        )
    }
  }
}

private struct RunwayDistance: View {
  var distance: Measurement<UnitLength>
  var NOTAMed: Bool

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  var body: some View {
    if NOTAMed {
      Text(distance.converted(to: runwayLengthUnit), format: .length)
        .foregroundStyle(Color.ui.warning)
    } else {
      Text(distance.converted(to: runwayLengthUnit), format: .length)
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    preview.setUpToDate()
    let runway30 = try preview.load(airportID: "OAK", runway: "30")!
    let runway28R = try preview.load(airportID: "OAK", runway: "28R")!
    let runway33 = try preview.load(airportID: "OAK", runway: "33")!
    try preview.addNOTAM(to: runway33, shortenLanding: 500)

    return List {
      HStack {
        Text("TORA/TODA").foregroundStyle(.secondary)
        Spacer()
        RunwayDistances(runway: runway30)
          .environment(\.operation, .takeoff)
      }

      HStack {
        Text("Length Only").foregroundStyle(.secondary)
        Spacer()
        RunwayDistances(runway: runway28R)
          .environment(\.operation, .takeoff)
      }
      HStack {
        Text("NOTAMed").foregroundStyle(.secondary)
        Spacer()
        RunwayDistances(runway: runway33)
          .environment(\.operation, .landing)
      }
    }
  }
}
