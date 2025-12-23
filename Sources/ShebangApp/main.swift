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

// MARK: - Session Model

class Session: NSObject {
    let id: UUID
    var name: String
    let terminalView: LocalProcessTerminalView
    var currentDirectory: String

    init(name: String, shell: String, environment: [String], startDirectory: String) {
        self.id = UUID()
        self.name = name
        self.currentDirectory = startDirectory
        self.terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.terminalView.autoresizingMask = [.width, .height]
        super.init()

        terminalView.startProcess(executable: shell, args: ["--login"], environment: environment, currentDirectory: startDirectory)
    }
}

// MARK: - FileTreeDataSource

class FileTreeDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    var rootItems: [FileItem] = []
    var rootURL: URL?
    weak var outlineView: NSOutlineView?

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

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return rootItems.count }
        guard let fileItem = item as? FileItem else { return 0 }
        return fileItem.children?.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { return rootItems[index] }
        guard let fileItem = item as? FileItem else { return NSNull() }
        return fileItem.children?[index] ?? NSNull()
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let fileItem = item as? FileItem else { return false }
        return fileItem.isDirectory
    }

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
            textField.lineBreakMode = .byClipping
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

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let newName = textField.stringValue.trimmingCharacters(in: .whitespaces)

        if newName.isEmpty {
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

    func createNewItem(name: String) {
        guard let rootURL = rootURL else { return }
        let parentURL = pendingNewItemParent?.url ?? rootURL
        let newURL = parentURL.appendingPathComponent(name)

        do {
            if creatingDirectory {
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false)
            } else {
                FileManager.default.createFile(atPath: newURL.path, contents: nil)
            }
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

        if let parent = parent { outlineView.expandItem(parent) }

        let parentURL = parent?.url ?? rootURL
        let tempName = isDirectory ? "New Folder" : "New File"
        let tempURL = parentURL.appendingPathComponent(tempName)

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

        parent?.invalidateChildren()
        refresh()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let items = parent?.children ?? self.rootItems
            if let newItem = items.first(where: { $0.name == tempName }) {
                self.editingItem = newItem
                self.startRename(item: newItem)
            }
        }
    }
}

// MARK: - Sessions TableView DataSource/Delegate

class SessionsDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var sessions: [Session] = []
    weak var tableView: NSTableView?
    weak var delegate: SessionsDelegate?

    func tableView(_ tableView: NSTableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return sessions.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let session = sessions[row]

        let cellIdentifier = NSUserInterfaceItemIdentifier("SessionCell")
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            textField.font = NSFont.systemFont(ofSize: 12)
            cellView?.addSubview(textField)
            cellView?.textField = textField

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -8),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        cellView?.textField?.stringValue = session.name
        return cellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let row = tableView.selectedRow
        if row >= 0 && row < sessions.count {
            delegate?.didSelectSession(sessions[row])
        }
    }

    func addSession(_ session: Session) {
        sessions.append(session)
        tableView?.reloadData()
        tableView?.selectRowIndexes(IndexSet(integer: sessions.count - 1), byExtendingSelection: false)
    }

    func removeSession(at index: Int) {
        guard index >= 0 && index < sessions.count else { return }
        sessions.remove(at: index)
        tableView?.reloadData()
    }

    func selectedSession() -> Session? {
        guard let tableView = tableView else { return nil }
        let row = tableView.selectedRow
        return row >= 0 && row < sessions.count ? sessions[row] : nil
    }
}

protocol SessionsDelegate: AnyObject {
    func didSelectSession(_ session: Session)
}

// MARK: - Custom OutlineView

class FileTreeOutlineView: NSOutlineView {
    weak var fileDelegate: FileTreeDelegate?

