import RealModule
import Testing

@testable import SF50_Shared

struct DataTableTests {

  // MARK: - 1D Interpolation Tests

  @Test
  func exactMatch1D() {
    let data = [
      [1000.0, 100.0],
      [2000.0, 200.0],
      [3000.0, 300.0]
    ]
    let table = DataTable(data: data)

    let result = table.value(for: [2000.0])
    #expect(result == .value(200.0))
  }

  @Test
  func linearInterpolation1D() {
    let data = [
      [1000.0, 100.0],
      [2000.0, 200.0]
    ]
    let table = DataTable(data: data)

    let result = table.value(for: [1500.0])
    #expect(result == .value(150.0))

    // Test with non-exact interpolation
    let result2 = table.value(for: [1234.5])
    guard case .value(let value) = result2 else {
      Issue.record("Expected interpolated value, got \(result2)")
      return
    }
    #expect(value.isApproximatelyEqual(to: 123.45, relativeTolerance: 0.0001))
  }

  @Test
  func offscale1D() {
    let data = [
      [1000.0, 100.0],
      [2000.0, 200.0]
    ]
    let table = DataTable(data: data)

    #expect(table.value(for: [500.0]) == .offscaleLow)
    #expect(table.value(for: [2500.0]) == .offscaleHigh)
  }

  @Test
  func clamping1D() {
    let data = [
      [1000.0, 100.0],
      [2000.0, 200.0]
    ]
    let table = DataTable(data: data)

    // Clamp low
    let clampLowResult = table.value(for: [500.0], clamping: [.clampLow])
    #expect(clampLowResult == .value(100.0))

    // Clamp high
    let clampHighResult = table.value(for: [2500.0], clamping: [.clampHigh])
    #expect(clampHighResult == .value(200.0))

    // Clamp both
    let clampBothLow = table.value(for: [500.0], clamping: [.clampBoth])
    #expect(clampBothLow == .value(100.0))

    let clampBothHigh = table.value(for: [2500.0], clamping: [.clampBoth])
    #expect(clampBothHigh == .value(200.0))
  }

  // MARK: - 2D Interpolation Tests

  @Test
  func exactMatch2D() {
    let data = [
      [1000.0, 10.0, 100.0],
      [1000.0, 20.0, 110.0],
      [2000.0, 10.0, 200.0],
      [2000.0, 20.0, 220.0]
    ]
    let table = DataTable(data: data)

    let result = table.value(for: [1000.0, 20.0])
    #expect(result == .value(110.0))
  }

  @Test
  func bilinearInterpolation2D() {
    let data = [
      [1000.0, 10.0, 100.0],
      [1000.0, 20.0, 200.0],
      [2000.0, 10.0, 300.0],
      [2000.0, 20.0, 400.0]
    ]
    let table = DataTable(data: data)

    // Interpolate at center point
    let result = table.value(for: [1500.0, 15.0])
    #expect(result == .value(250.0))
  }

  @Test
  func sparseDataInterpolation3D() {
    // Test with sparse data similar to actual CSV structure
    let data = [
      // Include ISA temperatures
      [6000.0, 7000.0, 1.1316, 2737.0],
      [6000.0, 7000.0, 20.0, 3960.0],
      [6000.0, 7000.0, 30.0, 4905.0],
      [6000.0, 8000.0, 20.0, 4429.0],
      [6000.0, 8000.0, 30.0, 5488.0]
    ]
    let table = DataTable(data: data)

    // Should interpolate between 20 and 30, ignoring ISA value
    let result = table.value(for: [6000.0, 7000.0, 25.0])
    guard case .value(let value) = result else {
      Issue.record("Expected interpolated value, got \(result)")
      return
    }
    let expected = 3960.0 + 0.5 * (4905.0 - 3960.0)
    #expect(value.isApproximatelyEqual(to: expected, relativeTolerance: 0.0001))
  }

  // MARK: - Edge Cases

  @Test
  func singleDataPoint() {
    let data = [[1000.0, 100.0]]
    let table = DataTable(data: data)

    // Exact match
    #expect(table.value(for: [1000.0]) == .value(100.0))

    // Off scale
    #expect(table.value(for: [999.0]) == .offscaleLow)
    #expect(table.value(for: [1001.0]) == .offscaleHigh)
  }

  // MARK: - CSV Parsing Tests

  @Test
  func csvParsing() {
    let csv = """
      weight,altitude,temperature,value
      5000,7000,20,3300
      5000,7000,30,4088
      6000,7000,20,3960
      6000,7000,30,4905
      """

    let table = DataTable(csv: csv)

    // Test exact match
    let result = table.value(for: [5000.0, 7000.0, 20.0])
    #expect(result == .value(3300.0))

    // Test interpolation
    let interpResult = table.value(for: [5500.0, 7000.0, 25.0])
    guard case .value(let value) = interpResult else {
      Issue.record("Expected interpolated value, got \(interpResult)")
      return
    }
    // Should be between the values
    #expect(value > 3300.0)
    #expect(value < 4905.0)
  }

  // MARK: - Min/Max Tests

  @Test
  func minMaxValues() {
    let data = [
      [1000.0, 10.0, 100.0],
      [2000.0, 20.0, 200.0],
      [3000.0, 30.0, 300.0]
    ]
    let table = DataTable(data: data)

    #expect(table.min(dimension: 0) == 1000.0)
    #expect(table.max(dimension: 0) == 3000.0)

    #expect(table.min(dimension: 1) == 10.0)
    #expect(table.max(dimension: 1) == 30.0)
  }
}
