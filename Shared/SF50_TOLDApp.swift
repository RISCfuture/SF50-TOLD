import BackgroundTasks
import CoreData
import Logging
import SwiftUI
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

    func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler: @escaping () -> Void) {
        self.airportDownloadCompletionHandler = completionHandler
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey : Any]? =
                     nil) -> Bool {
        // AirportLoaderTask.register()
        return true
    }
}
#endif

@main
struct SF50_TOLDApp: App {
    @StateObject private var state = AppState()

#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(state: state, service: state.airportLoadingService)
                .environment(\.managedObjectContext, PersistentContainer.shared.viewContext)
        }
    }

    init() {
#if canImport(UIKit)
        if CommandLine.arguments.contains("--disable-animations") {
            UIView.setAnimationsEnabled(false)
        }
#endif

        configureLogLevel()
        reloadOnAirportChange()
    }
}
