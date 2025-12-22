// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import SwiftTerm
import AppKit

/// SwiftUI wrapper for SwiftTerm's LocalProcessTerminalView
/// Handles PTY connection, output capture, and session CWD
struct SwiftTermView: NSViewRepresentable {
    let session: Session

    // Output callback for block parsing
    var onOutput: ((Data) -> Void)?

    // Command to execute (nil = interactive shell)
    var initialCommand: String?

    // Observe pending commands from AppState
    var pendingCommand: String?

    // Observe pending control characters (Ctrl+C, etc.)
    var pendingControlChar: UInt8?

    // Interactive mode - when true, keyboard passes through to terminal
    var isInteractiveMode: Bool = false

    func makeNSView(context: Context) -> ReadOnlyTerminalContainer {
        let terminalView = LocalProcessTerminalView(frame: .zero)

        // Store reference in coordinator
        context.coordinator.terminalView = terminalView

        // Configure terminal appearance
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeBackgroundColor = DefaultTheme.shared.background
        terminalView.nativeForegroundColor = DefaultTheme.shared.foreground

        // Disable mouse reporting so mouse events are used for text selection
        // instead of being sent to terminal apps (like tmux) as escape sequences
        terminalView.allowMouseReporting = false

        // Set delegate for output capture
        terminalView.processDelegate = context.coordinator

        let workDir = session.workingDirectory.path

        // Use tmux for session persistence (provides history, process survival, etc.)
        // Launch shell first, then exec into tmux (SwiftTerm needs shell as entry point)
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let tmuxSessionName = "shebang-\(session.id.uuidString.prefix(8))"

        // Shell command that starts/attaches to tmux session
        let tmuxCommand = "\(Self.tmuxPath) new-session -A -s \(tmuxSessionName) -c '\(workDir)'"

        terminalView.startProcess(
            executable: shell,
            args: ["-c", tmuxCommand],
            environment: buildEnvironment(),
            execName: "zsh"
        )

        // Set up shell integration inside tmux (delay for tmux init)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupShellIntegration(terminalView)
        }

        // Start CWD polling as fallback (tmux passthrough may not work with all terminals)
        Self.startCWDPolling(for: session.id)

