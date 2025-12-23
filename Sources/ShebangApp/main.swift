import AppKit
import SwiftTerm

// MARK: - FileItem Model

class FileItem: NSObject {
    let url: URL
    let name: String
    let isDirectory: Bool
    private var _children: [FileItem]?
    private var childrenLoaded = false

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        super.init()
    }

    var children: [FileItem]? {
        guard isDirectory else { return nil }
        if !childrenLoaded {
            loadChildren()
        }
        return _children
    }

    private func loadChildren() {
        childrenLoaded = true
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            _children = []
            return
        }

        // Sort: directories first, then alphabetical
        _children = contents
            .map { FileItem(url: $0) }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}

// MARK: - FileTreeDataSource

class FileTreeDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var rootItems: [FileItem] = []

    func loadDirectory(_ url: URL) {
        let root = FileItem(url: url)
        rootItems = root.children ?? []
    }

    // MARK: NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return rootItems.count
        }
        guard let fileItem = item as? FileItem else { return 0 }
        return fileItem.children?.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootItems[index]
        }
        guard let fileItem = item as? FileItem else { return NSNull() }
        return fileItem.children?[index] ?? NSNull()
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let fileItem = item as? FileItem else { return false }
        return fileItem.isDirectory
    }

    // MARK: NSOutlineViewDelegate

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let fileItem = item as? FileItem else { return nil }

        let cellIdentifier = NSUserInterfaceItemIdentifier("FileCell")
        var cellView = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cellView?.addSubview(imageView)
            cellView?.imageView = imageView

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            cellView?.addSubview(textField)
            cellView?.textField = textField

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        cellView?.textField?.stringValue = fileItem.name
        cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: fileItem.url.path)

        return cellView
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, LocalProcessTerminalViewDelegate {
    var window: NSWindow!
    var terminalView: LocalProcessTerminalView!
    var splitView: NSSplitView!
    var outlineView: NSOutlineView!
    var dataSource: FileTreeDataSource!
    var currentCwd: String = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create split view
        splitView = NSSplitView(frame: NSRect(x: 0, y: 0, width: 1000, height: 600))
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]

        // Create file tree (left pane)
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.rowHeight = 20
        outlineView.indentationPerLevel = 16
        outlineView.autoresizesOutlineColumn = true

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FileColumn"))
        column.isEditable = false
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        dataSource = FileTreeDataSource()
        dataSource.loadDirectory(URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        outlineView.dataSource = dataSource
        outlineView.delegate = dataSource

        scrollView.documentView = outlineView

        // Create terminal (right pane)
        terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.autoresizingMask = [.width, .height]

        // Add to split view
        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(terminalView)
        splitView.setPosition(200, ofDividerAt: 0)

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shebang"
        window.contentView = splitView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(terminalView)

        // Start shell in home directory
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        // Get default environment and add TERM_PROGRAM to enable OSC 7 in zsh
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        env.append("TERM_PROGRAM=Apple_Terminal")

        terminalView.process.startProcess(executable: shell, args: ["--login"], environment: env, currentDirectory: homeDir)

        // Set delegate for OSC 7 directory updates
        terminalView.processDelegate = self
        currentCwd = homeDir
        dataSource.loadDirectory(URL(fileURLWithPath: homeDir))
        outlineView.reloadData()

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

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // Terminal size changed - nothing to do
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        window.title = title.isEmpty ? "Shebang" : title
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let dir = directory else { return }

        // Parse file:// URL if present
        let path: String
        if dir.hasPrefix("file://") {
            if let url = URL(string: dir) {
                path = url.path
            } else {
                return
            }
        } else {
            path = dir
        }

        print("[OSC7] Directory changed to: \(path)")

        if path != currentCwd {
            currentCwd = path
            dataSource.loadDirectory(URL(fileURLWithPath: path))
            outlineView.reloadData()
        }
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        print("[TERM] Process terminated with exit code: \(exitCode ?? -1)")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.activate(ignoringOtherApps: true)
app.run()
