import SwiftUI
import BackgroundTasks
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
let navigationStyle = StackNavigationViewStyle()
#else
let navigationStyle = DefaultNavigationViewStyle()
#endif

#if canImport(UIKit)
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
#endif

@main
struct SF50_TOLDApp: App {
    @StateObject private var state = AppState()
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(state)
        }
    }
}
