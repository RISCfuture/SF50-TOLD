import SwiftUI
import UIKit
import BackgroundTasks

#if canImport(UIKit)
let navigationStyle = StackNavigationViewStyle()
#else
let navigationStyle = DefaultNavigationViewStyle()
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    var airportDownloadCompletionHandler: () -> Void = {}
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.airportDownloadCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? =
                        nil) -> Bool {
        //AirportLoaderTask.register(persistentContainer: AppState().persistentContainer)
        return true
    }
}

@main
struct SF50_TOLDApp: App {
    @StateObject private var state = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(state)
        }
    }
}
