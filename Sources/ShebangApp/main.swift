import AppKit
import SwiftTerm

// MARK: - FileItem Model

class FileItem: NSObject {
    var url: URL
    var name: String
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

    func invalidateChildren() {
        childrenLoaded = false
        _children = nil
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

class FileTreeDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    var rootItems: [FileItem] = []
    var rootURL: URL?
    weak var outlineView: NSOutlineView?

    // For inline editing
    var editingItem: FileItem?
    var isCreatingNew = false
    var creatingDirectory = false
    var pendingNewItemParent: FileItem?

    func loadDirectory(_ url: URL) {
        rootURL = url
        let root = FileItem(url: url)
        rootItems = root.children ?? []
    }

    func refresh() {
        guard let url = rootURL else { return }
        loadDirectory(url)
        outlineView?.reloadData()
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
            textField.isEditable = true
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.focusRingType = .none
            textField.delegate = self
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

    // MARK: NSTextFieldDelegate - Inline Editing

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let newName = textField.stringValue.trimmingCharacters(in: .whitespaces)

        if newName.isEmpty {
            // Cancelled or empty - restore original name or remove temp item
            refresh()
            editingItem = nil
            isCreatingNew = false
            return
        }

        if isCreatingNew {
            createNewItem(name: newName)
        } else if let item = editingItem {
            renameItem(item, to: newName)
        }

        editingItem = nil
        isCreatingNew = false
    }

    // MARK: File Operations

    func createNewItem(name: String) {
        guard let rootURL = rootURL else { return }

        let parentURL: URL
        if let parent = pendingNewItemParent {
            parentURL = parent.url
        } else {
            parentURL = rootURL
        }

        let newURL = parentURL.appendingPathComponent(name)

        do {
            if creatingDirectory {
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false)
            } else {
                FileManager.default.createFile(atPath: newURL.path, contents: nil)
            }

            // Invalidate parent's children cache
            pendingNewItemParent?.invalidateChildren()
            refresh()
        } catch {
            showError("Failed to create \(creatingDirectory ? "folder" : "file"): \(error.localizedDescription)")
        }

        pendingNewItemParent = nil
        creatingDirectory = false
    }

    func renameItem(_ item: FileItem, to newName: String) {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)

        do {
            try FileManager.default.moveItem(at: item.url, to: newURL)
            item.url = newURL
            item.name = newName
            refresh()
        } catch {
            showError("Failed to rename: \(error.localizedDescription)")
            refresh()
        }
    }

    func deleteItem(_ item: FileItem) {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Delete \"\(item.name)\"?"
        alert.informativeText = item.isDirectory
            ? "This folder and all its contents will be moved to the Trash."
            : "This file will be moved to the Trash."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                refresh()
            } catch {
                showError("Failed to delete: \(error.localizedDescription)")
            }
        }
    }

    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }

    // MARK: Start Editing

    func startRename(item: FileItem) {
        editingItem = item
        isCreatingNew = false

        guard let outlineView = outlineView else { return }
        let row = outlineView.row(forItem: item)
        guard row >= 0,
              let cellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
              let textField = cellView.textField else { return }

        textField.isEditable = true
        textField.selectText(nil)
        outlineView.window?.makeFirstResponder(textField)
    }

    func startCreate(isDirectory: Bool, parent: FileItem?) {
        guard let outlineView = outlineView, let rootURL = rootURL else { return }

        isCreatingNew = true
        creatingDirectory = isDirectory
        pendingNewItemParent = parent

        // Expand parent if needed
        if let parent = parent {
            outlineView.expandItem(parent)
        }

        // Create temporary item for inline editing
        let parentURL = parent?.url ?? rootURL
        let tempName = isDirectory ? "New Folder" : "New File"
        let tempURL = parentURL.appendingPathComponent(tempName)

        // Create the file/folder immediately so it shows in the tree
        do {
            if isDirectory {
                try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: false)
            } else {
                FileManager.default.createFile(atPath: tempURL.path, contents: nil)
            }
        } catch {
            showError("Failed to create: \(error.localizedDescription)")
            isCreatingNew = false
            return
        }

        // Refresh and start editing
        parent?.invalidateChildren()
        refresh()

        // Find the new item and start editing
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Find the newly created item
            let items = parent?.children ?? self.rootItems
            if let newItem = items.first(where: { $0.name == tempName }) {
                self.editingItem = newItem
                self.startRename(item: newItem)
            }
        }
    }
}

