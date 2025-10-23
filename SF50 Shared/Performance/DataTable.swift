import Foundation

/// A data table for multi-dimensional interpolation of performance data
class DataTable {
  private typealias Row = [Double]

  private var data: [Row] = []
  private var nInputs: Int = 0

  convenience init(fileURL: URL) throws {
    let data = try Data(contentsOf: fileURL)
    guard let string = String(data: data, encoding: .utf8) else {
      throw Errors.badEncoding
    }
    self.init(csv: string)
  }

  init(csv: String) {
    let lines = csv.split(whereSeparator: \.isNewline)
    for line in lines {
      let columns = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
      let values = columns.compactMap { Double($0) }
      if !values.isEmpty {
        data.append(values)
      }
    }
    if let first = data.first {
      nInputs = first.count - 1
    }
  }

  // Constructor for testing
  init(data: [[Double]]) {
    self.data = data
    if let first = data.first {
      nInputs = first.count - 1
    }
  }

  /// Linear interpolation for multiple inputs (returns Double output)
  func value(for inputs: [Double], clamping: [Clamping]? = nil) -> Value<Double> {
    precondition(inputs.count == nInputs, "Input dimension mismatch")

    let clampingModes = clamping ?? Array(repeating: .none, count: nInputs)
    precondition(clampingModes.count == nInputs, "Clamping dimension mismatch")

    // Apply clamping
    var clampedInputs: [Double] = []
    for dim in 0..<nInputs {
      let input = inputs[dim]
      let minVal = self.min(dimension: dim)
      let maxVal = self.max(dimension: dim)

      switch clampingModes[dim] {
        case .none:
          if input < minVal { return .offscaleLow }
          if input > maxVal { return .offscaleHigh }
          clampedInputs.append(input)
        case .clampLow:
          if input > maxVal { return .offscaleHigh }
          clampedInputs.append(Swift.max(input, minVal))
        case .clampHigh:
          if input < minVal { return .offscaleLow }
          clampedInputs.append(Swift.min(input, maxVal))
        case .clampBoth:
          clampedInputs.append(Swift.min(Swift.max(input, minVal), maxVal))
      }
    }

    // Check for exact match first
    for row in data {
      let matches = (0..<nInputs).allSatisfy { abs(row[$0] - clampedInputs[$0]) <= 1e-10 }
      if matches {
        return .value(row.last!)
      }
    }

    // Perform interpolation
    if nInputs == 1 {
      return interpolate1D(input: clampedInputs[0])
    }
    if nInputs == 2 {
      return interpolate2D(inputs: clampedInputs)
    }
    if nInputs == 3 {
      return interpolate3D(inputs: clampedInputs)
    }
    // For higher dimensions, use general n-D interpolation
    return interpolateND(inputs: clampedInputs)
  }

  private func interpolate1D(input: Double) -> Value<Double> {
    // Sort data by first column
    let sortedData = data.sorted { $0[0] < $1[0] }

    // Find bounding points
    var lower: Row?
    var upper: Row?

    for i in 0..<sortedData.count {
      if sortedData[i][0] <= input {
        lower = sortedData[i]
      }
      if sortedData[i][0] >= input && upper == nil {
        upper = sortedData[i]
        break
      }
    }

    guard let lowerPoint = lower, let upperPoint = upper else {
      return .offscaleHigh
    }

    if lowerPoint[0] == upperPoint[0] {
      return .value(lowerPoint[1])
    }

    let t = (input - lowerPoint[0]) / (upperPoint[0] - lowerPoint[0])
    return .value(lowerPoint[1] + t * (upperPoint[1] - lowerPoint[1]))
  }

