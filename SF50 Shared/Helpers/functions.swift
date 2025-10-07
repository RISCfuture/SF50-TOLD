import Foundation

func ftNmiToRatio(_ value: Double) -> Double {
  Measurement(value: value, unit: UnitLength.feet)
    / Measurement(value: 1, unit: UnitLength.nauticalMiles)
}

func ratioToFtNmi(_ value: Double) -> Double {
  Measurement(value: value, unit: UnitLength.nauticalMiles)
    / Measurement(value: 1, unit: UnitLength.feet)
}
