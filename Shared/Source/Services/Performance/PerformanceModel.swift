import Foundation


protocol PerformanceModel {
    var runway: Runway? { get set }
    var weather: Weather { get set }
    var weight: Double { get set }
    var flaps: FlapSetting? { get set }
    
    var takeoffRoll: Interpolation? { get }
    var takeoffDistance: Interpolation? { get }
    var takeoffPermitted: Bool? { get }
    var landingRoll: Interpolation? { get }
    var landingDistance: Interpolation? { get }
    var takeoffClimbGradient: Interpolation? { get }
    var takeoffClimbRate: Interpolation? { get }
    var vref: Interpolation? { get }
    var meetsGoAroundClimbGradient: Bool? { get }
    
    init(runway: Runway?, weather: Weather, weight: Double, flaps: FlapSetting?)
}


extension PerformanceModel {
    var isInitialized: Bool {
        runway != nil
    }
    
    var windComponent: Double {
        guard let runwayHeading = runway?.heading else { return weather.wind.speed }
        
        return Double(weather.wind.speed) * cos(deg2rad(weather.wind.direction - Double(runwayHeading)))
    }
    
    var headwind: Double {
        abs(max(windComponent, 0.0))
    }
    
    var tailwind: Double {
        abs(min(windComponent, 0.0))
    }
    
    var gradient: Double {
        runway?.slope?.doubleValue ?? 0
    }
    
    var uphillGradient: Double {
        abs(max(gradient, 0.0))
    }
    
    var downhillGradient: Double {
        abs(min(gradient, 0.0))
    }
    
    func offscale(low: Bool, high: Bool) -> Offscale {
        if high { return .high }
        else if low { return .low }
        else { return .none }
    }
}

func deg2rad(_ degrees: Double) -> Double {
    return degrees * .pi/180
}

func interpolation(weights: [Double], values: [Double]) -> ((Double) -> Double) {
    // Ensure the weights and values arrays have the same length
    guard weights.count == values.count, weights.count > 1 else {
        fatalError("Weights and values must have the same number of elements and at least two elements.")
    }
    guard weights == weights.sorted() else {
        fatalError("Weights must be in increasing order")
    }
    
    return { weight in
        // Handle weight below the minimum weight
        if weight <= weights.first! { return values.first! }
        // Handle weight above the maximum weight
        if weight >= weights.last! { return values.last! }
        
        // Find the interval that contains the weight
        for i in 0..<weights.count - 1 {
            if (weight >= weights[i] && weight <= weights[i + 1]) || (weight >= weights[i + 1] && weight <= weights[i]) {
                let lowerWeight = weights[i]
                let upperWeight = weights[i + 1]
                let lowerValue = values[i]
                let upperValue = values[i + 1]
                
                // Perform linear interpolation
                let interpolationFactor = (weight - lowerWeight) / (upperWeight - lowerWeight)
                return lowerValue + interpolationFactor * (upperValue - lowerValue)
            }
        }
        
        fatalError("Couldn't interpolate \(weight) in \(weights)")
    }
}
