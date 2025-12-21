// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI

/// File browser sidebar with collapsible directory tree
struct SidebarView: View {
    // Access global app state
    private var state: AppState { AppState.shared }
    var onFileSelect: ((URL) -> Void)?

    @State private var expandedFolders: Set<URL> = []
    @State private var selectedFile: URL?
    @State private var isRefreshHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with project name
            header

            // File tree - show CONTENTS of CWD directly
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let session = state.sessions.activeSession {
                        // Show contents of working directory directly
                        // Use id() to force recreation when CWD changes
                        DirectoryContentsView(
                            url: session.workingDirectory,
                            expandedFolders: $expandedFolders,
                            selectedFile: $selectedFile,
                            onFileSelect: handleFileSelect
                        )
                        .id(session.workingDirectory)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
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

    @State private var children: [URL] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding()
            } else if children.isEmpty {
                Text("Empty folder")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(children, id: \.self) { child in
                    FileTreeNode(
                        url: child,
                        expandedFolders: $expandedFolders,
                        selectedFile: $selectedFile,
                        onFileSelect: onFileSelect,
                        depth: 0
                    )
                }
            }
        }
        // Use task(id:) which auto-cancels and re-runs when URL changes
        // More reliable than onAppear + onChange combination
        .task(id: url.path) {
            await loadContentsAsync()
        }
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
                    options: [.skipsHiddenFiles]
                )
                children = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
            } catch {
                print("⚠️ Failed to load directory contents: \(error)")
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
            process.arguments = ["-1", directory.path]  // One entry per line, no hidden
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
                        .filter { !$0.isEmpty && !$0.hasPrefix(".") }
                        .map { directory.appendingPathComponent($0) }
                    continuation.resume(returning: entries)
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                print("⚠️ ls failed: \(error)")
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

    @State private var children: [URL] = []
    @State private var isLoading = false
    @State private var isHovered = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // This node
            HStack(spacing: 6) {
                // Expansion arrow (for directories)
                if isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isHovered ? Color.Shebang.accentPrimary : Color.Shebang.textMuted)
                        .frame(width: 12)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                } else {
                    Spacer()
                        .frame(width: 12)
                }

                // File/folder icon
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 14))

                // Name
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.leading, CGFloat(depth) * 16 + 10)
            .padding(.vertical, 5)
            .padding(.trailing, 8)
            .background(backgroundColor)
            .contentShape(Rectangle())
            .onTapGesture {
                onFileSelect(url)
            }
            .onHover { isHovered = $0 }

            // Children (if expanded directory)
            if isDirectory && isExpanded {
                ForEach(children, id: \.self) { child in
                    FileTreeNode(
                        url: child,
                        expandedFolders: $expandedFolders,
                        selectedFile: $selectedFile,
                        onFileSelect: onFileSelect,
                        depth: depth + 1
                    )
                }
            }
        }
        .onAppear {
            if isDirectory {
                loadChildren()
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                loadChildren()
            }
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

    private var backgroundColor: Color {
        if isSelected {
            return Color.Shebang.accentPrimary.opacity(0.2)
        } else if isHovered {
            return Color.Shebang.bgTertiary
        } else {
            return Color.clear
        }
    }

    // MARK: - Load Children

    private func loadChildren() {
        guard isDirectory, children.isEmpty else { return }

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                    options: [.skipsHiddenFiles]
                )

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
}

// MARK: - Preview

#Preview {
    SidebarView(onFileSelect: { _ in })
        .frame(width: 260, height: 600)
}
