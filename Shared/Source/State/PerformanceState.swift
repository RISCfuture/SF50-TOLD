import Foundation
import Combine
import Defaults
import CoreData
import OSLog
import UIKit

class PerformanceState: ObservableObject {
    var operation: Operation

    @Published var date = Date()
    @Published var airportID: String? = nil
    @Published var airport: Airport? = nil
    @Published var runway: Runway? = nil
    @Published var flaps: FlapSetting!
    @Published private(set) var weatherState = WeatherState()
    @Published var weight = 0.0

    @Published private(set) var takeoffRoll: Interpolation? = nil
    @Published private(set) var takeoffDistance: Interpolation? = nil
    @Published private(set) var climbGradient: Interpolation? = nil
    @Published private(set) var climbRate: Interpolation? = nil
    @Published private(set) var landingRoll: Interpolation? = nil
    @Published private(set) var landingDistance: Interpolation? = nil
    @Published private(set) var vref: Interpolation? = nil
    @Published private(set) var meetsGoAroundClimbGradient: Bool? = nil
    @Published private(set) var notamCount = 0

    @Published private(set) var error: Swift.Error? = nil
    
    var fuelDefault: Defaults.Key<Double> {
        switch operation {
            case .takeoff: return .takeoffFuel
            case .landing: return .landingFuel
        }
    }

    private var emptyWeight: Double { Defaults[.emptyWeight] }
    private var fuelDensity: Double { Defaults[.fuelDensity] }
    private var payload: Double { Defaults[.payload] }
    private var fuel: Double { Defaults[fuelDefault] }
    private var updatedThrustSchedule: Bool { Defaults[.updatedThrustSchedule] }

    private var cancellables = Set<AnyCancellable>()

