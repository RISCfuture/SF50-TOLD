import SwiftUI
import CoreData

fileprivate func formatDistance(_ distance: Int16) -> String {
    return "\(integerFormatter.string(for: Int(distance))) ft"
}

struct RunwayDistances: View {
    @ObservedObject var runway: Runway
    var operation: Operation
    
    var body: some View {
        switch operation {
            case .takeoff:
                if runway.takeoffRun == runway.takeoffDistance {
                    distanceText(runway.notamedTakeoffRun, notamed: runway.hasTakeoffDistanceNOTAM)
                } else {
                    HStack {
                        HStack(alignment: .bottom, spacing: 3) {
                            distanceText(runway.notamedTakeoffRun, notamed: runway.hasTakeoffDistanceNOTAM)
                            Text("TORA").font(.system(size: 9)).padding(.bottom, 2)
                        }
                        HStack(alignment: .bottom, spacing: 3) {
                            distanceText(runway.notamedTakeoffDistance, notamed: runway.hasTakeoffDistanceNOTAM)
                            Text("TODA").font(.system(size: 9)).padding(.bottom, 2)
                        }
                    }
                }
            case .landing:
                distanceText(runway.notamedLandingDistance, notamed: runway.hasLandingDistanceNOTAM)
        }
    }
    
    private func distanceText(_ distance: Int16, notamed: Bool) -> some View {
        if notamed {
            return Text(formatDistance(distance)).foregroundColor(.ui.warning)
        } else {
            return Text(formatDistance(distance))
        }
    }
}

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()
    
    return RunwayDistances(runway: rwy30, operation: .takeoff)
}
