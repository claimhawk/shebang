// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI
import AppKit

/// Right panel displaying terminal sessions list
struct SessionPanelView: View {
    private let state = AppState.shared
    @State private var isNewButtonHovered = false

    private var activeSessions: [Session] {
        state.sessions.sessions.filter { $0.status == .active || $0.status == .idle }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with new session button
            header

            // Session list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(activeSessions) { session in
                        SessionRowView(
                            session: session,
                            isActive: session.id == state.sessions.activeSessionId,
                            onSelect: {
                                state.sessions.selectSession(session)
                            },
                            onClose: {
                                state.sessions.closeSession(session)
                            }
                        )
                    }
                }
                .padding(12)
            }
        }
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("sessions")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .textCase(.lowercase)
                Text("\(activeSessions.count) active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // New session button
            Button {
                state.sessions.createSession()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("new")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.Shebang.accentPrimary)
            }
            .buttonStyle(.plain)
            .opacity(isNewButtonHovered ? 0.8 : 1.0)
            .onHover { hovering in
                isNewButtonHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .help("New Session")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: Session
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false
    @State private var isCloseHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with pulse for active
            ZStack {
                if session.status == .active {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isActive ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isActive)
                }
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Session name
                Text(session.name)
                    .font(.system(size: 14, weight: isActive ? .semibold : .medium, design: .rounded))
                    .lineLimit(1)

                // Directory path
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)

                    Text(session.directoryName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Close button (visible on hover)
            if isHovering || isActive {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isCloseHovered ? .white : .secondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(isCloseHovered ? Color.red : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(isCloseHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isCloseHovered)
                .onHover { isCloseHovered = $0 }
                .help("Close Session")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .strokeBorder(
                    isActive ? Color.Shebang.accentPrimary : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Styling

    private var backgroundColor: Color {
        if isActive {
            return Color.Shebang.accentPrimary.opacity(0.15)
        } else if isHovering {
            return Color.Shebang.bgTertiary
        } else {
            return Color.Shebang.bgSecondary
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .active:
            return .green
        case .idle:
            return .orange
        case .suspended:
            return .gray
        case .terminated:
            return .red
        }
    }
}

// MARK: - Closed Session Row

struct ClosedSessionRowView: View {
    let session: Session
    let onReopen: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var isDeleteHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Folder icon for closed sessions
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // Project name (directory name)
            Text(session.directoryName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineLimit(1)

            Spacer()

            // Reopen/Delete buttons on hover
            if isHovering {
                HStack(spacing: 4) {
                    // Reopen button
                    Button {
                        onReopen()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.Shebang.accentPrimary)
                    }
                    .buttonStyle(.plain)
                    .help("Reopen Project")

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isDeleteHovered ? .white : .secondary)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(isDeleteHovered ? Color.red : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { isDeleteHovered = $0 }
                    .help("Remove from History")
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovering ? Color.Shebang.bgTertiary : Color.Shebang.bgSecondary.opacity(0.5))
        .contentShape(Rectangle())
        .onTapGesture {
            onReopen()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview("Session Panel") {
    SessionPanelView()
        .frame(width: 280, height: 600)
}

#Preview("Session Row - Active") {
    SessionRowView(
        session: Session(
            name: "Main Session",
            workingDirectory: URL(fileURLWithPath: "/Users/developer/project"),
            status: .active
        ),
        isActive: true,
        onSelect: {},
        onClose: {}
    )
    .padding()
    .frame(width: 280)
}

#Preview("Session Row - Idle") {
    SessionRowView(
        session: Session(
            name: "Background Task",
            workingDirectory: URL(fileURLWithPath: "/Users/developer/background"),
            status: .idle
        ),
        isActive: false,
        onSelect: {},
        onClose: {}
    )
    .padding()
    .frame(width: 280)
}
