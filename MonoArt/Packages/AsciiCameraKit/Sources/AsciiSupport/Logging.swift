import Foundation

/// Lightweight logging surface to keep diagnostic dependencies isolated from other modules.
public protocol Logger {
    func log(_ message: @autoclosure () -> String, level: LogLevel, category: String)
}

public enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

public struct DefaultLogger: Logger {
    public init() {}

    public func log(_ message: @autoclosure () -> String, level: LogLevel, category: String) {
#if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(category)] [\(level.rawValue.uppercased())] \(message())")
#endif
    }
}

