import Foundation
import Logging
import WidgetKit

func configureLogLevel() {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
#if DEBUG
        handler.logLevel = .debug
#else
        handler.logLevel = .notice
#endif
        return handler
    }
}

func reloadOnAirportChange() {
    NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in
        WidgetCenter.shared.reloadTimelines(ofKind: "SF50_SelectedAirport")
    }
}
