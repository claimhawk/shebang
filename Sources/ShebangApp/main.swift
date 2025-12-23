import AppKit
import SwiftTerm

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var terminalView: LocalProcessTerminalView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create terminal
        terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.autoresizingMask = [.width, .height]

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shebang"
        window.contentView = terminalView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(terminalView)

        // Start shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        terminalView.startProcess(executable: shell, args: ["--login"])

        // Global key monitor for Cmd+C/V
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "c":
                    self.terminalView.copy(self)
                    return nil
                case "v":
                    self.terminalView.paste(self)
                    return nil
                case "a":
                    self.terminalView.selectAll(self)
                    return nil
                case "q":
                    NSApplication.shared.terminate(self)
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
