// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import SwiftTerm
import AppKit

/// SwiftUI wrapper for SwiftTerm's LocalProcessTerminalView
/// Uses dtach for session persistence (attach/detach only, no other features)
struct SwiftTermView: NSViewRepresentable {
    let session: Session

    // Output callback for block parsing
    var onOutput: ((Data) -> Void)?

    // Observe pending commands from AppState
    var pendingCommand: String?

    // Observe pending control characters (Ctrl+C, etc.)
    var pendingControlChar: UInt8?

    // Interactive mode - when true, keyboard passes through to terminal
    var isInteractiveMode: Bool = false

    func makeNSView(context: Context) -> TerminalContainer {
        let terminalView = LocalProcessTerminalView(frame: .zero)

        // Store reference in coordinator
        context.coordinator.terminalView = terminalView

        // Configure terminal appearance
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeBackgroundColor = DefaultTheme.shared.background
        terminalView.nativeForegroundColor = DefaultTheme.shared.foreground

        // Disable mouse reporting - let SwiftTerm handle text selection natively
        terminalView.allowMouseReporting = false

        // Set delegate for output capture
        terminalView.processDelegate = context.coordinator

        let workDir = session.workingDirectory.path
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        // Use dtach for session persistence (attach/detach only)
        let socketPath = Self.socketPath(for: session.id)
        let dtachCommand = "\(Self.dtachPath) -A \(socketPath) -z \(shell)"

        terminalView.startProcess(
            executable: shell,
            args: ["-c", "cd '\(workDir)' && \(dtachCommand)"],
            environment: buildEnvironment(),
            execName: "zsh"
        )

        // Set up shell integration for CWD tracking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.setupShellIntegration(terminalView)
        }

        // Wrap in container
        let container = TerminalContainer(terminalView: terminalView)
        context.coordinator.container = container
        return container
    }

    func updateNSView(_ nsView: TerminalContainer, context: Context) {
        // Update coordinator callback
        context.coordinator.onOutput = onOutput

        // Update interactive mode
        nsView.isInteractiveMode = isInteractiveMode

        // Send pending command if available
        if let command = pendingCommand, let terminalView = context.coordinator.terminalView {
            terminalView.send(txt: command)
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingCommand = nil
            }
        }

        // Send pending control character if available
        if let controlChar = pendingControlChar, let terminalView = context.coordinator.terminalView {
            let bytes: [UInt8] = [controlChar]
            terminalView.send(data: bytes[...])
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingControlChar = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOutput: onOutput)
    }

    // MARK: - dtach Paths

    /// Socket path for dtach session
    static func socketPath(for sessionId: UUID) -> String {
        "/tmp/shebang-\(sessionId.uuidString.prefix(8)).sock"
    }

    /// Get dtach executable path
    static var dtachPath: String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") {
            return "/opt/homebrew/bin/dtach"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/dtach") {
            return "/usr/local/bin/dtach"
        }
        return "/usr/bin/dtach"
    }

    /// Check if dtach is available
    static var dtachAvailable: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/dtach") ||
        FileManager.default.fileExists(atPath: "/usr/bin/dtach")
    }

    // MARK: - Environment

    private func buildEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["LANG"] = "en_US.UTF-8"
        env.removeValue(forKey: "PWD")
        env["TERM_PROGRAM"] = "Shebang"
        env["TERM_PROGRAM_VERSION"] = "1.0"
        return env.map { "\($0.key)=\($0.value)" }
    }

    // MARK: - Shell Integration

    /// Set up shell hooks for CWD tracking
    private func setupShellIntegration(_ terminalView: LocalProcessTerminalView) {
        // zsh hooks to emit OSC 7 on directory change
        let hooks = """
        chpwd() { printf '\\033]7;file://%s%s\\007' "$(hostname)" "$PWD" }
        precmd() { printf '\\033]7;file://%s%s\\007' "$(hostname)" "$PWD" }
        printf '\\033]7;file://%s%s\\007' "$(hostname)" "$PWD"
        clear
        """
        terminalView.send(txt: hooks + "\n")
    }

    // MARK: - Dependencies

    /// Ensure dtach is installed
    static func ensureDependencies(in terminalView: LocalProcessTerminalView? = nil) {
        guard !dtachAvailable else { return }

        if let terminal = terminalView {
            terminal.send(txt: "echo '📦 Installing dtach...' && brew install dtach && echo '✅ Done. Restart Shebang.'\n")
            return
        }

        // Background install
        let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
            ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"

        guard FileManager.default.fileExists(atPath: brewPath) else {
            print("⚠️ Homebrew not installed")
            return
        }

        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "dtach"]
            try? process.run()
            process.waitUntilExit()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onOutput: ((Data) -> Void)?
        weak var terminalView: LocalProcessTerminalView?
        weak var container: TerminalContainer?

        init(onOutput: ((Data) -> Void)?) {
            self.onOutput = onOutput
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let dir = directory else { return }

            let url: URL
            if dir.hasPrefix("file://") {
                if let parsed = URL(string: dir), let path = parsed.path.removingPercentEncoding {
                    url = URL(fileURLWithPath: path.isEmpty ? "/" : path)
                } else { return }
            } else {
                url = URL(fileURLWithPath: dir)
            }

            DispatchQueue.main.async {
                AppState.shared.sessions.updateActiveSessionCWD(url)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            print("Terminal process exited: \(exitCode ?? -1)")
        }
    }
}

// MARK: - Terminal Container

/// Simple container with padding that passes events to terminal
class TerminalContainer: NSView {
    let terminalView: LocalProcessTerminalView
    private let padding: CGFloat = 12

    var isInteractiveMode: Bool = false
    private var isHandlingEvent: Bool = false

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = DefaultTheme.shared.background.cgColor

        terminalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    // Keyboard handling
    override func keyDown(with event: NSEvent) {
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        if isInteractiveMode {
            terminalView.keyDown(with: event)
            return
        }

        // Allow Cmd+C for copy
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
            terminalView.keyDown(with: event)
        }
    }

    override func keyUp(with event: NSEvent) {
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        if isInteractiveMode {
            terminalView.keyUp(with: event)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        guard !isHandlingEvent else { return }
        isHandlingEvent = true
        defer { isHandlingEvent = false }

        if isInteractiveMode {
            terminalView.flagsChanged(with: event)
        }
    }

    // Mouse events - pass directly to terminal for selection
    override func mouseDown(with event: NSEvent) {
        terminalView.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        terminalView.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        terminalView.mouseUp(with: event)
    }

    // Scrolling - pass to terminal (SwiftTerm handles it)
    override func scrollWheel(with event: NSEvent) {
        terminalView.scrollWheel(with: event)
    }
}

// MARK: - Theme

struct DefaultTheme {
    static let shared = DefaultTheme()
    let background = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0)
    let foreground = NSColor(red: 0.800, green: 0.800, blue: 0.800, alpha: 1.0)
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
