import Foundation
import Combine
import Dispatch
import OSLog
import CSV
import SwiftMETAR

fileprivate let loadingQueue = DispatchQueue(label: "codes.tim.SF50-TOLD.LazyLoadingPublisher", qos: .utility, attributes: .concurrent)

fileprivate class LazyLoadingPublisher<T>: ObservableObject {
    typealias Processor = (_ data: Data) throws -> T
    
    @Published var loading = false
    private var loadingMutex = DispatchSemaphore(value: 1)
    
    private let url: URL
    private let timeout: TimeInterval
    private let process: Processor
    
    private let value = CurrentValueSubject<T?, Swift.Error>(nil)
    lazy var stream = value.filter { $0 != nil }.map { $0! }.eraseToAnyPublisher()
    
    private var lastLoaded: Date
    private var cancellables = Set<AnyCancellable>()
    
    private var sessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.timeoutIntervalForRequest = 2
        config.timeoutIntervalForResource = 2
        return config
    }
    
    init(url: URL, timeout: TimeInterval, process: @escaping Processor) {
        self.url = url
        self.timeout = timeout
        self.lastLoaded = Date()
        self.process = process
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    func load(force: Bool = false) {
        if !force && value.value != nil && lastLoaded.timeIntervalSinceNow < timeout {
            return
        }
        
        loadingQueue.async {
            let result = self.loadingMutex.wait(timeout: DispatchTime.now())
            if result == .timedOut { return }
            self.loading = true
            
            let session = URLSession(configuration: self.sessionConfiguration)
            session.dataTaskPublisher(for: self.url)
                .tryMap { data, response -> T in try self.process(data) }
                .sink(receiveCompletion: { result in
                    switch result {
                        case .finished:
                            self.lastLoaded = Date()
                        case .failure(let error):
                            self.value.send(completion: .failure(error))
                    }
                    self.loading = false
                    self.loadingMutex.signal()
                }, receiveValue: { value in
                    self.value.send(value)
                })
                .store(in: &self.cancellables)
        }
    }
}

enum ParseResult<T, E: Swift.Error> {
    case success(_ value: T?)
    case failure(_ error: E, raw: String)
}

typealias METARResult = ParseResult<METAR, SwiftMETAR.Error>
typealias TAFResult = ParseResult<TAF, SwiftMETAR.Error>

class WeatherService: ObservableObject {
    static let instance = WeatherService()
    
    @Published private(set) var loading = false
    
    private var METARs: LazyLoadingPublisher<Dictionary<String, ParseResult<METAR, SwiftMETAR.Error>>>
    private var TAFs: LazyLoadingPublisher<Dictionary<String, ParseResult<TAF, SwiftMETAR.Error>>>
    
    private let METAR_URL = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv")!
    private let TAF_URL = URL(string: "https://www.aviationweather.gov/adds/dataserver_current/current/tafs.cache.csv")!
    
    private let weatherTimeout: TimeInterval = 3600
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "WeatherService")
    
    private let METARProcessor: LazyLoadingPublisher<Dictionary<String, ParseResult<METAR, SwiftMETAR.Error>>>.Processor
    private let TAFProcessor: LazyLoadingPublisher<Dictionary<String, ParseResult<TAF, SwiftMETAR.Error>>>.Processor
        
    private init() {
        METARProcessor = { [logger] data in
            let CSV = try CSVReader(stream: InputStream(data: data))
            var METARs = Dictionary<String, ParseResult<METAR, SwiftMETAR.Error>>()
            CSV.forEach { row in
                guard row.count > 1 && row[0] != "raw_text" else { return }
                do {
                    let observation = try METAR.from(string: row[0])
                    METARs[observation.stationID] = .success(observation)
                } catch (let error as SwiftMETAR.Error) {
                    METARs[row[1]] = .failure(error, raw: row[0])
                } catch (let error) {
                    logger.error("Error while parsing METAR: \(error.localizedDescription)")
                }
            }
            return METARs
        }
        
        TAFProcessor = { [logger] data in
            let CSV = try CSVReader(stream: InputStream(data: data))
            var TAFs = Dictionary<String, ParseResult<TAF, SwiftMETAR.Error>>()
            CSV.forEach { row in
                guard row.count > 1 && row[0] != "raw_text" else { return }
                do {
                    let forecast = try TAF.from(string: row[0])
                    TAFs[forecast.airportID] = .success(forecast)
                } catch (let error as SwiftMETAR.Error) {
                    TAFs[row[1]] = .failure(error, raw: row[0])
                } catch (let error) {
                    logger.error("Error while parsing METAR: \(error.localizedDescription)")
                }
            }
            return TAFs
        }
        
        METARs = LazyLoadingPublisher(url: METAR_URL, timeout: weatherTimeout, process: METARProcessor)
        TAFs = LazyLoadingPublisher(url: TAF_URL, timeout: weatherTimeout, process: TAFProcessor)
        
        Publishers.CombineLatest(METARs.$loading, TAFs.$loading)
            .map { $0 || $1 }
            .assign(to: &$loading)
    }
    
    
    func getMETAR(for location: String, force: Bool = false) -> AnyPublisher<METARResult?, Never> {
        METARs.load(force: force)
        return METARs.stream
            .mapError { error -> Swift.Error in self.logger.error("Error while getting METAR: \(error.localizedDescription)"); return error }
            .map { $0[location] }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    func getTAF(for location: String, force: Bool = false) -> AnyPublisher<TAFResult?, Never> {
        TAFs.load(force: force)
        return TAFs.stream
            .mapError { error -> Swift.Error in self.logger.error("Error while getting METAR: \(error.localizedDescription)"); return error }
            .map { $0[location] }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    func conditionsFor(airport: Airport, runway: Runway?, date: Date, force: Bool = false) -> AnyPublisher<(METARResult?, TAFResult?), Never> {
        let fakeICAO = airport.icao ?? "K\(airport.lid!)"
        return Publishers.CombineLatest(getMETAR(for: fakeICAO, force: force), getTAF(for: fakeICAO, force: force))
            .eraseToAnyPublisher()
    }
}
