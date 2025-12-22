// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import AppKit

/// Command input bar with git-aware prompt
/// Shows: directory | git branch | git status indicators
/// Attached image for sending with messages
struct AttachedImage: Identifiable {
    let id = UUID()
    let path: String
    let filename: String

    init(path: String) {
        self.path = path
        self.filename = (path as NSString).lastPathComponent
    }
}

struct CommandBarView: View {
    private var state: AppState { AppState.shared }

    @State private var commandText = ""
    @State private var gitInfo: GitInfo?
    @State private var isSubmitHovered = false
    @State private var completions: [String] = []
    @State private var showCompletions = false
    @State private var selectedCompletion = 0
    @State private var attachedImages: [AttachedImage] = []
    @State private var isProcessingDrop = false  // Prevent re-entry
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Prompt row above input
            HStack {
                promptView
                Spacer()
            }
            .padding(.horizontal, 4)

            // Attached images row (if any)
            if !attachedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(attachedImages) { image in
                            ImagePill(image: image) {
                                attachedImages.removeAll { $0.id == image.id }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Multi-line input field with rounded background
            // Enter = newline, Shift+Enter = send
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if commandText.isEmpty && attachedImages.isEmpty {
                        Text("what's the move?")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }

                    TextEditor(text: $commandText)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .frame(minHeight: 20, maxHeight: 100)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .onKeyPress(.return, phases: .down) { event in
                    if event.modifiers.contains(.shift) {
                        // Shift+Enter = send
                        if showCompletions && !completions.isEmpty {
                            applyCompletion(completions[selectedCompletion])
                        } else {
                            executeCommand()
                        }
                        return .handled
                    }
                    // Enter = newline (default behavior)
                    return .ignored
                }
                .onKeyPress(.tab) {
                    triggerCompletion()
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    if showCompletions {
                        selectedCompletion = max(0, selectedCompletion - 1)
                        return .handled
                    } else if !commandText.contains("\n") {
                        navigateHistory(direction: -1)
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.downArrow) {
                    if showCompletions {
                        selectedCompletion = min(completions.count - 1, selectedCompletion + 1)
                        return .handled
                    } else if !commandText.contains("\n") {
                        navigateHistory(direction: 1)
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.escape) {
                    showCompletions = false
                    return .handled
                }
                // Ctrl+C - send interrupt to terminal
                .onKeyPress(keys: [.init("c")], phases: .down) { event in
                    if event.modifiers.contains(.control) {
                        state.terminal.sendInterrupt()
                        return .handled
                    }
                    return .ignored
                }
                // Ctrl+D - send EOF to terminal
                .onKeyPress(keys: [.init("d")], phases: .down) { event in
                    if event.modifiers.contains(.control) {
                        state.terminal.sendEOF()
                        return .handled
                    }
                    return .ignored
                }
                // Ctrl+Z - send suspend to terminal
                .onKeyPress(keys: [.init("z")], phases: .down) { event in
                    if event.modifiers.contains(.control) {
                        state.terminal.sendSuspend()
                        return .handled
                    }
                    return .ignored
                }
                .onChange(of: commandText) { oldValue, newValue in
                    showCompletions = false

                    // Debug: log text changes
                    if newValue != oldValue {
                        print("📝 Text changed: '\(oldValue)' → '\(newValue)'")
                        print("   Length: \(oldValue.count) → \(newValue.count)")
                    }

                    // Detect pasted/dropped image paths and convert to attachments
                    if detectAndAttachImage(from: newValue) {
                        print("✅ Image detected and attached!")
                    }
                }

                // Submit button - VS Code style
                Button {
                    executeCommand()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(commandText.isEmpty ? Color.Shebang.textMuted : .white)
                        .padding(8)
                        .background(commandText.isEmpty ? Color.clear : Color.Shebang.accentPrimary)
                }
                .buttonStyle(.plain)
                .disabled(commandText.isEmpty)
                .opacity(isSubmitHovered && !commandText.isEmpty ? 0.8 : 1.0)
                .onHover { isSubmitHovered = $0 }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isFocused ? Color.Shebang.accentPrimary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .contentShape(Rectangle())  // Make entire area tappable/droppable
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
            return true
        }
        .overlay(alignment: .topLeading) {
            // Completion popup
            if showCompletions && !completions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(completions.enumerated()), id: \.offset) { index, completion in
                        HStack {
                            Text(completion)
                                .font(.system(size: 13, design: .monospaced))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(index == selectedCompletion ? Color.Shebang.accentPrimary.opacity(0.3) : Color.clear)
                        .onTapGesture {
                            applyCompletion(completion)
                        }
                    }
                }
                .frame(minWidth: 200)
                .background(Color.Shebang.bgSecondary)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.Shebang.bgElevated, lineWidth: 1)
                )
                .offset(x: 16, y: -CGFloat(completions.count * 28) - 8)
            }
        }
        .onAppear {
            updateGitInfo()
            isFocused = true
        }
        .onChange(of: state.sessions.activeSession?.workingDirectory) { _, _ in
            updateGitInfo()
        }
    }

    // MARK: - Prompt View

    private var promptView: some View {
        HStack(spacing: 6) {
            // Username and directory
            if let session = state.sessions.activeSession {
                Text(NSUserName())
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.green)

                Text("in")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(session.directoryName)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.cyan)
            }

            // Git info
            if let git = gitInfo {
                Text("on")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Branch name with icon
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                    Text(git.branch)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.purple)

                // Status indicators - clearer format
                if git.hasChanges {
                    HStack(spacing: 6) {
                        if git.staged > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                Text("\(git.staged)")
                            }
                            .foregroundStyle(.green)
                            .help("\(git.staged) staged")
                        }
                        if git.modified > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 9))
                                Text("\(git.modified)")
                            }
                            .foregroundStyle(.yellow)
                            .help("\(git.modified) modified")
                        }
                        if git.untracked > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 9))
                                Text("\(git.untracked)")
                            }
                            .foregroundStyle(.orange)
                            .help("\(git.untracked) untracked")
                        }
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
            }

            // Prompt symbol
            Text("❯")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(gitInfo?.hasChanges == true ? .yellow : .green)
        }
    }

    // MARK: - Tab Completion

    private func triggerCompletion() {
        let input = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Slash command completion
        if input.hasPrefix("/") {
            let partial = String(input.dropFirst())
            let commands = ["help", "favorite", "fav", "reload", "new", "ask", "claude"]
            completions = commands.filter { $0.hasPrefix(partial) }.map { "/\($0)" }
        } else {
            // File/directory completion from current CWD
            completions = getFileCompletions(for: input)
        }

        selectedCompletion = 0
        showCompletions = !completions.isEmpty

        // If only one match, apply immediately
        if completions.count == 1 {
            applyCompletion(completions[0])
        }
    }

    private func getFileCompletions(for input: String) -> [String] {
        guard let session = state.sessions.activeSession else { return [] }
        let cwd = session.workingDirectory

        // Get the partial filename to complete
        let parts = input.split(separator: " ", omittingEmptySubsequences: false)
        let partial = parts.last.map(String.init) ?? ""

        // Determine the directory to search
        let (searchDir, prefix): (URL, String)
        if partial.contains("/") {
            let partialPath = partial as NSString
            let dir = partialPath.deletingLastPathComponent
            if partial.hasPrefix("/") {
                searchDir = URL(fileURLWithPath: dir)
            } else if partial.hasPrefix("~") {
                searchDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(String(dir.dropFirst()))
            } else {
                searchDir = cwd.appendingPathComponent(dir)
            }
            prefix = dir.isEmpty ? "" : dir + "/"
        } else {
            searchDir = cwd
            prefix = ""
        }

        // Get matching files
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: searchDir, includingPropertiesForKeys: [.isDirectoryKey])
            let partialName = partial.contains("/") ? (partial as NSString).lastPathComponent : partial

            return contents
                .filter { $0.lastPathComponent.hasPrefix(partialName) }
                .prefix(10)
                .map { url in
                    var isDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                    let name = prefix + url.lastPathComponent + (isDir.boolValue ? "/" : "")

                    // Reconstruct command with completion
                    if parts.count > 1 {
                        return parts.dropLast().joined(separator: " ") + " " + name
                    }
                    return name
                }
        } catch {
            return []
        }
    }

    private func applyCompletion(_ completion: String) {
        commandText = completion
        showCompletions = false
    }

    // MARK: - Actions

    private func executeCommand() {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Must have text or images
        guard !trimmed.isEmpty || !attachedImages.isEmpty else { return }

        // Add to history (text only)
        if !trimmed.isEmpty {
            state.ui.commandHistory.append(trimmed)
            state.ui.historyIndex = nil
        }

        // Route command with attached images
        CommandRouter.routeWithImages(trimmed, images: attachedImages, in: state)

        // Clear input and attachments
        commandText = ""
        attachedImages = []
    }

    // MARK: - Image Detection

    /// Detect image paths in text and convert to attachments
    /// Returns true if an image was found and extracted
    private func detectAndAttachImage(from text: String) -> Bool {
        // Normalize text (remove newlines from wrapped paths)
        let normalized = text
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        print("🔍 Checking for image: normalized='\(normalized)'")

        // Remove surrounding quotes if present
        var cleanPath = normalized
        if (cleanPath.hasPrefix("'") && cleanPath.hasSuffix("'")) ||
           (cleanPath.hasPrefix("\"") && cleanPath.hasSuffix("\"")) {
            cleanPath = String(cleanPath.dropFirst().dropLast())
            print("   Stripped quotes: '\(cleanPath)'")
        }

        let lower = cleanPath.lowercased()

        // Check if it's an image path
        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".heic"]
        let isImage = imageExtensions.contains { lower.hasSuffix($0) }
        let isPath = cleanPath.hasPrefix("/") || cleanPath.hasPrefix("~")

        print("   isImage=\(isImage), isPath=\(isPath), lower ends='\(String(lower.suffix(10)))'")

        if isImage && isPath {
            // It's an image path - convert to attachment
            print("   ✅ Converting to attachment: \(cleanPath)")
            attachedImages.append(AttachedImage(path: cleanPath))
            commandText = ""  // Clear the text since we converted it
            return true
        }

        return false
    }

    // MARK: - File Drop

    /// Handle files dropped onto the command bar
    private func handleFileDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                let path = url.path
                let lower = path.lowercased()

                // Check if it's an image
                let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".heic"]
                let isImage = imageExtensions.contains { lower.hasSuffix($0) }

                DispatchQueue.main.async {
                    if isImage {
                        attachedImages.append(AttachedImage(path: path))
                    } else {
                        // Non-image file - append path to text
                        if !commandText.isEmpty { commandText += " " }
                        commandText += path
                    }
                }
            }
        }
    }

    private func navigateHistory(direction: Int) {
        let history = state.ui.commandHistory
        guard !history.isEmpty else { return }

        if let current = state.ui.historyIndex {
            let newIndex = current + direction
            if newIndex >= 0 && newIndex < history.count {
                state.ui.historyIndex = newIndex
                commandText = history[newIndex]
            } else if newIndex >= history.count {
                state.ui.historyIndex = nil
                commandText = ""
            }
        } else if direction < 0 {
            // Start from end of history
            state.ui.historyIndex = history.count - 1
            commandText = history.last ?? ""
        }
    }

    // MARK: - Git Info

    private func updateGitInfo() {
        guard let session = state.sessions.activeSession else {
            gitInfo = nil
            return
        }

        Task {
            gitInfo = await GitInfo.fetch(at: session.workingDirectory)
        }
    }
}

