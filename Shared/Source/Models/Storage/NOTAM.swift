import Foundation
import SwiftData


enum Contamination: Codable {
    case waterOrSlush(depth: Float)
    case slushOrWetSnow(depth: Float)
    case drySnow
    case compactSnow
}

@Model class NOTAM {
    var contamination: Contamination?
    var landingDistanceShortening: UInt = 0
    var obstacleDistance: UInt = 0
    var obstacleHeight: UInt = 0
    var takeoffDistanceShortening: UInt = 0
    
    @Relationship(inverse: \Runway.notam) var runway: Runway
    
    var isContaminated: Bool { contamination != nil }
    
    init(runway: Runway) {
        self.runway = runway
    }
    
    func notamCountFor(_ operation: Operation) -> Int {
        var count = 0
        
        switch operation {
            case .takeoff: if takeoffDistanceShortening > 0 { count += 1 }
            case .landing:
                if landingDistanceShortening > 0 { count += 1 }
                if isContaminated { count += 1 }
        }
        if obstacleHeight > 0 { count += 1 }
        
        return count
    }
    
    func clearFor(_ operation: Operation) {
        switch operation {
            case .takeoff: takeoffDistanceShortening = 0
            case .landing:
                landingDistanceShortening = 0
                contamination = nil
        }
        
        obstacleHeight = 0
        obstacleDistance = 0
    }
}
