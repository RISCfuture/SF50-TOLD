import Foundation
import Combine
import Dispatch
import SwiftNASR
#if canImport(UIKit)
import UIKit
#endif

typealias BackgroundDownloaderCallback = (Result<Distribution, Swift.Error>) -> Void

@objc fileprivate class DownloadEventsDelegate: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionDelegate {
    var progress = Progress(totalUnitCount: 0)
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            #if canImport(UIKit)
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appDelegate.airportDownloadCompletionHandler()
            #endif
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // do nothing
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
        // do nothing
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress.completedUnitCount = totalBytesWritten
        progress.totalUnitCount = totalBytesExpectedToWrite
    }
}

@objc fileprivate class CallbackDelegate: DownloadEventsDelegate {
    private let callback: BackgroundDownloaderCallback
    
    init(callback: @escaping BackgroundDownloaderCallback) {
        self.callback = callback
    }
    
    override func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response as? HTTPURLResponse else { return }
        if response.statusCode/100 != 2 { callback(.failure(Error.badResponse(response))) }
        
        guard let distribution = ArchiveFileDistribution(location: location) else {
            callback(.failure(Error.badData))
            return
        }
        callback(.success(distribution))
    }
    
    override func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
        if let error = error {
            callback(.failure(error))
        }
    }
}

/**
 A downloader that downloads a distribution archive to a file on disk.
 */

class BackgroundDownloader: Downloader {
        
    /// The location to save the downloaded archive. If `nil`, saves to a
    /// tempfile.
    var location: URL? = nil
    
    /**
     Creates a new downloader.
     
     - Parameter cycle: The cycle to download NASR data for. If not specified,
     uses the current cycle.
     - Parameter location: The location to save the downloaded archive. If
     `nil`, saves to a tempfile.
     */
    
    public init(cycle: Cycle? = nil, location: URL? = nil) {
        if let cycle = cycle { super.init(cycle: cycle) }
        else { super.init() }
        self.location = location
    }
    
    override func load(withProgress progressHandler: @escaping (Progress) -> Void = { _ in }, callback: @escaping (_ result: Result<Distribution, Swift.Error>) -> Void) {
        let urlSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "codes.tim.SF50-TOLD.AirportService")
        urlSessionConfiguration.isDiscretionary = true
        let delegate = CallbackDelegate(callback: callback)
        let session = URLSession(configuration: urlSessionConfiguration, delegate: delegate, delegateQueue: nil)
        
        let task = session.downloadTask(with: cycleURL)
        progressHandler(task.progress)
        task.resume()
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    override func loadPublisher(withProgress progressHandler: @escaping (Progress) -> Void = { _ in }) -> AnyPublisher<Distribution, Swift.Error> {
        return Future { promise in
            self.load(withProgress: progressHandler) { result in promise(result) }
        }.eraseToAnyPublisher()
    }
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    override func load(withProgress progressHandler: @escaping (Progress) -> Void = { _ in }) async throws -> Distribution {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.isDiscretionary = true
        let delegate = DownloadEventsDelegate()
        progressHandler(delegate.progress)
        let session = URLSession(configuration: urlSessionConfiguration, delegate: delegate, delegateQueue: nil)
        
        
        
        let (location, response) = try await session.download(for: URLRequest(url: cycleURL), delegate: delegate)
        guard let response = response as? HTTPURLResponse else { throw Error.badResponse(response) }
        if response.statusCode/100 != 2 { throw Error.badResponse(response) }
        
        guard let distribution = ArchiveFileDistribution(location: location) else {
            throw Error.badData
        }
        
        return distribution
    }
}
