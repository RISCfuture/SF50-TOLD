import Foundation

func unit<U: Dimension>(_ u1: Dimension, per u2: Dimension, symbol: String? = nil) -> U {
  let v1 = u1.converter.baseUnitValue(fromValue: 1)
  let v2 = u2.converter.baseUnitValue(fromValue: 1)
  let symbol = symbol ?? "\(u1.symbol)/\(u2.symbol)"
  return .init(symbol: symbol, converter: UnitConverterLinear(coefficient: v1 / v2))
}

func unit<U: Dimension>(_ u1: Dimension, times u2: Dimension, symbol: String? = nil) -> U {
  let v1 = u1.converter.baseUnitValue(fromValue: 1)
  let v2 = u2.converter.baseUnitValue(fromValue: 1)
  let symbol = symbol ?? "\(u1.symbol)/\(u2.symbol)"
  return .init(symbol: symbol, converter: UnitConverterLinear(coefficient: v1 * v2))
}
