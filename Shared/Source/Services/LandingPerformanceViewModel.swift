import Foundation
import SwiftData
import Combine
import Dispatch

@MainActor @Observable class LandingPerformanceViewModel: LandingPerformanceServiceDelegate {
    //MARK: Inputs
    var date = Date() {
        didSet { inputsChanged() }
    }
    var runwayID: PersistentIdentifier? = nil {
        didSet { inputsChanged() }
    }
    var flaps: FlapSetting? = nil {
        didSet { inputsChanged() }
    }
    var weather: Weather? = nil {
        didSet { inputsChanged() }
    }
    
    // MARK: Outputs
    private(set) var landingRoll: Interpolation? = nil
    private(set) var landingDistance: Interpolation? = nil
    private(set) var vref: Interpolation? = nil
    private(set) var meetsGoAroundClimbGradient: Bool? = nil
    private(set) var notamCount = 0
    private(set) var error: Swift.Error? = nil
    private(set) var requiredClimbGradient = 0.0
    
    private let service: LandingPerformanceService
    private var cancellable: AnyCancellable? = nil
    
    required init(modelContext: ModelContext) {
        service = .init(modelContainer: modelContext.container)
        Task { await service.setDelegate(self) }
    }
    
    func inputsChanged() {
        Task { await service.updateInputs(date: date, runwayID: runwayID, flaps: flaps, weather: weather) }
    }
    
    func serviceDidRecompute(_ service: LandingPerformanceService) async {
        self.landingRoll = await service.landingRoll
        self.landingDistance = await service.landingDistance
        self.vref = await service.vref
        self.meetsGoAroundClimbGradient = await service.meetsGoAroundClimbGradient
        self.notamCount = await service.notamCount
        self.error = await service.error
    }
}
