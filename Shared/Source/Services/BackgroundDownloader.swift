import Foundation
import Combine
import Dispatch
import UIKit
import SwiftNASR

typealias BackgroundDownloaderCallback = (Result<Distribution, Swift.Error>) -> Void

@objc fileprivate class Delegate: NSObject, URLSessionDownloadDelegate {
    private let callback: BackgroundDownloaderCallback
    
    init(callback: @escaping BackgroundDownloaderCallback) {
        self.callback = callback
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response as? HTTPURLResponse else { return }
        if response.statusCode/100 != 2 { callback(.failure(Error.badResponse(response))) }
        
        guard let distribution = ArchiveFileDistribution(location: location) else {
            callback(.failure(Error.badData))
            return
        }
        callback(.success(distribution))
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appDelegate.airportDownloadCompletionHandler()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
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
    
    override func load(callback: @escaping BackgroundDownloaderCallback) -> Foundation.Progress {
        let urlSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "codes.tim.SF50-TOLD.AirportService")
        urlSessionConfiguration.isDiscretionary = true
        let delegate = Delegate(callback: callback)
        let session = URLSession(configuration: urlSessionConfiguration, delegate: delegate, delegateQueue: nil)
        
        let task = session.downloadTask(with: cycleURL)
        task.resume()
        
        return task.progress
    }
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    override func load() -> AnyPublisher<Distribution, Swift.Error> {
        return Future { promise in
            _ = self.load() { result in promise(result) }
        }.eraseToAnyPublisher()
    }
}
