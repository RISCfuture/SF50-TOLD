import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct SearchView: View {
  var onSelect: (Airport) -> Void
  @State private var searchText = ""

  var body: some View {
    NavigationStack {
      SearchResults(searchText: searchText, onSelect: onSelect)
        .searchable(text: $searchText)
    }
  }
}

private struct SearchResults: View {
  var searchText: String
  var onSelect: (Airport) -> Void

  @Query private var airports: [Airport]

  private var sortedAirports: [Airport] {
    return airports.sorted { airport1, airport2 in
      let score1 = relevanceScore(for: airport1, searchText: searchText)
      let score2 = relevanceScore(for: airport2, searchText: searchText)
      if score1 != score2 { return score1 > score2 }

      // If same relevance score, sort by name similarity
      let similarity1 = nameSimilarity(airport1.name, to: searchText)
      let similarity2 = nameSimilarity(airport2.name, to: searchText)
      if similarity1 != similarity2 { return similarity1 > similarity2 }

      // Final tie-breaker: alphabetical by name
      return airport1.name.localizedStandardCompare(airport2.name) == .orderedAscending
    }
  }

  private var predicate: Predicate<Airport> {
    let uppercaseText = searchText.uppercased()

    return #Predicate { airport in
      searchText.count > 2
        && (airport.locationID == uppercaseText
          || airport.name.localizedStandardContains(searchText)
          || (airport.ICAO_ID?.localizedStandardContains(searchText) ?? false))
    }
  }

  var body: some View {
    if sortedAirports.isEmpty {
      List {
        Text("No results.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
      }
    } else {
      List(sortedAirports) { (airport: Airport) in
        AirportRow(airport: airport, showFavoriteButton: true)
          .onTapGesture {
            onSelect(airport)
          }
          .accessibility(addTraits: .isButton)
          .accessibilityIdentifier("airportRow-\(airport.displayID)")
      }
    }
  }

  init(searchText: String, onSelect: @escaping (Airport) -> Void) {
    self.searchText = searchText
    self.onSelect = onSelect
    _airports = Query(FetchDescriptor(predicate: predicate))
  }

  private func relevanceScore(for airport: Airport, searchText: String) -> Int {
    if airport.displayID == searchText.uppercased() { return 3 }
    if let icaoID = airport.ICAO_ID, icaoID == searchText.uppercased() { return 2 }
    if airport.name.localizedStandardContains(searchText) {
      return 1
    }
    return 0
  }

  private func nameSimilarity(_ name: String, to searchText: String) -> Double {
    if name.localizedStandardEquals(searchText) { return 1.0 }
    if name.localizedStandardHasPrefix(searchText) { return 0.8 }
    if name.localizedStandardContains(searchText) { return 0.6 }

    // Calculate simple similarity based on common characters
    let commonChars = Set(name.localizedLowercase).intersection(Set(searchText.localizedLowercase))
      .count
    let totalChars = max(name.count, searchText.count)
    return Double(commonChars) / Double(totalChars) * 0.4
  }
}

#Preview {
  PreviewView(insert: .KOAK, .K1C9, .KSQL) { preview in
    preview.setUpToDate()

    return SearchView { _ in }
  }
}
