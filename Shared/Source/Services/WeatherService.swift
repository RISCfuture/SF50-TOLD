import Foundation
import Combine
import Dispatch
import Logging
import Alamofire
import SwiftCSV
import Gzip
import SwiftMETAR

extension TAF {
    var originDateOrToday: Date { originDate ?? Date() }
}

fileprivate let loadingQueue = DispatchQueue(label: "codes.tim.SR22-G2-TOLD.ExpiringCache", qos: .utility, attributes: .concurrent)

fileprivate class WeatherLoader<T> {
    private let subject = CurrentValueSubject<FetchState<Dictionary<String, WeatherResult<T>>>, Never>(FetchState.notLoaded)
    private let url: URL
    private let parse: ((String) throws -> T)
    
    private let logger = Logger(label: "codes.tim.SR22-G2-TOLD.WeatherLoader")
    
    init(url: URL, parse: @escaping ((String) throws -> T)) {
        self.url = url
        self.parse = parse
    }
    
    func publisherFor(icao: String) -> AnyPublisher<FetchState<WeatherResult<T>>, Never> {
        subject.map { state in
            switch state {
                case let .finished(value):
                    guard let result = value[icao] else { return .finished(.none) }
                    return .finished(result)
                case .notLoaded: return .notLoaded
                case .loading: return .loading
                case let .error(error): return .error(error)
            }
        }.eraseToAnyPublisher()
    }
    
    func reload() {
        loadingQueue.async {
            self.subject.value = .loading
            self.logger.debug("reload(): starting")
            AF.request(self.url).response(queue: loadingQueue) { response in
                do {
                    if let error = response.error {
                        self.logger.error("reload(): error", metadata: [
                            "url": "\(self.url)",
                            "error": "\(error.localizedDescription)"
                        ])
                        throw error
                    }
                    guard let HTTPResponse = response.response else {
                        throw WeatherDownloadError.badResponse
                    }
                    guard HTTPResponse.statusCode == 200 else {
                        self.logger.error("reload(): bad status", metadata: [
                            "url": "\(self.url)",
                            "status": "\(HTTPResponse.statusCode)"
                        ])
                        throw WeatherDownloadError.badStatusCode(HTTPResponse.statusCode)
                    }
                } catch {
                    self.subject.value = .error(error)
                }
                
                loadingQueue.async {
                    do {
                        self.logger.debug("reload(): complete", metadata: [
                            "url": "\(self.url)",
                        ])
                        
                        guard let data = response.data else { throw WeatherDownloadError.noData }
                        let unzippedData = try data.gunzipped()
                        guard let str = String(data: unzippedData, encoding: .ascii) else {
                            throw WeatherDownloadError.unexpectedEncoding
                        }
                        
                        guard let csv = try? CSV<Enumerated>(string: str) else {
                            throw WeatherDownloadError.badCSV
                        }
                        let wx: Dictionary<String, WeatherResult<T>> = csv.rows.filter { !$0[1].isEmpty && $0[1] != "station_id" }.reduce(Dictionary()) { dict, row in
                            var dict = dict
                            do {
                                dict[row[1]] = .some(try self.parse(row[0]))
                            } catch {
                                dict[row[1]] = .error(error, raw: row[0])
                            }
                            return dict
                        }
                        self.subject.value = .finished(wx)
                    } catch {
                        self.subject.value = .error(error)
                    }
                }
            }
        }
    }
}

enum WeatherResult<Value> {
    case none
    case some(_ value: Value)
    case error(_ error: Swift.Error, raw: String)
}

enum FetchState<Value> {
    case notLoaded
    case loading
    case finished(_ value: Value)
    case error(_ error: Swift.Error)
}

class WeatherService: ObservableObject {
    static let instance = WeatherService()
    
    private static let allMETARsURL = URL(string: "https://aviationweather.gov/data/cache/metars.cache.csv.gz")!
    private static let allTAFsURL = URL(string: "https://aviationweather.gov/data/cache/tafs.cache.csv.gz")!
    private static let airportWeatherURLTemplate = "https://aviationweather.gov/api/data/metar?ids=%{icao}&format=raw&taf=true"
    
