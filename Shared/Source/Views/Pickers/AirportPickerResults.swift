import SwiftUI
import CoreData
import Defaults

struct AirportPickerResults: View {
    @FetchRequest var airports: FetchedResults<Airport>
    @Binding var filterText: String
    
    let onSelect: (Airport) -> Void
    
    private var sortedAiports: Array<Airport> {
        if filterText.count < 3 {
            return airports.sorted(by: { favoriteAndRecentSort(airport1: $0, airport2: $1) })
        } else {
            return airports.sorted(by: { decreasingSimilarity(airport1: $0, airport2: $1) })
        }
    }
    
    var body: some View {
        if (1...2).contains(filterText.count) {
            List {
                Text("Keep typing…")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else if airports.isEmpty {
            List {
                Text("No results.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else {
            List(airports) { (airport: Airport) in
                AirportRow(airport: airport, showFavoriteButton: true).onTapGesture {
                    onSelect(airport)
                }
            }
        }
    }
    
    private func favoriteAndRecentSort(airport1: Airport, airport2: Airport) -> Bool {
        guard let id1 = airport1.id else { return false }
        guard let id2 = airport2.id else { return false }
        guard let lid1 = airport1.lid else { return false }
        guard let lid2 = airport2.lid else { return false }
        
        if Defaults[.favoriteAirports].contains(id1) {
            if Defaults[.favoriteAirports].contains(id2) {
                return caseInsensitiveEqual(lid1, lid2)
            } else {
                return true
            }
        } else if Defaults[.favoriteAirports].contains(id2) {
            return false
        } else {
            return caseInsensitiveEqual(lid1, lid2)
        }
    }
    
    private func decreasingSimilarity(airport1: Airport, airport2: Airport) -> Bool {
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
            if caseInsensitiveEqual(string1, filterText) { return true } // airport1 exact match, has precedence
        }
        if let string2 = string2 {
            if caseInsensitiveEqual(string2, filterText) { return false } // airport2 exact match, has precedence
        }
        return nil
    }
    
    private func checkContainsMatch(_ string1: String?, _ string2: String?) -> Bool? {
        if let string1 = string1 {
            if let string2 = string2 {
                // both string1 and string2 present
                if let index1 = caseInsensitiveContains(string: string1, substring: filterText) {
                    if let index2 = caseInsensitiveContains(string: string2, substring: filterText) {
                        // found in both airports, return the one that's closer to the start of the string
                        if index1 < index2 { return true } // airport1 has precedence
                        else if index1 > index2 { return false } // airport2 has precedence
                        else { return nil } // equal precedence
                    } else {
                        // found only in airport1, it takes precedence
                        return true
                    }
                } else if caseInsensitiveContains(string: string2, substring: filterText) != nil {
                    // found only in airport2, it takes precedence
                    return false
                } else {
                    // not found in either airport, equal precedence
                    return nil
                }
            } else {
                // string1 only present
                if caseInsensitiveContains(string: string1, substring: filterText) != nil { return true }
                else { return nil }
            }
        } else if let string2 = string2 {
            // string2 only present
            if caseInsensitiveContains(string: string2, substring: filterText) != nil { return false }
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
