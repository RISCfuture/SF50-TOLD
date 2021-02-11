import SwiftUI
import CoreData
#if canImport(CoreLocationUI)
import CoreLocationUI
#endif
import MapKit

fileprivate let earthRadius = 21638.0 // NM

fileprivate func degreeLonLen(lat: Double) -> Double {
    cos(deg2rad(lat))*(earthRadius/360)
}

struct NearestView: View {
    @ObservedObject var nearestAirport: NearestAirportPublisher
    var onSelect: (Airport) -> Void
    
    private var fetchAirports: FetchRequest<Airport> {
        return .init(entity: Airport.entity(),
                     sortDescriptors: [.init(keyPath: \Airport.id, ascending: true)],
                     predicate: nearestAirport.predicate)
    }

    var body: some View {
        if nearestAirport.loading {
            List {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Finding airports…")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        } else if let error = nearestAirport.errorText {
            List {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        } else if nearestAirport.location != nil {
            ListResults(airports: fetchAirports, sort: nearestAirport.airportDistance, onSelect: onSelect)
        } else {
            LocationButton { nearestAirport.request() }
                .clipShape(Capsule())
                .symbolVariant(.fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .foregroundColor(.white)
        }
    }
}

struct NearestView_Previews: PreviewProvider {
    private static let OAK = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        return a
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        NearestView(nearestAirport: NearestAirportPublisher()) { _ in }
    }
}
