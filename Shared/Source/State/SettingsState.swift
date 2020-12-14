import Foundation
import Combine
import Defaults

class SettingsState: ObservableObject {
    @Published var emptyWeight = Defaults[.emptyWeight]
    @Published var fuelDensity = Defaults[.fuelDensity]
    @Published var safetyFactor = Defaults[.safetyFactor]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $emptyWeight.sink { Defaults[.emptyWeight] = $0 }.store(in: &cancellables)
        $fuelDensity.sink { Defaults[.fuelDensity] = $0 }.store(in: &cancellables)
        $safetyFactor.sink { Defaults[.safetyFactor] = $0 }.store(in: &cancellables)
    }
}
