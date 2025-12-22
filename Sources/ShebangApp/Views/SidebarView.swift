// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Custom Transferable for Sidebar File Paths

/// A wrapper that transfers file paths as text with a custom UTType
/// This prevents confusion with actual file/image drops from Finder
struct SidebarFilePath: Transferable, Codable {
    let path: String

    static var transferRepresentation: some TransferRepresentation {
        // Use a custom type that won't be confused with images
        CodableRepresentation(contentType: .sidebarFilePath)
        // Also provide as plain text as fallback
        ProxyRepresentation(exporting: \.path)
    }
}

extension UTType {
    /// Custom UTType for sidebar file path drags
    static let sidebarFilePath = UTType(exportedAs: "com.shebang.sidebar-file-path")
}

/// Create an NSItemProvider that ONLY contains text path data
/// This prevents SwiftUI/macOS from automatically adding image representations for image files
func createPathOnlyItemProvider(for path: String) -> NSItemProvider {
    ShebangLog.info("=== CREATING DRAG ITEM PROVIDER ===")
    ShebangLog.info("Path: \(path)")

    let provider = NSItemProvider()

    // Register our custom sidebar marker type with the path as JSON
    let sidebarType = "com.shebang.sidebar-file-path"
    if let jsonData = try? JSONEncoder().encode(["path": path]) {
        provider.registerDataRepresentation(forTypeIdentifier: sidebarType, visibility: .all) { completion in
            ShebangLog.info("Sidebar type requested - providing JSON")
            completion(jsonData, nil)
            return nil
        }
    }

    // Register as plain text (this is what gets pasted)
    provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
        ShebangLog.info("Plain text requested - providing path")
        completion(path.data(using: .utf8), nil)
        return nil
    }

    // Also register as UTF8 text
    provider.registerDataRepresentation(forTypeIdentifier: "public.utf8-plain-text", visibility: .all) { completion in
        ShebangLog.info("UTF8 text requested - providing path")
        completion(path.data(using: .utf8), nil)
        return nil
    }

    ShebangLog.info("Provider registered types: \(provider.registeredTypeIdentifiers)")
    return provider
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// File browser sidebar with collapsible directory tree
struct SidebarView: View {
    // Access global app state
    private var state: AppState { AppState.shared }
    var onFileSelect: ((URL) -> Void)?

    @State private var expandedFolders: Set<URL> = []
    @State private var selectedFile: URL?
    @State private var isRefreshHovered = false
    @State private var showAllProjects = false

    // New project creation state
    @State private var pendingParentDir: URL?
    @State private var newProjectName = ""

    // Current project directory
    private var currentProjectURL: URL? {
        state.sessions.activeSession?.workingDirectory
    }

    // Recent projects - first 3 from the tracked list (filtered to shebang projects with system.md)
    private var recentProjects: [URL] {
        Array(state.ui.recentProjects.filter { isShebangProject($0) }.prefix(3))
    }

    // All projects (filtered to shebang projects with system.md)
    private var allProjects: [URL] {
        state.ui.recentProjects.filter { isShebangProject($0) }
    }

