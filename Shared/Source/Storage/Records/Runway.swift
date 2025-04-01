import CoreData

extension Runway {
    static var sortedList: (Runway, Runway) -> Bool {
        { a, b in
            if a.takeoffRun == b.takeoffRun {
                if let aName = a.name, let bName = b.name {
                    return aName.localizedCaseInsensitiveCompare(bName) == .orderedAscending
                }
                return true
            }
            return a.takeoffRun > b.takeoffRun
        }
    }

    var notamedTakeoffDistance: Int16 {
        takeoffDistance - Int16(notam?.takeoffDistanceShortening.rounded() ?? 0)
    }

    var notamedTakeoffRun: Int16 {
        takeoffRun - Int16(notam?.takeoffDistanceShortening.rounded() ?? 0)
    }

    var notamedLandingDistance: Int16 {
        landingDistance - Int16(notam?.landingDistanceShortening.rounded() ?? 0)
    }

    var hasTakeoffDistanceNOTAM: Bool {
        notam?.takeoffDistanceShortening ?? 0 > 0
    }

    var hasLandingDistanceNOTAM: Bool {
        notam?.landingDistanceShortening ?? 0 > 0
    }

    var contamination: Contamination? { notam?.contamination }
}
