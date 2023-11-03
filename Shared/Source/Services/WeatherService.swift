import Foundation
import Combine
import Dispatch
import OSLog
import Alamofire
import SwiftCSV
import Gzip
import SwiftMETAR

extension TAF {
    var originDateOrToday: Date { originDate ?? Date() }
}

fileprivate let loadingQueue = DispatchQueue(label: "codes.tim.SF50-TOLD.ExpiringCache", qos: .utility, attributes: .concurrent)

fileprivate class ExpiringCache<Key: Hashable, Value, Error: Swift.Error> {
    typealias Result = WeatherService.FetchResult<Value>
    typealias ValueGenerator = (Key) -> AnyPublisher<Result, Error>
    typealias ValueState = WeatherService.FetchState<Result>
    typealias ValuePublisher = AnyPublisher<ValueState, Error>
    typealias ValueSubject = CurrentValueSubject<ValueState, Error>

    private var dictionary = Dictionary<Key, ValueSubject>()
    private let expiryKey: KeyPath<Value, Date>
    private let timeout: TimeInterval
    private let valueGenerator: ValueGenerator
    private let mutex = DispatchSemaphore(value: 1)
    private var cancellables = Set<AnyCancellable>()

    init(expiryKey: KeyPath<Value, Date>, timeout: TimeInterval, valueGenerator: @escaping ValueGenerator) {
        self.expiryKey = expiryKey
        self.timeout = timeout
        self.valueGenerator = valueGenerator

        AF.sessionConfiguration.timeoutIntervalForResource = 60
        AF.sessionConfiguration.waitsForConnectivity = false
    }

    deinit {
        for c in cancellables { c.cancel() }
    }

    subscript(key: Key) -> ValuePublisher {
        mutex.wait()
        guard let subject = dictionary[key] else {
            let subject = CurrentValueSubject<ValueState, Error>(.loading)
            dictionary[key] = subject
            touch(key)
            mutex.signal()
            return subject.eraseToAnyPublisher()
        }
        mutex.signal()
        if isExpired(subject.value) { touch(key) }
        return subject.eraseToAnyPublisher()
    }

    func reload(_ key: Key) -> ValuePublisher {
        send(key: key, value: .loading)
        touch(key)
        return dictionary[key]!.eraseToAnyPublisher()
    }

    func send(key: Key, value: ValueState) {
        mutex.wait()
        if dictionary.keys.contains(key) {
            dictionary[key]!.send(value)
        } else {
            dictionary[key] = CurrentValueSubject<ValueState, Error>(value)
        }
        mutex.signal()
    }

    private func isExpired(_ state: ValueState) -> Bool {
        guard case let .finished(result) = state else { return false }
        guard case let .some(value) = result else { return false }
        
        let date = value[keyPath: expiryKey]
        return date.timeIntervalSinceNow > 0 || date.timeIntervalSinceNow <= -timeout
    }

    private func touch(_ key: Key) {
        valueGenerator(key).sink(receiveCompletion: { completion in
            switch completion {
                case .finished: break // keep our stream open for future requests
                case let .failure(error):
                    self.send(key: key, value: .finished(.error(error)))
            }
        }, receiveValue: { value in
            var state: ValueState = .finished(value)
            if self.isExpired(state) { state = .finished(.none) }
            self.send(key: key, value: state)
        }).store(in: &cancellables)
    }
}

class WeatherService: ObservableObject {
    static let instance = WeatherService()

    private let METARCache: ExpiringCache<String, METAR, Never>
    private let TAFCache: ExpiringCache<String, TAF, Never>

    private static let METAR_URL = URL(string: "https://aviationweather.gov/data/cache/metars.cache.csv.gz")!
    private static let TAF_URL = URL(string: "https://aviationweather.gov/data/cache/tafs.cache.csv.gz")!

