# Swift API Reference

Auto-generated from source code docstrings.

---

## AppState

_Source: `Sources/ShebangApp/Models/AppState.swift`_

### `func prepareForReload()`

Prepare state for hot reload (serialize volatile data)

### `func restoreAfterReload()`

Restore after hot reload

### `var sessions: [Session] = []`

All sessions (active, idle, or backgrounded)

### `var activeSessionId: UUID?`

ID of the currently displayed session

### `func updateActiveSessionCWD(_ url: URL)`

Update the active session's working directory (reactive to terminal cd)

### `var rawOutput: Data = Data()`

Raw terminal output bytes (ANSI included) - the source of truth

### `var blocks: [TerminalBlock] = []`

Parsed blocks for the block view mode

### `var currentCommand = ""`

Current command being composed (not yet sent)

### `var lastExitCode: Int32?`

Exit code from the most recent command

### `var pendingCommand: String?`

Command waiting to be sent to the terminal PTY

### `var pendingControlChar: UInt8?`

Control character waiting to be sent (e.g., 0x03 for Ctrl+C)

### `func sendControlCharacter(_ char: UInt8)`

Send a control character (e.g., Ctrl+C = 0x03, Ctrl+D = 0x04)

### `func sendInterrupt()`

Send Ctrl+C (SIGINT)

### `func sendEOF()`

Send Ctrl+D (EOF)

### `func sendSuspend()`

Send Ctrl+Z (SIGTSTP - suspend)

---

## AppVersion

_Source: `Sources/ShebangApp/Models/AppVersion.swift`_

### `enum AppVersion`

App version management with semantic versioning

---

## Session

_Source: `Sources/ShebangApp/Models/Session.swift`_

### `struct Session: Identifiable, Codable, Equatable`

Represents a terminal/agent session

### `var createdAtFormatted: String`

Formatted creation time for display

### `var directoryName: String`

Short directory name for display

### `var statusSymbol: String`

Status indicator symbol

---

## ToolsInstaller

_Source: `Sources/ShebangApp/Services/ToolsInstaller.swift`_

### `enum ToolsInstaller`

Background installer for development tools
Uses Claude Code agent to guide interactive installations

---

## FavoritesDrawerView

_Source: `Sources/ShebangApp/Views/FavoritesDrawerView.swift`_

### `struct FavoritesDrawerView: View`

Drawer showing favorited folders, slides up from bottom

---

## FilePreviewView

_Source: `Sources/ShebangApp/Views/FilePreviewView.swift`_

### `struct FilePreviewView: View`

File preview panel that displays file contents in a read-only scrollable text view.
Uses monospaced font for code files and caches content via AppState.shared.files.

---

## MainWindowView

_Source: `Sources/ShebangApp/Views/MainWindowView.swift`_

### `struct MainWindowView: View`

Main window layout:
- Sidebar and Sessions panel RESIZE the terminal (HStack)
- File preview and Favorites drawer OVERLAY the terminal (ZStack)

### `struct PanelHandle: View`

Vertical clickable handle for opening/closing side panels

### `struct HorizontalPanelHandle: View`

Horizontal clickable handle for opening/closing top/bottom panels

---

## SessionPanelView

_Source: `Sources/ShebangApp/Views/SessionPanelView.swift`_

### `struct SessionPanelView: View`

Right panel displaying session list with controls

---

## SidebarView

_Source: `Sources/ShebangApp/Views/SidebarView.swift`_

### `struct SidebarView: View`

File browser sidebar with collapsible directory tree

### `struct DirectoryContentsView: View`

Shows the contents of a directory directly (not the directory itself)

---

## SplashScreenView

_Source: `Sources/ShebangApp/Views/SplashScreenView.swift`_

### `struct SplashScreenView: View`

Splash screen shown on app launch for 3 seconds

---

## SwiftTermView

_Source: `Sources/ShebangApp/Views/SwiftTermView.swift`_

### `struct SwiftTermView: NSViewRepresentable`

SwiftUI wrapper for SwiftTerm's LocalProcessTerminalView
Handles PTY connection, output capture, and session CWD

### `class ReadOnlyTerminalContainer: NSView`

Container that wraps terminal view with dtach session persistence
Allows: text selection, copy (Cmd+C), native scrolling

---

## TerminalCanvasView

_Source: `Sources/ShebangApp/Views/TerminalCanvasView.swift`_

### `struct TerminalCanvasView: View`

Terminal canvas that switches between interactive terminal and block view
based on AppState.shared.ui.displayMode

### `struct TerminalHeaderView: View`

Shows current working directory at top of terminal

### `struct TerminalBlocksView: View`

Displays parsed terminal output as structured blocks

### `struct TerminalBlockRow: View`

Individual block row displaying command, output, or agent response

### `struct EmptySessionView: View`

Shown when no session is active

### `struct EmptyBlocksView: View`

Shown when block view has no blocks yet

---


## Architecture Overview

### State Management

Shebang uses a React-like state decomposition pattern:

- `AppState` - Root singleton containing all sub-stores
- `SessionState` - Manages terminal sessions
- `UIState` - UI visibility and preferences
- `FileState` - File browser state
- `TerminalState` - Terminal output and command queue

### View Components

| Component | Purpose |
|-----------|---------|
| `MainWindowView` | Root HSplitView layout |
| `SidebarView` | File browser with reactive CWD and file system watching |
| `TerminalCanvasView` | Terminal display (interactive/block modes) |
| `SessionPanelView` | Session list and management |
| `SwiftTermView` | Terminal with dtach session persistence |

### Session Persistence

Sessions use dtach for persistence:
- Socket path: `/tmp/shebang-{session-id}.sock`
- Sessions survive app restarts
- Claude Code runs directly in the terminal