  private func interpolate2D(inputs: [Double]) -> Value<Double> {
    // Find the four corner points
    // First, find x bounds from all data
    var xValues = Set<Double>()

    for row in data {
      xValues.insert(row[0])
    }

    // Sort and find x bounds
    let xSorted = xValues.sorted()

    var x0 = -Double.infinity
    var x1 = Double.infinity

    for val in xSorted {
      if val <= inputs[0] && val > x0 { x0 = val }
      if val >= inputs[0] && val < x1 { x1 = val }
    }

    // Now find y values only at the x bounds we found
    var yValues = Set<Double>()
    for row in data {
      let xMatch = abs(row[0] - x0) < 1e-10 || abs(row[0] - x1) < 1e-10
      if xMatch {
        yValues.insert(row[1])
      }
    }

    // Sort y values
    let ySorted = yValues.sorted()

    // Find valid y bounds where all 4 corners exist
    var y0 = -Double.infinity
    var y1 = Double.infinity
    var foundValidBounds = false

    // Build a set of existing corners for fast lookup
    var existingCorners = Set<String>()
    for row in data {
      if abs(row[0] - x0) < 1e-10 || abs(row[0] - x1) < 1e-10 {
        existingCorners.insert("\(row[0]),\(row[1])")
      }
    }

    // Try all possible y bound combinations, preferring tighter bounds
    var bestY0 = -Double.infinity
    var bestY1 = Double.infinity
    var bestSpan = Double.infinity

    for i in 0..<ySorted.count {
      for j in i..<ySorted.count {
        let yLower = ySorted[i]
        let yUpper = ySorted[j]

        // Check if input y is within these bounds
        if yLower <= inputs[1] && inputs[1] <= yUpper {
          // Check if all 4 corners exist
          let cornersNeeded = [
            "\(x0),\(yLower)", "\(x1),\(yLower)",
            "\(x0),\(yUpper)", "\(x1),\(yUpper)"
          ]

          let allCornersExist = cornersNeeded.allSatisfy { existingCorners.contains($0) }

          // If all corners exist, check if this is a better (tighter) bound
          if allCornersExist {
            let span = yUpper - yLower
            if span < bestSpan {
              bestY0 = yLower
              bestY1 = yUpper
              bestSpan = span
              foundValidBounds = true
            }
          }
        }
      }
    }

    if foundValidBounds {
      y0 = bestY0
      y1 = bestY1
    }

    // If no valid bounds found, return offscale
    if !foundValidBounds {
      return .offscaleHigh
    }

    // Find the four corner values
    var v00: Double?
    var v01: Double?
    var v10: Double?
    var v11: Double?

    for row in data {
      if abs(row[0] - x0) < 1e-10 && abs(row[1] - y0) < 1e-10 { v00 = row[2] }
      if abs(row[0] - x0) < 1e-10 && abs(row[1] - y1) < 1e-10 { v01 = row[2] }
      if abs(row[0] - x1) < 1e-10 && abs(row[1] - y0) < 1e-10 { v10 = row[2] }
      if abs(row[0] - x1) < 1e-10 && abs(row[1] - y1) < 1e-10 { v11 = row[2] }
    }

    // If we don't have all four corners, return offscale high (no extrapolation)
    if v00 == nil || v01 == nil || v10 == nil || v11 == nil {
      return .offscaleHigh
    }

    // Bilinear interpolation
    let tx = (x0 == x1) ? 0.0 : (inputs[0] - x0) / (x1 - x0)
    let ty = (y0 == y1) ? 0.0 : (inputs[1] - y0) / (y1 - y0)

    let v0 = v00! + tx * (v10! - v00!)
    let v1 = v01! + tx * (v11! - v01!)

    return .value(v0 + ty * (v1 - v0))
  }

