import CoreData
import Defaults
import SwiftUI

struct LoadoutView: View {
    @ObservedObject var state: PerformanceState
    var title: String
    var maxWeight: Double

    var payload = Binding(get: { Defaults[.payload] }, set: { Defaults[.payload] = $0 })
    var fuel: Binding<Double> {
        .init(get: { Defaults[state.fuelDefault] },
              set: { Defaults[state.fuelDefault] = $0 })
    }

    private let formatter = numberFormatter(precision: 0, minimum: 0)

    var body: some View {
        Section(header: Text("Loading")) {
            HStack {
                Text("Payload")
                Spacer()
                DecimalField("Payload", value: payload, formatter: formatter, suffix: "lbs.")
                    .accessibilityIdentifier("payloadField")
            }
            HStack {
                Text("\(title) Fuel")
                Spacer()
                DecimalField("\(title) Fuel",
                             value: fuel,
                             formatter: numberFormatter(precision: 0, minimum: 0),
                             suffix: "gal",
                             maximum: maxFuel)
                .accessibilityIdentifier("fuelField")
            }
            HStack(spacing: 0) {
                Text("\(title) Weight")
                Spacer()
                Text(NSNumber(value: state.weight), formatter: integerFormatter.forView)
                    .bold()
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(state.weight > maxWeight ? .red : .primary)
                Text(" lbs").bold()
            }
        }
    }
}

#Preview {
    Form {
        LoadoutView(state: PerformanceState(operation: .takeoff),
                    title: "Takeoff",
                    maxWeight: maxTakeoffWeight)
    }
}
