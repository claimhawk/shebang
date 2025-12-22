// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import SwiftTerm
import AppKit

/// SwiftUI wrapper for terminal
struct SwiftTermView: View {
    let session: Session
    var onOutput: ((Data) -> Void)?
    var pendingCommand: String?
    var pendingControlChar: UInt8?
    var isInteractiveMode: Bool = false

    var body: some View {
        TerminalNSViewRepresentable(session: session)
    }
}

/// NSViewRepresentable that wraps terminal in a coordinate-fixing container
struct TerminalNSViewRepresentable: NSViewRepresentable {
    let session: Session

    func makeNSView(context: Context) -> MouseFixingContainer {
        let terminalView = LocalProcessTerminalView(frame: .zero)

        // Configure
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeBackgroundColor = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0)
        terminalView.nativeForegroundColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        terminalView.allowMouseReporting = false

        // Start shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let workDir = session.workingDirectory.path

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = "en_US.UTF-8"

        terminalView.startProcess(
            executable: shell,
            args: ["-l"],
            environment: env.map { "\($0.key)=\($0.value)" },
            execName: "zsh"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            terminalView.send(txt: "cd '\(workDir)' && clear\n")
        }

        // Wrap in container that fixes mouse coordinates
        let container = MouseFixingContainer(terminalView: terminalView)
        return container
    }

    func updateNSView(_ nsView: MouseFixingContainer, context: Context) {
    }
}

/// Container that intercepts mouse events and adjusts coordinates before passing to terminal
class MouseFixingContainer: NSView {
    let terminalView: LocalProcessTerminalView

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0).cgColor

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

    // Intercept mouse events and create new events with corrected coordinates
    override func mouseDown(with event: NSEvent) {
        let fixedEvent = fixMouseEvent(event)
        terminalView.mouseDown(with: fixedEvent)
    }

    override func mouseDragged(with event: NSEvent) {
        let fixedEvent = fixMouseEvent(event)
        terminalView.mouseDragged(with: fixedEvent)
    }

    override func mouseUp(with event: NSEvent) {
        let fixedEvent = fixMouseEvent(event)
        terminalView.mouseUp(with: fixedEvent)
    }

    override func scrollWheel(with event: NSEvent) {
        terminalView.scrollWheel(with: event)
    }

    /// Fix the mouse event coordinates
    /// SwiftTerm uses event.locationInWindow which is relative to window bottom-left
    /// But when embedded in SwiftUI, the hosting view adds offset we need to compensate for
    private func fixMouseEvent(_ event: NSEvent) -> NSEvent {
        // Get the click point in our coordinate system
        let localPoint = convert(event.locationInWindow, from: nil)

        // Convert that to window coordinates as if terminal was at window origin
        let terminalOriginInWindow = terminalView.convert(NSPoint.zero, to: nil)
        let fixedWindowLocation = NSPoint(
            x: terminalOriginInWindow.x + localPoint.x,
            y: terminalOriginInWindow.y + localPoint.y
        )

        // Create new event with fixed location
        guard let cgEvent = event.cgEvent?.copy() else { return event }

        // CGEvent uses screen coordinates, so we need to convert
        if let window = self.window {
            let windowOrigin = window.frame.origin
            let screenPoint = NSPoint(
                x: windowOrigin.x + fixedWindowLocation.x,
                y: windowOrigin.y + fixedWindowLocation.y
            )
            cgEvent.location = screenPoint
        }

        return NSEvent(cgEvent: cgEvent) ?? event
    }
}

// MARK: - Static helpers

extension SwiftTermView {
    static func socketPath(for sessionId: UUID) -> String {
        "/tmp/shebang-\(sessionId.uuidString.prefix(8)).sock"
    }

    static var dtachPath: String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") {
            return "/opt/homebrew/bin/dtach"
        }
        return "/usr/local/bin/dtach"
    }

    static var dtachAvailable: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/dtach")
    }

    static func ensureDependencies(in terminalView: LocalProcessTerminalView? = nil) {}
}
