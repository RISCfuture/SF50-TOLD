import Foundation

struct Wind: Equatable {
    var direction: Double
    var speed: Double
    
    static let calm = Self(direction: 0, speed: 0)
}

enum Source {
    case ISA
    case downloaded
    case entered
}

enum Temperature {
    case ISA
    case value(_ number: Double)
}

struct Weather: CustomDebugStringConvertible {
    var observation: String?
    var forecast: String?
    
    var wind: Wind
    var temperature: Temperature
    var altimeter: Double
    
    var source: Source
    
    var debugDescription: String {
        "<Weather \(wind.direction)@\(wind.speed), \(temperature) °C, \(altimeter)>"
    }
    
    // inHg
    func absolutePressure(elevation: Double) -> Double {
        enPressure(altimeter: altimeter, altitude: elevation)
    }
    
    // ft
    func pressureAltitude(elevation: Double) -> Double {
        return 145366.45*(1-pow(absolutePressure(elevation: elevation)/standardSLP, 0.190284))
    }
    
    func temperature(at elevation: Double) -> Double {
        switch temperature {
            case .ISA: return ISATemperature(at: elevation)
            case .value(let num): return num
        }
    }
    
    // ft
    func densityAltitude(elevation: Double) -> Double {
        145442.16*(1.0-pow((17.326*absolutePressure(elevation: elevation))/(459.67+C2F(temperature(at: elevation))), 0.235))
    }
}

// feet
fileprivate func ISATemperature(at altitude: Double) -> Double {
    standardTemperature - 0.001978152*altitude
}

// hPa, m
fileprivate func pressure(altimeter: Double, altitude: Double) -> Double {
    altimeter*pow(1.0 + altitude * -0.0000225616, 5.25143)
}

// inHg, ft
fileprivate func enPressure(altimeter: Double, altitude: Double) -> Double {
    Pa2inHg(pressure(altimeter: inHg2Pa(altimeter), altitude: ft2m(altitude)))
}


fileprivate func inHg2hPa(_ pressure: Double) -> Double {
    pressure*33.8639
}

fileprivate func inHg2Pa(_ pressure: Double) -> Double {
    return pressure*3386.39
}

fileprivate func Pa2inHg(_ pressure: Double) -> Double {
    return pressure*0.0002953
}

fileprivate func ft2m(_ alt: Double) -> Double {
    alt*0.3048
}

fileprivate func C2F(_ temperature: Double) -> Double {
    temperature*9/5+32
}
