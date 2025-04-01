import CoreData
import SwiftUI

struct RunwayShorteningView: View {
    var operation: Operation
    @ObservedObject var notam: NOTAM

    private let formatter = numberFormatter(precision: 0, minimum: 0)

    private var shortenPrompt: String {
        switch operation {
            case .takeoff: return "Shorten takeoff distance by:"
            case .landing: return "Shorten landing distance by:"
        }
    }

    private var shortenBinding: Binding<Double> {
        switch operation {
            case .takeoff: return $notam.takeoffDistanceShortening
            case .landing: return $notam.landingDistanceShortening
        }
    }

    var body: some View {
        Section(header: Text("Runway Shortening")) {
            HStack {
                Text(shortenPrompt)
                Spacer()
                DecimalField("Distance", value: shortenBinding, formatter: formatter, suffix: "ft")
                    .accessibilityIdentifier("distanceField")
            }
        }
    }
}

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let notam = NOTAM(entity: model.entitiesByName["NOTAM"]!, insertInto: nil)

    return List {
        RunwayShorteningView(operation: .takeoff, notam: notam)
    }
}
