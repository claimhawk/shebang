// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import Foundation
import SwiftUI
import Combine

// MARK: - App State (Root)

/// The root application state singleton that survives hot reloads.
///
/// Shebang uses a React-like state decomposition pattern where state is completely
/// separate from views. Views are pure functions of state, which enables:
///
/// - **Hot Reload**: `/reload` rebuilds views while preserving state
/// - **Testability**: State can be tested independently of UI
/// - **Predictability**: Unidirectional data flow
///
/// ## Sub-stores
/// - `sessions` - Terminal session management
/// - `ui` - Panel visibility and display preferences
/// - `files` - File browser state
/// - `terminal` - Output buffer and command queue
///
/// ## Usage
/// ```swift
/// let state = AppState.shared
/// state.sessions.createSession(name: "My Project")
/// state.ui.sidebarOpen = true
/// ```
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

/// Manages terminal sessions - like browser tabs for your terminal.
///
/// Each session has its own working directory, terminal history, and PTY process.
/// Sessions persist across app restarts via JSON serialization.
///
/// ## Key Methods
/// - `createSession(name:at:)` - Create a new session
/// - `closeSession(_:)` - Close and remove a session
/// - `selectSession(_:)` - Switch to a different session
/// - `updateActiveSessionCWD(_:)` - Sync CWD from terminal OSC 7
@Observable
final class SessionState {
    /// All sessions (active, idle, or backgrounded)
    var sessions: [Session] = []

    /// ID of the currently displayed session
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
            workingDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        sessions = [session]
        activeSessionId = session.id
    }

    // MARK: - Actions

    @discardableResult
    func createSession(name: String? = nil, at url: URL? = nil) -> Session {
        let session = Session(
            name: name ?? "Session \(sessions.count + 1)",
            workingDirectory: url ?? FileManager.default.homeDirectoryForCurrentUser
        )
        sessions.append(session)
        activeSessionId = session.id
        saveToDisk()
        return session
    }

    func closeSession(_ session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }

        // Switch active session before removing
        if activeSessionId == session.id {
            // Find another session to switch to
            let otherSessions = sessions.filter { $0.id != session.id }
            activeSessionId = otherSessions.first?.id
        }

        // Remove the session entirely
        sessions.remove(at: index)

        // If no sessions left, create a new default one
        if sessions.isEmpty {
            createDefaultSession()
        }

        saveToDisk()
    }

    func selectSession(_ session: Session) {
        activeSessionId = session.id
    }

    /// Update the active session's working directory (reactive to terminal cd)
    func updateActiveSessionCWD(_ url: URL) {
        guard let index = sessions.firstIndex(where: { $0.id == activeSessionId }) else { return }
        sessions[index].workingDirectory = url
        sessions[index].touch()
        // Don't save to disk on every cd - too noisy
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

/// Manages terminal I/O and command queuing.
///
/// The terminal is the source of truth in Shebang. This state object:
/// - Queues commands to send to the active PTY
/// - Buffers raw output for block parsing
/// - Tracks command exit codes
///
/// ## Command Flow
/// 1. User types in CommandBarView
/// 2. CommandRouter classifies input (shell vs AI)
/// 3. `sendCommand()` queues the command
/// 4. SwiftTermView picks up `pendingCommand` and sends to PTY
///
/// ## Control Characters
/// Ctrl+C, Ctrl+D, Ctrl+Z are sent via `sendInterrupt()`, `sendEOF()`, `sendSuspend()`
@Observable
final class TerminalState {
    /// Raw terminal output bytes (ANSI included) - the source of truth
    var rawOutput: Data = Data()

    /// Parsed blocks for the block view mode
    var blocks: [TerminalBlock] = []

    /// Current command being composed (not yet sent)
    var currentCommand = ""

    /// Exit code from the most recent command
    var lastExitCode: Int32?

    /// Command waiting to be sent to the terminal PTY
    var pendingCommand: String?

    /// Control character waiting to be sent (e.g., 0x03 for Ctrl+C)
    var pendingControlChar: UInt8?

    // MARK: - Send Command

    func sendCommand(_ command: String) {
        // Add newline if not present
        let cmdWithNewline = command.hasSuffix("\n") ? command : command + "\n"
        pendingCommand = cmdWithNewline
    }

    /// Send a control character (e.g., Ctrl+C = 0x03, Ctrl+D = 0x04)
    func sendControlCharacter(_ char: UInt8) {
        pendingControlChar = char
    }

    /// Send Ctrl+C (SIGINT)
    func sendInterrupt() {
        sendControlCharacter(0x03)  // ASCII ETX (End of Text) = Ctrl+C
    }

    /// Send Ctrl+D (EOF)
    func sendEOF() {
        sendControlCharacter(0x04)  // ASCII EOT (End of Transmission) = Ctrl+D
    }

    /// Send Ctrl+Z (SIGTSTP - suspend)
    func sendSuspend() {
        sendControlCharacter(0x1A)  // ASCII SUB = Ctrl+Z
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
