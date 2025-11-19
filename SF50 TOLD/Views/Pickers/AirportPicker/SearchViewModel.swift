import SF50_Shared
import Sentry
import SwiftData

@Observable
@MainActor
final class SearchViewModel: WithIdentifiableError {
  // Inputs
  var searchText: String = "" {
    didSet { debouncedSearch() }
  }

  // Outputs
  private(set) var airports: [Airport] = []
  private(set) var isLoading = false
  var error: Error?

  private let container: ModelContainer
  private var searchTask: Task<Void, Never>?

  var sortedAirports: [Airport] {
    let sorted = airports.sorted { airport1, airport2 in
      let score1 = relevanceScore(for: airport1, searchText: searchText)
      let score2 = relevanceScore(for: airport2, searchText: searchText)
      if score1 != score2 { return score1 > score2 }

      // If same relevance score, sort by name similarity (primary) + city similarity (secondary)
      let nameSim1 = nameSimilarity(airport1.name, to: searchText)
      let nameSim2 = nameSimilarity(airport2.name, to: searchText)
      let citySim1 = citySimilarity(airport1.city, to: searchText)
      let citySim2 = citySimilarity(airport2.city, to: searchText)
      let similarity1 = max(nameSim1, citySim1)
      let similarity2 = max(nameSim2, citySim2)
      if similarity1 != similarity2 { return similarity1 > similarity2 }

      // Final tie-breaker: alphabetical by name
      return airport1.name.localizedStandardCompare(airport2.name) == .orderedAscending
    }

    // Limit to top 10 results after sorting
    return Array(sorted.prefix(10))
  }

  init(container: ModelContainer) {
    self.container = container
  }

  private func debouncedSearch() {
    searchTask?.cancel()
    searchTask = Task {
      // Wait 250ms before executing the search
      try? await Task.sleep(nanoseconds: 250_000_000)
      if !Task.isCancelled { performSearch() }
    }
  }

  private func performSearch() {
    guard searchText.count > 2 else {
      airports = []
      return
    }

    isLoading = true
    let searchTextCopy = searchText

    Task.detached { [container] in
      let context = ModelContext(container)
      let uppercaseText = searchTextCopy.uppercased()

      let predicate = #Predicate<Airport> { airport in
        airport.locationID == uppercaseText
          || airport.name.localizedStandardContains(searchTextCopy)
          || airport.ICAO_ID == uppercaseText
          || airport.city?.localizedStandardContains(searchTextCopy) == true
      }

      let descriptor = FetchDescriptor(predicate: predicate)

      do {
        let results = try context.fetch(descriptor)

        await MainActor.run {
          // Only update if search text hasn't changed
          if searchTextCopy == self.searchText {
            self.airports = results
            self.isLoading = false
            self.error = nil
          }
        }
      } catch {
        await MainActor.run {
          SentrySDK.capture(error: error)
          self.airports = []
          self.isLoading = false
          self.error = error
        }
      }
    }
  }

  private func relevanceScore(for airport: Airport, searchText: String) -> Int {
    if airport.locationID == searchText.uppercased() { return 3 }
    if let ICAO_ID = airport.ICAO_ID, ICAO_ID == searchText.uppercased() { return 3 }
    if airport.name.localizedStandardContains(searchText) { return 2 }
    if let city = airport.city, city.localizedStandardContains(searchText) { return 1 }
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

  private func citySimilarity(_ city: String?, to searchText: String) -> Double {
    guard let city else { return 0.0 }
    if city.localizedStandardEquals(searchText) { return 0.5 }
    if city.localizedStandardHasPrefix(searchText) { return 0.4 }
    if city.localizedStandardContains(searchText) { return 0.3 }
    return 0.0
  }
}
