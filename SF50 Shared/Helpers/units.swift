import Defaults
import Foundation

// Convenience extension methods for converting measurements to user-preferred units
extension Measurement where UnitType == UnitMass {
  public var asWeight: Self { converted(to: Defaults[.weightUnit]) }
}

extension Measurement where UnitType == UnitVolume {
  public var asFuel: Self { converted(to: Defaults[.fuelVolumeUnit]) }
}

extension Measurement where UnitType == UnitDensity {
  public var asFuelDensity: Self { converted(to: Defaults[.fuelDensityUnit]) }
}

extension Measurement where UnitType == UnitLength {
  public var asLength: Self { converted(to: Defaults[.runwayLengthUnit]) }
  public var asDistance: Self { converted(to: Defaults[.distanceUnit]) }
  public var asHeight: Self { converted(to: Defaults[.heightUnit]) }
  // Depth always uses inches regardless of user preference
  public var asDepth: Self { converted(to: .inches) }
}

extension Measurement where UnitType == UnitSpeed {
  // Rate of climb always uses feet per minute regardless of user preference
  public var asRateOfClimb: Self { converted(to: .feetPerMinute) }
  public var asSpeed: Self { converted(to: Defaults[.speedUnit]) }
}

extension Measurement where UnitType == UnitTemperature {
  public var asTemperature: Self { converted(to: Defaults[.temperatureUnit]) }
}

extension Measurement where UnitType == UnitPressure {
  public var asAirPressure: Self { converted(to: Defaults[.pressureUnit]) }
}

extension Measurement where UnitType == UnitAngle {
  // Heading always uses degrees regardless of user preference
  public var asHeading: Self { converted(to: .degrees) }
}

extension Measurement where UnitType == UnitSlope {
  public var asGradient: Self { converted(to: .feetPerNauticalMile) }
}
