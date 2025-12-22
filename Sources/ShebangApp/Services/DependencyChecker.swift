// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import Foundation

/// Checks and reports on required system dependencies
/// Called on every app launch to ensure environment is ready
@MainActor
@Observable
final class DependencyChecker {

    // MARK: - Singleton

    static let shared = DependencyChecker()

    // MARK: - Dependency Status

    struct DependencyStatus: Identifiable {
        let id: String
        let name: String
        let description: String
        var isInstalled: Bool
        var path: String?
        var installCommand: String
    }

    /// All tracked dependencies
    var dependencies: [DependencyStatus] = []

    /// Whether all required dependencies are installed
    var allDependenciesInstalled: Bool {
        dependencies.allSatisfy { $0.isInstalled }
    }

    /// Whether we've completed the initial check
    var hasChecked = false

    // MARK: - Initialization

    private init() {
        // Define required dependencies
        dependencies = [
            DependencyStatus(
                id: "homebrew",
                name: "Homebrew",
                description: "Package manager for macOS",
                isInstalled: false,
                installCommand: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            ),
            DependencyStatus(
                id: "dtach",
                name: "dtach",
                description: "Session persistence (keeps terminals alive)",
                isInstalled: false,
                installCommand: "brew install dtach"
            ),
            DependencyStatus(
                id: "claude",
                name: "Claude Code",
                description: "AI coding assistant CLI",
                isInstalled: false,
                installCommand: "npm install -g @anthropic-ai/claude-code"
            )
        ]
    }

    // MARK: - Check Dependencies

    /// Check all dependencies and update their status
    func checkAll() async {
        // Check Homebrew
        if let index = dependencies.firstIndex(where: { $0.id == "homebrew" }) {
            let brewPath = findExecutable("brew", searchPaths: [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew"
            ])
            dependencies[index].isInstalled = brewPath != nil
            dependencies[index].path = brewPath
        }

        // Check dtach
        if let index = dependencies.firstIndex(where: { $0.id == "dtach" }) {
            let dtachPath = findExecutable("dtach", searchPaths: [
                "/opt/homebrew/bin/dtach",
                "/usr/local/bin/dtach"
            ])
            dependencies[index].isInstalled = dtachPath != nil
            dependencies[index].path = dtachPath
        }

        // Check Claude Code
        if let index = dependencies.firstIndex(where: { $0.id == "claude" }) {
            let claudePath = findExecutable("claude", searchPaths: [
                "/opt/homebrew/bin/claude",
                "/usr/local/bin/claude",
                // npm global installs (various locations)
                "\(NSHomeDirectory())/.local/bin/claude",
                "\(NSHomeDirectory())/.npm-global/bin/claude",
                "/usr/local/lib/node_modules/.bin/claude"
            ])
            // Also check via `which` for PATH-based installations
            let whichResult = claudePath ?? runWhich("claude")
            dependencies[index].isInstalled = whichResult != nil
            dependencies[index].path = whichResult
        }

        hasChecked = true
    }

    // MARK: - Helpers

    /// Find an executable at known paths
    private func findExecutable(_ name: String, searchPaths: [String]) -> String? {
        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    /// Run `which` command to find executable in PATH
    private func runWhich(_ command: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {
            // Ignore errors
        }
        return nil
    }

    /// Get missing dependencies
    var missingDependencies: [DependencyStatus] {
        dependencies.filter { !$0.isInstalled }
    }

    /// Get the dtach path (or nil if not installed)
    var dtachPath: String? {
        dependencies.first(where: { $0.id == "dtach" })?.path
    }

    /// Check if dtach specifically is available
    var dtachAvailable: Bool {
        dependencies.first(where: { $0.id == "dtach" })?.isInstalled ?? false
    }

    /// Check if Homebrew is available
    var brewAvailable: Bool {
        dependencies.first(where: { $0.id == "homebrew" })?.isInstalled ?? false
    }

    /// Get brew path
    var brewPath: String? {
        dependencies.first(where: { $0.id == "homebrew" })?.path
    }
}
