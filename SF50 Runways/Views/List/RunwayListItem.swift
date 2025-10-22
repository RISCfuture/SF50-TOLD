import Defaults
import SF50_Shared
import SwiftUI
import WidgetKit

struct RunwayListItem: View {
  var runway: Runway
  var takeoffDistance: Value<Measurement<UnitLength>>?
  var conditions: Conditions?

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  private let integerFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
  }()

  var body: some View {
    HStack {
      Text(runway.name).bold()
        .fixedSize(horizontal: true, vertical: false)

      if let conditions {
        WindComponents(runway: runway, conditions: conditions)
      }

      Spacer()

      switch takeoffDistance {
        case .value(let measurement), .valueWithUncertainty(let measurement, _):
          if measurement > runway.takeoffDistanceOrLength {
            Text(measurement.converted(to: runwayLengthUnit), format: .length)
              .foregroundColor(.red)
          } else {
            Text(measurement.converted(to: runwayLengthUnit), format: .length)
              .foregroundColor(.green)
          }
          Text("/")
          Text(
            runway.takeoffDistanceOrLength.converted(to: runwayLengthUnit),
            format: .length
          )
        case .offscaleHigh:
          Text("Exceeds Limits")
            .foregroundColor(.red)
            .bold()
        case .notAuthorized:
          Text("Config N/A")
            .foregroundColor(.red)
            .bold()
        case .invalid, .notAvailable, .offscaleLow:
          Text("N/A")
            .foregroundColor(.gray)
        case .none:
          Text("10,000′ / 10,000′")
            .redacted(reason: .placeholder)
      }
    }
  }
}
