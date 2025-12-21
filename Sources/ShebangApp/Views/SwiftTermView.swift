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

    func makeNSView(context: Context) -> ReadOnlyTerminalContainer {
        let terminalView = LocalProcessTerminalView(frame: .zero)

        // Store reference in coordinator
        context.coordinator.terminalView = terminalView

        // Configure terminal appearance
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeBackgroundColor = DefaultTheme.shared.background
        terminalView.nativeForegroundColor = DefaultTheme.shared.foreground

        // Set delegate for output capture
        terminalView.processDelegate = context.coordinator

        // Start shell in session's working directory
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let args = initialCommand.map { ["-c", $0] } ?? ["-l"]

        terminalView.startProcess(
            executable: shell,
            args: args,
            environment: buildEnvironment(),
            execName: shell
        )

        // Set up shell integration for directory tracking (zsh)
        // OSC 7 format: \e]7;file://hostname/path\e\\
        let zshHook = """
        chpwd() { printf '\\e]7;file://%s%s\\a' "$(hostname)" "$PWD" }
        """
        terminalView.send(txt: zshHook + "\n")

        // Change to session's working directory
        let cdCommand = "cd \"\(session.workingDirectory.path)\"\n"
        terminalView.send(txt: cdCommand)

        // Clear the cd output for cleaner initial state
        if initialCommand == nil {
            terminalView.send(txt: "clear\n")
        }

        // Emit initial directory for tracking
        terminalView.send(txt: "printf '\\e]7;file://%s%s\\a' \"$(hostname)\" \"$PWD\"\n")

        // Wrap in read-only container that blocks keyboard input
        let container = ReadOnlyTerminalContainer(terminalView: terminalView)
        context.coordinator.container = container
        return container
    }

    func updateNSView(_ nsView: ReadOnlyTerminalContainer, context: Context) {
        // Update coordinator callback
        context.coordinator.onOutput = onOutput

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
            if let dir = directory {
                print("🔄 Terminal CWD changed to: \(dir)")
                let url = URL(fileURLWithPath: dir)
                DispatchQueue.main.async {
                    print("🔄 Updating session CWD to: \(url.path)")
                    AppState.shared.sessions.updateActiveSessionCWD(url)
                }
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            // Shell process ended
            print("Terminal process exited: \(exitCode ?? -1)")
        }
    }
}

// MARK: - Read-Only Terminal Container

/// Container that wraps terminal view and blocks keyboard input
/// All input must go through the command bar
/// Allows: text selection, copy (Cmd+C), scrolling
class ReadOnlyTerminalContainer: NSView {
    let terminalView: LocalProcessTerminalView
    private let padding: CGFloat = 12

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        // Match terminal background so padding looks internal
        wantsLayer = true
        layer?.backgroundColor = DefaultTheme.shared.background.cgColor

        // Add terminal as subview with padding
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

    // Allow first responder for copy operations
    override var acceptsFirstResponder: Bool { true }

    // Intercept key events - only allow copy (Cmd+C)
    override func keyDown(with event: NSEvent) {
        // Allow Cmd+C for copy
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
            terminalView.keyDown(with: event)
            return
        }
        // Block all other keyboard input
    }

    override func keyUp(with event: NSEvent) {
        // Don't pass to terminal
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

    // Allow mouse events for scrolling
    override func scrollWheel(with event: NSEvent) {
        terminalView.scrollWheel(with: event)
    }
}

// MARK: - Default Terminal Theme

struct DefaultTheme {
    static let shared = DefaultTheme()

    // Solarized Dark-inspired colors
    let background = NSColor(red: 0.00, green: 0.07, blue: 0.12, alpha: 1.0)
    let foreground = NSColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1.0)
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
