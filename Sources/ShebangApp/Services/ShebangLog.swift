// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import Foundation

/// Simple file-based logger for debugging
/// Logs are written to /tmp/shebang.log and can be tailed with:
///   tail -f /tmp/shebang.log
enum ShebangLog {
    private static let logFile = "/tmp/shebang.log"
    private static let queue = DispatchQueue(label: "shebang.log", qos: .utility)

    /// Log levels
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }

    /// Initialize log file (clear on app start)
    /// This runs synchronously to ensure the file exists immediately
    static func initialize() {
        let header = """
        =====================================
        Shebang Log - \(Date())
        =====================================

        """
        do {
            try header.write(toFile: logFile, atomically: true, encoding: .utf8)
            print("[ShebangLog] Initialized at \(logFile)")
        } catch {
            print("[ShebangLog] Failed to initialize: \(error)")
        }
    }

    /// Log a debug message
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }

    /// Log a warning
    static func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warn, message, file: file, function: function, line: line)
    }

    /// Log an error
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }

    /// Core logging function
    private static func log(_ level: Level, _ message: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [\(level.rawValue)] \(fileName):\(line) \(function) - \(message)\n"

        // Print to console too
        print(logLine, terminator: "")

        // Write to file
        queue.async {
            if let handle = FileHandle(forWritingAtPath: logFile) {
                handle.seekToEndOfFile()
                if let data = logLine.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                // File doesn't exist, create it
                try? logLine.write(toFile: logFile, atomically: true, encoding: .utf8)
            }
        }
    }
}
