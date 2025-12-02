import Foundation

/// Base implementation of ``PerformanceModel`` with common functionality.
///
/// ``BasePerformanceModel`` provides shared infrastructure for performance calculations
/// including input data storage and common derived values (headwind, gradient, etc.).
/// Subclasses must override the abstract performance properties to provide actual
/// calculation logic.
///
/// ## Subclassing Notes
///
/// All performance output properties are declared with `fatalError` implementations
/// and must be overridden by concrete subclasses:
/// - ``takeoffRunFt``
/// - ``takeoffDistanceFt``
/// - ``takeoffClimbGradientFtNmi``
/// - ``takeoffClimbRateFtMin``
/// - ``VrefKts``
/// - ``landingRunFt``
/// - ``landingDistanceFt``
open class BasePerformanceModel: PerformanceModel {

  // MARK: - Properties

  public let conditions: Conditions
  public let configuration: Configuration
  public let runway: RunwayInput
  public let notam: NOTAMInput?

  // MARK: - Required Protocol Properties (to be overridden)

  open var takeoffRunFt: Value<Double> {
    fatalError("Subclasses must implement takeoffRunFt")
  }

  open var takeoffDistanceFt: Value<Double> {
    fatalError("Subclasses must implement takeoffDistanceFt")
  }

  open var takeoffClimbGradientFtNmi: Value<Double> {
    fatalError("Subclasses must implement takeoffClimbGradientFtNmi")
  }

  open var takeoffClimbRateFtMin: Value<Double> {
    fatalError("Subclasses must implement takeoffClimbRateFtMin")
  }

  open var VrefKts: Value<Double> {
    fatalError("Subclasses must implement VrefKts")
  }

  open var landingRunFt: Value<Double> {
    fatalError("Subclasses must implement landingRunFt")
  }

  open var landingDistanceFt: Value<Double> {
    fatalError("Subclasses must implement landingDistanceFt")
  }

  open var meetsGoAroundClimbGradient: Value<Bool> {
    .notAvailable
  }

  // MARK: - Common Input Properties

  /// Aircraft weight in pounds.
  var weight: Double {
    configuration.weight.converted(to: .pounds).value
  }

  /// Temperature in Celsius, or ISA if not reported.
  var temperature: Double {
    conditions.temperature?.converted(to: .celsius).value ?? ISAdegC(altitudeFt: altitude)
  }

  /// Runway elevation in feet.
  var altitude: Double {
    runway.elevation.converted(to: .feet).value
  }

  /// Headwind component in knots (positive = headwind, negative = tailwind).
  var headwindComponent: Double {
    runway.headwind(conditions: conditions).converted(to: .knots).value
  }

  /// Headwind in knots (zero if tailwind).
  var headwind: Double {
    headwindComponent > 0 ? headwindComponent : 0
  }

  /// Tailwind in knots (zero if headwind).
  var tailwind: Double {
    headwindComponent < 0 ? -headwindComponent : 0
  }

  /// Runway gradient as a fraction (positive = uphill).
  var gradient: Double {
    Double(runway.gradient)
  }

  /// Uphill gradient (zero if downhill).
  var uphill: Double {
    gradient > 0 ? gradient : 0
  }

  /// Downhill gradient as positive value (zero if uphill).
  var downhill: Double {
    gradient < 0 ? -gradient : 0
  }

  // MARK: - Initializer

  /**
   * Creates a base performance model with the given inputs.
   *
   * - Parameters:
   *   - conditions: Atmospheric conditions for the calculation.
   *   - configuration: Aircraft weight and flap configuration.
   *   - runway: Runway data snapshot.
   *   - notam: Active NOTAM restrictions, if any.
   */
  public init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMInput?
  ) {
    self.conditions = conditions
    self.configuration = configuration
    self.runway = runway
    self.notam = notam
  }

  // MARK: - Helper Methods for Subclasses

  /// Returns the AFM table prefix for Vref lookup based on flap setting.
  func vrefPrefix(for flapSetting: FlapSetting) -> String {
    switch flapSetting {
      case .flapsUp: "up"
      case .flapsUpIce: "up ice"
      case .flaps50: "50"
      case .flaps50Ice: "50 ice"
      case .flaps100: "100"
    }
  }

  /// Returns the AFM table prefix for landing distance lookup based on flap setting.
  func landingPrefix(for flapSetting: FlapSetting) -> String {
    switch flapSetting {
      case .flaps50, .flapsUp: "50"
      case .flaps50Ice, .flapsUpIce: "50 ice"
      case .flaps100: "100"
    }
  }
}
