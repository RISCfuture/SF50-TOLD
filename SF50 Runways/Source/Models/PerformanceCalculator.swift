import Combine
import CoreData
import Defaults
import Foundation
import Logging
import SwiftMETAR

private let ISA = Weather(wind: .calm,
                          temperature: .ISA,
                          altimeter: standardSLP,
                          source: .ISA)

class PerformanceCalculator {
    private static let logger = Logger(label: "codes.tim.SF50-TOLD.PerformanceCalculator")

    private lazy var nearestAirportPublisher = NearestAirportPublisher() // don't initialize it until we need location info
    private var cancellables = Set<AnyCancellable>()
    private var takeoffWeight: Double {
        Defaults[.emptyWeight]
        + Defaults[.payload]
        + Defaults[.fuelDensity] * Defaults[.takeoffFuel]
    }

    private var selectedAirport: Airport? {
        guard let airportID = Defaults[.takeoffAirport] else { return nil }
        do {
            let results = try PersistentContainer.shared.viewContext.fetch(Airport.byIDRequest(id: airportID))
            guard results.count == 1 else {
                Self.logger.error("selectedAirport: couldn't find exactly one airport with ID", metadata: ["id": "\(airportID)"])
                return nil
            }
            return results[0]
        } catch {
            Self.logger.error("selectedAirport: error", metadata: ["error": "\(error.localizedDescription)"])
            return nil
        }
    }

    func generateEntries(completion: @escaping ((Array<RunwayWidgetEntry>) -> Void)) {
        Task.detached {
            guard let airport = self.selectedAirport else {
                completion([.empty()])
                return
            }
            let (metar, taf) = await WeatherService.instance.loadWeatherFor(airport: airport)
            completion(self.entriesFor(airport: airport, metar: metar, taf: taf))
        }
    }

    private func loadNearestAirport(in context: NSManagedObjectContext) async throws -> Airport? {
        nearestAirportPublisher.request()

        guard let airportID = await nearestAirportPublisher.findNearestAirportID() else { return nil }

        let fetchRequest = Airport.fetchRequest()
        fetchRequest.predicate = .init(format: "id == ?", airportID)
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    private func entriesFor(airport: Airport, metar: METAR?, taf: TAF?) -> [RunwayWidgetEntry] {
        var dates = [Date()]
        if let taf {
            dates.append(contentsOf: self.datesFrom(taf: taf))
        }

        return dates.map { date -> RunwayWidgetEntry in
            if let weatherValues = WeatherValues(date: date, observation: metar, forecast: taf) {
                let weather = Weather(wind: weatherValues.wind,
                                      temperature: weatherValues.temperature,
                                      altimeter: weatherValues.altimeter,
                                      source: .downloaded)
                return RunwayWidgetEntry(date: date,
                                         airport: airport,
                                         weather: weather,
                                         takeoffDistances: self.runwayResults(airport: airport, weather: weather))
            }
            return RunwayWidgetEntry(date: date,
                                     airport: airport,
                                     weather: ISA,
                                     takeoffDistances: self.runwayResults(airport: airport, weather: ISA))
        }
    }

    private func runwayResults(airport: Airport, weather: Weather) -> [String: Interpolation] {
        airport.runways!.reduce(into: [String: Interpolation]()) { dict, runway in
            let runway = runway as! Runway
            let model = self.performanceModel(runway: runway, weather: weather)
            dict[runway.name!] = model.takeoffDistance
        }
    }

    private func datesFrom(taf: TAF) -> [Date] {
        taf.groups.compactMap { group in
            switch group.period {
                case let .becoming(period): return period.start.date
                case let .from(from): return from.date
                case let .probability(_, period): return period.start.date
                case let .range(period): return period.start.date
                case let .temporary(period): return period.start.date
            }
        }
    }

    private func performanceModel(runway: Runway, weather: Weather) -> PerformanceModel {
        Defaults[.updatedThrustSchedule]
        ? PerformanceModelG2Plus(runway: runway, weather: weather, weight: takeoffWeight, flaps: .flaps50)
        : PerformanceModelG1(runway: runway, weather: weather, weight: takeoffWeight, flaps: .flaps50)
    }

    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
}
