import Combine
import Defaults
import Foundation
import SF50_Shared
import SwiftData

@MainActor
class PerformanceCalculator {
  private var modelContext: ModelContext

  private var takeoffWeight: Measurement<UnitMass> {
    let emptyWeight = Defaults[.emptyWeight]
    let payload = Defaults[.payload]
    let fuel = Defaults[.takeoffFuel]
    let fuelDensity = Defaults[.fuelDensity]

    let fuelWeight = fuel * fuelDensity
    return emptyWeight + payload + fuelWeight
  }

  private var selectedAirport: Airport? {
    guard let airportID = Defaults[.takeoffAirport] else { return nil }

    let fetchDescriptor = FetchDescriptor<Airport>(
      predicate: #Predicate { $0.recordID == airportID }
    )

    do {
      let airports = try modelContext.fetch(fetchDescriptor)
      return airports.first
    } catch {
      return nil
    }
  }

  init() {
    let schema = Schema([
      Airport.self,
      Runway.self,
      NOTAM.self
    ])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      groupContainer: .identifier("group.codes.tim.TOLD")
    )

    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      self.modelContext = ModelContext(container)
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }

  func generateEntries() async -> [RunwayWidgetEntry] {
    guard let airport = selectedAirport else {
      return [.empty()]
    }

    let conditions = await loadWeatherFor(airport: airport)

    // If we couldn't load weather, show the airport but with unknown performance values
    if conditions == nil {
      return [
        RunwayWidgetEntry(
          date: Date(),
          airport: airport,
          conditions: nil,
          takeoffDistances: nil
        )
      ]
    }

    return entriesFor(airport: airport, conditions: conditions)
  }

  private func loadWeatherFor(airport: Airport) async -> Conditions? {
    // Try to load METAR data from WeatherLoader
    await WeatherLoader.shared.load(force: true)
    let key = WeatherLoader.Key(airport: airport, time: Date())
    let stream = await WeatherLoader.shared.streamConditions(for: key)

    // Get the first available conditions
    for await loadable in stream {
      switch loadable {
        case .value(let conditions):
          return conditions
        case .loading, .notLoaded, .error:
          continue
      }
    }

    return nil
  }

  private func entriesFor(airport: Airport, conditions: Conditions?) -> [RunwayWidgetEntry] {
    let date = Date()

    // Only calculate takeoff distances if we have valid conditions
    guard let conditions else {
      return [
        RunwayWidgetEntry(
          date: date,
          airport: airport,
          conditions: nil,
          takeoffDistances: nil
        )
      ]
    }

    let takeoffDistances = runwayResults(airport: airport, conditions: conditions)
    return [
      RunwayWidgetEntry(
        date: date,
        airport: airport,
        conditions: conditions,
        takeoffDistances: takeoffDistances
      )
    ]
  }

  private func runwayResults(airport: Airport, conditions: Conditions) -> [String: Value<
    Measurement<UnitLength>
  >] {
    var results: [String: Value<Measurement<UnitLength>>] = [:]

    let configuration = Configuration(weight: takeoffWeight, flapSetting: .flaps50)
    let calculationService = DefaultPerformanceCalculationService.shared
    let safetyFactor = Defaults[.safetyFactor]
    let useRegressionModel = Defaults[.useRegressionModel]
    let updatedThrustSchedule = Defaults[.updatedThrustSchedule]

    for runway in airport.runways {
      let runwaySnapshot = RunwayInput(from: runway, airport: airport)
      let model = calculationService.createPerformanceModel(
        conditions: conditions,
        configuration: configuration,
        runway: runwaySnapshot,
        notam: runwaySnapshot.notam,
        useRegressionModel: useRegressionModel,
        updatedThrustSchedule: updatedThrustSchedule
      )

      do {
        let takeoffResults = try calculationService.calculateTakeoff(
          for: model,
          safetyFactor: safetyFactor
        )
        results[runway.name] = takeoffResults.takeoffDistance
      } catch {
        results[runway.name] = .invalid
      }
    }

    return results
  }
}
