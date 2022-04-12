import SwiftUI
import Defaults

struct AirportRow: View {
    @ObservedObject var airport: Airport
    
    var showFavoriteButton: Bool
    @State var isFavorite: Bool = false
    
    private var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }
    
    init(airport: Airport, showFavoriteButton: Bool) {
        self.airport = airport
        self.showFavoriteButton = showFavoriteButton
        isFavorite = Defaults[.favoriteAirports].contains(airport.id!)
    }
    
    var body: some View {
        HStack {
            Text(airport.lid ?? "<UNK>").bold()
            Text(airport.name?.localizedCapitalized ?? "<unknown>")
            
            Spacer()
            
            if showFavoriteButton {
                Label("", systemImage: favoriteIcon).onTapGesture {
                    if Defaults[.favoriteAirports].contains(airport.id!) {
                        Defaults[.favoriteAirports].remove(airport.id!)
                    } else {
                        Defaults[.favoriteAirports].insert(airport.id!)
                    }
                }
            }
        }.contentShape(Rectangle())
            .onReceive(Defaults.publisher(.favoriteAirports), perform: { faves in
                self.isFavorite = faves.newValue.contains(airport.id!)
            })
    }
}

struct AirportRow_Previews: PreviewProvider {
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        AirportRow(airport: SQL, showFavoriteButton: true)
    }
}
