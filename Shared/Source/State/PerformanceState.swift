import Foundation
import Combine
import Defaults

class PerformanceState: ObservableObject {
    @Published var date = Date()
    @Published var airport: Airport? = nil
    @Published var runway: Runway? = nil
    @Published var flaps: FlapSetting? = nil
    var weatherState = WeatherState()
    @Published var weather: Weather
    @Published var fuel = 0.0
    @Published var weight = 0.0
    
    @Published var takeoffRoll: Interpolation? = nil
    @Published var takeoffDistance: Interpolation? = nil
    @Published var climbGradient: Interpolation? = nil
    @Published var climbRate: Interpolation? = nil
    @Published var landingRoll: Interpolation? = nil
    @Published var landingDistance: Interpolation? = nil
    @Published var vref: Interpolation? = nil
    @Published var meetsGoAroundClimbGradient: Bool? = nil
    
    private var emptyWeight: Double { Defaults[.emptyWeight] }
    private var fuelDensity: Double { Defaults[.fuelDensity] }
    private var payload: Double { Defaults[.payload] }
    
    private var cancellables = Set<AnyCancellable>()
    
    var elevation: Double {
        Double(runway?.elevation ?? airport?.elevation ?? 0.0)
    }
    
    init() {
        weather = weatherState.weather

        // update runway, weather, and performance when airport changes
        $airport.sink { airport in
            self.runway = nil
            self.updatePerformanceData(runway: nil, weather: self.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
        }.store(in: &cancellables)
        
        weight = emptyWeight + payload + fuel*fuelDensity
        initializeModel()
        
        updateWeight()
        updatePerformanceWhenConditionsChange()
        updatePerformanceWhenSafetyFactorChanges()
        
        weatherState.objectWillChange.sink {
            // next runloop, wx state is changed
            RunLoop.main.perform { [weak self] in
                guard let this = self else { return }
                this.weather = this.weatherState.weather
            }
        }.store(in: &cancellables)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    private func initializeModel() {
        let model = PerformanceModel(runway: runway, weather: weather, weight: weight, flaps: flaps)
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
                                  $fuel)
            .map { (emptyWeight: Double, payload: Double, fuelDensity: Double, fuel: Double) -> Double in
                emptyWeight + payload + fuel*fuelDensity
            }.receive(on: RunLoop.main).assign(to: &$weight)
    }
    
    private func updatePerformanceWhenConditionsChange() {
        Publishers.CombineLatest3($runway, $weather, $weight)
            .sink { runway, weather, weight in
                self.updatePerformanceData(runway: runway, weather: weather, weight: weight, flaps: self.flaps, takeoff: true, landing: false)
            }.store(in: &cancellables)
        Publishers.CombineLatest4($runway, $weather, $weight, $flaps)
            .sink { runway, weather, weight, flaps in
                self.updatePerformanceData(runway: runway, weather: weather, weight: weight, flaps: flaps, takeoff: false, landing: true)
            }.store(in: &cancellables)
    }
    
    private func updatePerformanceWhenSafetyFactorChanges() {
        Defaults.publisher(.safetyFactor).sink { _ in
            self.updatePerformanceData(runway: self.runway, weather: self.weather, weight: self.weight, flaps: self.flaps, takeoff: true, landing: true)
        }.store(in: &cancellables)
    }
    
    private func updatePerformanceData(runway: Runway?, weather: Weather, weight: Double, flaps: FlapSetting?, takeoff: Bool, landing: Bool) {
        let model = PerformanceModel(runway: runway, weather: weather, weight: weight, flaps: flaps)
        if takeoff {
            let takeoffRoll = model.takeoffRoll
            let takeoffDistance = model.takeoffDistance
            let climbGradient = model.takeoffClimbGradient
            let climbRate = model.takeoffClimbRate
            RunLoop.main.perform {
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
            RunLoop.main.perform {
                self.landingRoll = landingRoll
                self.landingDistance = landingDistance
                self.vref = vref
                self.meetsGoAroundClimbGradient = meetsGoAroundClimbGradient
            }
        }
    }
}

