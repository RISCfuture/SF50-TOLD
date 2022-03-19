import SwiftUI

struct AirportRow: View {
    var airport: Airport
    
    var body: some View {
        HStack {
            Text(airport.lid ?? "<UNK>").bold()
            Text(airport.name?.localizedCapitalized ?? "<unknown>")
            Spacer() // fill out tappable area
        }.contentShape(Rectangle())
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
        AirportRow(airport: SQL)
    }
}
