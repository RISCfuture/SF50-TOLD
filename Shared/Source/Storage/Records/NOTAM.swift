import Foundation
import CoreData
import Combine
import OSLog

fileprivate let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "NOTAM")

enum Contamination {
    case waterOrSlush(depth: Float)
    case slushOrWetSnow(depth: Float)
    case drySnow
    case compactSnow
}

extension NOTAM {
    var isContaminated: Bool { contamination != nil }
    
    var contamination: Contamination? {
        switch contaminationType {
            case "waterOrSlush":
                guard let depth = contaminationDepth?.floatValue, depth != 0 else { return nil }
                return .waterOrSlush(depth: depth)
            case "slushOrWetSnow":
                guard let depth = contaminationDepth?.floatValue, depth != 0 else { return nil }
                return .slushOrWetSnow(depth: depth)
            case "drySnow": return .drySnow
            case "compactSnow": return .compactSnow
            case .none: return nil
            default:
                logger.info("Ignoring unknown contamination type \(self.contaminationType!, privacy: .public)")
                return nil
        }
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
                clearContamination()
        }
        
        obstacleHeight = 0
        obstacleDistance = 0
    }
    
    func clearContamination() {
        contaminationType = nil
        contaminationDepth = 0
    }
}
