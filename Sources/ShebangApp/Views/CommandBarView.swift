// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI

/// Command input bar with git-aware prompt
/// Shows: directory | git branch | git status indicators
struct CommandBarView: View {
    private var state: AppState { AppState.shared }

    @State private var commandText = ""
    @State private var gitInfo: GitInfo?
    @State private var isSubmitHovered = false
    @State private var completions: [String] = []
    @State private var showCompletions = false
    @State private var selectedCompletion = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Prompt row above input
            HStack {
                promptView
                Spacer()
            }
            .padding(.horizontal, 4)

            // Multi-line input field with rounded background
            // Enter = newline, Shift+Enter = send
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Placeholder
                    if commandText.isEmpty {
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
                .onChange(of: commandText) { _, _ in
                    showCompletions = false
                }

                // Submit button with glow (Shift+Enter hint)
                Button {
                    executeCommand()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(commandText.isEmpty ? Color.secondary : .white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(commandText.isEmpty ? Color.clear : Color.accentColor)
                        )
                        .shadow(color: commandText.isEmpty ? .clear : Color.accentColor.opacity(0.5), radius: isSubmitHovered ? 8 : 4)
                }
                .buttonStyle(.plain)
                .disabled(commandText.isEmpty)
                .scaleEffect(isSubmitHovered && !commandText.isEmpty ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSubmitHovered)
                .onHover { isSubmitHovered = $0 }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isFocused ? Color.accentColor.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
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
                        .background(index == selectedCompletion ? Color.accentColor.opacity(0.3) : Color.clear)
                        .onTapGesture {
                            applyCompletion(completion)
                        }
                    }
                }
                .frame(minWidth: 200)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(radius: 8)
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
        let input = commandText.trimmingCharacters(in: .whitespaces)

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
        let trimmed = commandText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Add to history
        state.ui.commandHistory.append(trimmed)
        state.ui.historyIndex = nil

        // Route command
        CommandRouter.route(trimmed, in: state)

        // Clear input
        commandText = ""
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
        if command.hasPrefix("/") {
            // Slash command - internal Shebang command
            handleSlashCommand(command, in: state)
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

    /// Detect if input looks like a shell command
    private static func isShellCommand(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Empty or very short - not a command
        guard trimmed.count > 0 else { return false }

        // Get first word
        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

        // Check if it starts with a known shell command
        if shellCommands.contains(firstWord.lowercased()) {
            return true
        }

        // Check if it starts with ./ or ~/ or / (path execution)
        if trimmed.hasPrefix("./") || trimmed.hasPrefix("~/") || trimmed.hasPrefix("/") {
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
        state.terminal.sendCommand(command)
    }

    private static func sendToClaudeCode(_ query: String, in state: AppState) {
        // Send query to Claude Code CLI
        // Escape the query for shell
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")

        let claudeCommand = "claude \"\(escaped)\""
        state.terminal.sendCommand(claudeCommand)
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

// MARK: - Preview

#Preview {
    CommandBarView()
        .frame(width: 800, height: 50)
}
