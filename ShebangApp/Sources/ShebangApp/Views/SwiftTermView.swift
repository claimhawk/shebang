// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

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

        // Change to session's working directory
        let cdCommand = "cd \"\(session.workingDirectory.path)\"\n"
        terminalView.send(txt: cdCommand)

        // Clear the cd output for cleaner initial state
        if initialCommand == nil {
            terminalView.send(txt: "clear\n")
        }

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
            // Directory changed - could update session CWD
            if let dir = directory {
                print("Terminal CWD: \(dir)")
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
class ReadOnlyTerminalContainer: NSView {
    let terminalView: LocalProcessTerminalView

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        // Add terminal as subview
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Block keyboard input - don't become first responder
    override var acceptsFirstResponder: Bool { false }

    // Intercept key events
    override func keyDown(with event: NSEvent) {
        // Don't pass to terminal - input goes through command bar
    }

    override func keyUp(with event: NSEvent) {
        // Don't pass to terminal
    }

    // Allow mouse events for scrolling/selection
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
