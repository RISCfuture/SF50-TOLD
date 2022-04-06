//
//  PerformanceModel.swift
//  SF50 TOLD
//
//  Created by Tim Morgan on 4/5/22.
//

import Foundation


protocol PerformanceModel {
    var runway: Runway? { get set }
    var weather: Weather { get set }
    var weight: Double { get set }
    var flaps: FlapSetting? { get set }
    
    var takeoffRoll: Interpolation? { get }
    var takeoffDistance: Interpolation? { get }
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
    
    func deg2rad(_ degrees: Double) -> Double {
        return degrees * .pi/180
    }
    
    func offscale(low: Bool, high: Bool) -> Offscale {
        if high { return .high }
        else if low { return .low }
        else { return .none }
    }
}
