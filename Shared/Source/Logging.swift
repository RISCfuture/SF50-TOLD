import Foundation
import Logging

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