    private static let logger = Logger(label: "codes.tim.SR22-G2-TOLD.WeatherService")
    
    private let METARLoader: WeatherLoader<METAR>
    private let TAFLoader: WeatherLoader<TAF>
    
    let reachable = CurrentValueSubject<NetworkReachabilityManager.NetworkReachabilityStatus, Never>(NetworkReachabilityManager.NetworkReachabilityStatus.unknown)
    private var reachability: NetworkReachabilityManager { .init(host: Self.allMETARsURL.host!)! }
    
    init() {
        AF.sessionConfiguration.timeoutIntervalForResource = 60
        AF.sessionConfiguration.waitsForConnectivity = false
        
        METARLoader = .init(url: Self.allMETARsURL) { try METAR.from(string: $0) }
        TAFLoader = .init(url: Self.allTAFsURL) { try TAF.from(string: $0) }
        
        reachability.startListening(onQueue: loadingQueue) { status in
            self.reachable.send(status)
        }
    }
    
    deinit {
        reachability.stopListening()
        reachable.send(completion: .finished)
    }
    
    func loadWeatherFor(airport: Airport) async -> (METAR?, TAF?) {
        Self.logger.debug("loadWeatherFor(): starting", metadata: [
            "airport": "\(airport.lid ?? airport.id ?? "<unknown>")"
        ])
        
        let fakeICAO = airport.icao ?? "K\(airport.lid!)"
        let URL_String = Self.airportWeatherURLTemplate.replacingOccurrences(of: "%{icao}", with: fakeICAO)
        guard let url = URL(string: URL_String) else {
            Self.logger.error("loadWeatherFor(): invalid URL", metadata: [
                "airport": "\(airport.lid ?? airport.id ?? "<unknown>")",
                "url": "\(URL_String)"
            ])
            return (nil, nil)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let weatherStr = String(data: data, encoding: .ascii) else {
                Self.logger.error("loadWeatherFor(): bad ASCII response", metadata: [
                    "airport": "\(airport.lid ?? airport.id ?? "<unknown>")",
                    "url": "\(url.absoluteString)"
                ])
                return (nil, nil)
            }
            Self.logger.debug("loadWeatherFor(): loaded data", metadata: [
                "airport": "\(airport.lid ?? airport.id ?? "<unknown>")",
                "data": "\(weatherStr)"
            ])
            
            let lines = weatherStr.components(separatedBy: .newlines)
            guard !lines.isEmpty else {
                Self.logger.error("loadWeatherFor(): empty response")
                return (nil, nil)
            }
            
            let metar = try? METAR.from(string: lines[0], on: Date())
            let taf = lines.count > 1 ? try? TAF.from(string: lines.dropFirst().joined(separator: "\n"), on: Date()) : nil
            
            return (metar, taf)
        } catch {
            Self.logger.error("loadWeatherFor(): error", metadata: [
                "airport": "\(airport.lid ?? airport.id ?? "<unknown>")",
                "error": "\(error.localizedDescription)"
            ])
            return (nil, nil)
        }
    }
    
    func cachedConditionsFor(airport: Airport, date: Date) -> AnyPublisher<(FetchState<(WeatherResult<METAR>, WeatherResult<TAF>)>), Never> {
        let fakeICAO = airport.icao ?? "K\(airport.lid!)"
        return Publishers.CombineLatest(
            METARLoader.publisherFor(icao: fakeICAO),
            TAFLoader.publisherFor(icao: fakeICAO)
        ).map { METARState, TAFState -> FetchState<(WeatherResult<METAR>, WeatherResult<TAF>)> in
            switch METARState {
                case .notLoaded: return .notLoaded
                case .loading: return .loading
                case let .error(error): return .error(error)
                case let .finished(METAR):
                    switch TAFState {
                        case .notLoaded: return .notLoaded
                        case .loading: return .loading
                        case let .error(error): return .error(error)
                        case let .finished(TAF): return .finished((METAR, TAF))
                    }
            }
        }.eraseToAnyPublisher()
    }
    
    func reload() {
        METARLoader.reload()
        TAFLoader.reload()
    }
}
