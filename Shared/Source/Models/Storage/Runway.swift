import Foundation
import SwiftData

@Model final class Runway {
    var airport: Airport
    
    var name: String
    
    var turf = false
    var elevation: Double
    var heading: UInt8
    var slope: Float
    
    var landingDistance: UInt
    var takeoffDistance: UInt
    var takeoffRun: UInt
    
    @Relationship(deleteRule: .cascade) var notam: NOTAM?
    
    static var sortedList: (Runway, Runway) -> Bool { { a, b in
        if a.takeoffRun == b.takeoffRun {
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        return a.takeoffRun > b.takeoffRun
    } }
    
    var notamedTakeoffDistance: UInt {
        if let notam = notam {
            return takeoffDistance - notam.takeoffDistanceShortening
        } else {
            return takeoffDistance
        }
    }
    
    var notamedTakeoffRun: UInt {
        if let notam = notam {
            return takeoffRun - notam.takeoffDistanceShortening
        } else {
            return takeoffRun
        }
    }
    
    var notamedLandingDistance: UInt {
        if let notam = notam {
            return landingDistance - notam.landingDistanceShortening
        } else {
            return landingDistance
        }
    }
    
    var hasTakeoffDistanceNOTAM: Bool {
        notam?.takeoffDistanceShortening ?? 0 > 0
    }
    
    var hasLandingDistanceNOTAM: Bool {
        notam?.landingDistanceShortening ?? 0 > 0
    }
    
    var contamination: Contamination? {
        guard let contamination = notam?.contamination else { return nil }
        return contamination
    }
    
    init(airport: Airport, name: String, turf: Bool = false, elevation: Double, heading: UInt8, slope: Float, landingDistance: UInt, takeoffDistance: UInt, takeoffRun: UInt) {
        self.airport = airport
        self.name = name
        self.turf = turf
        self.elevation = elevation
        self.heading = heading
        self.slope = slope
        self.landingDistance = landingDistance
        self.takeoffDistance = takeoffDistance
        self.takeoffRun = takeoffRun
    }
}
