import Foundation

extension Runway {
  public struct NameComparator: SortComparator {
    public var order: SortOrder = .forward

    public init(order: SortOrder = .forward) {
      self.order = order
    }

    public func compare(_ lhs: Runway, _ rhs: Runway) -> ComparisonResult {
      let name1 = lhs.name
      let name2 = rhs.name

      // Extract numeric and letter parts
      let num1 = Int(name1.filter(\.isNumber)) ?? 0
      let num2 = Int(name2.filter(\.isNumber)) ?? 0

      if num1 != num2 {
        let result: ComparisonResult = num1 < num2 ? .orderedAscending : .orderedDescending
        return order == .forward ? result : result.inverted
      }

      // If numbers are equal, compare the letters
      let letter1 = name1.filter(\.isLetter)
      let letter2 = name2.filter(\.isLetter)

      // Order: no letter < L < C < R
      let letterOrder = ["": 0, "L": 1, "C": 2, "R": 3]
      let val1 = letterOrder[letter1] ?? 4
      let val2 = letterOrder[letter2] ?? 4

      if val1 != val2 {
        let result: ComparisonResult = val1 < val2 ? .orderedAscending : .orderedDescending
        return order == .forward ? result : result.inverted
      }

      return .orderedSame
    }
  }
}

extension ComparisonResult {
  fileprivate var inverted: ComparisonResult {
    switch self {
      case .orderedAscending: return .orderedDescending
      case .orderedDescending: return .orderedAscending
      case .orderedSame: return .orderedSame
    }
  }
}