    private static let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "PerformanceState")

    var elevation: Double {
        Double(runway?.elevation ?? airport?.elevation ?? 0.0)
    }

    var offscale: Offscale {
        var cum: Offscale = .none
        let fields: Array<Interpolation?>
        
        switch operation {
            case .takeoff:
                fields = [takeoffRoll, takeoffDistance, climbGradient, climbRate]
            case .landing:
                fields = [landingRoll, landingDistance, vref]
        }

        for field in fields {
            guard case let .value(_, offscale) = field else { continue }
            switch offscale {
                case .high: return .high
                case .low: if cum == .none { cum = .low }
                default: break
            }
        }

        return cum
    }

    var requiredClimbGradient: Double {
        guard let takeoffRollInterp = takeoffRoll,
              let runwayLength = runway?.takeoffRun,
              let obstacleHeight = runway?.notam?.obstacleHeight,
              let obstacleDistance = runway?.notam?.obstacleDistance else { return 0 }
        guard case let .value(takeoffRoll, _) = takeoffRollInterp else { return 0 }

        let distanceFromRunwayStart = obstacleDistance + Double(runwayLength)
        let distanceFromLiftoffPoint = distanceFromRunwayStart - takeoffRoll

        return (obstacleHeight / distanceFromLiftoffPoint) * 6076
    }

    private var defaultKey: Defaults.Key<String?> {
        switch operation {
            case .takeoff: return .takeoffAirport
            case .landing: return .landingAirport
        }
    }

    init(operation: Operation) {
        self.operation = operation
        switch operation {
            case .takeoff: self.flaps = .flaps50
            case .landing: self.flaps = .flaps100
        }

        airportID = Defaults[defaultKey]
        $airportID.receive(on: DispatchQueue.main).sink { Defaults[self.defaultKey] = $0 }.store(in: &cancellables)
        $airportID.tryMap { ID -> Airport? in
            guard let ID = ID else { return nil }
            return try self.findAirport(id: ID)
        }.catch { error -> AnyPublisher<Airport?, Never> in
            self.error = error
            return Just(nil).eraseToAnyPublisher()
        }.receive(on: DispatchQueue.main)
            .assign(to: &$airport)
        
        // refresh airport and runway when new cycle is loaded
        Defaults.publisher(.lastCycleLoaded).tryMap { _ in
            guard let ID = self.airportID else { return nil }
            return try self.findAirport(id: ID)
        }.catch { error -> AnyPublisher<Airport?, Never> in
            self.error = error
            return Just(nil).eraseToAnyPublisher()
        }.receive(on: DispatchQueue.main)
            .assign(to: &$airport)

        // update runway, weather, and performance when airport changes
        $airport.sink { airport in
            self.runway = nil
            self.updatePerformanceData(runway: nil, weather: self.weatherState.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
            if let airportID = airport?.id {
                Defaults[.recentAirports] = Array((Defaults[.recentAirports] + [airportID])
                    .uniqued()
                    .prefix(10))
            }
        }.store(in: &cancellables)

        $runway.sink { runway in
            guard let runway = runway, let notam = runway.notam else {
                self.notamCount = 0
                return
            }
            self.notamCount = notam.notamCountFor(self.operation)
        }.store(in: &cancellables)

        weight = emptyWeight + payload + fuel*fuelDensity
        initializeModel()

        updateWeight()
        updatePerformanceWhenConditionsChange()
        updatePerformanceWhenSafetyFactorChanges()
        updateNOTAMCountWhenNOTAMChanges()
    }

    deinit {
        for c in cancellables { c.cancel() }
    }

    private func initializeModel() {
        let model: PerformanceModel = updatedThrustSchedule ?
            PerformanceModelG2Plus(runway: runway, weather: weatherState.weather, weight: weight, flaps: flaps) :
        PerformanceModelG1(runway: runway, weather: weatherState.weather, weight: weight, flaps: flaps)
        takeoffRoll = model.takeoffRoll
        takeoffDistance = model.takeoffDistance
        climbGradient = model.takeoffClimbGradient
        climbRate = model.takeoffClimbRate
        landingRoll = model.landingRoll
        landingDistance = model.landingDistance
        vref = model.vref
        meetsGoAroundClimbGradient = model.meetsGoAroundClimbGradient
    }

    private func updateWeight() {
        Publishers.CombineLatest4(Defaults.publisher(.emptyWeight).map(\.newValue),
                                  Defaults.publisher(.payload).map(\.newValue),
                                  Defaults.publisher(.fuelDensity).map(\.newValue),
                                  Defaults.publisher(fuelDefault).map(\.newValue))
            .map { (emptyWeight: Double, payload: Double, fuelDensity: Double, fuel: Double) -> Double in
                emptyWeight + payload + fuel*fuelDensity
            }.receive(on: DispatchQueue.main).assign(to: &$weight)
    }

    private func updatePerformanceWhenConditionsChange() {
        Publishers.CombineLatest3($runway, $weatherState, $weight)
            .sink { runway, weatherState, weight in
                self.updatePerformanceData(runway: runway, weather: weatherState.weather, weight: weight, flaps: self.flaps, takeoff: true, landing: false)
            }.store(in: &cancellables)
        Publishers.CombineLatest4($runway, $weatherState, $weight, $flaps)
            .sink { runway, weatherState, weight, flaps in
                self.updatePerformanceData(runway: runway, weather: weatherState.weather, weight: weight, flaps: flaps, takeoff: false, landing: true)
            }.store(in: &cancellables)
    }

    private func updatePerformanceWhenSafetyFactorChanges() {
        Defaults.publisher(.safetyFactor).sink { _ in
            self.updatePerformanceData(runway: self.runway, weather: self.weatherState.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
        }.store(in: &cancellables)
        
        Defaults.publisher(.updatedThrustSchedule).sink { _ in
            self.updatePerformanceData(runway: self.runway, weather: self.weatherState.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
        }.store(in: &cancellables)
    }

    private func updatePerformanceData(runway: Runway?, weather: Weather, weight: Double, flaps: FlapSetting?, takeoff: Bool, landing: Bool) {
        let model: PerformanceModel = updatedThrustSchedule ?
            PerformanceModelG2Plus(runway: runway, weather: weather, weight: weight, flaps: flaps) :
            PerformanceModelG1(runway: runway, weather: weather, weight: weight, flaps: flaps)
        if takeoff {
            let takeoffRoll = model.takeoffRoll
            let takeoffDistance = model.takeoffDistance
            let climbGradient = model.takeoffClimbGradient
            let climbRate = model.takeoffClimbRate
            DispatchQueue.main.async {
                self.takeoffRoll = takeoffRoll
                self.takeoffDistance = takeoffDistance
                self.climbGradient = climbGradient
                self.climbRate = climbRate
            }
        }

        if landing {
            let landingRoll = model.landingRoll
            let landingDistance = model.landingDistance
            let vref = model.vref
            let meetsGoAroundClimbGradient = model.meetsGoAroundClimbGradient
            DispatchQueue.main.async {
                self.landingRoll = landingRoll
                self.landingDistance = landingDistance
                self.vref = vref
                self.meetsGoAroundClimbGradient = meetsGoAroundClimbGradient
            }
        }
    }

    private func updateNOTAMCountWhenNOTAMChanges() {
        NotificationCenter.default.publisher(for: Notification.Name.NSManagedObjectContextObjectsDidChange)
            .filter { notification in
                let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
                let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
                let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
                return inserted.union(updated).union(deleted).contains { $0.entity == NOTAM.entity() }
            }.receive(on: DispatchQueue.main)
            .sink(receiveValue: { notam in
                guard let runway = self.runway, let notam = runway.notam else {
                    self.notamCount = 0
                    return
                }
                self.notamCount = notam.notamCountFor(self.operation)

                self.updatePerformanceData(runway: runway, weather: self.weatherState.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
            }).store(in: &cancellables)
    }

    private func findAirport(id: String) throws -> Airport? {
        let results = try PersistentContainer.shared.viewContext.fetch(Airport.byIDRequest(id: id))
        guard results.count == 1 else {
            Self.logger.error("Couldn't find exactly one airport with ID '\(id)'")
            return nil
        }
        return results[0]
    }
}