// MARK: - Git Info

struct GitInfo {
    let branch: String
    let staged: Int
    let modified: Int
    let untracked: Int

    var hasChanges: Bool {
        staged > 0 || modified > 0 || untracked > 0
    }

    static func fetch(at url: URL) async -> GitInfo? {
        // Get current branch
        guard let branch = await runGit(["branch", "--show-current"], at: url) else {
            return nil
        }

        // Get status counts
        let status = await runGit(["status", "--porcelain"], at: url) ?? ""
        let lines = status.split(separator: "\n")

        var staged = 0
        var modified = 0
        var untracked = 0

        for line in lines {
            guard line.count >= 2 else { continue }
            let index = line.index(line.startIndex, offsetBy: 0)
            let worktree = line.index(line.startIndex, offsetBy: 1)

            let indexChar = line[index]
            let worktreeChar = line[worktree]

            if indexChar != " " && indexChar != "?" {
                staged += 1
            }
            if worktreeChar == "M" || worktreeChar == "D" {
                modified += 1
            }
            if indexChar == "?" {
                untracked += 1
            }
        }

        return GitInfo(
            branch: branch.trimmingCharacters(in: .whitespacesAndNewlines),
            staged: staged,
            modified: modified,
            untracked: untracked
        )
    }

    private static func runGit(_ args: [String], at url: URL) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = url

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)
            }
        } catch {
            return nil
        }
        return nil
    }
}