// MARK: - Custom OutlineView for keyboard handling

class FileTreeOutlineView: NSOutlineView {
    weak var fileDelegate: FileTreeDelegate?

    override func keyDown(with event: NSEvent) {
        guard let fileDelegate = fileDelegate else {
            super.keyDown(with: event)
            return
        }

        let key = event.keyCode

        switch key {
        case 51, 117: // Delete or Forward Delete
            fileDelegate.deleteSelectedItem()
        case 36: // Return - rename
            fileDelegate.renameSelectedItem()
        default:
            super.keyDown(with: event)
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)

        if row >= 0 {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }

        return fileDelegate?.contextMenu(for: row)
    }
}

protocol FileTreeDelegate: AnyObject {
    func deleteSelectedItem()
    func renameSelectedItem()
    func contextMenu(for row: Int) -> NSMenu?
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, LocalProcessTerminalViewDelegate, FileTreeDelegate {
    var window: NSWindow!
    var terminalView: LocalProcessTerminalView!
    var splitView: NSSplitView!
    var outlineView: FileTreeOutlineView!
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

        outlineView = FileTreeOutlineView()
        outlineView.fileDelegate = self
        outlineView.headerView = nil
        outlineView.rowHeight = 20
        outlineView.indentationPerLevel = 16
        outlineView.autoresizesOutlineColumn = true

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FileColumn"))
        column.isEditable = true
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        dataSource = FileTreeDataSource()
        dataSource.outlineView = outlineView
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

        terminalView.startProcess(executable: shell, args: ["--login"], environment: env, currentDirectory: homeDir)

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

    // MARK: - FileTreeDelegate

    func deleteSelectedItem() {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? FileItem else { return }
        dataSource.deleteItem(item)
    }

    func renameSelectedItem() {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? FileItem else { return }
        dataSource.startRename(item: item)
    }

    func contextMenu(for row: Int) -> NSMenu? {
        let menu = NSMenu()

        let selectedItem = row >= 0 ? outlineView.item(atRow: row) as? FileItem : nil

        // New File
        let newFileItem = NSMenuItem(title: "New File", action: #selector(newFile(_:)), keyEquivalent: "")
        newFileItem.target = self
        newFileItem.representedObject = selectedItem
        menu.addItem(newFileItem)

        // New Folder
        let newFolderItem = NSMenuItem(title: "New Folder", action: #selector(newFolder(_:)), keyEquivalent: "")
        newFolderItem.target = self
        newFolderItem.representedObject = selectedItem
        menu.addItem(newFolderItem)

        if selectedItem != nil {
            menu.addItem(NSMenuItem.separator())

            // Rename
            let renameItem = NSMenuItem(title: "Rename", action: #selector(renameMenuItem(_:)), keyEquivalent: "")
            renameItem.target = self
            menu.addItem(renameItem)

            // Delete
            let deleteItem = NSMenuItem(title: "Move to Trash", action: #selector(deleteMenuItem(_:)), keyEquivalent: "")
            deleteItem.target = self
            menu.addItem(deleteItem)
        }

        return menu
    }

    @objc func newFile(_ sender: NSMenuItem) {
        let parent = sender.representedObject as? FileItem
        let actualParent = parent?.isDirectory == true ? parent : nil
        dataSource.startCreate(isDirectory: false, parent: actualParent)
    }

    @objc func newFolder(_ sender: NSMenuItem) {
        let parent = sender.representedObject as? FileItem
        let actualParent = parent?.isDirectory == true ? parent : nil
        dataSource.startCreate(isDirectory: true, parent: actualParent)
    }

    @objc func renameMenuItem(_ sender: NSMenuItem) {
        renameSelectedItem()
    }

    @objc func deleteMenuItem(_ sender: NSMenuItem) {
        deleteSelectedItem()
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
