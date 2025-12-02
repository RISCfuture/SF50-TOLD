import Foundation
import SwiftData

/// A user-customizable performance scenario for takeoff or landing calculations.
///
/// ``Scenario`` represents a set of adjustments to be applied to base conditions
/// when calculating hypothetical performance. Scenarios can modify temperature,
/// wind speed, weight, flap settings, and runway contamination.
///
/// ## Topics
///
/// ### Properties
/// - ``name``
/// - ``operation``
///
/// ### Delta Adjustments
/// - ``deltaTemperature``
/// - ``deltaWindSpeed``
/// - ``deltaWeight``
///
/// ### Overrides
/// - ``flapSettingOverride``
/// - ``getFlapSettingOverride()``
/// - ``contaminationOverride``
/// - ``contaminationDepth``
/// - ``getContaminationOverride()``
/// - ``isDryOverride``
///
/// ### Factory Methods
/// - ``defaultScenarios()``
@Model
public final class Scenario {
  /// Scenario name
  public var name: String

  /// Operation type raw value (stored as string for SwiftData)
  public var _operation: String

  // Private storage for measurements (stored in base units)
  private var _deltaTemperature: Double  // Celsius
  private var _deltaWindSpeed: Double  // knots
  private var _deltaWeight: Double  // pounds
  private var _contaminationDepth: Double?  // meters

  /// Flap setting override (raw value of FlapSetting)
  public var flapSettingOverride: String?

  /// Contamination type override (raw value of Contamination.ContaminationType)
  public var contaminationOverride: String?

  /// Force dry runway conditions
  public var isDryOverride: Bool

  /// Operation type (takeoff or landing)
  public var operation: Operation {
    get { Operation(rawValue: _operation) ?? .takeoff }
    set { _operation = newValue.rawValue }
  }

  /// Temperature delta to apply to base conditions
  public var deltaTemperature: Measurement<UnitTemperature> {
    get { .init(value: _deltaTemperature, unit: .celsius) }
    set { _deltaTemperature = newValue.converted(to: .celsius).value }
  }

  /// Wind speed delta to apply to base conditions
  public var deltaWindSpeed: Measurement<UnitSpeed> {
    get { .init(value: _deltaWindSpeed, unit: .knots) }
    set { _deltaWindSpeed = newValue.converted(to: .knots).value }
  }

  /// Weight delta to apply to base configuration
  public var deltaWeight: Measurement<UnitMass> {
    get { .init(value: _deltaWeight, unit: .pounds) }
    set { _deltaWeight = newValue.converted(to: .pounds).value }
  }

  /// Contamination depth (for water/slush contamination types)
  public var contaminationDepth: Measurement<UnitLength>? {
    get { _contaminationDepth.map { .init(value: $0, unit: .meters) } }
    set { _contaminationDepth = newValue?.converted(to: .meters).value }
  }

  /**
   * Creates a new scenario.
   *
   * - Parameters:
   *   - name: Display name for this scenario.
   *   - operation: Whether this scenario applies to takeoff or landing.
   *   - deltaTemperature: Temperature adjustment to apply.
   *   - deltaWindSpeed: Wind speed adjustment to apply.
   *   - deltaWeight: Weight adjustment to apply.
   *   - flapSettingOverride: Flap setting raw value to override, or `nil`.
   *   - contaminationOverride: Contamination type raw value to override, or `nil`.
   *   - contaminationDepth: Contamination depth for water/slush types.
   *   - isDryOverride: Whether to force dry runway conditions.
   */
  public init(
    name: String,
    operation: Operation,
    deltaTemperature: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius),
    deltaWindSpeed: Measurement<UnitSpeed> = .init(value: 0, unit: .knots),
    deltaWeight: Measurement<UnitMass> = .init(value: 0, unit: .pounds),
    flapSettingOverride: String? = nil,
    contaminationOverride: String? = nil,
    contaminationDepth: Measurement<UnitLength>? = nil,
    isDryOverride: Bool = false
  ) {
    self.name = name
    _operation = operation.rawValue
    _deltaTemperature = deltaTemperature.converted(to: .celsius).value
    _deltaWindSpeed = deltaWindSpeed.converted(to: .knots).value
    _deltaWeight = deltaWeight.converted(to: .pounds).value
    _contaminationDepth = contaminationDepth?.converted(to: .meters).value
    self.flapSettingOverride = flapSettingOverride
    self.contaminationOverride = contaminationOverride
    self.isDryOverride = isDryOverride
  }

  /// Creates the default set of scenarios for the app
  public static func defaultScenarios() -> [Scenario] {
    // Default takeoff scenarios (hypotheticals only)
    let takeoffScenarios: [Scenario] = [
      Scenario(
        name: "OAT +10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "OAT -10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: -10, unit: .celsius)
      ),
      Scenario(
        name: "Wind Speed +10 kn",
        operation: .takeoff,
        deltaWindSpeed: .init(value: 10, unit: .knots)
      ),
      Scenario(
        name: "Wind Speed -10 kn",
        operation: .takeoff,
        deltaWindSpeed: .init(value: -10, unit: .knots)
      ),
      Scenario(
        name: "Weight +200 lbs",
        operation: .takeoff,
        deltaWeight: .init(value: 200, unit: .pounds)
      ),
      Scenario(
        name: "Weight -200 lbs",
        operation: .takeoff,
        deltaWeight: .init(value: -200, unit: .pounds)
      )
    ]

    // Default landing scenarios (hypotheticals only)
    let landingScenarios: [Scenario] = [
      Scenario(
        name: "OAT +10°C",
        operation: .landing,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "OAT -10°C",
        operation: .landing,
        deltaTemperature: .init(value: -10, unit: .celsius)
      ),
      Scenario(
        name: "Wind Speed +10 kn",
        operation: .landing,
        deltaWindSpeed: .init(value: 10, unit: .knots)
      ),
      Scenario(
        name: "Wind Speed -10 kn",
        operation: .landing,
        deltaWindSpeed: .init(value: -10, unit: .knots)
      ),
      Scenario(
        name: "Weight +200 lbs",
        operation: .landing,
        deltaWeight: .init(value: 200, unit: .pounds)
      ),
      Scenario(
        name: "Weight -200 lbs",
        operation: .landing,
        deltaWeight: .init(value: -200, unit: .pounds)
      ),
      Scenario(
        name: "Flaps 50",
        operation: .landing,
        flapSettingOverride: "flaps50"
      )
    ]

    return takeoffScenarios + landingScenarios
  }

  /// Converts the contamination override to the Contamination enum type
  public func getContaminationOverride() -> Contamination? {
    guard let contaminationType = contaminationOverride else { return nil }
    return Contamination(type: contaminationType, depth: _contaminationDepth)
  }

  /// Converts the flap setting override to the FlapSetting enum type
  public func getFlapSettingOverride() -> FlapSetting? {
    guard let flapString = flapSettingOverride else { return nil }
    switch flapString {
      case "flapsUp": return .flapsUp
      case "flapsUpIce": return .flapsUpIce
      case "flaps50": return .flaps50
      case "flaps50Ice": return .flaps50Ice
      case "flaps100": return .flaps100
      default: return nil
    }
  }
}
