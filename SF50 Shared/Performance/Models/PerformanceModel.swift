/// Protocol defining aircraft performance calculation capabilities.
///
/// ``PerformanceModel`` abstracts the performance calculations for different
/// aircraft generations and calculation methods. Implementations include
/// tabular models (direct AFM table lookup) and regression models (curve-fitted
/// equations for smoother interpolation).
///
/// Performance models are configured with atmospheric conditions, aircraft
/// configuration, and runway data, then queried for specific performance values.
///
/// ## Topics
///
/// ### Input Data
/// - ``conditions``
/// - ``configuration``
/// - ``runway``
/// - ``notam``
///
/// ### Takeoff Performance
/// - ``takeoffRunFt``
/// - ``takeoffDistanceFt``
/// - ``takeoffClimbGradientFtNmi``
/// - ``takeoffClimbRateFtMin``
///
/// ### Landing Performance
/// - ``VrefKts``
/// - ``landingRunFt``
/// - ``landingDistanceFt``
/// - ``meetsGoAroundClimbGradient``
public protocol PerformanceModel {
  /// Atmospheric conditions for the calculation.
  var conditions: Conditions { get }

  /// Aircraft weight and flap configuration.
  var configuration: Configuration { get }

  /// Runway physical properties and declared distances.
  var runway: RunwayInput { get }

  /// Active NOTAM restrictions (contamination, obstacles, etc.).
  var notam: NOTAMInput? { get }

  /// Takeoff ground run distance in feet.
  var takeoffRunFt: Value<Double> { get }

  /// Takeoff distance to 35 feet AGL in feet.
  var takeoffDistanceFt: Value<Double> { get }

  /// Takeoff climb gradient at Vx in feet per nautical mile.
  var takeoffClimbGradientFtNmi: Value<Double> { get }

  /// Takeoff climb rate at Vx in feet per minute.
  var takeoffClimbRateFtMin: Value<Double> { get }

  /// Reference approach speed in knots.
  var VrefKts: Value<Double> { get }

  /// Landing ground run distance in feet.
  var landingRunFt: Value<Double> { get }

  /// Landing distance from 50 feet AGL in feet.
  var landingDistanceFt: Value<Double> { get }

  /// Whether the aircraft meets go-around climb gradient requirements.
  var meetsGoAroundClimbGradient: Value<Bool> { get }
}

/// Returns ISA standard temperature in Celsius at the given altitude in feet.
func ISAdegC(altitudeFt: Double) -> Double {
  15 - (0.0019812 * altitudeFt)
}
