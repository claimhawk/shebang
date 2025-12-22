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
        ui.loadRecentProjects()
        ui.loadFavorites()

        // Seed recent projects from existing sessions if empty
        if ui.recentProjects.isEmpty {
            for session in sessions.sessions.sorted(by: { $0.lastActiveAt > $1.lastActiveAt }) {
                ui.trackProject(session.workingDirectory)
            }
        }
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
        // Default to Shebang repo folder if it exists, otherwise home directory
        let shebangRepo = URL(fileURLWithPath: "/Users/michaeloneal/development/Shebang")
        let defaultDir = FileManager.default.fileExists(atPath: shebangRepo.path)
            ? shebangRepo
            : FileManager.default.homeDirectoryForCurrentUser

        let session = Session(
            name: "Session 1",
            workingDirectory: defaultDir
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

    /// Create a new project folder at the specified parent location
    /// Sets up shebang files (system.md, etc.) and creates a session
    @discardableResult
    func createProjectAtLocation(parentDir: URL, name: String) -> Session {
        // Create project folder
        let projectDir = parentDir.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        // Set up shebang files
        setupShebangFiles(in: projectDir, projectName: name)

        // Create session for this project
        let session = Session(
            name: name,
            workingDirectory: projectDir
        )
        sessions.append(session)
        activeSessionId = session.id
        saveToDisk()
        return session
    }

    /// Set up initial shebang project files
    private func setupShebangFiles(in projectDir: URL, projectName: String) {
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())

        // Extract the bundled shebang.zip containing the full .shebang knowledge base
        // This includes: ANTI_PATTERNS.md, BEST_PRACTICES.md, system.md, docs/, web/, etc.
        extractShebangArchive(to: projectDir)

        let shebangDir = projectDir.appendingPathComponent(".shebang", isDirectory: true)

        // Ensure .shebang directory exists (in case zip extraction failed)
        try? FileManager.default.createDirectory(at: shebangDir, withIntermediateDirectories: true)

        // Create .claude directory for Claude Code settings
        let claudeDir = projectDir.appendingPathComponent(".claude", isDirectory: true)
        try? FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)

        // Create .claude/settings.json with default project settings
        let claudeSettings = """
        {
          "permissions": {
            "allow": ["Bash", "Read", "Write", "Edit", "Glob", "Grep"],
            "deny": []
          }
        }
        """
        try? claudeSettings.write(to: claudeDir.appendingPathComponent("settings.json"), atomically: true, encoding: .utf8)

        // Create kanban.json for task tracking (overwrites template with timestamps)
        let kanban = """
        {
          "lastUpdated": "\(now)",
          "columns": [
            {"id": "backlog", "name": "BACKLOG", "color": "accent", "tasks": []},
            {"id": "in_progress", "name": "IN PROGRESS", "color": "warning", "tasks": []},
            {"id": "review", "name": "REVIEW", "color": "purple", "tasks": []},
            {"id": "done", "name": "DONE", "color": "success", "tasks": []}
          ]
        }
        """
        try? kanban.write(to: shebangDir.appendingPathComponent("kanban.json"), atomically: true, encoding: .utf8)

        // Create metrics.json for productivity tracking (overwrites template with timestamps)
        let metrics = """
        {
          "lastUpdated": "\(now)",
          "productivity": {"multiplier": 0, "linesPerHour": 0, "baseline": 20},
          "codebase": {"totalLines": 0, "commits": 0, "features": {"completed": 0, "inProgress": 0, "planned": 0, "total": 0}},
          "timeline": {"startDate": "\(now)", "activeHours": 0, "calendarHours": 0}
        }
        """
        try? metrics.write(to: shebangDir.appendingPathComponent("metrics.json"), atomically: true, encoding: .utf8)

        // Create config.yaml with project-specific metadata
        let config = """
        name: "\(projectName)"
        description: "A new Shebang project"
        created: "\(now)"
        tags: []
        """
        try? config.write(to: shebangDir.appendingPathComponent("config.yaml"), atomically: true, encoding: .utf8)

        // Note: system.md is already in .shebang/ from the zip extraction
        // It contains the full agent workflow protocol, not project-specific content

        // Create CLAUDE.md with Claude Code instructions
        let claudeMd = """
        # CLAUDE.md

        This file provides guidance to Claude Code when working with this project.

        ## Project: \(projectName)

        ## Quick Start
        ```bash
        # Add setup commands here
        ```

        ## Architecture
        [Describe key components]

        ## Code Standards
        - Follow existing patterns in the codebase
        - Write tests for new functionality
        - Keep functions small and focused

        ## Git Commits
        - Use conventional commit messages
        - Keep commits atomic and focused

        ## Shebang Knowledge Base
        See `.shebang/` for comprehensive development guidelines:
        - `ANTI_PATTERNS.md` - What NOT to do
        - `BEST_PRACTICES.md` - Engineering guidelines
        - `CODE_QUALITY.md` - Language-specific standards
        - `system.md` - Agent workflow protocol
        """
        try? claudeMd.write(to: projectDir.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)

        // Create README.md
        let readme = """
        # \(projectName)

        > Created with [Shebang!](https://github.com/anthropics/shebang) - Automated Development Environment

        ## Overview
        [Project description]

        ## Getting Started
        ```bash
        # Installation steps
        ```

        ## Development
        This project uses Shebang for AI-assisted development. The `.shebang/` folder contains:
        - `kanban.json` - Task tracking
        - `metrics.json` - Productivity metrics
        - `config.yaml` - Project configuration
        - `ANTI_PATTERNS.md` - What NOT to do (65 years of wisdom)
        - `BEST_PRACTICES.md` - Engineering guidelines
        - `docs/` - Full documentation
        - `web/` - Documentation web server

        ## License
        [Choose a license]
        """
        try? readme.write(to: projectDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        // Create .gitignore with common patterns
        let gitignore = """
        # Dependencies
        node_modules/
        .venv/
        venv/
        __pycache__/

        # Build
        .build/
        dist/
        build/
        *.egg-info/

        # IDE
        .idea/
        .vscode/
        *.swp
        *.swo

        # OS
        .DS_Store
        Thumbs.db

        # Environment
        .env
        .env.local
        .env.*.local

        # Logs
        *.log
        logs/
        """
        try? gitignore.write(to: projectDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        // Initialize git repository
        let process = Process()
        process.currentDirectoryURL = projectDir
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init", "-q"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    /// Extract the bundled shebang.zip to the project directory
    private func extractShebangArchive(to projectDir: URL) {
        // Find the shebang.zip in the app bundle
        guard let zipURL = Bundle.module.url(forResource: "shebang", withExtension: "zip") else {
            print("Warning: shebang.zip not found in bundle, falling back to minimal setup")
            return
        }

        // Use unzip command to extract the archive
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", "-o", zipURL.path, "-d", projectDir.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                print("Warning: Failed to extract shebang.zip (exit code: \(process.terminationStatus))")
            }
        } catch {
            print("Warning: Failed to run unzip: \(error)")
        }
    }

    func closeSession(_ session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }

        // Kill the dtach process and clean up socket
        killDtachSession(for: session)

        // Mark as terminated instead of deleting (preserves history)
        sessions[index].status = .terminated
        sessions[index].touch()

        // Switch active session if this was active
        if activeSessionId == session.id {
            // Find another active/idle session to switch to
            let otherActiveSessions = sessions.filter {
                $0.id != session.id && ($0.status == .active || $0.status == .idle)
            }
            activeSessionId = otherActiveSessions.first?.id
            // If no active sessions, leave activeSessionId as nil
            // User must explicitly create a new session via the UI
        }

        saveToDisk()
    }

    /// Kill the dtach process for a session and remove its socket file
    /// IMPORTANT: Only kills the dtach master process, NOT child processes
    private func killDtachSession(for session: Session) {
        let socketPath = "/tmp/shebang-\(session.id.uuidString.prefix(8)).sock"

        // First check if socket exists
        guard FileManager.default.fileExists(atPath: socketPath) else {
            return
        }

        // Find the dtach master process for THIS specific socket
        // lsof syntax: lsof <filename> finds processes using that exact file
        // NOTE: Do NOT use -U flag - it filters to ALL unix sockets system-wide!
        let findProcess = Process()
        findProcess.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        findProcess.arguments = ["-t", socketPath]  // -t = PIDs only, no -U flag!

        let pipe = Pipe()
        findProcess.standardOutput = pipe
        findProcess.standardError = FileHandle.nullDevice

        do {
            try findProcess.run()
            findProcess.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                // Get PIDs - there should typically be just one (the dtach master)
                let pids = output.split(separator: "\n")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

                // Only kill the FIRST pid (dtach master process)
                // When dtach dies, it sends SIGHUP to children which gracefully terminates them
                if let dtachPid = pids.first {
                    // Use SIGTERM (graceful) not SIGKILL
                    let killProcess = Process()
                    killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
                    killProcess.arguments = ["-TERM", String(dtachPid)]
                    killProcess.standardOutput = FileHandle.nullDevice
                    killProcess.standardError = FileHandle.nullDevice
                    try? killProcess.run()
                    killProcess.waitUntilExit()
                }
            }
        } catch {
            // lsof failed - just remove the socket file
        }

        // Remove the socket file
        try? FileManager.default.removeItem(atPath: socketPath)
    }

    /// Reopen a terminated session
    func reopenSession(_ session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].status = .active
        sessions[index].touch()
        activeSessionId = session.id
        saveToDisk()
    }

    /// Permanently delete a session from history
    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }

        // If we deleted the active session, clear the active ID
        if activeSessionId == session.id {
            activeSessionId = activeSessions.first?.id
        }

        // Don't auto-create - let user explicitly create new sessions
        saveToDisk()
    }

    /// Get recently closed sessions (for history)
    var closedSessions: [Session] {
        sessions.filter { $0.status == .terminated }
            .sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    func selectSession(_ session: Session) {
        activeSessionId = session.id
    }

    /// Update the active session's working directory (reactive to terminal cd)
    func updateActiveSessionCWD(_ url: URL) {
        guard let index = sessions.firstIndex(where: { $0.id == activeSessionId }) else { return }
        sessions[index].workingDirectory = url
        sessions[index].touch()
        // Save to disk so CWD persists across restarts
        saveToDisk()
        // Track as recent project
        AppState.shared.ui.trackProject(url)
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

    // Project picker - now handled in sidebar
    var showProjectPicker = false

    // Display mode
    var displayMode: DisplayMode = .interactive

    // File preview
    var previewingFile: URL?

    // Recent projects (directories that have been opened)
    var recentProjects: [URL] = []

    // Favorites
    var favoriteFolders: [URL] = []

    // MARK: - App Support Directory

    private var appSupportDir: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Shebang", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Recent Projects Persistence

    private var recentProjectsURL: URL {
        appSupportDir.appendingPathComponent("recent_projects.json")
    }

    func loadRecentProjects() {
        guard FileManager.default.fileExists(atPath: recentProjectsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recentProjectsURL)
            let paths = try JSONDecoder().decode([String].self, from: data)
            recentProjects = paths.map { URL(fileURLWithPath: $0) }
        } catch {
            print("Failed to load recent projects: \(error)")
        }
    }

    func saveRecentProjects() {
        do {
            let paths = recentProjects.map { $0.path }
            let data = try JSONEncoder().encode(paths)
            try data.write(to: recentProjectsURL, options: .atomic)
        } catch {
            print("Failed to save recent projects: \(error)")
        }
    }

    /// Track a project directory as recently used (moves to front of list)
    func trackProject(_ url: URL) {
        // Remove if already in list
        recentProjects.removeAll { $0.path == url.path }
        // Add to front
        recentProjects.insert(url, at: 0)
        // Keep max 20
        if recentProjects.count > 20 {
            recentProjects = Array(recentProjects.prefix(20))
        }
        saveRecentProjects()
    }

    // MARK: - Favorites Persistence

    private var favoritesURL: URL {
        appSupportDir.appendingPathComponent("favorites.json")
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

    /// Whether Claude Code is currently running in the terminal
    /// When true, queries are sent as raw text; when false, wrapped as `claude "query"`
    var isClaudeRunning = false

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
        isClaudeRunning = false  // Assume interrupt exits Claude
    }

    /// Send Ctrl+D (EOF)
    func sendEOF() {
        sendControlCharacter(0x04)  // ASCII EOT (End of Transmission) = Ctrl+D
        isClaudeRunning = false  // EOF exits Claude
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
