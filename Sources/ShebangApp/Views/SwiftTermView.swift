// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import SwiftTerm
import AppKit

/// SwiftUI wrapper for SwiftTerm using NSViewControllerRepresentable
/// for proper coordinate translation
struct SwiftTermView: NSViewControllerRepresentable {
    let session: Session

    var onOutput: ((Data) -> Void)?
    var pendingCommand: String?
    var pendingControlChar: UInt8?
    var isInteractiveMode: Bool = false

    func makeNSViewController(context: Context) -> TerminalViewController {
        let controller = TerminalViewController()
        controller.session = session
        controller.coordinator = context.coordinator
        context.coordinator.terminalView = controller.terminalView
        return controller
    }

    func updateNSViewController(_ controller: TerminalViewController, context: Context) {
        context.coordinator.onOutput = onOutput

        if let command = pendingCommand {
            controller.terminalView.send(txt: command)
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingCommand = nil
            }
        }

        if let controlChar = pendingControlChar {
            let bytes: [UInt8] = [controlChar]
            controller.terminalView.send(data: bytes[...])
            DispatchQueue.main.async {
                AppState.shared.terminal.pendingControlChar = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOutput: onOutput)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onOutput: ((Data) -> Void)?
        weak var terminalView: LocalProcessTerminalView?

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

    // MARK: - dtach paths

    static func socketPath(for sessionId: UUID) -> String {
        "/tmp/shebang-\(sessionId.uuidString.prefix(8)).sock"
    }

    static var dtachPath: String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") {
            return "/opt/homebrew/bin/dtach"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/dtach") {
            return "/usr/local/bin/dtach"
        }
        return "/usr/bin/dtach"
    }

    static var dtachAvailable: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/dtach") ||
        FileManager.default.fileExists(atPath: "/usr/local/bin/dtach") ||
        FileManager.default.fileExists(atPath: "/usr/bin/dtach")
    }

    static func ensureDependencies(in terminalView: LocalProcessTerminalView? = nil) {
        guard !dtachAvailable else { return }
        if let terminal = terminalView {
            terminal.send(txt: "brew install dtach\n")
        }
    }
}

// MARK: - Terminal View Controller

class TerminalViewController: NSViewController {
    let terminalView = LocalProcessTerminalView(frame: .zero)
    var session: Session?
    weak var coordinator: SwiftTermView.Coordinator?

    override func loadView() {
        view = terminalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let session = session else { return }

        // Configure appearance
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.nativeBackgroundColor = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0)
        terminalView.nativeForegroundColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)

        // Disable mouse reporting for native selection
        terminalView.allowMouseReporting = false

        // Set delegate
        if let coordinator = coordinator {
            terminalView.processDelegate = coordinator
        }

        // Start plain shell
        let workDir = session.workingDirectory.path
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["LANG"] = "en_US.UTF-8"
        env.removeValue(forKey: "PWD")

        terminalView.startProcess(
            executable: shell,
            args: ["-l"],
            environment: env.map { "\($0.key)=\($0.value)" },
            execName: "zsh"
        )

        // cd to working directory
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.terminalView.send(txt: "cd '\(workDir)' && clear\n")
        }
    }
}

// MARK: - Preview

#Preview {
    SwiftTermView(
        session: Session(workingDirectory: FileManager.default.homeDirectoryForCurrentUser)
    )
    .frame(width: 800, height: 600)
}