    // Check if a directory is a shebang project (has system.md file)
    private func isShebangProject(_ url: URL) -> Bool {
        let systemMdPath = url.appendingPathComponent("system.md").path
        return FileManager.default.fileExists(atPath: systemMdPath)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with project name
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Recent projects section - always visible
                    projectsSection
                        .padding(.vertical, 8)
                        .background(Color.Shebang.bgSecondary.opacity(0.5))

                    // Files section header
                    HStack {
                        Text("files")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.lowercase)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    // File tree with drop zone for root directory
                    if let session = state.sessions.activeSession {
                        DirectoryContentsView(
                            url: session.workingDirectory,
                            expandedFolders: $expandedFolders,
                            selectedFile: $selectedFile,
                            onFileSelect: handleFileSelect,
                            rootDropTarget: session.workingDirectory
                        )
                        .id(session.workingDirectory)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Projects Section

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Section header
            HStack {
                Text("projects")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.lowercase)

                Spacer()

                // New project button - opens folder picker
                Button {
                    openFolderPickerForNewProject()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("new")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.Shebang.accentPrimary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.horizontal, 12)

            // Name input (shown after folder is selected)
            if pendingParentDir != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Creating in: \(pendingParentDir!.lastPathComponent)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        TextField("Project name", text: $newProjectName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .onSubmit {
                                createProjectInSelectedFolder()
                            }

                        Button("Create") {
                            createProjectInSelectedFolder()
                        }
                        .font(.system(size: 11))
                        .disabled(newProjectName.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Button("Cancel") {
                        pendingParentDir = nil
                        newProjectName = ""
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.Shebang.bgTertiary)
            }

            // Recent projects list
            let projectsToShow = showAllProjects ? allProjects : recentProjects
            ForEach(projectsToShow, id: \.path) { projectURL in
                ProjectRowCompact(
                    url: projectURL,
                    isCurrentProject: projectURL.path == currentProjectURL?.path
                ) {
                    switchToProject(projectURL)
                }
            }

            // See more / See less
            if allProjects.count > 3 {
                Button {
                    showAllProjects.toggle()
                } label: {
                    Text(showAllProjects ? "show less" : "see \(allProjects.count - 3) more...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
    }

    /// Opens folder picker to select where to create new project
    private func openFolderPickerForNewProject() {
        let panel = NSOpenPanel()
        panel.title = "Choose Location for New Project"
        panel.message = "Select the folder where you want to create your new project"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Location"

        if panel.runModal() == .OK, let url = panel.url {
            pendingParentDir = url
            newProjectName = ""
        }
    }

    /// Creates the project folder with shebang files and opens it
    private func createProjectInSelectedFolder() {
        guard let parentDir = pendingParentDir, !newProjectName.isEmpty else { return }

        // Creates project folder, sets up shebang files, and creates+selects session
        let session = state.sessions.createProjectAtLocation(
            parentDir: parentDir,
            name: newProjectName
        )
        state.ui.trackProject(session.workingDirectory)

        // Reset state
        pendingParentDir = nil
        newProjectName = ""
    }

    /// Switch to a project directory
    private func switchToProject(_ url: URL) {
        // Find existing session for this project, or create one
        if let existingSession = state.sessions.sessions.first(where: {
            $0.workingDirectory.path == url.path && $0.status != .terminated
        }) {
            // Switch to existing session
            state.sessions.selectSession(existingSession)
        } else {
            // Create new session for this project
            state.sessions.createSession(name: url.lastPathComponent, at: url)
        }
        state.ui.trackProject(url)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("files")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .textCase(.lowercase)

                if let session = state.sessions.activeSession {
                    Text(session.directoryName)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("no project")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Refresh button
            Button {
                // Force refresh file tree
                expandedFolders = expandedFolders
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isRefreshHovered ? Color.accentColor : .secondary)
                    .rotationEffect(.degrees(isRefreshHovered ? 180 : 0))
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRefreshHovered)
            .onHover { isRefreshHovered = $0 }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func handleFileSelect(_ url: URL) {
        selectedFile = url

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Toggle folder expansion
                if expandedFolders.contains(url) {
                    expandedFolders.remove(url)
                } else {
                    expandedFolders.insert(url)
                }
            } else {
                // Open file preview
                onFileSelect?(url)
            }
        }
    }
}

// MARK: - Directory Contents View

/// Shows the contents of a directory directly (not the directory itself)
struct DirectoryContentsView: View {
    let url: URL
    @Binding var expandedFolders: Set<URL>
    @Binding var selectedFile: URL?
    let onFileSelect: (URL) -> Void
    var rootDropTarget: URL?  // Where to drop files when dropped on empty space

    @State private var children: [URL] = []
    @State private var isLoading = true
    @State private var isRootDropTargeted = false
    @State private var fileWatcher: DispatchSourceFileSystemObject?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding()
            } else if children.isEmpty {
                // Empty folder drop zone
                Text("Empty folder - drop files here")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(isRootDropTargeted ? Color.Shebang.accentPrimary.opacity(0.2) : Color.clear)
                    .onDrop(of: [.fileURL], isTargeted: $isRootDropTargeted) { providers in
                        guard let targetDir = rootDropTarget ?? Optional(url) else { return false }
                        return handleFileDrop(providers: providers, targetFolder: targetDir)
                    }
            } else {
                ForEach(children, id: \.self) { child in
                    FileTreeNode(
                        url: child,
                        expandedFolders: $expandedFolders,
                        selectedFile: $selectedFile,
                        onFileSelect: onFileSelect,
                        depth: 0,
                        onFileMoved: { Task { await loadContentsAsync() } },
                        projectRoot: url  // Pass the root directory for relative path computation
                    )
                }

                // Drop zone at bottom for dropping to root
                Rectangle()
                    .fill(isRootDropTargeted ? Color.Shebang.accentPrimary.opacity(0.3) : Color.Shebang.bgTertiary.opacity(0.3))
                    .frame(height: 50)
                    .contentShape(Rectangle())
                    .overlay {
                        Text(isRootDropTargeted ? "Drop here to add to project root" : "Drop files here")
                            .font(.system(size: 11))
                            .foregroundStyle(isRootDropTargeted ? Color.Shebang.accentPrimary : .secondary)
                    }
                    .onDrop(of: [.fileURL, .url], isTargeted: $isRootDropTargeted) { providers in
                        ShebangLog.debug("ROOT DROP detected, providers: \(providers.count)")
                        guard let targetDir = rootDropTarget ?? Optional(url) else { return false }
                        return handleFileDrop(providers: providers, targetFolder: targetDir)
                    }
                    .onChange(of: isRootDropTargeted) { _, targeted in
                        ShebangLog.debug("Root drop zone targeted: \(targeted)")
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            ShebangLog.info("DirectoryContentsView loaded for: \(url.lastPathComponent)")
            startWatchingDirectory()
        }
        .onDisappear {
            stopWatchingDirectory()
        }
        // Use task(id:) which auto-cancels and re-runs when URL changes
        .task(id: url.path) {
            await loadContentsAsync()
            // Restart watcher when URL changes
            stopWatchingDirectory()
            startWatchingDirectory()
        }
    }

    // MARK: - File System Watching

    /// Start watching the directory for changes
    private func startWatchingDirectory() {
        // Open file descriptor for the directory
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            ShebangLog.warn("Failed to open directory for watching: \(url.lastPathComponent)")
            return
        }

        // Create dispatch source for file system events
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: .main
        )

        source.setEventHandler { [url] in
            // Directory contents changed - refresh
            ShebangLog.debug("File system change detected in root: \(url.lastPathComponent)")
            Task {
                await self.loadContentsAsync()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileWatcher = source
        ShebangLog.debug("Started watching directory: \(url.lastPathComponent)")
    }

    /// Stop watching the directory
    private func stopWatchingDirectory() {
        fileWatcher?.cancel()
        fileWatcher = nil
    }

    /// Handle files dropped onto root
    private func handleFileDrop(providers: [NSItemProvider], targetFolder: URL) -> Bool {
        ShebangLog.debug("handleFileDrop called with \(providers.count) providers to \(targetFolder.lastPathComponent)")
        for (index, provider) in providers.enumerated() {
            let types = provider.registeredTypeIdentifiers
            ShebangLog.debug("Provider \(index) types: \(types)")
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                ShebangLog.debug("Provider \(index) has public.file-url, loading...")
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let sourceURL = URL(dataRepresentation: data, relativeTo: nil) {
                        let destinationURL = targetFolder.appendingPathComponent(sourceURL.lastPathComponent)

                        DispatchQueue.global(qos: .userInitiated).async {
                            do {
                                // Don't move if already in target folder
                                if sourceURL.deletingLastPathComponent().path == targetFolder.path {
                                    return
                                }

                                // Check if destination exists
                                if FileManager.default.fileExists(atPath: destinationURL.path) {
                                    ShebangLog.warn("File already exists: \(destinationURL.lastPathComponent)")
                                    return
                                }

                                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                                ShebangLog.info("Moved \(sourceURL.lastPathComponent) to \(targetFolder.lastPathComponent)")

                                // Refresh the view
                                DispatchQueue.main.async {
                                    Task { await loadContentsAsync() }
                                }
                            } catch {
                                do {
                                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                                    ShebangLog.info("Copied \(sourceURL.lastPathComponent) to \(targetFolder.lastPathComponent)")
                                } catch {
                                    ShebangLog.error("Failed to move/copy: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }

    private func loadContentsAsync() async {
        isLoading = true

        // Use ls command to get directory contents - ensures consistency with terminal
        // This is more reliable than FileManager which may have permission differences
        let result = await runLS(at: url)

        if !result.isEmpty {
            // Sort: directories first, then alphabetically
            let sorted = result.sorted { a, b in
                var aIsDir: ObjCBool = false
                var bIsDir: ObjCBool = false
                FileManager.default.fileExists(atPath: a.path, isDirectory: &aIsDir)
                FileManager.default.fileExists(atPath: b.path, isDirectory: &bIsDir)

                if aIsDir.boolValue != bIsDir.boolValue {
                    return aIsDir.boolValue
                }
                return a.lastPathComponent.localizedCaseInsensitiveCompare(
                    b.lastPathComponent
                ) == .orderedAscending
            }
            children = sorted
        } else {
            // Fallback to FileManager if ls fails
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                    options: []
                )
                children = contents
                    .filter { $0.lastPathComponent != "." && $0.lastPathComponent != ".." }
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
            } catch {
                ShebangLog.warn("Failed to load directory contents: \(error)")
            }
        }

        isLoading = false
    }

    /// Run ls command to get directory contents - matches terminal behavior
    private func runLS(at directory: URL) async -> [URL] {
        await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/ls")
            process.arguments = ["-1a", directory.path]  // One entry per line, include dotfiles
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            process.currentDirectoryURL = directory

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let entries = output.split(separator: "\n")
                        .map { String($0) }
                        .filter { !$0.isEmpty && $0 != "." && $0 != ".." }
                        .map { directory.appendingPathComponent($0) }
                    continuation.resume(returning: entries)
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                ShebangLog.warn("ls failed: \(error)")
                continuation.resume(returning: [])
            }
        }
    }

}

// MARK: - File Tree Node

struct FileTreeNode: View {
    let url: URL
    @Binding var expandedFolders: Set<URL>
    @Binding var selectedFile: URL?
    let onFileSelect: (URL) -> Void
    let depth: Int
    var onFileMoved: (() -> Void)?  // Callback when file is moved/deleted
    var projectRoot: URL?  // Project root for computing relative paths

    @State private var children: [URL] = []
    @State private var isLoading = false
    @State private var isHovered = false
    @State private var isDropTargeted = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var fileWatcher: DispatchSourceFileSystemObject?

    private var isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }

    private var isExpanded: Bool {
        expandedFolders.contains(url)
    }

    private var isSelected: Bool {
        selectedFile == url
    }

    /// Compute relative path from project root
    private var relativePath: String {
        guard let root = projectRoot else { return url.path }
        let rootPath = root.path
        let filePath = url.path
        if filePath.hasPrefix(rootPath) {
            var relative = String(filePath.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative = String(relative.dropFirst())
            }
            return relative.isEmpty ? url.lastPathComponent : relative
        }
        return url.path
    }

    /// Copy relative path to clipboard
    private func copyPathToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(relativePath, forType: .string)
        ShebangLog.info("Copied to clipboard: \(relativePath)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Use Button for proper click + context menu support
            Button {
                onFileSelect(url)
            } label: {
                nodeRow
                    .padding(.leading, CGFloat(depth) * 16 + 10)
                    .padding(.vertical, 5)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(dropBackground)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            // Context menu on right-click
            .contextMenu {
                Button {
                    copyPathToClipboard()
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }

                Button {
                    revealInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }

                if !isDirectory {
                    Button {
                        openWithDefaultApp()
                    } label: {
                        Label("Open with Default App", systemImage: "arrow.up.forward.app")
                    }
                }

                Divider()

                Button {
                    startRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteFile()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            // Make files draggable FROM the sidebar as TEXT (file path)
            // Using onDrag with custom NSItemProvider to prevent SwiftUI from adding image data
            .onDrag {
                createPathOnlyItemProvider(for: url.path)
            } preview: {
                // Preview shown while dragging
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                    Text(url.lastPathComponent)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.Shebang.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            // Enable Cmd+C to copy the relative path as plain text
            .copyable([relativePath])
            // Drop zone for directories - use UTType strings for better compatibility
            .onDrop(of: isDirectory ? [.fileURL, .url] : [], isTargeted: $isDropTargeted) { providers in
                ShebangLog.debug("DROP detected on: \(url.lastPathComponent), providers: \(providers.count)")
                return handleFileDrop(providers: providers, targetFolder: url)
            }
            .onChange(of: isDropTargeted) { _, targeted in
                if isDirectory {
                    ShebangLog.debug("Folder '\(url.lastPathComponent)' drop targeted: \(targeted)")
                }
            }

            // Children (if expanded directory)
            if isDirectory && isExpanded {
                ForEach(children, id: \.self) { child in
                    FileTreeNode(
                        url: child,
                        expandedFolders: $expandedFolders,
                        selectedFile: $selectedFile,
                        onFileSelect: onFileSelect,
                        depth: depth + 1,
                        onFileMoved: { loadChildren() },
                        projectRoot: projectRoot
                    )
                }
            }
        }
        .onAppear {
            if isDirectory {
                loadChildren()
                startWatchingDirectory()
            }
        }
        .onDisappear {
            stopWatchingDirectory()
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                loadChildren()
            }
        }
    }

    // MARK: - Node Row

    @FocusState private var isRenameFieldFocused: Bool

    private var nodeRow: some View {
        HStack(spacing: 6) {
            // Expansion arrow (for directories)
            if isDirectory {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isHovered || isDropTargeted ? Color.Shebang.accentPrimary : Color.Shebang.textMuted)
                    .frame(width: 12)
            } else {
                Spacer()
                    .frame(width: 12)
            }

            // File/folder icon
            Image(systemName: iconName)
                .foregroundStyle(isDropTargeted ? Color.Shebang.accentPrimary : iconColor)
                .font(.system(size: 14))

            // Name - inline editable when renaming
            if isRenaming {
                TextField("", text: $renameText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isRenameFieldFocused)
                    .onSubmit {
                        commitRename()
                    }
                    .onExitCommand {
                        cancelRename()
                    }
                    .onAppear {
                        // Select filename without extension
                        isRenameFieldFocused = true
                    }
            } else {
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Drop indicator for folders
            if isDirectory && isDropTargeted {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.Shebang.accentPrimary)
                    .font(.system(size: 12))
            }
        }
    }

    private var dropBackground: Color {
        if isDropTargeted && isDirectory {
            return Color.Shebang.accentPrimary.opacity(0.3)
        } else if isSelected {
            return Color.Shebang.accentPrimary.opacity(0.2)
        } else if isHovered {
            return Color.Shebang.bgTertiary
        } else {
            return Color.clear
        }
    }

    // MARK: - Icon

    private var iconName: String {
        if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "doc.text"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "json": return "curlybraces.square"
        case "md": return "doc.richtext"
        case "txt": return "doc.text"
        case "sh", "bash", "zsh": return "terminal"
        case "yaml", "yml": return "doc.text"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        if isDirectory {
            return .blue
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "py": return .green
        case "js", "ts", "jsx", "tsx": return .yellow
        case "json": return .purple
        case "md": return .cyan
        default: return .secondary
        }
    }

    // MARK: - Load Children

    private func loadChildren(forceRefresh: Bool = false) {
        guard isDirectory else { return }
        guard forceRefresh || children.isEmpty else { return }

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                    options: []
                ).filter { $0.lastPathComponent != "." && $0.lastPathComponent != ".." }

                // Sort: directories first, then alphabetically
                let sorted = contents.sorted { a, b in
                    var aIsDir: ObjCBool = false
                    var bIsDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: a.path, isDirectory: &aIsDir)
                    FileManager.default.fileExists(atPath: b.path, isDirectory: &bIsDir)

                    if aIsDir.boolValue != bIsDir.boolValue {
                        return aIsDir.boolValue
                    }
                    return a.lastPathComponent.localizedCaseInsensitiveCompare(
                        b.lastPathComponent
                    ) == .orderedAscending
                }

                DispatchQueue.main.async {
                    children = sorted
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    // MARK: - File System Watching

    private func startWatchingDirectory() {
        guard isDirectory else { return }

        // Open file descriptor for the directory
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        // Create dispatch source for file system events
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: .main
        )

        source.setEventHandler { [url] in
            // Directory contents changed - refresh
            ShebangLog.debug("File system change detected in: \(url.lastPathComponent)")
            self.loadChildren(forceRefresh: true)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileWatcher = source
    }

    private func stopWatchingDirectory() {
        fileWatcher?.cancel()
        fileWatcher = nil
    }

    // MARK: - Context Menu Actions

    /// Reveal file/folder in Finder
    private func revealInFinder() {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }

    /// Open file with default application
    private func openWithDefaultApp() {
        NSWorkspace.shared.open(url)
    }

    /// Delete file or folder (moves to trash)
    private func deleteFile() {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            ShebangLog.info("Moved to trash: \(url.lastPathComponent)")
            onFileMoved?()
        } catch {
            ShebangLog.error("Failed to delete: \(error)")
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Cannot Delete"
            alert.informativeText = "Failed to move \"\(url.lastPathComponent)\" to trash: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    /// Start inline rename mode
    private func startRename() {
        renameText = url.lastPathComponent
        isRenaming = true
        ShebangLog.debug("Started inline rename for: \(url.lastPathComponent)")
    }

    /// Commit the rename
    private func commitRename() {
        let newName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        isRenaming = false

        // Don't rename if empty or unchanged
        guard !newName.isEmpty, newName != url.lastPathComponent else {
            ShebangLog.debug("Rename cancelled - no change")
            return
        }

        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)

        // Check if destination already exists
        if FileManager.default.fileExists(atPath: newURL.path) {
            ShebangLog.warn("Cannot rename: \(newName) already exists")
            NSSound.beep()
            return
        }

        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            ShebangLog.info("Renamed \(url.lastPathComponent) to \(newName)")
            // Immediately refresh parent
            onFileMoved?()
        } catch {
            ShebangLog.error("Failed to rename: \(error)")
            NSSound.beep()
        }
    }

    /// Cancel rename mode
    private func cancelRename() {
        isRenaming = false
        renameText = ""
        ShebangLog.debug("Rename cancelled")
    }

    // MARK: - Drag and Drop

    /// Handle files dropped onto a folder
    private func handleFileDrop(providers: [NSItemProvider], targetFolder: URL) -> Bool {
        ShebangLog.debug("[FileTreeNode] handleFileDrop called with \(providers.count) providers to \(targetFolder.lastPathComponent)")
        for (index, provider) in providers.enumerated() {
            let types = provider.registeredTypeIdentifiers
            ShebangLog.debug("[FileTreeNode] Provider \(index) types: \(types)")
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                ShebangLog.debug("[FileTreeNode] Provider \(index) has public.file-url, loading...")
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let sourceURL = URL(dataRepresentation: data, relativeTo: nil) {
                        let destinationURL = targetFolder.appendingPathComponent(sourceURL.lastPathComponent)

                        DispatchQueue.global(qos: .userInitiated).async {
                            do {
                                // Check if it's a move (same volume) or copy (different volume)
                                if sourceURL.deletingLastPathComponent().path == targetFolder.path {
                                    // Already in this folder, do nothing
                                    return
                                }

                                // Try to move first (faster for same volume)
                                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                                ShebangLog.info("Moved \(sourceURL.lastPathComponent) to \(targetFolder.lastPathComponent)")
                            } catch {
                                // If move fails, try copy
                                do {
                                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                                    ShebangLog.info("Copied \(sourceURL.lastPathComponent) to \(targetFolder.lastPathComponent)")
                                } catch {
                                    ShebangLog.error("Failed to move/copy file: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Compact Project Row

struct ProjectRowCompact: View {
    let url: URL
    let isCurrentProject: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(isCurrentProject ? Color.Shebang.accentPrimary : .secondary)

                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: isCurrentProject ? .semibold : .medium))
                    .lineLimit(1)

                Spacer()

                if isCurrentProject {
                    Text("current")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.Shebang.bgTertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.Shebang.bgTertiary : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SidebarView(onFileSelect: { _ in })
        .frame(width: 260, height: 600)
}
