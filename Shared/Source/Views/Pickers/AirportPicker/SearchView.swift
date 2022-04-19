import SwiftUI
import Defaults

struct SearchView: View {
    @State var filter = ""
    var onSelect: (Airport) -> Void
    
    private var predicate: NSPredicate {
        .init(format: "lid ==[c] %@ OR icao ==[c] %@ OR name CONTAINS[cd] %@ OR city CONTAINS[cd] %@",
              filter, filter, filter, filter)
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
        if let string1 = string1 {
            if caseInsensitiveEqual(string1, filter) { return true } // airport1 exact match, has precedence
        }
        if let string2 = string2 {
            if caseInsensitiveEqual(string2, filter) { return false } // airport2 exact match, has precedence
        }
        return nil
    }
    
    private func checkContainsMatch(_ string1: String?, _ string2: String?) -> Bool? {
        if let string1 = string1 {
            if let string2 = string2 {
                // both string1 and string2 present
                if let index1 = caseInsensitiveContains(string: string1, substring: filter) {
                    if let index2 = caseInsensitiveContains(string: string2, substring: filter) {
                        // found in both airports, return the one that's closer to the start of the string
                        if index1 < index2 { return true } // airport1 has precedence
                        else if index1 > index2 { return false } // airport2 has precedence
                        else { return nil } // equal precedence
                    } else {
                        // found only in airport1, it takes precedence
                        return true
                    }
                } else if caseInsensitiveContains(string: string2, substring: filter) != nil {
                    // found only in airport2, it takes precedence
                    return false
                } else {
                    // not found in either airport, equal precedence
                    return nil
                }
            } else {
                // string1 only present
                if caseInsensitiveContains(string: string1, substring: filter) != nil { return true }
                else { return nil }
            }
        } else if let string2 = string2 {
            // string2 only present
            if caseInsensitiveContains(string: string2, substring: filter) != nil { return false }
            else { return nil }
        } else {
            // neither string present
            return nil
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

struct SearchView_Previews: PreviewProvider {
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
        SearchView() { _ in }
    }
}
