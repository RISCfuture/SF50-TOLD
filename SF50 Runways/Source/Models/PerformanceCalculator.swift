import Foundation
import Combine
import CoreData
import OSLog
import SwiftMETAR
import Defaults

fileprivate let ISA = Weather(wind: .calm,
                              temperature: .ISA,
                              altimeter: standardSLP,
                              source: .ISA)

class PerformanceCalculator {
    private let airportSelection: AirportSelection
    private lazy var nearestAirportPublisher = NearestAirportPublisher() // don't initialize it until we need location info
    private static let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "PerformanceCalculator")
    
    private var cancellables = Set<AnyCancellable>()
    
    private var takeoffWeight: Double {
        Defaults[.emptyWeight]
        + Defaults[.payload]
        + Defaults[.fuelDensity]*Defaults[.takeoffFuel]
    }
    
    private var selectedAirport: Airport? {
        guard let airportID = Defaults[.takeoffAirport] else { return nil }
        do {
            let results = try PersistentContainer.shared.viewContext.fetch(Airport.byIDRequest(id: airportID))
            guard results.count == 1 else {
                Self.logger.error("Couldn't find exactly one airport with ID '\(airportID)'")
                return nil
            }
            return results[0]
        } catch (let error) {
            Self.logger.error("Error while loading selected airport: \(error.localizedDescription))")
            return nil
        }
    }
    
    init(airport: AirportSelection) {
        airportSelection = airport
    }
    
    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    func generateEntries(completion: @escaping ((Array<RunwayWidgetEntry>) -> Void)) {
        Task.detached {
            do {
                let context = PersistentContainer.shared.newBackgroundContext()
                guard let airport = try await self.loadAirport(in: context) else {
                    completion([])
                    return
                }
                let (metar, taf) = await self.weatherFor(airport: airport)
                completion(self.entriesFor(airport: airport, metar: metar, taf: taf))
            } catch {
                Self.logger.error("\(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    private func loadAirport(in context: NSManagedObjectContext) async throws -> Airport? {
        switch self.airportSelection {
            case .nearest:
                return try await self.loadNearestAirport(in: context)
            case .selected:
                return self.selectedAirport
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
    
    private func weatherFor(airport: Airport) async -> (METAR?, TAF?) {
        await withCheckedContinuation { continuation in
            WeatherService.instance.conditionsFor(airport: airport, force: true)
                .sink { state in
                    switch state {
                        case .loading:
                            continuation.resume(returning: (nil, nil))
                        case let .finished(pair):
                            let metar: METAR?
                            let taf: TAF?
                            switch pair.0 {
                                case let .some(metar_): metar = metar_
                                default: metar = nil
                            }
                            switch pair.1 {
                                case let .some(taf_): taf = taf_
                                default: taf = nil
                            }
                            continuation.resume(returning: (metar, taf))
                    }
                }.store(in: &cancellables)
        }
    }
    
    private func entriesFor(airport: Airport, metar: METAR?, taf: TAF?) -> Array<RunwayWidgetEntry> {
        var dates = [Date()]
        if let taf = taf {
            dates.append(contentsOf: self.datesFrom(taf: taf))
        }
        
        let datapoints = dates.map { date -> RunwayWidgetEntry in
            if let weatherValues = WeatherValues(date: date, observation: metar, forecast: taf) {
                let weather = Weather(wind: weatherValues.wind,
                                      temperature: weatherValues.temperature,
                                      altimeter: weatherValues.altimeter,
                                      source: .downloaded)
                return RunwayWidgetEntry(date: date,
                                         airport: airport,
                                         weather: weather,
                                         takeoffDistances: self.runwayResults(airport: airport, weather: weather))
            } else {
                return RunwayWidgetEntry(date: date,
                                         airport: airport,
                                         weather: ISA,
                                         takeoffDistances: self.runwayResults(airport: airport, weather: ISA))
            }
        }
        
        return datapoints
    }
    
    private func runwayResults(airport: Airport, weather: Weather) -> Dictionary<String, Interpolation> {
        airport.runways!.reduce(Dictionary<String, Interpolation>()) { dict, runway in
            let runway = runway as! Runway
            var dict = dict
            let model = self.performanceModel(runway: runway, weather: weather)
            dict[runway.name!] = model.takeoffDistance
            return dict
        }
    }
    
    private func datesFrom(taf: TAF) -> Array<Date> {
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
}
