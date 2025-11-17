import SF50_Shared
import SwiftUI
import WidgetKit

struct RunwayGridItem: View {
  var runway: RunwaySnapshot
  var takeoffDistance: Value<Measurement<UnitLength>>?

  var body: some View {
    HStack(spacing: 2) {
      switch takeoffDistance {
        case .value(let measurement):
          if measurement > runway.takeoffDistanceOrLength {
            Image(systemName: "x.circle.fill")
              .foregroundColor(.red)
              .accessibilityLabel("Available takeoff distance insufficient")
          } else {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
              .accessibilityLabel("Available takeoff distance sufficient")
          }
        case .valueWithUncertainty(let measurement, _):
          if measurement > runway.takeoffDistanceOrLength {
            Image(systemName: "x.circle.fill")
              .foregroundColor(.red)
              .accessibilityLabel("Available takeoff distance insufficient")
          } else {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
              .accessibilityLabel("Available takeoff distance sufficient")
          }
        case .notAuthorized:
          Image(systemName: "x.circle.fill")
            .foregroundColor(.red)
            .accessibilityLabel("Configuration not authorized")
        case .invalid, .notAvailable:
          Image(systemName: "questionmark.circle.fill")
            .foregroundColor(.gray)
            .accessibilityLabel("Not available")
        case .offscaleHigh:
          Image(systemName: "x.circle.fill")
            .foregroundColor(.red)
            .accessibilityLabel("Offscale high")
        case .offscaleLow:
          Image(systemName: "x.circle.fill")
            .foregroundColor(.gray)
            .accessibilityLabel("Offscale low")
        case .none:
          Image(systemName: "questionmark.circle.fill")
            .foregroundColor(.gray)
            .accessibilityLabel("Unknown")
      }

      Text(runway.name)
        .bold()
        .fixedSize(horizontal: true, vertical: false)
    }
  }
}
