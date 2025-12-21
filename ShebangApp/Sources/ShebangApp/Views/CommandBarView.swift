// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

/// Command input bar with git-aware prompt
/// Shows: directory | git branch | git status indicators
struct CommandBarView: View {
    private var state: AppState { AppState.shared }

    @State private var commandText = ""
    @State private var gitInfo: GitInfo?
    @State private var isSubmitHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Prompt row above input
            HStack {
                promptView
                Spacer()
            }
            .padding(.horizontal, 4)

            // Input field with rounded background
            HStack(spacing: 8) {
                TextField("what's the move?", text: $commandText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .focused($isFocused)
                    .onSubmit {
                        executeCommand()
                    }
                    .onKeyPress(.upArrow) {
                        navigateHistory(direction: -1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        navigateHistory(direction: 1)
                        return .handled
                    }

                // Submit button with glow
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
            // Directory name
            if let session = state.sessions.activeSession {
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

                // Status indicators
                if git.hasChanges {
                    HStack(spacing: 2) {
                        if git.staged > 0 {
                            Text("+\(git.staged)")
                                .foregroundStyle(.green)
                        }
                        if git.modified > 0 {
                            Text("~\(git.modified)")
                                .foregroundStyle(.yellow)
                        }
                        if git.untracked > 0 {
                            Text("?\(git.untracked)")
                                .foregroundStyle(.red)
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
    /// Route a command to the appropriate handler
    static func route(_ command: String, in state: AppState) {
        if command.hasPrefix("/") {
            // Slash command
            handleSlashCommand(command, in: state)
        } else {
            // Shell command - send to terminal
            executeShellCommand(command, in: state)
        }
    }

    private static func handleSlashCommand(_ command: String, in state: AppState) {
        let parts = command.dropFirst().split(separator: " ", maxSplits: 1)
        let cmd = String(parts.first ?? "")

        switch cmd.lowercased() {
        case "favorite", "fav":
            // Add current directory to favorites
            if let session = state.sessions.activeSession {
                state.ui.addFavorite(session.workingDirectory)
                // TODO: Show toast notification
            }

        case "reload":
            // Hot reload the application
            hotReload()

        case "help":
            // Show help - send to terminal
            showHelp(in: state)

        case "new":
            // Create new session
            state.sessions.createSession()

        default:
            // Unknown command - maybe send to agent?
            print("Unknown command: /\(cmd)")
        }
    }

    private static func executeShellCommand(_ command: String, in state: AppState) {
        // Send command to terminal via TerminalState
        state.terminal.sendCommand(command)
    }

    private static func hotReload() {
        // TODO: Implement hot reload
        // 1. Save state
        // 2. Rebuild Swift package
        // 3. Replace binary
        // 4. Restart with state restoration
        print("Hot reload requested")
    }

    private static func showHelp(in state: AppState) {
        // Send help text to terminal
        let helpText = """
        echo "Shebang Commands:
          /favorite, /fav  - Add current folder to favorites
          /reload          - Hot reload the application
          /new             - Create new session
          /help            - Show this help

        Shell commands (cd, ls, git, etc.) are typed directly."
        """
        state.terminal.sendCommand(helpText)
    }
}

// MARK: - Preview

#Preview {
    CommandBarView()
        .frame(width: 800, height: 50)
}
