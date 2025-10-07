import Foundation
import SwiftData

/// Notice to Airmen (NOTAM) affecting runway performance.
///
/// `NOTAM` represents temporary conditions that affect runway performance calculations,
/// including contamination (ice, snow, water), displaced thresholds, and obstacles.
@Model
public final class NOTAM {
  private var _contaminationType: String?
  private var _contaminationDepth: Double  // meters
  private var _takeoffDistanceShortening: Double  // meters
  private var _landingDistanceShortening: Double  // meters
  private var _obstacleHeight: Double  // meters
  private var _obstacleDistance: Double  // meters

  @Relationship(deleteRule: .nullify)
  var runway: Runway

  /// Runway surface contamination (ice, snow, slush, water)
  public var contamination: Contamination? {
    get { .init(type: _contaminationType, depth: _contaminationDepth) }
    set {
      _contaminationType = newValue?.type
      _contaminationDepth = newValue?.depth ?? 0
    }
  }

  /// Reduction in takeoff distance available due to displaced threshold
  public var takeoffDistanceShortening: Measurement<UnitLength> {
    get { .init(value: _takeoffDistanceShortening, unit: .meters) }
    set { _takeoffDistanceShortening = newValue.converted(to: .meters).value }
  }

  /// Reduction in landing distance available due to displaced threshold
  public var landingDistanceShortening: Measurement<UnitLength> {
    get { .init(value: _landingDistanceShortening, unit: .meters) }
    set { _landingDistanceShortening = newValue.converted(to: .meters).value }
  }

  /// Height of obstacle above runway surface
  public var obstacleHeight: Measurement<UnitLength> {
    get { .init(value: _obstacleHeight, unit: .meters) }
    set { _obstacleHeight = newValue.converted(to: .meters).value }
  }

  /// Distance from runway threshold to obstacle
  public var obstacleDistance: Measurement<UnitLength> {
    get { .init(value: _obstacleDistance, unit: .meters) }
    set { _obstacleDistance = newValue.converted(to: .meters).value }
  }

  /// Creates a new NOTAM for a runway.
  public init(
    runway: Runway,
    contamination: Contamination? = nil,
    takeoffDistanceShortening: Measurement<UnitLength>? = nil,
    landingDistanceShortening: Measurement<UnitLength>? = nil,
    obstacleHeight: Measurement<UnitLength>? = nil,
    obstacleDistance: Measurement<UnitLength>? = nil
  ) {
    self.runway = runway
    _contaminationType = contamination?.type
    _contaminationDepth = contamination?.depth ?? 0
    _takeoffDistanceShortening = takeoffDistanceShortening?.converted(to: .meters).value ?? 0
    _landingDistanceShortening = landingDistanceShortening?.converted(to: .meters).value ?? 0
    _obstacleHeight = obstacleHeight?.converted(to: .meters).value ?? 0
    _obstacleDistance = obstacleDistance?.converted(to: .meters).value ?? 0
  }

  /// Clears NOTAM restrictions for the specified operation type.
  public func clearFor(operation: Operation) {
    switch operation {
      case .takeoff:
        takeoffDistanceShortening = .init(value: 0, unit: .feet)
        obstacleHeight = .init(value: 0, unit: .feet)
        obstacleDistance = .init(value: 0, unit: .nauticalMiles)
      case .landing:
        landingDistanceShortening = .init(value: 0, unit: .feet)
        contamination = nil
    }
  }
}

/// Runway surface contamination type and depth.
public enum Contamination: Sendable, Hashable {
  /// Standing water or slush on the runway surface
  case waterOrSlush(depth: Measurement<UnitLength>)

  /// Slush or wet snow on the runway surface
  case slushOrWetSnow(depth: Measurement<UnitLength>)

  /// Dry snow covering the runway
  case drySnow

  /// Compacted snow or ice on the runway
  case compactSnow

  var type: String {
    switch self {
      case .waterOrSlush: ContaminationType.waterOrSlush.rawValue
      case .slushOrWetSnow: ContaminationType.slushOrWetSnow.rawValue
      case .drySnow: ContaminationType.drySnow.rawValue
      case .compactSnow: ContaminationType.compactSnow.rawValue
    }
  }

  var depth: Double? {
    switch self {
      case .waterOrSlush(let depth): depth.converted(to: .meters).value
      case .slushOrWetSnow(let depth): depth.converted(to: .meters).value
      case .drySnow: nil
      case .compactSnow: nil
    }
  }

  init?(type: String?, depth: Double?) {
    guard let type, let typeEnum = ContaminationType(rawValue: type) else { return nil }

    switch typeEnum {
      case .waterOrSlush:
        guard let depth else { return nil }
        self = .waterOrSlush(depth: .init(value: depth, unit: .meters))
      case .slushOrWetSnow:
        guard let depth else { return nil }
        self = .slushOrWetSnow(depth: .init(value: depth, unit: .meters))
      case .drySnow:
        self = .drySnow
      case .compactSnow:
        self = .compactSnow
    }
  }

  enum ContaminationType: String {
    case waterOrSlush
    case slushOrWetSnow
    case drySnow
    case compactSnow
  }
}