    private static let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "WeatherService")
    private let METARTimeout: TimeInterval = 5400 // METARs valid until 1.5 hours old
    private let TAFTimeout: TimeInterval = 43200 // TAFs valid until 12 hours old
    
    let reachable = CurrentValueSubject<NetworkReachabilityManager.NetworkReachabilityStatus, Never>(NetworkReachabilityManager.NetworkReachabilityStatus.unknown)
    private var reachability: NetworkReachabilityManager { .init(host: Self.METAR_URL.host!)! }
    
    init() {
        METARCache = .init(expiryKey: \.date, timeout: METARTimeout) { icao -> AnyPublisher<FetchResult<METAR>, Never> in
            return AF.request(Self.METAR_URL)
                .publishUnserialized(queue: loadingQueue)
                .map { response in
                    if let error = response.error { return .error(error) }
                    guard let data = response.data else { return .none }
                    guard let rawText = Self.processAWSFile(data: data, icao: icao, context: "METAR") else { return .none }
                    
                    do {
                        return .some(try METAR.from(string: rawText))
                    } catch (let error as SwiftMETAR.Error) {
                        Self.logger.error("Failed to parse METAR: \(error.localizedDescription)")
                        return .parseError(error, raw: rawText)
                    } catch {
                        Self.logger.error("Failed to parse METAR: \(error.localizedDescription)")
                        return .none
                    }
                }.eraseToAnyPublisher()
        }
        TAFCache = .init(expiryKey: \.originDateOrToday, timeout: TAFTimeout) { icao -> AnyPublisher<FetchResult<TAF>, Never> in
            return AF.request(Self.TAF_URL)
                .publishUnserialized(queue: loadingQueue)
                .map { response in
                    if let error = response.error { return .error(error) }
                    guard let data = response.data else { return .none }
                    guard let rawText = Self.processAWSFile(data: data, icao: icao, context: "TAF") else { return .none}
                    
                    do {
                        return .some(try TAF.from(string: rawText))
                    } catch (let error as SwiftMETAR.Error) {
                        Self.logger.error("Failed to parse TAF: \(error.localizedDescription)")
                        return .parseError(error, raw: rawText)
                    } catch {
                        Self.logger.error("Failed to parse TAF: \(error.localizedDescription)")
                        return .none
                    }
                }.eraseToAnyPublisher()
        }
        
        reachability.startListening(onQueue: loadingQueue) { status in
            self.reachable.send(status)
        }
    }
    
    deinit {
        reachability.stopListening()
        reachable.send(completion: .finished)
    }

    func getMETAR(for location: String, force: Bool = false) -> AnyPublisher<FetchState<FetchResult<METAR>>, Never> {
        if force { return METARCache.reload(location) }
        else { return METARCache[location] }
    }

    func getTAF(for location: String, force: Bool = false) -> AnyPublisher<FetchState<FetchResult<TAF>>, Never> {
        if force { return TAFCache.reload(location) }
        else { return TAFCache[location] }
    }

    func conditionsFor(airport: Airport, date: Date, force: Bool = false) -> AnyPublisher<(FetchState<(FetchResult<METAR>, FetchResult<TAF>)>), Never> {
        let fakeICAO = airport.icao ?? "K\(airport.lid!)"
        return Publishers.CombineLatest(
            getMETAR(for: fakeICAO, force: force),
            getTAF(for: fakeICAO, force: force)
        ).map { METARState, TAFState -> FetchState<(FetchResult<METAR>, FetchResult<TAF>)> in
            switch METARState {
                case .loading: return .loading
                case let .finished(METAR):
                    switch TAFState {
                        case .loading: return .loading
                        case let .finished(TAF): return .finished((METAR, TAF))
                    }
            }
        }.eraseToAnyPublisher()
    }
    
    private static func processAWSFile(data: Data, icao: String, context: String) -> String? {
        guard let unzippedData = try? data.gunzipped() else {
            logger.notice("\(context) data not gzipped")
            return nil
        }
        
        guard let str = String(data: unzippedData, encoding: .ascii) else {
            logger.notice("\(context) CSV not ASCII-encoded")
            return nil
        }
        
        guard let csv = try? CSV<Enumerated>(string: str) else {
            logger.notice("Failed to parse CSV for \(context)")
            return nil
        }
        guard let row = csv.rows.first(where: { $0[1] == icao }) else {
            logger.notice("No \(context) in response for \(icao)")
            return nil
        }
        let rawText = row[0]
        logger.info("Loaded \(context): \(rawText)")
        
        return rawText
    }

    enum FetchResult<Value> {
        case none
        case some(_ value: Value)
        case error(_ error: Swift.Error)
        case parseError(_ error: SwiftMETAR.Error, raw: String)
    }

    enum FetchState<Value> {
        case loading
        case finished(_ value: Value)
    }
}