// MARK: - Command Router

@MainActor
enum CommandRouter {
    // Common shell commands to detect
    private static let shellCommands: Set<String> = [
        "ls", "cd", "pwd", "mkdir", "rm", "cp", "mv", "cat", "less", "more",
        "head", "tail", "grep", "find", "which", "whereis", "man", "echo",
        "git", "npm", "yarn", "pnpm", "node", "python", "python3", "pip",
        "swift", "swiftc", "xcodebuild", "xcrun", "make", "cmake", "cargo",
        "brew", "apt", "yum", "curl", "wget", "ssh", "scp", "rsync",
        "docker", "kubectl", "terraform", "aws", "gcloud", "az",
        "vim", "nvim", "nano", "code", "open", "touch", "chmod", "chown",
        "export", "source", "alias", "unalias", "history", "clear", "exit",
        "ps", "kill", "top", "htop", "df", "du", "free", "uname", "env",
        "tar", "zip", "unzip", "gzip", "gunzip", "xargs", "awk", "sed",
        "sort", "uniq", "wc", "diff", "patch", "tree", "file", "stat"
    ]

    /// Route a command to the appropriate handler
    static func route(_ command: String, in state: AppState) {
        routeWithImages(command, images: [], in: state)
    }

    /// Route a command with attached images
    static func routeWithImages(_ command: String, images: [AttachedImage], in state: AppState) {
        // If we have images, send to Claude with images
        if !images.isEmpty {
            sendToClaudeCodeWithImages(command, images: images, in: state)
            return
        }

        // No images - normal routing
        if isSlashCommand(command) {
            // Slash command - internal Shebang command (not file paths!)
            handleSlashCommand(command, in: state)
        } else if isImagePath(command) {
            // Image file - send to Claude with --image flag
            sendImageToClaudeCode(command, in: state)
        } else if command.hasPrefix("$ ") || command.hasPrefix("> ") {
            // Explicit shell command (strip prefix)
            let shellCmd = String(command.dropFirst(2))
            executeShellCommand(shellCmd, in: state)
        } else if isShellCommand(command) {
            // Detected shell command
            executeShellCommand(command, in: state)
        } else {
            // Natural language - send to Claude Code
            sendToClaudeCode(command, in: state)
        }
    }