    override func keyDown(with event: NSEvent) {
        guard let fileDelegate = fileDelegate else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 51, 117: fileDelegate.deleteSelectedItem()
        case 36: fileDelegate.renameSelectedItem()
        default: super.keyDown(with: event)
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        if row >= 0 { selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        return fileDelegate?.contextMenu(for: row)
    }
}

protocol FileTreeDelegate: AnyObject {
    func deleteSelectedItem()
    func renameSelectedItem()
    func contextMenu(for row: Int) -> NSMenu?
}

// MARK: - Custom Sessions TableView

class SessionsTableView: NSTableView {
    weak var sessionsDelegate: SessionsTableDelegate?

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        if row >= 0 { selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        return sessionsDelegate?.sessionsContextMenu(for: row)
    }
}

protocol SessionsTableDelegate: AnyObject {
    func sessionsContextMenu(for row: Int) -> NSMenu?
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, NSSplitViewDelegate, LocalProcessTerminalViewDelegate, FileTreeDelegate, SessionsDelegate, SessionsTableDelegate {
    var window: NSWindow!
    var splitView: NSSplitView!
    var terminalContainer: NSView!
    var outlineView: FileTreeOutlineView!
    var sessionsTableView: SessionsTableView!
    var dataSource: FileTreeDataSource!
    var sessionsDataSource: SessionsDataSource!

    var activeSession: Session?
    var sessionCounter = 1

    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    lazy var env: [String] = {
        var e = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        e.append("TERM_PROGRAM=Apple_Terminal")
        return e
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupUI()
        // Defer session creation until after layout is complete
        DispatchQueue.main.async {
            self.createNewSession()
        }
    }

    func setupUI() {
        // Main split view
        splitView = NSSplitView(frame: NSRect(x: 0, y: 0, width: 1100, height: 600))
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]
        splitView.delegate = self

        // Left pane - File tree
        let fileScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
        fileScrollView.hasVerticalScroller = true
        fileScrollView.autohidesScrollers = true

        outlineView = FileTreeOutlineView()
        outlineView.fileDelegate = self
        outlineView.headerView = nil
        outlineView.rowHeight = 20
        outlineView.indentationPerLevel = 16
        outlineView.autoresizesOutlineColumn = true

        let fileColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FileColumn"))
        fileColumn.isEditable = true
        fileColumn.resizingMask = .autoresizingMask
        fileColumn.width = 200
        outlineView.addTableColumn(fileColumn)
        outlineView.outlineTableColumn = fileColumn
        outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        dataSource = FileTreeDataSource()
        dataSource.outlineView = outlineView
        dataSource.loadDirectory(URL(fileURLWithPath: homeDir))
        outlineView.dataSource = dataSource
        outlineView.delegate = dataSource

        fileScrollView.documentView = outlineView

        // Center pane - Terminal container
        terminalContainer = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 600))
        terminalContainer.autoresizingMask = [.width, .height]

