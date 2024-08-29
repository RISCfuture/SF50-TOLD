import Foundation
import Defaults
import Logging
import SwiftData

protocol LandingPerformanceServiceDelegate: AnyObject {
    func serviceDidRecompute(_ service: LandingPerformanceService) async
}

actor LandingPerformanceService {
    private let modelContext: ModelContext
    weak var delegate: LandingPerformanceServiceDelegate? = nil
    
    // MARK: Inputs
    var date = Date()
    var runwayID: PersistentIdentifier? = nil
    var flaps: FlapSetting? = nil
    var weather: Weather? = nil
    
    // MARK: Outputs
    private(set) var landingRoll: Interpolation? = nil
    private(set) var landingDistance: Interpolation? = nil
    private(set) var vref: Interpolation? = nil
    private(set) var meetsGoAroundClimbGradient: Bool? = nil
    private(set) var notamCount = 0
    private(set) var error: Swift.Error? = nil
    
    // MARK: Internal
    private var defaultsTask: Task<Void, Never>?
    private static let logger = Logger(label: "codes.tim.SF50-TOLD.PerformanceState")
    private let context: ModelContext
    
    private var emptyWeight: Double { Defaults[.emptyWeight] }
    private var fuelDensity: Double { Defaults[.fuelDensity] }
    private var payload: Double { Defaults[.payload] }
    private var fuel: Double { Defaults[.takeoffFuel] }
    private var updatedThrustSchedule: Bool { Defaults[.updatedThrustSchedule] }
    var weight: Double { emptyWeight + payload + fuel*fuelDensity }
    
    var offscale: Offscale {
        var cum: Offscale = .none
        
        for field in [landingRoll, landingDistance, vref] {
            guard case let .value(_, offscale) = field else { continue }
            switch offscale {
                case .high: return .high
                case .low: if cum == .none { cum = .low }
                default: break
            }
        }
        
        return cum
    }
    
    init(modelContainer: ModelContainer) {
        context = ModelContext(modelContainer)
        Task { await start() }
    }
     
    private func start() {
        defaultsTask = Task {
            for await _ in Defaults.updates([
                .emptyWeight,
                .fuelDensity,
                .payload,
                .takeoffFuel,
                .updatedThrustSchedule,
                .safetyFactor
            ]) { self.updatePerformanceData() }
        }
    }
    
    deinit {
        defaultsTask?.cancel()
    }
    
    func setDelegate(_ delegate: LandingPerformanceServiceDelegate) {
        self.delegate = delegate
    }
    
    func updateInputs(date: Date, runwayID: PersistentIdentifier?, flaps: FlapSetting?, weather: Weather?) {
        self.date = date
        self.runwayID = runwayID
        self.flaps = flaps
        self.weather = weather
        updatePerformanceData()
    }
    
    func updatePerformanceData() {
        defer {
            Task { await delegate?.serviceDidRecompute(self) }
        }
        
        do {
            guard let runway = try findRunway(),
                  let weather = weather,
                  let flaps = flaps else {
                landingRoll = nil
                landingDistance = nil
                vref = nil
                meetsGoAroundClimbGradient = nil
                notamCount = 0
                error = nil
                return
            }
            
            let model: PerformanceModel = updatedThrustSchedule ?
            PerformanceModelG2Plus(runway: runway, weather: weather, weight: weight, flaps: flaps) :
            PerformanceModelG1(runway: runway, weather: weather, weight: weight, flaps: flaps)
            
            landingRoll = model.landingRoll
            landingDistance = model.landingDistance
            vref = model.vref
            meetsGoAroundClimbGradient = model.meetsGoAroundClimbGradient
            notamCount = runway.notam?.notamCountFor(.landing) ?? 0
        } catch {
            landingRoll = nil
            landingDistance = nil
            vref = nil
            meetsGoAroundClimbGradient = nil
            notamCount = 0
            self.error = error
            Self.logger.error("findRunway(): error", metadata: ["error": "\(error)", "runwayID": "\(runwayID.debugDescription)"])
        }
    }
    
    private func findRunway() throws -> Runway? {
        guard let runwayID = runwayID else { return nil }
        let predicate = #Predicate<Runway> { runway in runway.id == runwayID }
        
        return try context.fetch(.init(predicate: predicate)).first
    }
}
