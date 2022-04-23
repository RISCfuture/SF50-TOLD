import CoreData

extension Runway {
    var notamedTakeoffDistance: Int16 {
        if let notam = notam {
            return takeoffDistance - Int16(notam.takeoffDistanceShortening.rounded())
        } else {
            return takeoffDistance
        }
    }
    
    var notamedTakeoffRun: Int16 {
        if let notam = notam {
            return takeoffRun - Int16(notam.takeoffDistanceShortening.rounded())
        } else {
            return takeoffRun
        }
    }
    
    var notamedLandingDistance: Int16 {
        if let notam = notam {
            return landingDistance - Int16(notam.landingDistanceShortening.rounded())
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
}
