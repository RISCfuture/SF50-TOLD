import Foundation
import Combine
import CoreData
import Dispatch
import OSLog
import Defaults

class AirportStorage: ObservableObject {
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "AirportStorage")
    private let queue = DispatchQueue(label: "SF50-Told.AirportService", qos: .background)
    
    private let context: NSManagedObjectContext
    
    required init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func airport(id: String) throws -> Airport? {
        let results = try context.fetch(byIDRequest(id: id))
        guard results.count == 1 else {
            logger.error("Couldn't find exactly one airport with ID '\(id)'")
            return nil
        }
        return results[0]
    }
    
    func findAirports(query: String) throws -> Array<Airport> {
        guard query.count >= 3 else { return [] }
        
        var airports = try context.fetch(filterRequest(string: query))
        airports.sort { decreasingSimilarity(query: query, airport1: $0, airport2: $1) }
        return airports
    }
    
    private func filterRequest(string: String) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.fetchLimit = 100
        request.includesPropertyValues = true
        request.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "lid ==[c] %@ OR icao ==[c] %@ OR name CONTAINS[cd] %@ OR city CONTAINS[cd] %@", string, string, string, string)
        request.predicate = predicate
        return request
    }
    
    private func byIDRequest(id: String) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.fetchLimit = 1
        request.includesPropertyValues = true
        request.includesSubentities = true
        request.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "id == %@", id)
        request.predicate = predicate
        return request
    }
    
    private func decreasingSimilarity(query: String, airport1: Airport, airport2: Airport) -> Bool {
        if let match = checkExactMatch(airport1.lid, airport2.lid, query: query) { return match }
        if let match = checkExactMatch(airport1.icao, airport2.icao, query: query) { return match }
        if let match = checkContainsMatch(airport1.name, airport2.name, query: query) { return match }
        if let match = checkContainsMatch(airport1.city, airport2.city, query: query) { return match }
        
        // equal similarity, sort alphabetically increasing
        switch airport1.name!.localizedCompare(airport2.name!) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            default: return true // stable sort
        }
    }
    
    private func checkExactMatch(_ string1: String?, _ string2: String?, query: String) -> Bool? {
        if let string1 = string1 {
            if caseInsensitiveEqual(query, string1) { return true } // airport1 exact match, has precedence
        }
        if let string2 = string2 {
            if caseInsensitiveEqual(query, string2) { return false } // airport2 exact match, has precedence
        }
        return nil
    }
    
    private func checkContainsMatch(_ string1: String?, _ string2: String?, query: String) -> Bool? {
        if let string1 = string1 {
            if let string2 = string2 {
                // both string1 and string2 present
                if let index1 = caseInsensitiveContains(string: string1, substring: query) {
                    if let index2 = caseInsensitiveContains(string: string2, substring: query) {
                        // found in both airports, return the one that's closer to the start of the string
                        if index1 < index2 { return true } // airport1 has precedence
                        else if index1 > index2 { return false } // airport2 has precedence
                        else { return nil } // equal precedence
                    } else {
                        // found only in airport1, it takes precedence
                        return true
                    }
                } else if caseInsensitiveContains(string: string2, substring: query) != nil {
                    // found only in airport2, it takes precedence
                    return false
                } else {
                    // not found in either airport, equal precedence
                    return nil
                }
            } else {
                // string1 only present
                if caseInsensitiveContains(string: string1, substring: query) != nil { return true }
                else { return nil }
            }
        } else if let string2 = string2 {
                // string2 only present
                if caseInsensitiveContains(string: string2, substring: query) != nil { return false }
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
