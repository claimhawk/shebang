// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import Foundation
import AppKit

/// Background installer for development tools
/// Uses Claude Code agent to guide interactive installations
enum ToolsInstaller {

    // MARK: - Install Dependencies

    /// Install git and common development dependencies
    /// Runs in background, brings to front for user interaction when needed
    static func installDependencies() async {
        let state = AppState.shared

        // Create a dedicated session for installation
        let session = state.sessions.createSession(
            name: "Install Dependencies"
        )

        // Send the installation prompt to Claude Code
        let prompt = """
        You are helping install development dependencies on this macOS system.

        Check and install the following if missing:
        1. Xcode Command Line Tools (xcode-select --install)
        2. Homebrew (if not installed)
        3. Git (via Homebrew if needed)
        4. Node.js and npm (via Homebrew)
        5. Python 3 (via Homebrew)

        For each step:
        - Check if already installed
        - If not, explain what will be installed
        - Run the installation command
        - Verify success

        If any step requires user interaction (like password), pause and wait.

        Start by checking what's already installed.
        """

        // Execute via the session's terminal
        await executeAgentTask(prompt, in: session)
    }

    // MARK: - Install Claude Code

    /// Install Claude Code CLI
    static func installClaudeCode() async {
        let state = AppState.shared

        let session = state.sessions.createSession(
            name: "Install Claude Code"
        )

        let prompt = """
        Install Claude Code CLI on this system.

        Steps:
        1. Check if npm is installed (install via Homebrew if not)
        2. Install Claude Code globally: npm install -g @anthropic-ai/claude-code
        3. Verify installation: claude --version
        4. If the user hasn't authenticated, guide them through: claude login

        Report each step's success or failure.
        """

        await executeAgentTask(prompt, in: session)
    }

    // MARK: - Check Environment

    /// Check what development tools are available
    static func checkEnvironment() async {
        let state = AppState.shared

        let session = state.sessions.createSession(
            name: "Environment Check"
        )

        let prompt = """
        Check this development environment and report what's installed:

        1. macOS version
        2. Xcode Command Line Tools
        3. Homebrew
        4. Git (with version)
        5. Node.js and npm (with versions)
        6. Python (with version)
        7. Claude Code (with version)

        Format as a clear status report showing:
        - Tool name
        - Installed? (Yes/No)
        - Version if installed
        - Location (path)

        Also report any issues or recommendations.
        """

        await executeAgentTask(prompt, in: session)
    }

    // MARK: - Private Helpers

    /// Execute an agent task in the given session
    /// Brings window to front when user interaction is needed
    private static func executeAgentTask(_ prompt: String, in session: Session) async {
        // For now, just run claude code with the prompt
        // In the future, this will:
        // 1. Run in background
        // 2. Parse output to detect when user input is needed
        // 3. Bring window to front when interaction required
        // 4. Return to background when done

        let escapedPrompt = prompt
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        // Build the command to run claude with the prompt
        let command = "claude \"\(escapedPrompt)\""

        // Send to terminal (will be picked up by SwiftTermView)
        print("Would execute: \(command)")

        // Bring app to front since this is user-initiated
        await MainActor.run {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    // MARK: - Background Process Management

    /// Check if a command is available in PATH
    static func isCommandAvailable(_ command: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Run a shell command and return output
    static func runCommand(_ command: String, arguments: [String] = []) async -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            return (output, process.terminationStatus)
        } catch {
            return ("Error: \(error.localizedDescription)", -1)
        }
    }
}
