// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI

/// Terminal canvas that switches between interactive terminal and block view
/// based on AppState.shared.ui.displayMode
struct TerminalCanvasView: View {
    // Access global app state
    private var state: AppState { AppState.shared }

    var body: some View {
        VStack(spacing: 0) {
            // CWD Header - always visible at top
            if let session = state.sessions.activeSession {
                TerminalHeaderView(session: session)
            }

            // Terminal content
            Group {
                if let session = state.sessions.activeSession {
                    switch state.ui.displayMode {
                    case .interactive:
                        // Interactive terminal using SwiftTerm
                        SwiftTermView(
                            session: session,
                            onOutput: handleTerminalOutput,
                            pendingCommand: state.terminal.pendingCommand,
                            pendingControlChar: state.terminal.pendingControlChar,
                            isInteractiveMode: state.terminal.isClaudeRunning
                        )

                    case .blocks:
                        // Block-based view of parsed terminal output
                        TerminalBlocksView(
                            blocks: state.terminal.blocks,
                            session: session
                        )
                    }
                } else {
                    // No active session - show empty state
                    EmptySessionView()
                }
            }
        }
        .background(Color.Shebang.bgPrimary)
    }

    // MARK: - Output Handling

    private func handleTerminalOutput(_ data: Data) {
        // Append raw output to terminal state
        state.terminal.appendOutput(data)
    }
}

// MARK: - Terminal Header View

/// Shows current working directory at top of terminal
struct TerminalHeaderView: View {
    let session: Session
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Folder icon
            Image(systemName: "folder.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            // Path breadcrumbs
            pathBreadcrumbs

            Spacer()

            // Session name pill
            Text(session.name)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.Shebang.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.Shebang.bgTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.Shebang.bgSecondary)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.Shebang.bgElevated)
                .frame(height: 1)
        }
    }

    private var pathBreadcrumbs: some View {
        let components = session.workingDirectory.pathComponents.suffix(4)
        let showEllipsis = session.workingDirectory.pathComponents.count > 4

        return HStack(spacing: 4) {
            if showEllipsis {
                Text("...")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }

            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                if component != "/" {
                    if index > 0 || showEllipsis {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    Text(component)
                        .font(.system(size: 12, weight: index == components.count - 1 ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(index == components.count - 1 ? .primary : .secondary)
                }
            }
        }
    }
}

// MARK: - Terminal Blocks View

/// Displays parsed terminal output as structured blocks
struct TerminalBlocksView: View {
    let blocks: [TerminalBlock]
    let session: Session

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if blocks.isEmpty {
                    EmptyBlocksView()
                } else {
                    ForEach(blocks) { block in
                        TerminalBlockRow(block: block)
                    }
                }
            }
            .padding()
        }
        .background(Color.Shebang.bgPrimary)
    }
}

// MARK: - Terminal Block Row

/// Individual block row displaying command, output, or agent response
struct TerminalBlockRow: View {
    let block: TerminalBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Block header with type and timestamp
            HStack {
                Image(systemName: blockIcon)
                    .foregroundColor(blockColor)
                    .frame(width: 16)

                Text(blockTypeLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(blockColor)

                Spacer()

                Text(formatTimestamp(block.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Block content
            Text(block.content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(blockBackgroundColor)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Block Styling

    private var blockIcon: String {
        switch block.type {
        case .command: return "chevron.right"
        case .output: return "text.alignleft"
        case .toolCall: return "wrench.and.screwdriver"
        case .agentResponse: return "sparkles"
        case .error: return "exclamationmark.triangle"
        case .system: return "gearshape"
        }
    }

    private var blockColor: Color {
        switch block.type {
        case .command: return .blue
        case .output: return .primary
        case .toolCall: return .purple
        case .agentResponse: return .green
        case .error: return .red
        case .system: return .orange
        }
    }

    private var blockTypeLabel: String {
        switch block.type {
        case .command: return "Command"
        case .output: return "Output"
        case .toolCall: return "Tool Call"
        case .agentResponse: return "Agent"
        case .error: return "Error"
        case .system: return "System"
        }
    }

    private var blockBackgroundColor: Color {
        switch block.type {
        case .command: return Color.blue.opacity(0.05)
        case .output: return Color.gray.opacity(0.05)
        case .toolCall: return Color.purple.opacity(0.05)
        case .agentResponse: return Color.green.opacity(0.05)
        case .error: return Color.red.opacity(0.08)
        case .system: return Color.orange.opacity(0.05)
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Empty States

/// Shown when no session is active
struct EmptySessionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Active Session")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a new session to get started")
                .font(.body)
                .foregroundColor(.secondary)

            Button("New Session") {
                AppState.shared.sessions.createSession()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Shebang.bgPrimary)
    }
}

/// Shown when block view has no blocks yet
struct EmptyBlocksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No blocks yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Run commands to see structured output")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview("Interactive Mode") {
    TerminalCanvasView()
        .frame(width: 800, height: 600)
        .onAppear {
            AppState.shared.ui.displayMode = .interactive
        }
}

#Preview("Blocks Mode - Empty") {
    TerminalCanvasView()
        .frame(width: 800, height: 600)
        .onAppear {
            AppState.shared.ui.displayMode = .blocks
        }
}

#Preview("Blocks Mode - With Content") {
    TerminalCanvasView()
        .frame(width: 800, height: 600)
        .onAppear {
            AppState.shared.ui.displayMode = .blocks
            AppState.shared.terminal.blocks = [
                TerminalBlock(
                    type: .command,
                    content: "ls -la",
                    timestamp: Date(),
                    isComplete: true
                ),
                TerminalBlock(
                    type: .output,
                    content: "total 64\ndrwxr-xr-x  8 user  staff   256 Dec 21 10:30 .\ndrwxr-xr-x  5 user  staff   160 Dec 20 15:45 ..",
                    timestamp: Date(),
                    isComplete: true
                ),
                TerminalBlock(
                    type: .agentResponse,
                    content: "I can see the directory listing. Would you like me to analyze any specific files?",
                    timestamp: Date(),
                    isComplete: true
                ),
            ]
        }
}
