import Foundation
import CoreData
import Combine

extension NOTAM {
    func notamCountFor(_ operation: Operation) -> Int {
        var count = 0
        
        switch operation {
            case .takeoff: if takeoffDistanceShortening > 0 { count += 1 }
            case .landing: if landingDistanceShortening > 0 { count += 1 }
        }
        if obstacleHeight > 0 { count += 1 }
        
        return count
    }
    
    func clearFor(_ operation: Operation) {
        switch operation {
            case .takeoff: takeoffDistanceShortening = 0
            case .landing: landingDistanceShortening = 0
        }
        
        obstacleHeight = 0
        obstacleDistance = 0
    }
}
