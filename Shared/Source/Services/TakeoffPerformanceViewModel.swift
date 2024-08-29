import Foundation
import SwiftData
import Combine
import Dispatch

@MainActor @Observable class TakeoffPerformanceViewModel: TakeoffPerformanceServiceDelegate {
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
    private(set) var takeoffRoll: Interpolation? = nil
    private(set) var takeoffDistance: Interpolation? = nil
    private(set) var climbGradient: Interpolation? = nil
    private(set) var climbRate: Interpolation? = nil
    private(set) var notamCount = 0
    private(set) var error: Swift.Error? = nil
    private(set) var requiredClimbGradient = 0.0
    
    private let service: TakeoffPerformanceService
    private var cancellable: AnyCancellable? = nil
    
    required init(modelContext: ModelContext) {
        service = .init(modelContainer: modelContext.container)
        Task { await service.setDelegate(self) }
    }
    
    func inputsChanged() {
        Task { await service.updateInputs(date: date, runwayID: runwayID, flaps: flaps, weather: weather) }
    }
    
    func serviceDidRecompute(_ service: TakeoffPerformanceService) async {
        self.takeoffRoll = await service.takeoffRoll
        self.takeoffDistance = await service.takeoffDistance
        self.climbGradient = await service.climbGradient
        self.climbRate = await service.climbRate
        self.notamCount = await service.notamCount
        self.error = await service.error
        self.requiredClimbGradient = await service.requiredClimbGradient
    }
}
