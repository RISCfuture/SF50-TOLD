import Foundation

extension Measurement {
  public var absoluteValue: Self {
    .init(value: abs(value), unit: unit)
  }

  public var magnitude: Self { .init(value: value.magnitude, unit: unit) }

  public static prefix func - (val: Self) -> Self {
    .init(value: -val.value, unit: val.unit)
  }

  public static func / <U: Dimension>(lhs: Measurement<U>, rhs: Measurement<U>) -> Double {
    lhs.converted(to: .baseUnit()).value / rhs.converted(to: .baseUnit()).value
  }

  public static func * (lhs: Measurement<UnitVolume>, rhs: Measurement<UnitDensity>) -> Measurement<
    UnitMass
  > {
    let value = lhs.converted(to: .baseUnit()).value * rhs.converted(to: .baseUnit()).value
    return .init(value: value, unit: .baseUnit())
  }
}

extension UnitSpeed {
  public static let feetPerMinute = UnitSpeed(
    symbol: "ft/min",
    converter: UnitConverterLinear(coefficient: 0.00508)
  )
}

public func sin(_ angle: Measurement<UnitAngle>) -> Double {
  sin(angle.converted(to: .radians).value)
}

public func cos(_ angle: Measurement<UnitAngle>) -> Double {
  cos(angle.converted(to: .radians).value)
}

extension Measurement where UnitType == UnitAngle {
  public var reciprocal: Self {
    let degreesValue = self.converted(to: .degrees).value
    let reciprocalDegrees = (degreesValue + 180).truncatingRemainder(dividingBy: 360)
    return .init(value: reciprocalDegrees, unit: .degrees)
  }
}
