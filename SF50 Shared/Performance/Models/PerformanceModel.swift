public protocol PerformanceModel {
  var conditions: Conditions { get }
  var configuration: Configuration { get }
  var runway: RunwayInput { get }
  var notam: NOTAMSnapshot? { get }

  var takeoffRunFt: Value<Double> { get }
  var takeoffDistanceFt: Value<Double> { get }

  var takeoffClimbGradientFtNmi: Value<Double> { get }
  var takeoffClimbRateFtMin: Value<Double> { get }

  var VrefKts: Value<Double> { get }
  var landingRunFt: Value<Double> { get }
  var landingDistanceFt: Value<Double> { get }

  var meetsGoAroundClimbGradient: Value<Bool> { get }
}

func ISAdegC(altitudeFt: Double) -> Double {
  15 - (0.0019812 * altitudeFt)
}
