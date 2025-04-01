import CoreData
import SwiftUI

struct ObstacleView: View {
    @ObservedObject var notam: NOTAM

    private let formatter = numberFormatter(precision: 0, minimum: 0)

    var body: some View {
        Section(header: Text("Obstacle")) {
            HStack {
                Text("Obstacle Height")
                Spacer()
                DecimalField("Height", value: $notam.obstacleHeight, formatter: formatter, suffix: "ft")
                    .accessibilityIdentifier("obstacleHeightField")
            }

            HStack {
                Text("Obstacle Distance")
                Spacer()
                DecimalField("Distance", value: $notam.obstacleDistance, formatter: formatter, suffix: "ft")
                    .accessibilityIdentifier("obstacleDistanceField")
            }
        }
    }
}

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let notam = NOTAM(entity: model.entitiesByName["NOTAM"]!, insertInto: nil)

    return List {
        ObstacleView(notam: notam)
    }
}