        // Wrap in read-only container that blocks keyboard input
        let container = ReadOnlyTerminalContainer(terminalView: terminalView)
        container.tmuxSessionName = tmuxSessionName  // Enable scrollbar sync with tmux
        context.coordinator.container = container
        return container
    }

    func updateNSView(_ nsView: ReadOnlyTerminalContainer, context: Context) {
        // Update coordinator callback
        context.coordinator.onOutput = onOutput

        // Update interactive mode - allows keyboard passthrough when Claude is running
        nsView.isInteractiveMode = isInteractiveMode

        // Send pending command if available
        if let command = pendingCommand, let terminalView = context.coordinator.terminalView {
            terminalView.send(txt: command)
            // Clear the pending command on main thread
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingCommand = nil
            }
        }

        // Send pending control character if available (Ctrl+C, Ctrl+D, etc.)
        if let controlChar = pendingControlChar, let terminalView = context.coordinator.terminalView {
            // Send the control character as raw byte using ArraySlice
            let bytes: [UInt8] = [controlChar]
            terminalView.send(data: bytes[...])
            // Clear the pending control character on main thread
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingControlChar = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOutput: onOutput)
    }

    // MARK: - Environment

    private func buildEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["LANG"] = "en_US.UTF-8"
        // Don't inherit the original PWD
        env.removeValue(forKey: "PWD")

        // Enable shell integration for directory tracking
        // This tells zsh/bash to emit OSC 7 sequences on directory change
        env["TERM_PROGRAM"] = "Shebang"
        env["TERM_PROGRAM_VERSION"] = "1.0"

        // Set up prompt command for bash to report CWD
        env["PROMPT_COMMAND"] = "printf '\\e]7;file://%s%s\\e\\\\' \"$HOSTNAME\" \"$PWD\""

        return env.map { "\($0.key)=\($0.value)" }
    }

    // MARK: - Helpers

    /// Set up shell integration for directory tracking inside tmux
    /// This configures the shell to emit OSC 7 sequences that SwiftTerm can receive
    private func setupShellIntegration(_ terminalView: LocalProcessTerminalView) {
        // Enable tmux passthrough mode so escape sequences reach the outer terminal (SwiftTerm)
        // tmux 3.3+ supports 'all' for allow-passthrough, earlier versions use 'on'
        terminalView.send(txt: "tmux set-option -g allow-passthrough all 2>/dev/null || tmux set-option -g allow-passthrough on 2>/dev/null\n")

        // NOTE: We do NOT enable tmux mouse mode because it sends escape sequences
        // that re-enable mouse reporting, breaking SwiftTerm's native text selection.
        // Scrolling is handled by our custom scroller that talks to tmux directly.

        // Set up the zsh chpwd hook to emit OSC 7 with DCS passthrough
        // DCS format: \eP (start) + tmux; (app identifier) + \e (escape the inner sequence) + sequence + \e\\ (end DCS)
        // The inner OSC 7 is: \e]7;file://hostname/path\a
        let zshHook = """
        chpwd() { printf '\\033Ptmux;\\033\\033]7;file://%s%s\\007\\033\\\\' "$(hostname)" "$PWD" }
        """
        terminalView.send(txt: zshHook + "\n")

        // Also set precmd to emit on every prompt (catches directory changes from all sources)
        let precmdHook = """
        precmd() { printf '\\033Ptmux;\\033\\033]7;file://%s%s\\007\\033\\\\' "$(hostname)" "$PWD" }
        """
        terminalView.send(txt: precmdHook + "\n")

        // Emit initial directory for tracking
        terminalView.send(txt: "printf '\\033Ptmux;\\033\\033]7;file://%s%s\\007\\033\\\\' \"$(hostname)\" \"$PWD\"\n")

        // Clear the screen to hide the setup commands
        terminalView.send(txt: "clear\n")
    }

    /// Active CWD polling timers by session ID
    private static var cwdPollingTimers: [UUID: Timer] = [:]

    /// Start polling tmux for the current pane's working directory
    /// This is the primary CWD tracking mechanism since DCS passthrough is unreliable
    static func startCWDPolling(for sessionId: UUID, interval: TimeInterval = 1.0) {
        // Don't start duplicate timers
        guard cwdPollingTimers[sessionId] == nil else { return }

        let tmuxSessionName = "shebang-\(sessionId.uuidString.prefix(8))"

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            queryTmuxCWD(sessionName: tmuxSessionName) { path in
                guard let path = path else { return }
                let url = URL(fileURLWithPath: path)

                DispatchQueue.main.async {
                    // Only update if this is still the active session and path changed
                    guard AppState.shared.sessions.activeSessionId == sessionId else { return }
                    guard AppState.shared.sessions.activeSession?.workingDirectory != url else { return }

                    print("🔄 [tmux poll] CWD changed to: \(path)")
                    AppState.shared.sessions.updateActiveSessionCWD(url)
                }
            }
        }

        cwdPollingTimers[sessionId] = timer
    }

    /// Stop CWD polling for a session
    static func stopCWDPolling(for sessionId: UUID) {
        cwdPollingTimers[sessionId]?.invalidate()
        cwdPollingTimers.removeValue(forKey: sessionId)
    }

    /// Query tmux for the current working directory of a pane
    private static func queryTmuxCWD(sessionName: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: tmuxPath)
            process.arguments = [
                "display-message",
                "-t", sessionName,
                "-p", "#{pane_current_path}"
            ]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    completion(output)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
    }

    /// Check if tmux is available on the system
    private static var tmuxAvailable: Bool = {
        FileManager.default.fileExists(atPath: "/usr/bin/tmux") ||
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/tmux") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/tmux")
    }()

    /// Get tmux executable path (used by container for scroll commands)
    static var tmuxPath: String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/tmux") {
            return "/opt/homebrew/bin/tmux"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/tmux") {
            return "/usr/local/bin/tmux"
        }
        return "/usr/bin/tmux"
    }

    /// Check if Homebrew is installed
    private static var brewAvailable: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
    }

    /// Get brew executable path
    private static var brewPath: String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
            return "/opt/homebrew/bin/brew"
        }
        return "/usr/local/bin/brew"
    }

    /// Ensure all dependencies are installed (called on app startup)
    /// Installs: Homebrew (if needed), tmux
    static func ensureDependencies(in terminalView: LocalProcessTerminalView? = nil) {
        // Run dependency installation in terminal if provided
        if let terminal = terminalView {
            var commands: [String] = []

            // Install Homebrew if not present
            if !brewAvailable {
                commands.append("echo '📦 Installing Homebrew...'")
                commands.append("/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                commands.append("eval \"$(/opt/homebrew/bin/brew shellenv)\"")
            }

            // Install tmux if not present
            if !tmuxAvailable {
                commands.append("echo '📦 Installing tmux...'")
                commands.append("brew install tmux")
            }

            if !commands.isEmpty {
                commands.append("echo '✅ Dependencies installed. Restart Shebang to apply.'")
                let script = commands.joined(separator: " && ")
                terminal.send(txt: script + "\n")
            }
            return
        }

        // Background installation (no terminal UI)
        guard !tmuxAvailable else { return }
        guard brewAvailable else {
            print("⚠️ Homebrew not installed. Use Tools > Install Dependencies menu.")
            return
        }

        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "tmux"]

            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    print("✅ tmux installed successfully")
                }
            } catch {
                print("⚠️ Failed to install tmux: \(error)")
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onOutput: ((Data) -> Void)?
        weak var terminalView: LocalProcessTerminalView?
        weak var container: ReadOnlyTerminalContainer?

        init(onOutput: ((Data) -> Void)?) {
            self.onOutput = onOutput
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            // Terminal size changed - update PTY
        }

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            // Terminal title changed (from escape sequence)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            // Directory changed - update session CWD reactively
            // OSC 7 sends: file://hostname/path - we need just the path
            guard let dir = directory else {
                print("🔄 Terminal CWD update received: nil")
                return
            }

            print("🔄 Terminal CWD update received: '\(dir)' (length: \(dir.count))")

            let url: URL
            if dir.hasPrefix("file://") {
                // Parse OSC 7 URL format: file://hostname/path
                if let parsed = URL(string: dir), let path = parsed.path.removingPercentEncoding {
                    url = URL(fileURLWithPath: path.isEmpty ? "/" : path)
                } else {
                    return
                }
            } else {
                // Plain path
                url = URL(fileURLWithPath: dir)
            }

            DispatchQueue.main.async {
                print("🔄 Updating session CWD to: \(url.path)")
                AppState.shared.sessions.updateActiveSessionCWD(url)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            // Shell process ended
            print("Terminal process exited: \(exitCode ?? -1)")
        }
    }
}

