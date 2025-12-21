# Shebang Power User Guide

A technical deep-dive into Shebang's architecture, internals, and advanced features for experienced developers.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [State Management](#state-management)
- [Command Routing](#command-routing)
- [Session Management](#session-management)
- [Terminal Integration](#terminal-integration)
- [File Browser](#file-browser)
- [Slash Commands Reference](#slash-commands-reference)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Hot Reload Development](#hot-reload-development)
- [Building from Source](#building-from-source)
- [Advanced Customization](#advanced-customization)

## Architecture Overview

Shebang follows a **React-like unidirectional data flow** pattern:

```
┌─────────────────────────────────────────────────┐
│              AppState (Singleton)               │
│  ┌──────────────────────────────────────────┐   │
│  │ SessionState  │ UIState                  │   │
│  │ FileState     │ TerminalState            │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────┐
│             Views (Pure Functions)              │
│  MainWindowView → CommandBarView                │
│                → SidebarView                    │
│                → SessionPanelView               │
│                → TerminalCanvasView             │
└─────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────┐
│          User Actions / Terminal Events         │
└─────────────────────────────────────────────────┘
```

### Key Design Principles

1. **State Survives Hot Reload**: `AppState.shared` is a singleton that persists across app rebuilds
2. **Views Are Stateless**: All UI is derived from `AppState` — no local @State for critical data
3. **Reactive Updates**: Views automatically re-render when state changes (via `@Observable`)
4. **Separation of Concerns**: Each sub-state handles one domain (sessions, UI, files, terminal)

### File Structure

```
Sources/ShebangApp/
├── ShebangApp.swift           # App entry point
├── Models/
│   ├── AppState.swift         # Root state + sub-states
│   ├── Session.swift          # Session model
│   └── AppVersion.swift       # Version info
├── Views/
│   ├── MainWindowView.swift   # Window layout
│   ├── CommandBarView.swift   # Command input + routing
│   ├── SidebarView.swift      # File browser
│   ├── SessionPanelView.swift # Session list
│   ├── TerminalCanvasView.swift # Terminal display
│   ├── SwiftTermView.swift    # PTY wrapper
│   ├── FilePreviewView.swift  # File preview overlay
│   ├── FavoritesDrawerView.swift # Favorites drawer
│   └── SplashScreenView.swift # Launch screen
└── Services/
    └── ToolsInstaller.swift   # Dependency installer
```

## State Management

### AppState Architecture

`AppState` is a singleton with four sub-stores:

```swift
@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    let sessions: SessionState     // Session lifecycle
    let ui: UIState               // UI panel state
    let files: FileState          // File browser state
    let terminal: TerminalState   // Terminal output
}
```

### SessionState

Manages session lifecycle and persistence:

```swift
@Observable
final class SessionState {
    var sessions: [Session] = []
    var activeSessionId: UUID?

    // Persistence
    func loadFromDisk()  // ~/Library/Application Support/Shebang/sessions.json
    func saveToDisk()

    // Actions
    func createSession(name: String?, at: URL?) -> Session
    func closeSession(_ session: Session)
    func selectSession(_ session: Session)
    func updateActiveSessionCWD(_ url: URL)  // Called by OSC 7
}
```

Sessions are persisted as JSON and restored on app launch.

### UIState

Tracks panel visibility and UI preferences:

```swift
@Observable
final class UIState {
    var sidebarOpen = true
    var sessionsPanelOpen = true
    var filePreviewOpen = false
    var favoritesDrawerOpen = false

    var displayMode: DisplayMode = .interactive  // .interactive or .blocks

    var commandHistory: [String] = []
    var historyIndex: Int?

    var favoriteFolders: [URL] = []  // Persisted separately
}
```

### TerminalState

Manages terminal output and command queue:

```swift
@Observable
final class TerminalState {
    var rawOutput: Data = Data()
    var blocks: [TerminalBlock] = []

    var pendingCommand: String?
    var pendingControlChar: UInt8?

    func sendCommand(_ command: String)
    func sendInterrupt()  // Ctrl+C
    func sendEOF()        // Ctrl+D
    func sendSuspend()    // Ctrl+Z
}
```

## Command Routing

The `CommandRouter` in `CommandBarView.swift` intelligently routes input:

```swift
enum CommandRouter {
    static func route(_ command: String, in state: AppState) {
        if command.hasPrefix("/") {
            handleSlashCommand(command, in: state)
        } else if command.hasPrefix("$ ") || command.hasPrefix("> ") {
            executeShellCommand(command.dropFirst(2), in: state)
        } else if isShellCommand(command) {
            executeShellCommand(command, in: state)
        } else {
            sendToClaudeCode(command, in: state)
        }
    }
}
```

### Detection Heuristics

**Shell Command Detection**:
1. Starts with known command (`ls`, `git`, `npm`, etc. — 80+ commands in the whitelist)
2. Starts with path execution (`./`, `~/`, `/`)
3. Contains shell operators (`|`, `>`, `>>`, `&&`, `||`, `;`)
4. Short (≤3 words) and no `?` character

**Natural Language Detection**:
- Anything else goes to Claude Code via `claude "<query>"`

### Explicit Routing

Users can force routing:
- `$ ls -la` → Shell command (forced)
- `/ask what is this?` → Claude Code (forced)
- `ls -la` → Shell command (auto-detected)
- `what is this?` → Claude Code (auto-detected)

## Session Management

### Session Lifecycle

```swift
struct Session: Identifiable, Codable {
    let id: UUID
    var name: String
    var workingDirectory: URL
    var createdAt: Date
    var lastActiveAt: Date
    var status: SessionStatus  // .active, .idle, .suspended, .terminated
}
```

### Persistence Strategy

**On Disk**: `~/Library/Application Support/Shebang/sessions.json`

```json
[
  {
    "id": "UUID",
    "name": "Session 1",
    "workingDirectory": "/Users/dev/project",
    "createdAt": "2024-12-21T10:00:00Z",
    "lastActiveAt": "2024-12-21T15:30:00Z",
    "status": "active"
  }
]
```

**Auto-save triggers**:
- Session creation
- Session close
- Manual save (but NOT on every `cd` — too noisy)

### Terminal Multiplexing

Unlike tmux/screen, Shebang uses a **single PTY per app instance** with session state tracking:

- Each session has its own `workingDirectory`
- The file browser reactively updates when `cd` changes the CWD
- OSC 7 terminal escape sequences update the session's CWD

This is simpler than multiple PTYs because:
1. No complex PTY lifecycle management
2. No need to detach/reattach
3. State is serialized to disk, not PTY buffers

## Terminal Integration

### PTY (Pseudo-Terminal)

Shebang uses SwiftTerm to provide a full PTY implementation. The terminal runs a login shell (`/bin/bash` or `/bin/zsh`) with proper environment setup.

### OSC 7: Working Directory Tracking

The terminal watches for **OSC 7 escape sequences** to track directory changes:

```
ESC ] 7 ; file://hostname/path/to/directory BEL
```

When the shell emits this (via `PROMPT_COMMAND` or `.zshrc` hooks), SwiftTerm notifies Shebang, which updates:
1. `SessionState.updateActiveSessionCWD(url)`
2. File browser refreshes to show new directory
3. Command bar prompt updates to show new path

### Control Characters

The terminal accepts control characters for process management:

| Key | Code | Function |
|-----|------|----------|
| Ctrl+C | `0x03` | SIGINT (interrupt) |
| Ctrl+D | `0x04` | EOF (end of file) |
| Ctrl+Z | `0x1A` | SIGTSTP (suspend) |

These are sent via `TerminalState.sendControlCharacter()`.

### Display Modes

#### Interactive Mode

Uses `SwiftTermView` — a full VT100/xterm-compatible terminal. Supports:
- ANSI colors and formatting
- Cursor positioning
- Screen clearing
- Scrollback buffer
- Text selection

#### Block Mode

Parses terminal output into structured blocks:

```swift
struct TerminalBlock: Identifiable {
    let id: UUID
    let type: BlockType  // .command, .output, .toolCall, .agentResponse, .error
    var content: String
    var timestamp: Date
    var isComplete: Bool
}
```

Block parsing is still TODO — currently shows an empty state.

## File Browser

### Reactive Directory Tracking

The file browser shows the **contents** of the current working directory, not a project root:

```swift
struct DirectoryContentsView: View {
    let url: URL  // CWD

    var body: some View {
        // ...
    }
    .task(id: url.path) {
        await loadContentsAsync()  // Auto-reloads when URL changes
    }
}
```

This creates a **reactive file browser** that updates when you `cd`:

1. User runs `cd ~/projects`
2. OSC 7 updates `session.workingDirectory`
3. File browser's `url` binding changes
4. `.task(id: url.path)` triggers reload
5. New directory contents appear

### File Tree Node

```swift
struct FileTreeNode: View {
    let url: URL
    @Binding var expandedFolders: Set<URL>
    @Binding var selectedFile: URL?
    let depth: Int  // For indentation

    private var isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}
```

**Lazy loading**: Children are only loaded when a folder is expanded.

**Sorting**: Directories first, then alphabetically (case-insensitive).

### File Preview

Clicking a file opens `FilePreviewView` as a **ZStack overlay**:

```swift
ZStack(alignment: .leading) {
    TerminalCanvasView()  // Base layer

    if state.ui.filePreviewOpen, let file = state.ui.previewingFile {
        FilePreviewView(file: file, onClose: closeFilePreview)
            .background(.ultraThinMaterial)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
```

The preview **overlays the terminal**, not the entire window — so you can still see sessions and the command bar.

## Slash Commands Reference

### Implementation

All slash commands are handled in `CommandRouter.handleSlashCommand()`:

```swift
switch cmd.lowercased() {
case "favorite", "fav":
    if let session = state.sessions.activeSession {
        state.ui.addFavorite(session.workingDirectory)
    }

case "reload":
    hotReload()

case "help":
    showHelp(in: state)

case "new":
    state.sessions.createSession()

case "ask", "claude":
    let query = parts.count > 1 ? String(parts[1]) : ""
    if !query.isEmpty {
        sendToClaudeCode(query, in: state)
    }

default:
    state.terminal.sendCommand("echo 'Unknown command: /\(cmd).'")
}
```

### Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/help` | Show available commands | `/help` |
| `/favorite`, `/fav` | Add CWD to favorites | `/fav` |
| `/reload` | Hot reload the app | `/reload` |
| `/new` | Create new session | `/new` |
| `/ask <query>` | Explicit Claude Code query | `/ask what is this file?` |
| `/claude <query>` | Alias for `/ask` | `/claude explain this error` |

### Tab Completion

Slash commands support tab completion:

```swift
if input.hasPrefix("/") {
    let partial = String(input.dropFirst())
    let commands = ["help", "favorite", "fav", "reload", "new", "ask", "claude"]
    completions = commands.filter { $0.hasPrefix(partial) }.map { "/\($0)" }
}
```

Type `/fa[Tab]` → `/favorite`

## Keyboard Shortcuts

### Command Bar Shortcuts

Implemented via `.onKeyPress()` modifiers:

```swift
.onKeyPress(.return, phases: .down) { event in
    if event.modifiers.contains(.shift) {
        executeCommand()  // Shift+Enter
        return .handled
    }
    return .ignored  // Enter = newline
}

.onKeyPress(.tab) {
    triggerCompletion()
    return .handled
}

.onKeyPress(keys: [.init("c")], phases: .down) { event in
    if event.modifiers.contains(.control) {
        state.terminal.sendInterrupt()  // Ctrl+C
        return .handled
    }
    return .ignored
}
```

### Panel Toggles

Implemented via `.onReceive(NotificationCenter)` and toolbar buttons:

```swift
.onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
    state.ui.sidebarOpen.toggle()
}
```

**Shortcuts**:
- **Cmd+B**: Toggle sidebar
- **Cmd+0**: Toggle sessions panel
- **Cmd+Shift+F**: Toggle favorites drawer

### History Navigation

```swift
.onKeyPress(.upArrow) {
    if !commandText.contains("\n") {
        navigateHistory(direction: -1)
        return .handled
    }
    return .ignored  // Allow default behavior in multi-line
}
```

## Hot Reload Development

### The Magic of `/reload`

Shebang can **rebuild and restart itself** without losing state:

```swift
static func hotReload() {
    Task {
        // 1. Save state
        AppState.shared.prepareForReload()

        // 2. Get app bundle path
        let appPath = Bundle.main.bundlePath
        let appDir = URL(fileURLWithPath: appPath).deletingLastPathComponent()

        // 3. Run build script and relaunch
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", """
            cd "\(appDir.path)" && ./build.sh && sleep 0.5 && open Shebang.app
        """]

        try process.run()

        // 4. Exit current app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApplication.shared.terminate(nil)
        }
    }
}
```

### State Persistence

`AppState.prepareForReload()` serializes volatile state:

```swift
func prepareForReload() {
    sessions.saveToDisk()  // Write sessions.json
    // Terminal PTY will reconnect automatically
}
```

When the new app launches:
1. `SessionState.loadFromDisk()` restores sessions
2. Active session is re-selected
3. Terminal spawns a new PTY in the same working directory
4. User continues working seamlessly

### Development Workflow

1. Make code changes in your editor
2. Type `/reload` in Shebang
3. App rebuilds and relaunches in ~2 seconds
4. Sessions and state are preserved

This is **dogfooding at its finest** — Shebang builds itself using itself.

## Building from Source

### Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15+ (for Swift 5.9+)
- Swift Package Manager (included with Xcode)

### Build Script

The `build.sh` script handles the entire build process:

```bash
#!/bin/bash
swift build --configuration release

# Create app bundle
rm -rf Shebang.app
mkdir -p Shebang.app/Contents/MacOS
mkdir -p Shebang.app/Contents/Resources

# Copy binary
cp .build/release/Shebang Shebang.app/Contents/MacOS/

# Generate Info.plist with versioning
# Generate app icon from Assets/AppIcon.png
# Sign with entitlements
```

### Build Commands

```bash
# Standard build
./build.sh

# Build and run
./build.sh --run

# Bump version and build
./build.sh --bump
```

### Versioning

Version is stored in `VERSION` file (semantic versioning):

```
0.0.1
```

The build script:
- Reads `VERSION` file
- Optionally bumps patch version with `--bump`
- Embeds version in `Info.plist` as `CFBundleShortVersionString`
- Uses patch number as `CFBundleVersion` (build number)

### Entitlements

`Shebang.entitlements` grants necessary permissions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

**No sandbox** is required because:
- We need full PTY access
- We need to run arbitrary shell commands
- We need to access the file system reactively

### Icon Generation

If `Assets/AppIcon.png` exists, the build script:
1. Creates an `AppIcon.iconset` directory
2. Uses `sips` to generate all required sizes (16x16 to 512x512 @2x)
3. Converts to `.icns` with `iconutil`
4. Embeds in app bundle

## Advanced Customization

### Adding Shell Commands to Detection

Edit the `shellCommands` set in `CommandBarView.swift`:

```swift
private static let shellCommands: Set<String> = [
    "ls", "cd", "git", "npm", "python",
    // Add your custom commands here
    "mycommand", "mytool"
]
```

### Customizing Git Status Display

Edit `GitInfo.fetch()` in `CommandBarView.swift` to parse additional git info:

```swift
// Get ahead/behind counts
let tracking = await runGit(["rev-list", "--left-right", "--count", "@{u}..."], at: url)
// Parse and display
```

### Extending Slash Commands

Add new cases to `CommandRouter.handleSlashCommand()`:

```swift
case "custom":
    // Your custom command logic
    state.terminal.sendCommand("echo 'Custom command executed'")
```

### Panel Sizing

Edit constants in `MainWindowView.swift`:

```swift
private let sidebarWidth: CGFloat = 260
private let sessionsPanelWidth: CGFloat = 280
private let filePreviewWidth: CGFloat = 500
private let favoritesDrawerHeight: CGFloat = 200
```

### Terminal Shell

SwiftTerm spawns a login shell from the user's default shell. To customize:

Edit `SwiftTermView.swift`:

```swift
let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
// Change to:
let shell = "/bin/bash"  // Force bash
```

### Favorites Persistence

Favorites are stored separately from sessions:

**Location**: `~/Library/Application Support/Shebang/favorites.json`

```json
[
  "/Users/dev/projects/shebang",
  "/Users/dev/documents"
]
```

## Debugging

### Print Debugging

Use standard Swift debugging:

```swift
print("⚠️ State change: \(state.sessions.sessions.count) sessions")
```

Output appears in Xcode console when running from Xcode, or in Console.app when running the built app.

### Inspecting State

Add temporary UI to display state:

```swift
VStack {
    Text("Sessions: \(state.sessions.sessions.count)")
    Text("Active: \(state.sessions.activeSessionId?.uuidString ?? "none")")
}
```

### Terminal Output Inspection

Enable raw output logging in `TerminalState`:

```swift
func appendOutput(_ data: Data) {
    rawOutput.append(data)
    if let str = String(data: data, encoding: .utf8) {
        print("📺 Terminal output: \(str)")
    }
}
```

## Performance Considerations

### File Browser Lazy Loading

The file browser only loads children when folders are expanded:

```swift
.onChange(of: isExpanded) { _, expanded in
    if expanded {
        loadChildren()  // Only load when needed
    }
}
```

### Session Persistence Strategy

Sessions are saved:
- On create/close (infrequent)
- NOT on every `cd` (would thrash disk)

### Terminal Output Buffering

Terminal output is buffered in `Data` and only parsed when switching to block mode. This keeps interactive mode performant.

## Security Notes

### No Sandbox

Shebang runs **without App Sandbox** to support:
- Full PTY access
- Arbitrary shell command execution
- Unrestricted file system access

This is required for a terminal-based tool but means:
- Users should only run trusted commands
- The app has full access to the user's files

### Entitlements

The app is **ad-hoc signed** (`codesign --sign -`) which is sufficient for local development. For distribution, you'd need:
- Apple Developer ID certificate
- Notarization

## Future Enhancements

### Block Mode Parsing (TODO)

Currently unimplemented. Would parse terminal output into blocks:

```swift
// Parse ANSI sequences
// Detect prompt patterns
// Extract commands vs output
// Identify Claude Code tool calls
```

### Multiple PTYs per Session

Currently one PTY for the entire app. Could be enhanced to:
- One PTY per session
- Persist PTY state between app launches (like tmux)

### Session Import/Export

Export sessions to share with teammates:

```bash
/export-session my-project  # → my-project.shebangsession
/import-session my-project.shebangsession
```

### Custom Themes

Allow customization of terminal colors, fonts, and UI themes.

---

## Contributing

Shebang is built using Shebang. To contribute:

1. Clone the repo
2. Open Shebang
3. Navigate to the repo directory
4. Make changes
5. Type `/reload` to rebuild
6. Test your changes
7. Submit a PR

The `/reload` command makes iteration instant — no need to leave the app.

## License

MIT — see LICENSE file for details.

---

**Shebang is dogfooded daily.** Every feature exists because we needed it while building Shebang. The `/reload` command alone saves hours every week.

The interface fades away. The work remains.