    /// Detect if input is a Shebang slash command (not a file path)
    private static func isSlashCommand(_ input: String) -> Bool {
        guard input.hasPrefix("/") else { return false }

        // Known slash commands are short, single-word
        let afterSlash = String(input.dropFirst())
        let firstPart = afterSlash.split(separator: " ").first.map(String.init) ?? afterSlash

        // Slash commands don't contain path separators
        if firstPart.contains("/") { return false }

        // Known commands
        let knownCommands = ["help", "favorite", "fav", "reload", "new", "ask", "claude"]
        return knownCommands.contains(firstPart.lowercased())
    }

    /// Detect if input is an image file path
    private static func isImagePath(_ input: String) -> Bool {
        // Normalize: remove quotes, newlines, whitespace (macOS adds quotes on drag)
        let normalized = normalizePath(input)
        let lower = normalized.lowercased()

        // Check for image extensions
        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".heic"]
        for ext in imageExtensions {
            if lower.hasSuffix(ext) {
                // Verify it looks like a path
                if normalized.hasPrefix("/") || normalized.hasPrefix("~") || normalized.hasPrefix("./") {
                    return true
                }
            }
        }
        return false
    }

    /// Normalize a path by removing quotes, line breaks, whitespace
    private static func normalizePath(_ input: String) -> String {
        var result = input
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Remove surrounding quotes (macOS adds these on drag)
        if (result.hasPrefix("'") && result.hasSuffix("'")) ||
           (result.hasPrefix("\"") && result.hasSuffix("\"")) {
            result = String(result.dropFirst().dropLast())
        }

        return result
    }

    /// Detect if input looks like a shell command
    private static func isShellCommand(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty or very short - not a command
        guard trimmed.count > 0 else { return false }

        // Get first word
        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

        // Check if it starts with a known shell command
        if shellCommands.contains(firstWord.lowercased()) {
            return true
        }

        // Check if it starts with ./ or ~/ (executable paths)
        // Note: We don't treat bare / paths as shell commands anymore (could be Claude input)
        if trimmed.hasPrefix("./") || trimmed.hasPrefix("~/") {
            return true
        }

        // Check for common shell patterns
        // Pipes, redirects, semicolons, &&, ||
        if trimmed.contains(" | ") || trimmed.contains(" > ") || trimmed.contains(" >> ") ||
           trimmed.contains(" && ") || trimmed.contains(" || ") || trimmed.contains("; ") {
            return true
        }

        // If it's short (< 4 words) and has no spaces, likely a command
        let wordCount = trimmed.split(separator: " ").count
        if wordCount <= 3 && !trimmed.contains("?") {
            // Check if it could be a command with args
            if firstWord.allSatisfy({ $0.isLetter || $0 == "-" || $0 == "_" }) {
                return true
            }
        }

        return false
    }

    private static func handleSlashCommand(_ command: String, in state: AppState) {
        let parts = command.dropFirst().split(separator: " ", maxSplits: 1)
        let cmd = String(parts.first ?? "")

        switch cmd.lowercased() {
        case "favorite", "fav":
            // Add current directory to favorites
            if let session = state.sessions.activeSession {
                state.ui.addFavorite(session.workingDirectory)
            }

        case "reload":
            hotReload()

        case "help":
            showHelp(in: state)

        case "new":
            state.sessions.createSession()

        case "ask", "claude":
            // Explicit Claude Code command
            let query = parts.count > 1 ? String(parts[1]) : ""
            if !query.isEmpty {
                sendToClaudeCode(query, in: state)
            }

        default:
            // Unknown slash command - tell user
            state.terminal.sendCommand("echo 'Unknown command: /\(cmd). Type /help for available commands.'")
        }
    }

    private static func executeShellCommand(_ command: String, in state: AppState) {
        // Detect if user is starting Claude manually
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "claude" || trimmed.hasPrefix("claude ") {
            state.terminal.isClaudeRunning = true
        }
        state.terminal.sendCommand(command)
    }

    private static func sendToClaudeCode(_ query: String, in state: AppState) {
        if state.terminal.isClaudeRunning {
            // Claude is already running - send raw text directly to its stdin
            state.terminal.sendCommand(query)
        } else {
            // Claude not running - start it with the query
            // Escape the query for shell
            let escaped = query
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "`", with: "\\`")

            let claudeCommand = "claude \"\(escaped)\""
            state.terminal.sendCommand(claudeCommand)
            state.terminal.isClaudeRunning = true
        }
    }

    /// Send a message with attached images to Claude Code
    private static func sendToClaudeCodeWithImages(_ query: String, images: [AttachedImage], in state: AppState) {
        // Build image references - Claude reads files via path
        var imageRefs: [String] = []
        for image in images {
            imageCounter += 1
            imageRefs.append("img\(imageCounter): \(image.path)")
        }

        // Combine image refs with query
        var fullMessage = imageRefs.joined(separator: "\n")
        if !query.isEmpty {
            fullMessage += "\n\n" + query
        } else if !images.isEmpty {
            fullMessage += "\n\nAnalyze these images"
        }

        // Send to Claude
        if state.terminal.isClaudeRunning {
            // Claude is running - send as text
            state.terminal.sendCommand(fullMessage)
        } else {
            // Start Claude with the message
            let escaped = fullMessage
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "`", with: "\\`")

            let claudeCommand = "claude \"\(escaped)\""
            state.terminal.sendCommand(claudeCommand)
            state.terminal.isClaudeRunning = true
        }
    }

    /// Track image count for labeling
    private static var imageCounter = 0

    /// Send an image to Claude Code
    private static func sendImageToClaudeCode(_ imagePath: String, in state: AppState) {
        // Normalize path (remove line breaks from UI wrapping)
        let normalized = normalizePath(imagePath)

        // Expand ~ to home directory
        let expandedPath: String
        if normalized.hasPrefix("~") {
            expandedPath = (normalized as NSString).expandingTildeInPath
        } else {
            expandedPath = normalized
        }

        // Increment image counter and create label
        imageCounter += 1
        let label = "img\(imageCounter)"
        let message = "\(label): \(expandedPath)\n\nAnalyze this image"

        if state.terminal.isClaudeRunning {
            // Claude is running - send as labeled reference
            state.terminal.sendCommand(message)
        } else {
            // Start Claude with the image path
            let escaped = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "`", with: "\\`")

            let claudeCommand = "claude \"\(escaped)\""
            state.terminal.sendCommand(claudeCommand)
            state.terminal.isClaudeRunning = true
        }
    }

    /// Reset image counter (call when conversation resets)
    static func resetImageCounter() {
        imageCounter = 0
    }

    private static func hotReload() {
        // Hot reload: rebuild and relaunch the app
        Task {
            // Save state before reload
            AppState.shared.prepareForReload()

            // Get the app bundle directory
            let appPath = Bundle.main.bundlePath
            let appDir = URL(fileURLWithPath: appPath).deletingLastPathComponent()

            // Run build script and relaunch
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", """
                cd "\(appDir.path)" && ./build.sh && sleep 0.5 && open Shebang.app
            """]
            process.currentDirectoryURL = appDir

            do {
                try process.run()
                // Exit current app after starting rebuild
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                print("Hot reload failed: \(error)")
            }
        }
    }

    private static func showHelp(in state: AppState) {
        let helpText = """
        echo "
        Shebang Commands:
          /help            - Show this help
          /favorite, /fav  - Add current folder to favorites
          /reload          - Hot reload the application
          /new             - Create new session
          /ask <query>     - Explicit Claude Code query

        Input Routing:
          $ <cmd>          - Force shell command
          /command         - Shebang internal command
          Natural language - Automatically sent to Claude Code
          Shell commands   - Detected and sent to terminal

        Examples:
          ls -la           → Shell (detected)
          git status       → Shell (detected)
          $ echo test      → Shell (forced)
          What is this?    → Claude Code
          Fix the bug      → Claude Code
        "
        """
        state.terminal.sendCommand(helpText)
    }
}

// MARK: - Image Pill

/// Visual pill/tag for attached images
struct ImagePill: View {
    let image: AttachedImage
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.system(size: 10))

            Text(image.filename)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isHovered ? .white : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.Shebang.accentPrimary.opacity(0.2))
        .foregroundStyle(Color.Shebang.accentPrimary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.Shebang.accentPrimary.opacity(0.4), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .help(image.path)
    }
}

// MARK: - Preview

#Preview {
    CommandBarView()
        .frame(width: 800, height: 100)
}
