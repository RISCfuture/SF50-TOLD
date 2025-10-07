import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct AirportRow: View {
  let airport: Airport

  var showFavoriteButton: Bool

  @Default(.favoriteAirports)
  private var favoriteAirports

  private var isFavorite: Bool {
    favoriteAirports.contains(airport.recordID)
  }

  private var favoriteIcon: String {
    isFavorite ? "heart.fill" : "heart"
  }

  var body: some View {
    HStack {
      Text(airport.displayID).bold()
      Text(airport.name.localizedCapitalized)

      Spacer()

      if showFavoriteButton {
        Label("", systemImage: favoriteIcon).onTapGesture {
          if favoriteAirports.contains(airport.recordID) {
            favoriteAirports.remove(airport.recordID)
          } else {
            favoriteAirports.insert(airport.recordID)
          }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toggle favorite")
        .accessibilityIdentifier("airportFaveButton")
      }
    }.contentShape(Rectangle())
  }
}

#Preview("Not Favorite") {
  let SQL = AirportBuilder.KSQL.unsaved()
  Defaults[.favoriteAirports] = []

  return List {
    AirportRow(airport: SQL, showFavoriteButton: true)
  }
}

#Preview("Favorite") {
  let SQL = AirportBuilder.KSQL.unsaved()
  Defaults[.favoriteAirports] = [SQL.recordID]

  return List {
    AirportRow(airport: SQL, showFavoriteButton: true)
  }
}
