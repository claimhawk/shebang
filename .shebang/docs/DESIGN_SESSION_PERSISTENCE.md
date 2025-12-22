# Session Persistence Design (Screen/Tmux-like)

## Goal

Enable sessions to persist beyond app lifecycle, similar to screen/tmux, but without the hotkey complexity. Sessions should:

1. Survive app quit/restart
2. Allow detach/attach semantics
3. Be invisible to users (no screen/tmux UI)
4. Work automatically in the background

## Architecture Options

### Option 1: Launch Agent Daemon (Recommended)

A lightweight daemon process (`shebang-daemon`) runs in the background and owns the PTY sessions.

```
┌─────────────────────┐       ┌─────────────────────┐
│   Shebang.app       │ ←───→ │  shebang-daemon     │
│   (UI frontend)     │  IPC  │  (PTY backend)      │
│   - Views           │       │  - PTY sessions     │
│   - Command bar     │       │  - Shell processes  │
│   - File browser    │       │  - Output buffer    │
└─────────────────────┘       └─────────────────────┘
                                       ↓
                              ┌─────────────────────┐
                              │   zsh/bash shells   │
                              └─────────────────────┘
```

**Implementation:**
1. Create `shebang-daemon` binary (Swift)
2. Register as LaunchAgent for auto-start
3. Communication via Unix domain socket
4. Daemon owns PTY file descriptors
5. App connects to daemon on launch
6. Daemon keeps sessions alive when app closes

**Pros:**
- True persistence like screen/tmux
- Clean separation of concerns
- Can have sessions running without UI

**Cons:**
- More complex architecture
- Need daemon lifecycle management
- IPC overhead (minimal)

### Option 2: XPC Service

Use macOS XPC for process communication.

**Pros:**
- Apple-blessed IPC mechanism
- Automatic lifecycle management
- Sandboxing support

**Cons:**
- Requires app sandbox (we disabled it)
- More complex setup
- Apple-specific

### Option 3: Terminal Output Persistence Only

Simpler approach: persist terminal output/history, not running processes.

**Implementation:**
1. Save terminal scrollback to disk periodically
2. On app restart, restore scrollback view
3. Shell process restarts fresh, but history looks continuous

**Pros:**
- Simple implementation
- No daemon needed
- Works within current architecture

**Cons:**
- Running processes don't survive (not true persistence)
- Long-running commands are killed on quit

## Recommended Implementation Plan

### Phase 1: Daemon Foundation
1. Create `shebang-daemon` target in Package.swift
2. Implement Unix socket server
3. Move PTY creation to daemon
4. App becomes client connecting to daemon

### Phase 2: Session Management
1. Daemon tracks session metadata
2. App can list/attach to existing sessions
3. Session output buffered in daemon
4. Attach sends historical output to app

### Phase 3: Launch Agent
1. Create LaunchAgent plist
2. Auto-start daemon on login
3. Keep-alive configuration
4. Clean shutdown handling

### Phase 4: UI Integration
1. Show "backgrounded" sessions in session list
2. Visual indicator for attached/detached
3. Auto-attach to most recent session on launch

## File Structure

```
Sources/
├── ShebangApp/          # UI app (existing)
└── ShebangDaemon/       # New daemon
    ├── main.swift
    ├── DaemonService.swift
    ├── PTYManager.swift
    ├── SessionStore.swift
    └── IPCProtocol.swift

LaunchAgents/
└── com.shebang.daemon.plist
```

## IPC Protocol (Draft)

```swift
enum DaemonMessage {
    case listSessions
    case createSession(name: String, cwd: URL)
    case attachSession(id: UUID)
    case detachSession(id: UUID)
    case sendInput(sessionId: UUID, data: Data)
    case resize(sessionId: UUID, cols: Int, rows: Int)
}

enum AppMessage {
    case sessionList([SessionInfo])
    case sessionOutput(sessionId: UUID, data: Data)
    case sessionExited(sessionId: UUID, code: Int32)
    case error(String)
}
```

## Timeline Estimate

- Phase 1: 2-3 days (daemon foundation)
- Phase 2: 2-3 days (session management)
- Phase 3: 1 day (LaunchAgent)
- Phase 4: 1-2 days (UI integration)

**Total: ~1 week for full implementation**

## Alternative: Quick Win

For faster iteration, implement Option 3 (output persistence) first:
- Save last N lines of terminal output
- Restore on app restart
- Shows continuity even if process doesn't survive

This gives 80% of the UX benefit with 20% of the effort.
