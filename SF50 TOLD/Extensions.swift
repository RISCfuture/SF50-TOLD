extension Array where Element: Equatable {
  mutating func appendRemovingDuplicates(of newElement: Element) {
    self.removeAll { $0 == newElement }
    self.append(newElement)
  }
}

extension String {
  func localizedStandardHasPrefix(_ prefix: String) -> Bool {
    guard let range = localizedStandardRange(of: prefix) else { return false }
    return range.lowerBound == startIndex
  }

  func localizedStandardEquals(_ other: String) -> Bool {
    localizedStandardCompare(other) == .orderedSame
  }
}
