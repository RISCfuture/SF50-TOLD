import Foundation
import Combine
import Defaults

class PerformanceState: ObservableObject {
    @Published var date = Date()
    @Published var airport: Airport? = nil
    @Published var runway: Runway? = nil
    @Published var airConditioning = false
    var weatherState = WeatherState()
    @Published var weather: Weather
    @Published var fuel = 0.0
    @Published var weight = 0.0
    
    @Published var takeoffRoll: Interpolation? = nil
    @Published var takeoffDistance: Interpolation? = nil
    @Published var climbSpeed: Interpolation? = nil
    @Published var climbGradient: Interpolation? = nil
    @Published var climbRate: Interpolation? = nil
    @Published var landingRoll: Interpolation? = nil
    @Published var landingDistance: Interpolation? = nil
    
    @Published var maxFuel: Double
    
    private var emptyWeight: Double { Defaults[.emptyWeight] }
    private var fuelDensity: Double { Defaults[.fuelDensity] }
    private var payload: Double { Defaults[.payload] }
    
    private var cancellables = Set<AnyCancellable>()
    
    var elevation: Double {
        Double(runway?.elevation ?? airport?.elevation ?? 0.0)
    }
    
    var offscale: Offscale {
        var cum: Offscale = .none
        
        let fields = [
            takeoffRoll,
            takeoffDistance,
            climbSpeed,
            climbGradient,
            climbRate,
            landingRoll,
            landingDistance,
        ]
        
        for field in fields {
            switch field {
                case .value(_, let offscale):
                    switch offscale {
                        case .high: return .high
                        case .low: if cum == .none { cum = .low }
                        default: break
                    }
                default: break
            }
        }
        
        return cum
    }
    
    init() {
        weather = weatherState.weather
        
        if Defaults[.g3Wing] { maxFuel = g3MaxFuel }
        else { maxFuel = g2MaxFuel }
        Defaults.publisher(.g3Wing).map { change in
            if change.newValue { return g3MaxFuel }
            else { return g2MaxFuel }
        }.assign(to: &$maxFuel)

        // update runway, weather, and performance when airport changes
        $airport.sink { airport in
            self.runway = nil
            self.updatePerformanceData(runway: nil, weather: self.weather, weight: self.weight, ac: self.airConditioning, takeoff: true, landing: true)
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
        let model = PerformanceModel(runway: runway, weather: weather, weight: weight, ac: airConditioning)
        takeoffRoll = model.takeoffRoll
        takeoffDistance = model.takeoffDistance
        climbSpeed = model.climbSpeed
        climbGradient = model.takeoffClimbGradient
        climbRate = model.takeoffClimbRate
        landingRoll = model.landingRoll
        landingDistance = model.landingDistance
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
        Publishers.CombineLatest4($runway, $weather, $weight, $airConditioning)
            .sink { runway, weather, weight, ac in
                self.updatePerformanceData(runway: runway, weather: weather, weight: weight, ac: ac, takeoff: true, landing: false)
            }.store(in: &cancellables)
        Publishers.CombineLatest3($runway, $weather, $weight)
            .sink { runway, weather, weight in
                self.updatePerformanceData(runway: runway, weather: weather, weight: weight, ac: self.airConditioning, takeoff: false, landing: true)
            }.store(in: &cancellables)
    }
    
    private func updatePerformanceWhenSafetyFactorChanges() {
        Defaults.publisher(.safetyFactor).sink { _ in
            self.updatePerformanceData(runway: self.runway, weather: self.weather, weight: self.weight, ac: self.airConditioning, takeoff: true, landing: true)
        }.store(in: &cancellables)
    }
    
    private func updatePerformanceData(runway: Runway?, weather: Weather, weight: Double, ac: Bool, takeoff: Bool, landing: Bool) {
        let model = PerformanceModel(runway: runway, weather: weather, weight: weight, ac: ac)
        if takeoff {
            let takeoffRoll = model.takeoffRoll
            let takeoffDistance = model.takeoffDistance
            let climbSpeed = model.climbSpeed
            let climbGradient = model.takeoffClimbGradient
            let climbRate = model.takeoffClimbRate
            RunLoop.main.perform {
                self.takeoffRoll = takeoffRoll
                self.takeoffDistance = takeoffDistance
                self.climbSpeed = climbSpeed
                self.climbGradient = climbGradient
                self.climbRate = climbRate
            }
        }
        
        if landing {
            let landingRoll = model.landingRoll
            let landingDistance = model.landingDistance
            RunLoop.main.perform {
                self.landingRoll = landingRoll
                self.landingDistance = landingDistance
            }
        }
    }
}

