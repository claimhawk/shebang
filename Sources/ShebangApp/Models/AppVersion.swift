// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import Foundation

/// App version management with semantic versioning
enum AppVersion {
    /// Current version from bundle info
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
    }

    /// Build number
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string (e.g., "0.0.1 (1)")
    static var full: String {
        "\(current) (\(build))"
    }

    /// Parse version components
    static var components: (major: Int, minor: Int, patch: Int) {
        let parts = current.split(separator: ".").compactMap { Int($0) }
        return (
            major: parts.count > 0 ? parts[0] : 0,
            minor: parts.count > 1 ? parts[1] : 0,
            patch: parts.count > 2 ? parts[2] : 1
        )
    }
}
