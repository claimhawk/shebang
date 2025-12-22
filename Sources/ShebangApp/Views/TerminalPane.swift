// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import SwiftTerm

struct TerminalPane: NSViewRepresentable {
    let session: Session

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminal = LocalProcessTerminalView(frame: .zero)
        terminal.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminal.nativeBackgroundColor = NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.0)
        terminal.nativeForegroundColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        terminal.startProcess(
            executable: shell,
            args: ["-l"],
            environment: ["TERM=xterm-256color", "LANG=en_US.UTF-8"],
            execName: "zsh"
        )

        return terminal
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
    }
}
