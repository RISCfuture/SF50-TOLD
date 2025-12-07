import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double> {
  public static var weight: Self { .number.rounded(increment: 1) }
  public static var fuel: Self { .number.rounded(increment: 1) }
  public static var fuelDensity: Self { .number.rounded(increment: 0.01) }
  public static var length: Self { .number.rounded(increment: 1) }
  public static var distance: Self { .number.rounded(increment: 0.1) }
  public static var height: Self { .number.rounded(increment: 1) }
  public static var depth: Self { .number.rounded(increment: 0.1) }
  public static var rateOfClimb: Self { .number.rounded(increment: 1) }
  public static var gradient: Self { .number.rounded(increment: 1) }
  public static var speed: Self { .number.rounded(increment: 1) }
  public static var mach: Self { .number.precision(.fractionLength(3)) }
  public static var temperature: Self { .number.rounded(increment: 1) }
  public static var airPressure: Self { .number.rounded(increment: 0.01) }
  public static var heading: Self { .number.rounded(increment: 1) }
  public static var safetyFactor: Self { .number.rounded(increment: 0.1) }
}

extension FormatStyle where Self == IntegerFormatStyle<Int> {
  public static var count: Self { .number.grouping(.automatic) }
}

extension FormatStyle where Self == Measurement<UnitMass>.FormatStyle {
  public static var weight: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .weight)
  }

  public static func weight(plusSign: Bool = false) -> Self {
    plusSign
      ? .measurement(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .weight.sign(strategy: .always())
      ) : .weight
  }
}

extension FormatStyle where Self == Measurement<UnitVolume>.FormatStyle {
  public static var fuel: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .fuel)
  }
}

extension FormatStyle where Self == Measurement<UnitDensity>.FormatStyle {
  public static var fuelDensity: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .fuelDensity)
  }
}

extension FormatStyle where Self == Measurement<UnitLength>.FormatStyle {
  public static var length: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .length)
  }

  public static var distance: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .distance)
  }

  public static var height: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .height)
  }

  public static var depth: Self {
    .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .depth)
  }

  public static func length(plusSign: Bool = false) -> Self {
    plusSign
      ? .measurement(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .length.sign(strategy: .always())
      ) : .length
  }
}

extension FormatStyle where Self == Measurement<UnitSpeed>.FormatStyle {
  public static var rateOfClimb: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .rateOfClimb)
  }

  public static var speed: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .speed)
  }

  public static func speed(plusSign: Bool = false) -> Self {
    plusSign
      ? .measurement(
        width: .abbreviated,
        usage: .asProvided,
        numberFormatStyle: .rateOfClimb.sign(strategy: .always())
      ) : .speed
  }
}

extension FormatStyle where Self == Measurement<UnitTemperature>.FormatStyle {
  public static var temperature: Self {
    .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .temperature)
  }

  public static func temperature(plusSign: Bool = false) -> Self {
    plusSign
      ? .measurement(
        width: .narrow,
        usage: .asProvided,
        numberFormatStyle: .temperature.sign(strategy: .always())
      ) : .temperature
  }
}

extension FormatStyle where Self == Measurement<UnitPressure>.FormatStyle {
  public static var airPressure: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .airPressure)
  }
}

extension FormatStyle where Self == Measurement<UnitAngle>.FormatStyle {
  public static var heading: Self {
    .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .heading)
  }
}

extension FormatStyle where Self == Measurement<UnitSlope>.FormatStyle {
  public static var gradient: Self {
    .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .gradient)
  }
}
