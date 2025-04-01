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

// swiftlint:disable discarded_notification_center_observer
@discardableResult
func reloadOnAirportChange() -> any NSObjectProtocol {
    return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in
        WidgetCenter.shared.reloadTimelines(ofKind: "SF50_SelectedAirport")
    }
}
// swiftlint:enable discarded_notification_center_observer