  private func interpolate3D(inputs: [Double]) -> Value<Double> {
    // Find the eight corner points
    // First, find x bounds from all data
    var xValues = Set<Double>()

    for row in data {
      xValues.insert(row[0])
    }

    // Sort and find x bounds
    let xSorted = xValues.sorted()

    var x0 = -Double.infinity
    var x1 = Double.infinity

    for val in xSorted {
      if val <= inputs[0] && val > x0 { x0 = val }
      if val >= inputs[0] && val < x1 { x1 = val }
    }

    // Now find y values ONLY at the x bounds we found
    var yValues = Set<Double>()
    for row in data {
      let xMatch = abs(row[0] - x0) < 1e-10 || abs(row[0] - x1) < 1e-10
      if xMatch {
        yValues.insert(row[1])
      }
    }

    // Sort and find y bounds
    let ySorted = yValues.sorted()

    var y0 = -Double.infinity
    var y1 = Double.infinity

    for val in ySorted {
      if val <= inputs[1] && val > y0 { y0 = val }
      if val >= inputs[1] && val < y1 { y1 = val }
    }

    // Now find z values only at the x,y bounds we found
    var zValues = Set<Double>()
    for row in data {
      let xMatch = abs(row[0] - x0) < 1e-10 || abs(row[0] - x1) < 1e-10
      let yMatch = abs(row[1] - y0) < 1e-10 || abs(row[1] - y1) < 1e-10
      if xMatch && yMatch {
        zValues.insert(row[2])
      }
    }

    // Sort z values
    let zSorted = zValues.sorted()

    // Find valid z bounds where all 8 corners exist
    var z0 = -Double.infinity
    var z1 = Double.infinity
    var foundValidBounds = false

    // Build a set of existing corners for fast lookup
    var existingCorners = Set<String>()
    for row in data {
      // Only consider corners at our x,y bounds
      if (abs(row[0] - x0) < 1e-10 || abs(row[0] - x1) < 1e-10)
        && (abs(row[1] - y0) < 1e-10 || abs(row[1] - y1) < 1e-10)
      {
        existingCorners.insert("\(row[0]),\(row[1]),\(row[2])")
      }
    }

    // Try all possible z bound combinations, preferring tighter bounds
    var bestZ0 = -Double.infinity
    var bestZ1 = Double.infinity
    var bestSpan = Double.infinity

    for i in 0..<zSorted.count {
      for j in i..<zSorted.count {
        let zLower = zSorted[i]
        let zUpper = zSorted[j]

        // Check if input z is within these bounds
        if zLower <= inputs[2] && inputs[2] <= zUpper {
          // Check if all 8 corners exist for these bounds
          let cornersNeeded = [
            "\(x0),\(y0),\(zLower)", "\(x1),\(y0),\(zLower)",
            "\(x0),\(y1),\(zLower)", "\(x1),\(y1),\(zLower)",
            "\(x0),\(y0),\(zUpper)", "\(x1),\(y0),\(zUpper)",
            "\(x0),\(y1),\(zUpper)", "\(x1),\(y1),\(zUpper)"
          ]

          let allCornersExist = cornersNeeded.allSatisfy { existingCorners.contains($0) }

          // If all corners exist, check if this is a better (tighter) bound
          if allCornersExist {
            let span = zUpper - zLower
            if span < bestSpan {
              bestZ0 = zLower
              bestZ1 = zUpper
              bestSpan = span
              foundValidBounds = true
            }
          }
        }
      }
    }

    if foundValidBounds {
      z0 = bestZ0
      z1 = bestZ1
    }

    // If no valid bounds found, return offscale
    if !foundValidBounds {
      return .offscaleHigh
    }

    // Find the eight corner values
    var corners: [Double?] = Array(repeating: nil, count: 8)

    for row in data {
      let xMatch0 = abs(row[0] - x0) < 1e-10
      let xMatch1 = abs(row[0] - x1) < 1e-10
      let yMatch0 = abs(row[1] - y0) < 1e-10
      let yMatch1 = abs(row[1] - y1) < 1e-10
      let zMatch0 = abs(row[2] - z0) < 1e-10
      let zMatch1 = abs(row[2] - z1) < 1e-10

      if xMatch0 && yMatch0 && zMatch0 { corners[0] = row[3] }
      if xMatch1 && yMatch0 && zMatch0 { corners[1] = row[3] }
      if xMatch0 && yMatch1 && zMatch0 { corners[2] = row[3] }
      if xMatch1 && yMatch1 && zMatch0 { corners[3] = row[3] }
      if xMatch0 && yMatch0 && zMatch1 { corners[4] = row[3] }
      if xMatch1 && yMatch0 && zMatch1 { corners[5] = row[3] }
      if xMatch0 && yMatch1 && zMatch1 { corners[6] = row[3] }
      if xMatch1 && yMatch1 && zMatch1 { corners[7] = row[3] }
    }

    // Check if we have all corners
    let hasAllCorners = corners.allSatisfy { $0 != nil }
    if !hasAllCorners {
      return .offscaleHigh
    }

    // Trilinear interpolation
    let tx = (x0 == x1) ? 0.0 : (inputs[0] - x0) / (x1 - x0)
    let ty = (y0 == y1) ? 0.0 : (inputs[1] - y0) / (y1 - y0)
    let tz = (z0 == z1) ? 0.0 : (inputs[2] - z0) / (z1 - z0)

    // Interpolate along x
    let v00 = corners[0]! + tx * (corners[1]! - corners[0]!)
    let v01 = corners[2]! + tx * (corners[3]! - corners[2]!)
    let v10 = corners[4]! + tx * (corners[5]! - corners[4]!)
    let v11 = corners[6]! + tx * (corners[7]! - corners[6]!)

    // Interpolate along y
    let v0 = v00 + ty * (v01 - v00)
    let v1 = v10 + ty * (v11 - v10)

    // Interpolate along z
    return .value(v0 + tz * (v1 - v0))
  }

  private func interpolateND(inputs _: [Double]) -> Value<Double> {
    // For higher dimensions, we don't support interpolation yet
    // Return offscale to avoid extrapolation
    return .offscaleHigh
  }

  private func nearestNeighbor(inputs: [Double]) -> Value<Double> {
    var minDistance = Double.infinity
    var nearestValue = 0.0

    for row in data {
      var distance = 0.0
      for dim in 0..<nInputs {
        let diff = row[dim] - inputs[dim]
        distance += diff * diff
      }

      if distance < minDistance {
        minDistance = distance
        nearestValue = row.last!
      }
    }

    return .value(nearestValue)
  }

  func min(dimension: Int) -> Double {
    precondition((0..<nInputs).contains(dimension), "Invalid dimension")
    return data.map { $0[dimension] }.min()!
  }

  func max(dimension: Int) -> Double {
    precondition((0..<nInputs).contains(dimension), "Invalid dimension")
    return data.map { $0[dimension] }.max()!
  }

  enum Errors: Error {
    case badEncoding
  }

  enum Clamping {
    case none
    case clampLow
    case clampHigh
    case clampBoth
  }
}
