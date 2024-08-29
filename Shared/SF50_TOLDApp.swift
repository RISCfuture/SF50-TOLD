import SwiftUI
import BackgroundTasks
import SwiftData
import Logging
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
        //AirportLoaderTask.register()
        return true
    }
}
#endif

@main
struct SF50_TOLDApp: App {
    @Environment(\.modelContext) var modelContext
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    init() {
#if canImport(UIKit)
        if CommandLine.arguments.contains("--disable-animations") {
            UIView.setAnimationsEnabled(false)
        }
#endif
        
        configureLogLevel()
        reloadOnAirportChange()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(state: state, service: state.airportLoadingService)
                .modelContainer(for: [Airport.self, Runway.self, NOTAM.self])
                .environmentObject(<#T##T#>)
        }
    }
}
