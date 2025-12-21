// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

/// Right panel displaying session list with controls
struct SessionPanelView: View {
    private let state = AppState.shared
    @State private var isNewButtonHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with new session button
            header

            // Session list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(state.sessions.sessions) { session in
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
            // Vibe check header
            VStack(alignment: .leading, spacing: 2) {
                Text("sessions")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .textCase(.lowercase)
                Text("\(state.sessions.sessions.count) active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // New session button - pill style
            Button {
                state.sessions.createSession()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("new")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentColor)
                )
                .shadow(color: Color.accentColor.opacity(isNewButtonHovered ? 0.5 : 0.3), radius: isNewButtonHovered ? 8 : 4)
            }
            .buttonStyle(.plain)
            .scaleEffect(isNewButtonHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isNewButtonHovered)
            .onHover { isNewButtonHovered = $0 }
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: isActive ? Color.accentColor.opacity(0.2) : .clear, radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isActive ? Color.accentColor.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
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
            return Color.accentColor.opacity(0.12)
        } else if isHovering {
            return Color.primary.opacity(0.06)
        } else {
            return Color(nsColor: .windowBackgroundColor).opacity(0.5)
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
