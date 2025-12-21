// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI
import Combine

// MARK: - App State (Root)

/// Root application state - survives hot reloads
/// Pattern: React-like state decomposition
/// - State is separate from Views
/// - Views are pure functions of state
/// - Hot reload replaces Views, preserves State
@MainActor
@Observable
final class AppState {
    // MARK: - Singleton (survives reload)

    static let shared = AppState()

    // MARK: - Sub-stores

    let sessions: SessionState
    let ui: UIState
    let files: FileState
    let terminal: TerminalState

    // MARK: - Initialization

    private init() {
        self.sessions = SessionState()
        self.ui = UIState()
        self.files = FileState()
        self.terminal = TerminalState()

        // Load persisted state
        sessions.loadFromDisk()
    }

    // MARK: - Hot Reload Support

    /// Prepare state for hot reload (serialize volatile data)
    func prepareForReload() {
        sessions.saveToDisk()
        // Terminal state is PTY-based, will reconnect
    }

    /// Restore after hot reload
    func restoreAfterReload() {
        // Views will re-bind to existing state
        // No action needed - state persisted in memory
    }
}

// MARK: - Session State

@Observable
final class SessionState {
    var sessions: [Session] = []
    var activeSessionId: UUID?

    var activeSession: Session? {
        sessions.first { $0.id == activeSessionId }
    }

    var activeSessions: [Session] {
        sessions.filter { $0.status == .active || $0.status == .idle }
    }

    // MARK: - Persistence

    private var persistenceURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Shebang", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }

    func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else {
            createDefaultSession()
            return
        }

        do {
            let data = try Data(contentsOf: persistenceURL)
            sessions = try JSONDecoder().decode([Session].self, from: data)
            activeSessionId = activeSessions.first?.id ?? sessions.first?.id

            if sessions.isEmpty {
                createDefaultSession()
            }
        } catch {
            print("Failed to load sessions: \(error)")
            createDefaultSession()
        }
    }

    func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(sessions)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func createDefaultSession() {
        let session = Session(
            name: "Session 1",
            workingDirectory: currentWorkingDirectory()
        )
        sessions = [session]
        activeSessionId = session.id
    }

    private func currentWorkingDirectory() -> URL {
        if let pwd = ProcessInfo.processInfo.environment["PWD"] {
            return URL(fileURLWithPath: pwd)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    // MARK: - Actions

    @discardableResult
    func createSession(name: String? = nil, at url: URL? = nil) -> Session {
        let session = Session(
            name: name ?? "Session \(sessions.count + 1)",
            workingDirectory: url ?? currentWorkingDirectory()
        )
        sessions.append(session)
        activeSessionId = session.id
        saveToDisk()
        return session
    }

    func closeSession(_ session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].status = .terminated
        if activeSessionId == session.id {
            activeSessionId = activeSessions.first?.id
        }
        saveToDisk()
    }

    func selectSession(_ session: Session) {
        activeSessionId = session.id
    }
}

// MARK: - UI State

@Observable
final class UIState {
    // Panel visibility
    var sidebarOpen = true
    var sessionsPanelOpen = true
    var filePreviewOpen = false
    var favoritesDrawerOpen = false

    // Display mode
    var displayMode: DisplayMode = .interactive

    // File preview
    var previewingFile: URL?

    // Command input
    var commandInput = ""
    var commandHistory: [String] = []
    var historyIndex: Int?

    // Favorites
    var favoriteFolders: [URL] = []

    // MARK: - Favorites Persistence

    private var favoritesURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Shebang", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("favorites.json")
    }

    func loadFavorites() {
        guard FileManager.default.fileExists(atPath: favoritesURL.path) else { return }
        do {
            let data = try Data(contentsOf: favoritesURL)
            let paths = try JSONDecoder().decode([String].self, from: data)
            favoriteFolders = paths.map { URL(fileURLWithPath: $0) }
        } catch {
            print("Failed to load favorites: \(error)")
        }
    }

    func saveFavorites() {
        do {
            let paths = favoriteFolders.map { $0.path }
            let data = try JSONEncoder().encode(paths)
            try data.write(to: favoritesURL, options: .atomic)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }

    func addFavorite(_ url: URL) {
        guard !favoriteFolders.contains(url) else { return }
        favoriteFolders.append(url)
        saveFavorites()
    }

    func removeFavorite(_ url: URL) {
        favoriteFolders.removeAll { $0 == url }
        saveFavorites()
    }
}

// MARK: - File State

@Observable
final class FileState {
    var expandedFolders: Set<URL> = []
    var selectedFile: URL?

    // File content cache (for preview)
    var fileContents: [URL: String] = [:]

    func toggleFolder(_ url: URL) {
        if expandedFolders.contains(url) {
            expandedFolders.remove(url)
        } else {
            expandedFolders.insert(url)
        }
    }

    func loadFileContent(_ url: URL) async {
        guard fileContents[url] == nil else { return }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            fileContents[url] = content
        } catch {
            fileContents[url] = "// Failed to load: \(error.localizedDescription)"
        }
    }
}

// MARK: - Terminal State

@Observable
final class TerminalState {
    // Raw terminal output (source of truth)
    var rawOutput: Data = Data()

    // Parsed blocks for block view
    var blocks: [TerminalBlock] = []

    // Current command being typed
    var currentCommand = ""

    // Exit codes from recent commands
    var lastExitCode: Int32?

    // Command queue - commands to send to terminal
    var pendingCommand: String?

    // MARK: - Send Command

    func sendCommand(_ command: String) {
        // Add newline if not present
        let cmdWithNewline = command.hasSuffix("\n") ? command : command + "\n"
        pendingCommand = cmdWithNewline
    }

    // MARK: - Block Parsing

    func appendOutput(_ data: Data) {
        rawOutput.append(data)
        // Parse into blocks (will be implemented in TerminalParser)
    }

    func clearOutput() {
        rawOutput = Data()
        blocks = []
    }
}

// MARK: - Terminal Block

struct TerminalBlock: Identifiable, Equatable {
    let id = UUID()
    let type: BlockType
    var content: String
    var timestamp: Date
    var isComplete: Bool

    enum BlockType: String, Codable {
        case command        // User-entered command
        case output         // Command output
        case toolCall       // Agent tool invocation
        case agentResponse  // Agent text response
        case error          // Error message
        case system         // System message
    }
}