        // Right pane - Sessions list
        let sessionsScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 150, height: 600))
        sessionsScrollView.hasVerticalScroller = true
        sessionsScrollView.autohidesScrollers = true

        sessionsTableView = SessionsTableView()
        sessionsTableView.sessionsDelegate = self
        sessionsTableView.headerView = nil
        sessionsTableView.rowHeight = 28

        let sessionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SessionColumn"))
        sessionColumn.isEditable = false
        sessionColumn.resizingMask = .autoresizingMask
        sessionColumn.width = 150
        sessionsTableView.addTableColumn(sessionColumn)
        sessionsTableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        sessionsDataSource = SessionsDataSource()
        sessionsDataSource.tableView = sessionsTableView
        sessionsDataSource.delegate = self
        sessionsTableView.dataSource = sessionsDataSource
        sessionsTableView.delegate = sessionsDataSource

        sessionsScrollView.documentView = sessionsTableView

        // Add panes to split view
        splitView.addArrangedSubview(fileScrollView)
        splitView.addArrangedSubview(terminalContainer)
        splitView.addArrangedSubview(sessionsScrollView)

        // Set minimum widths using Auto Layout constraints
        fileScrollView.translatesAutoresizingMaskIntoConstraints = false
        terminalContainer.translatesAutoresizingMaskIntoConstraints = false
        sessionsScrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fileScrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            terminalContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 400),
            sessionsScrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        // Set holding priorities to prevent collapse
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 1)
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 2)

        // Window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shebang"
        window.contentView = splitView
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Keyboard shortcuts
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "c":
                    self.activeSession?.terminalView.copy(self)
                    return nil
                case "v":
                    self.activeSession?.terminalView.paste(self)
                    return nil
                case "a":
                    self.activeSession?.terminalView.selectAll(self)
                    return nil
                case "t":
                    self.createNewSession()
                    return nil
                case "w":
                    self.closeCurrentSession()
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

    func createNewSession() {
        let session = Session(name: "Session \(sessionCounter)", shell: shell, environment: env, startDirectory: homeDir)
        session.terminalView.processDelegate = self
        sessionCounter += 1
        sessionsDataSource.addSession(session)
        switchToSession(session)
    }

    func closeCurrentSession() {
        guard let tableView = sessionsDataSource.tableView else { return }
        let row = tableView.selectedRow
        guard row >= 0 && row < sessionsDataSource.sessions.count else { return }

        let session = sessionsDataSource.sessions[row]
        session.terminalView.removeFromSuperview()

        sessionsDataSource.removeSession(at: row)

        if sessionsDataSource.sessions.isEmpty {
            createNewSession()
        } else {
            let newRow = min(row, sessionsDataSource.sessions.count - 1)
            tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
            switchToSession(sessionsDataSource.sessions[newRow])
        }
    }

    func switchToSession(_ session: Session) {
        // Remove current terminal from container
        activeSession?.terminalView.removeFromSuperview()

        // Add new terminal with Auto Layout constraints
        activeSession = session
        session.terminalView.translatesAutoresizingMaskIntoConstraints = false
        terminalContainer.addSubview(session.terminalView)

        NSLayoutConstraint.activate([
            session.terminalView.topAnchor.constraint(equalTo: terminalContainer.topAnchor),
            session.terminalView.bottomAnchor.constraint(equalTo: terminalContainer.bottomAnchor),
            session.terminalView.leadingAnchor.constraint(equalTo: terminalContainer.leadingAnchor),
            session.terminalView.trailingAnchor.constraint(equalTo: terminalContainer.trailingAnchor)
        ])

        // Update file tree
        dataSource.loadDirectory(URL(fileURLWithPath: session.currentDirectory))
        outlineView.reloadData()

        // Focus terminal
        window.makeFirstResponder(session.terminalView)
    }

    // MARK: - NSSplitViewDelegate

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if dividerIndex == 0 {
            return 100  // Min width for file tree
        } else {
            return splitView.subviews[0].frame.width + 300  // Min terminal width
        }
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let totalWidth = splitView.frame.width
        if dividerIndex == 0 {
            return totalWidth - 420  // Leave room for terminal + sessions
        } else {
            return totalWidth - 100  // Min width for sessions panel
        }
    }

    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        guard splitView.subviews.count == 3 else {
            splitView.adjustSubviews()
            return
        }

        let dividerThickness = splitView.dividerThickness
        let totalWidth = splitView.frame.width
        let totalHeight = splitView.frame.height

        // Get current widths of side panels (keep them fixed)
        let leftWidth = splitView.subviews[0].frame.width
        let rightWidth = splitView.subviews[2].frame.width

        // Terminal gets remaining space
        let centerWidth = totalWidth - leftWidth - rightWidth - (2 * dividerThickness)

        splitView.subviews[0].frame = NSRect(x: 0, y: 0, width: leftWidth, height: totalHeight)
        splitView.subviews[1].frame = NSRect(x: leftWidth + dividerThickness, y: 0, width: centerWidth, height: totalHeight)
        splitView.subviews[2].frame = NSRect(x: totalWidth - rightWidth, y: 0, width: rightWidth, height: totalHeight)
    }

    // MARK: - SessionsDelegate

    func didSelectSession(_ session: Session) {
        switchToSession(session)
    }

    // MARK: - SessionsTableDelegate

    func sessionsContextMenu(for row: Int) -> NSMenu? {
        let menu = NSMenu()

        let newItem = NSMenuItem(title: "New Session", action: #selector(newSessionMenuItem(_:)), keyEquivalent: "")
        newItem.target = self
        menu.addItem(newItem)

        if row >= 0 {
            let closeItem = NSMenuItem(title: "Close Session", action: #selector(closeSessionMenuItem(_:)), keyEquivalent: "")
            closeItem.target = self
            menu.addItem(closeItem)
        }

        return menu
    }

    @objc func newSessionMenuItem(_ sender: NSMenuItem) {
        createNewSession()
    }

    @objc func closeSessionMenuItem(_ sender: NSMenuItem) {
        closeCurrentSession()
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

        let newFileItem = NSMenuItem(title: "New File", action: #selector(newFile(_:)), keyEquivalent: "")
        newFileItem.target = self
        newFileItem.representedObject = selectedItem
        menu.addItem(newFileItem)

        let newFolderItem = NSMenuItem(title: "New Folder", action: #selector(newFolder(_:)), keyEquivalent: "")
        newFolderItem.target = self
        newFolderItem.representedObject = selectedItem
        menu.addItem(newFolderItem)

        if selectedItem != nil {
            menu.addItem(NSMenuItem.separator())

            let renameItem = NSMenuItem(title: "Rename", action: #selector(renameMenuItem(_:)), keyEquivalent: "")
            renameItem.target = self
            menu.addItem(renameItem)

            let deleteItem = NSMenuItem(title: "Move to Trash", action: #selector(deleteMenuItem(_:)), keyEquivalent: "")
            deleteItem.target = self
            menu.addItem(deleteItem)
        }

        return menu
    }

    @objc func newFile(_ sender: NSMenuItem) {
        let parent = sender.representedObject as? FileItem
        dataSource.startCreate(isDirectory: false, parent: parent?.isDirectory == true ? parent : nil)
    }

    @objc func newFolder(_ sender: NSMenuItem) {
        let parent = sender.representedObject as? FileItem
        dataSource.startCreate(isDirectory: true, parent: parent?.isDirectory == true ? parent : nil)
    }

    @objc func renameMenuItem(_ sender: NSMenuItem) { renameSelectedItem() }
    @objc func deleteMenuItem(_ sender: NSMenuItem) { deleteSelectedItem() }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        // Update session name if it's the active session
        if let session = activeSession, session.terminalView === source {
            window.title = title.isEmpty ? "Shebang" : title
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let dir = directory else { return }

        let path: String
        if dir.hasPrefix("file://") {
            guard let url = URL(string: dir) else { return }
            path = url.path
        } else {
            path = dir
        }

        // Find which session this belongs to and update its CWD
        for session in sessionsDataSource.sessions {
            if session.terminalView === source {
                session.currentDirectory = path

                // If it's the active session, update file tree
                if session === activeSession {
                    dataSource.loadDirectory(URL(fileURLWithPath: path))
                    outlineView.reloadData()
                }
                break
            }
        }
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        // Find and close the session whose process terminated
        for (index, session) in sessionsDataSource.sessions.enumerated() {
            if session.terminalView === source {
                sessionsDataSource.removeSession(at: index)

                if sessionsDataSource.sessions.isEmpty {
                    createNewSession()
                } else if session === activeSession {
                    let newIndex = min(index, sessionsDataSource.sessions.count - 1)
                    sessionsTableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
                    switchToSession(sessionsDataSource.sessions[newIndex])
                }
                break
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.activate(ignoringOtherApps: true)
app.run()
