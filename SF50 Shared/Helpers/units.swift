import Foundation

public let defaultWeightUnit = UnitMass.pounds
public let defaultFuelVolumeUnit = UnitVolume.gallons
public let defaultFuelDensityUnit = UnitDensity.poundsPerGallon
public let defaultLengthUnit = UnitLength.feet
public let defaultDistanceUnit = UnitLength.nauticalMiles
public let defaultHeightUnit = UnitLength.feet
public let defaultDepthUnit = UnitLength.inches
public let defaultRateOfClimbUnit = UnitSpeed.feetPerMinute
public let defaultSpeedUnit = UnitSpeed.knots
public let defaultTemperatureUnit = UnitTemperature.celsius
public let defaultAirPressureUnit = UnitPressure.inchesOfMercury
public let defaultHeadingUnit = UnitAngle.degrees

extension Measurement where UnitType == UnitMass {
  public var asWeight: Self { converted(to: defaultWeightUnit) }
}

extension Measurement where UnitType == UnitVolume {
  public var asFuel: Self { converted(to: defaultFuelVolumeUnit) }
}

extension Measurement where UnitType == UnitDensity {
  public var asFuelDensity: Self { converted(to: defaultFuelDensityUnit) }
}

extension Measurement where UnitType == UnitLength {
  public var asLength: Self { converted(to: defaultLengthUnit) }
  public var asDistance: Self { converted(to: defaultDistanceUnit) }
  public var asHeight: Self { converted(to: defaultHeightUnit) }
  public var asDepth: Self { converted(to: defaultDepthUnit) }
}

extension Measurement where UnitType == UnitSpeed {
  public var asRateOfClimb: Self { converted(to: defaultRateOfClimbUnit) }
  public var asSpeed: Self { converted(to: defaultSpeedUnit) }
}

extension Measurement where UnitType == UnitTemperature {
  public var asTemperature: Self { converted(to: defaultTemperatureUnit) }
}

extension Measurement where UnitType == UnitPressure {
  public var asAirPressure: Self { converted(to: defaultAirPressureUnit) }
}

extension Measurement where UnitType == UnitAngle {
  public var asHeading: Self { converted(to: defaultHeadingUnit) }
}

extension Measurement where UnitType == UnitSlope {
  public var asGradient: Self { converted(to: .feetPerNauticalMile) }
}
