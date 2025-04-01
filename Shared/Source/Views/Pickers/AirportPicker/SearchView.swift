import Defaults
import SwiftUI

struct SearchView: View {
    @State private var filter = ""
    var onSelect: (Airport) -> Void

    private var predicate: NSPredicate {
        .init(format: "lid ==[c] %@ OR icao ==[c] %@ OR ((name CONTAINS[cd] %@ OR city CONTAINS[cd] %@) AND longestRunway >= %d)",
              filter, filter, filter, filter, minRunwayLength)
    }

    private var fetchAirports: FetchRequest<Airport> {
        .init(entity: Airport.entity(), sortDescriptors: [
            .init(keyPath: \Airport.id, ascending: true)
        ],
              predicate: predicate)
    }

    var body: some View {
        VStack(alignment: .leading) {
            SearchField(placeholder: "Find Airport", text: $filter)
                .accessibilityIdentifier("searchAirportsField")
            SearchResults(airports: fetchAirports,
                          filterText: $filter,
                          sort: decreasingSimilarity,
                          onSelect: { airport in
                onSelect(airport)
            })
        }
    }

    private func decreasingSimilarity(_ airport1: Airport, _ airport2: Airport) -> Bool {
        if let match = checkExactMatch(airport1.lid, airport2.lid) { return match }
        if let match = checkExactMatch(airport1.icao, airport2.icao) { return match }
        if let match = checkContainsMatch(airport1.name, airport2.name) { return match }
        if let match = checkContainsMatch(airport1.city, airport2.city) { return match }

        // equal similarity, sort alphabetically increasing
        switch airport1.name!.localizedCompare(airport2.name!) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            default: return true // stable sort
        }
    }

    private func checkExactMatch(_ string1: String?, _ string2: String?) -> Bool? {
        if let string1, caseInsensitiveEqual(string1, filter) { return true } // airport1 exact match, has precedence
        if let string2, caseInsensitiveEqual(string2, filter) { return false } // airport2 exact match, has precedence
        return nil
    }

    private func checkContainsMatch(_ string1: String?, _ string2: String?) -> Bool? {
        let index1 = string1.flatMap { caseInsensitiveContains(string: $0, substring: filter) }
        let index2 = string2.flatMap { caseInsensitiveContains(string: $0, substring: filter) }

        switch (index1, index2) {
            case let (i1?, i2?): return i1 < i2 ? true : (i1 > i2 ? false : nil)
            case (_?, nil): return true
            case (nil, _?): return false
            default: return nil
        }
    }

    private func caseInsensitiveEqual(_ string1: String, _ string2: String) -> Bool {
        switch string1.compare(string2, options: [.caseInsensitive, .diacriticInsensitive]) {
            case .orderedSame: return true
            default: return false
        }
    }

    private func caseInsensitiveContains(string: String, substring: String) -> String.Index? {
        guard let range = string.range(of: substring, options: [.caseInsensitive, .diacriticInsensitive]) else { return nil }
        return range.lowerBound
    }
}

#Preview {
    SearchView { _ in }
}
