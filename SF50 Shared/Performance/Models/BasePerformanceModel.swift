import Foundation

open class BasePerformanceModel: PerformanceModel {

  // MARK: - Properties

  public let conditions: Conditions
  public let configuration: Configuration
  public let runway: RunwayInput
  public let notam: NOTAMSnapshot?

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

  public var weight: Double {
    configuration.weight.converted(to: .pounds).value
  }

  public var temperature: Double {
    conditions.temperature?.converted(to: .celsius).value ?? ISAdegC(altitudeFt: altitude)
  }

  public var altitude: Double {
    runway.elevation.converted(to: .feet).value
  }

  public var headwindComponent: Double {
    runway.headwind(conditions: conditions).converted(to: .knots).value
  }

  public var headwind: Double {
    headwindComponent > 0 ? headwindComponent : 0
  }

  public var tailwind: Double {
    headwindComponent < 0 ? -headwindComponent : 0
  }

  public var gradient: Double {
    Double(runway.gradient)
  }

  public var uphill: Double {
    gradient > 0 ? gradient : 0
  }

  public var downhill: Double {
    gradient < 0 ? -gradient : 0
  }

  // MARK: - Initializer

  public init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMSnapshot?
  ) {
    self.conditions = conditions
    self.configuration = configuration
    self.runway = runway
    self.notam = notam
  }

  // MARK: - Helper Methods for Subclasses

  func vrefPrefix(for flapSetting: FlapSetting) -> String {
    switch flapSetting {
      case .flapsUp: "up"
      case .flapsUpIce: "up ice"
      case .flaps50: "50"
      case .flaps50Ice: "50 ice"
      case .flaps100: "100"
    }
  }

  func landingPrefix(for flapSetting: FlapSetting) -> String {
    switch flapSetting {
      case .flaps50, .flapsUp: "50"
      case .flaps50Ice, .flapsUpIce: "50 ice"
      case .flaps100: "100"
    }
  }
}
