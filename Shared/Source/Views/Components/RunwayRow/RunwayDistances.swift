import SwiftUI

fileprivate func formatDistance(_ distance: Int16) -> String {
    return "\(integerFormatter.string(for: Int(distance))) ft."
}

struct RunwayDistances: View {
    var runway: Runway
    var operation: Operation
    
    var body: some View {
        switch operation {
            case .takeoff:
                if runway.takeoffRun == runway.takeoffDistance {
                    Text(formatDistance(runway.takeoffRun))
                } else {
                    HStack {
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(formatDistance(runway.takeoffRun))
                            Text("TORA").font(.system(size: 9)).padding(.bottom, 2)
                        }
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(formatDistance(runway.takeoffRun))
                            Text("TODA").font(.system(size: 9)).padding(.bottom, 2)
                        }
                    }
                }
            case .landing:
                Text(formatDistance(runway.landingDistance))
        }
    }
}

struct RunwayDistances_Previews: PreviewProvider {
    static let runway = AppState().persistentContainer.managedObjectModel.entitiesByName["Runway"]!
    static var rwy30 = { () -> Runway in
        let r = Runway(entity: runway, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()
    
    static var previews: some View {
        RunwayDistances(runway: rwy30, operation: .takeoff)
    }
}
