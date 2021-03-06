import Foundation
import Combine
import Dispatch
import OSLog
import Alamofire
import SWXMLHash
import SwiftMETAR

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
        switch state {
            case .loading: return false
            case.finished(let result):
                switch result {
                    case .some(let value):
                        let date = value[keyPath: expiryKey]
                        return date.timeIntervalSinceNow > 0 || date.timeIntervalSinceNow <= -timeout
                    default:
                        return false
                }
        }
    }

    private func touch(_ key: Key) {
        valueGenerator(key).sink(receiveCompletion: { completion in
            switch completion {
                case .finished: break // keep our stream open for future requests
                case .failure(let error):
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

    private static let METARPattern = "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=%{icao}&hoursBeforeNow=2"
    private static let TAFPattern = "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=tafs&requestType=retrieve&format=xml&stationString=%{icao}&hoursBeforeNow=8"

    private static let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "WeatherService")
    private let METARTimeout: TimeInterval = 5400 // METARs valid until 1.5 hours old
    private let TAFTimeout: TimeInterval = 43200 // TAFs valid until 12 hours old

    init() {
        METARCache = .init(expiryKey: \.date, timeout: METARTimeout) { icao -> AnyPublisher<FetchResult<METAR>, Never> in
            return AF.request(Self.METAR_URL(icao))
                .publishUnserialized(queue: loadingQueue)
                .map { response in
                    if let error = response.error { return .error(error) }
                    guard let data = response.data else { return .none }

                    let XML = SWXMLHash.parse(data)
                    guard let rawText = XML["response"]["data"]["METAR"][0]["raw_text"].element?.text else {
                        Self.logger.notice("No METAR in response for \(icao)")
                        return .none
                    }
                    Self.logger.info("Loaded METAR: \(rawText)")
                    do {
                        return .some(try METAR.from(string: rawText))
                    } catch (let error as Error) {
                        Self.logger.error("Failed to parse METAR: \(error.localizedDescription)")
                        return .parseError(error, raw: rawText)
                    } catch (let error) {
                        Self.logger.error("Failed to parse METAR: \(error.localizedDescription)")
                        return .none
                    }
                }.eraseToAnyPublisher()
        }
        TAFCache = .init(expiryKey: \.originDate, timeout: TAFTimeout) { icao -> AnyPublisher<FetchResult<TAF>, Never> in
            return AF.request(Self.TAF_URL(icao))
                .publishUnserialized(queue: loadingQueue)
                .map { response in
                    if let error = response.error { return .error(error) }
                    guard let data = response.data else { return .none }

                    let XML = SWXMLHash.parse(data)
                    guard let rawText = XML["response"]["data"]["TAF"][0]["raw_text"].element?.text else {
                        Self.logger.notice("No TAF in response for \(icao)")
                        return .none
                    }
                    Self.logger.info("Loaded TAF: \(rawText)")
                    do {
                        return .some(try TAF.from(string: rawText))
                    } catch (let error as Error) {
                        Self.logger.error("Failed to parse TAF: \(error.localizedDescription)")
                        return .parseError(error, raw: rawText)
                    } catch (let error) {
                        Self.logger.error("Failed to parse TAF: \(error.localizedDescription)")
                        return .none
                    }
                }.eraseToAnyPublisher()
        }
    }

    func getMETAR(for location: String, force: Bool = false) -> AnyPublisher<FetchState<FetchResult<METAR>>, Never> {
        if force { return METARCache.reload(location) }
        else { return METARCache[location] }
    }

    func getTAF(for location: String, force: Bool = false) -> AnyPublisher<FetchState<FetchResult<TAF>>, Never> {
        if force { return TAFCache.reload(location) }
        else { return TAFCache[location] }
    }

    func conditionsFor(airport: Airport, runway: Runway?, date: Date, force: Bool = false) -> AnyPublisher<(FetchState<(FetchResult<METAR>, FetchResult<TAF>)>), Never> {
        let fakeICAO = airport.icao ?? "K\(airport.lid!)"
        return Publishers.CombineLatest(
            getMETAR(for: fakeICAO, force: force),
            getTAF(for: fakeICAO, force: force)
        ).map { METARState, TAFState -> FetchState<(FetchResult<METAR>, FetchResult<TAF>)> in
            switch METARState {
                case .loading: return .loading
                case .finished(let METAR):
                    switch TAFState {
                        case .loading: return .loading
                        case .finished(let TAF): return .finished((METAR, TAF))
                    }
            }
        }.eraseToAnyPublisher()
    }

    private static func METAR_URL(_ icao: String) -> URL {
        return URL(string: METARPattern.replacingOccurrences(of: "%{icao}", with: icao))!
    }

    private static func TAF_URL(_ icao: String) -> URL {
        return URL(string: TAFPattern.replacingOccurrences(of: "%{icao}", with: icao))!
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