// MARK: - Read-Only Terminal Container

/// Container that wraps terminal view and conditionally blocks keyboard input
/// When NOT in interactive mode: blocks keyboard (input goes through command bar)
/// When in interactive mode: passes keyboard to terminal (for Claude interaction)
/// Always allows: text selection, copy (Cmd+C), scrolling
class ReadOnlyTerminalContainer: NSView {
    let terminalView: LocalProcessTerminalView
    private let padding: CGFloat = 12
    private let scrollerWidth: CGFloat = 14

    /// When true, keyboard input passes through to terminal
    var isInteractiveMode: Bool = false

    /// Re-entrancy guard to prevent responder chain loops
    private var isHandlingEvent: Bool = false

    /// Custom scroller for tmux scroll visualization
    private var scroller: NSScroller!

    /// tmux session name for scroll commands
    var tmuxSessionName: String?

    /// Current scroll state
    private var historySize: Int = 0
    private var scrollPosition: Int = 0
    private var paneHeight: Int = 50
    private var isInCopyMode: Bool = false

    /// Timer for updating scroll position
    private var scrollUpdateTimer: Timer?

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        // Match terminal background so padding looks internal
        wantsLayer = true
        layer?.backgroundColor = DefaultTheme.shared.background.cgColor

        // Add terminal as subview with padding (leave room for scroller on right)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding - scrollerWidth)
        ])

        // Create scroller
        setupScroller()

        // Start polling tmux for scroll state
        startScrollUpdateTimer()
    }

    private func setupScroller() {
        let scrollerFrame = NSRect(x: bounds.maxX - scrollerWidth, y: padding, width: scrollerWidth, height: bounds.height - padding * 2)
        scroller = NSScroller(frame: scrollerFrame)
        scroller.autoresizingMask = [.minXMargin, .height]
        scroller.scrollerStyle = .overlay
        scroller.knobProportion = 1.0
        scroller.doubleValue = 1.0  // Start at bottom
        scroller.isEnabled = false  // Enable when there's scrollback
        scroller.target = self
        scroller.action = #selector(scrollerActivated)
        addSubview(scroller)
    }

    override func layout() {
        super.layout()
        // Update scroller frame on resize
        scroller.frame = NSRect(x: bounds.maxX - scrollerWidth, y: padding, width: scrollerWidth, height: bounds.height - padding * 2)
    }

    @objc private func scrollerActivated() {
        guard let sessionName = tmuxSessionName else { return }

        switch scroller.hitPart {
        case .knob, .knobSlot:
            // User dragging the knob - scroll to position
            let targetPosition = scroller.doubleValue
            scrollTmuxToPosition(sessionName: sessionName, position: targetPosition)
        case .decrementPage:
            // Clicked above knob - page up
            scrollTmuxPageUp(sessionName: sessionName)
        case .incrementPage:
            // Clicked below knob - page down
            scrollTmuxPageDown(sessionName: sessionName)
        default:
            break
        }
    }

    private func scrollTmuxToPosition(sessionName: String, position: Double) {
        // Calculate target line from position (0.0 = top, 1.0 = bottom)
        let totalLines = historySize + paneHeight
        let targetLine = Int(Double(totalLines) * (1.0 - position))

        // Enter copy mode if not already
        if !isInCopyMode {
            runTmuxCommand("copy-mode -t \(sessionName)")
            isInCopyMode = true
        }

        // Go to specific line using goto-line
        runTmuxCommand("send-keys -t \(sessionName) -X goto-line \(targetLine)")
    }

    private func scrollTmuxPageUp(sessionName: String) {
        if !isInCopyMode {
            runTmuxCommand("copy-mode -t \(sessionName)")
            isInCopyMode = true
        }
        runTmuxCommand("send-keys -t \(sessionName) -X page-up")
    }

    private func scrollTmuxPageDown(sessionName: String) {
        if isInCopyMode {
            runTmuxCommand("send-keys -t \(sessionName) -X page-down")
        }
    }

    private func runTmuxCommand(_ command: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: SwiftTermView.tmuxPath)
        task.arguments = command.split(separator: " ").map(String.init)
        try? task.run()
    }

    private func startScrollUpdateTimer() {
        scrollUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateScrollState()
        }
    }

    private func updateScrollState() {
        guard let sessionName = tmuxSessionName else { return }

        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: SwiftTermView.tmuxPath)
        task.arguments = ["list-panes", "-t", sessionName, "-F", "#{pane_height} #{history_size} #{scroll_position}"]
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let parts = output.split(separator: " ").map(String.init)
                if parts.count >= 2 {
                    paneHeight = Int(parts[0]) ?? 50
                    historySize = Int(parts[1]) ?? 0

                    // scroll_position is only set in copy mode
                    if parts.count >= 3, let sp = Int(parts[2]) {
                        scrollPosition = sp
                        isInCopyMode = true
                    } else {
                        scrollPosition = 0  // At bottom
                        isInCopyMode = false
                    }

                    DispatchQueue.main.async { [weak self] in
                        self?.updateScrollerUI()
                    }
                }
            }
        } catch {
            // Ignore errors
        }
    }

    private func updateScrollerUI() {
        let totalLines = historySize + paneHeight
        guard totalLines > paneHeight else {
            scroller.isEnabled = false
            return
        }

        scroller.isEnabled = true

        // Knob proportion = visible / total
        let proportion = Double(paneHeight) / Double(totalLines)
        scroller.knobProportion = CGFloat(proportion)

        // Position: 0 = top, 1 = bottom
        // scroll_position is lines from top (when in copy mode)
        if isInCopyMode {
            let maxScroll = totalLines - paneHeight
            let position = 1.0 - (Double(scrollPosition) / Double(maxScroll))
            scroller.doubleValue = position
        } else {
            scroller.doubleValue = 1.0  // At bottom
        }
    }

    deinit {
        scrollUpdateTimer?.invalidate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Allow first responder for copy operations and interactive mode
    override var acceptsFirstResponder: Bool { true }

    // Intercept key events - pass through in interactive mode
    // CRITICAL: Never call super or forward to terminalView without explicit handling
    // to avoid responder chain loops that cause stack overflow
    override func keyDown(with event: NSEvent) {
        // Re-entrancy guard - prevent infinite loops
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        // In interactive mode, pass all keys to terminal
        if isInteractiveMode {
            terminalView.keyDown(with: event)
            return
        }

        // Otherwise only allow Cmd+C for copy
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
            terminalView.keyDown(with: event)
            return
        }
        // Block all other keyboard input in read-only mode - do NOT call super
    }

    override func keyUp(with event: NSEvent) {
        // Re-entrancy guard - prevent infinite loops from LocalProcessTerminalView forwarding
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        // Only forward keyUp in interactive mode
        // CRITICAL: Never call super to avoid responder chain loops
        if isInteractiveMode {
            terminalView.keyUp(with: event)
        }
        // Consume the event - don't let it propagate further
    }

    // Consume flag changes to prevent responder chain issues
    override func flagsChanged(with event: NSEvent) {
        // Re-entrancy guard
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        if isInteractiveMode {
            terminalView.flagsChanged(with: event)
        }
        // Consume - don't call super
    }

    // Override nextResponder to break any potential responder loops
    override var nextResponder: NSResponder? {
        get { nil }  // Terminate the responder chain here
        set { }  // Ignore attempts to set next responder
    }

    // Pass mouse events for text selection
    override func mouseDown(with event: NSEvent) {
        terminalView.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        terminalView.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        terminalView.mouseUp(with: event)
    }

    // Handle scroll wheel by sending commands to tmux directly
    // (since we disabled tmux mouse mode to preserve text selection)
    override func scrollWheel(with event: NSEvent) {
        guard let sessionName = tmuxSessionName else {
            terminalView.scrollWheel(with: event)
            return
        }

        let deltaY = event.scrollingDeltaY

        // Enter copy mode if scrolling up
        if deltaY > 0 && !isInCopyMode {
            runTmuxCommand("copy-mode -t \(sessionName)")
            isInCopyMode = true
        }

        // Convert scroll delta to line count
        let lines = Int(abs(deltaY) / 3) + 1

        if deltaY > 0 {
            // Scroll up
            for _ in 0..<lines {
                runTmuxCommand("send-keys -t \(sessionName) -X scroll-up")
            }
        } else if deltaY < 0 && isInCopyMode {
            // Scroll down (only in copy mode)
            for _ in 0..<lines {
                runTmuxCommand("send-keys -t \(sessionName) -X scroll-down")
            }
        }
    }
}

// MARK: - Terminal Theme (matches Shebang theme.yaml)

struct DefaultTheme {
    static let shared = DefaultTheme()

    // VS Code-style neutral grey - matches theme.yaml bgPrimary
    let background = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0)  // #1e1e1e
    let foreground = NSColor(red: 0.800, green: 0.800, blue: 0.800, alpha: 1.0)  // #cccccc
}

// MARK: - Preview

#Preview {
    SwiftTermView(
        session: Session(
            workingDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
    )
    .frame(width: 800, height: 600)
}
