// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

/// Main window layout:
/// - Sidebar and Sessions panel RESIZE the terminal (HStack)
/// - File preview and Favorites drawer OVERLAY the terminal (ZStack)
struct MainWindowView: View {
    // Access global app state (survives hot reload)
    private var state: AppState { AppState.shared }

    // Panel dimensions
    private let sidebarWidth: CGFloat = 260
    private let sessionsPanelWidth: CGFloat = 280
    private let filePreviewWidth: CGFloat = 500
    private let favoritesDrawerHeight: CGFloat = 200
    private let commandBarHeight: CGFloat = 90

    var body: some View {
        ZStack {
            // Base layer: HStack layout (panels resize terminal)
            HStack(spacing: 0) {
                // Left sidebar (resizes terminal when open/closed)
                if state.ui.sidebarOpen {
                    SidebarView(onFileSelect: openFilePreview)
                        .frame(width: sidebarWidth)
                        .background(Color(nsColor: .windowBackgroundColor))

                    // Sidebar handle
                    PanelHandle(
                        isOpen: Binding(
                            get: { state.ui.sidebarOpen },
                            set: { state.ui.sidebarOpen = $0 }
                        ),
                        edge: .trailing
                    )
                } else {
                    // Collapsed handle only
                    PanelHandle(
                        isOpen: Binding(
                            get: { state.ui.sidebarOpen },
                            set: { state.ui.sidebarOpen = $0 }
                        ),
                        edge: .trailing
                    )
                }

                // Center: Terminal + Command bar (takes remaining space)
                VStack(spacing: 0) {
                    TerminalCanvasView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Command bar at bottom
                    CommandBarView()
                        .frame(height: commandBarHeight)
                        .background(Color(nsColor: .windowBackgroundColor))
                }

                // Right sessions panel (resizes terminal when open/closed)
                if state.ui.sessionsPanelOpen {
                    // Sessions handle
                    PanelHandle(
                        isOpen: Binding(
                            get: { state.ui.sessionsPanelOpen },
                            set: { state.ui.sessionsPanelOpen = $0 }
                        ),
                        edge: .leading
                    )

                    SessionPanelView()
                        .frame(width: sessionsPanelWidth)
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    // Collapsed handle only
                    PanelHandle(
                        isOpen: Binding(
                            get: { state.ui.sessionsPanelOpen },
                            set: { state.ui.sessionsPanelOpen = $0 }
                        ),
                        edge: .leading
                    )
                }
            }

            // Overlay layer: File preview (slides over terminal)
            if state.ui.filePreviewOpen, let file = state.ui.previewingFile {
                HStack(spacing: 0) {
                    // Position after sidebar
                    if state.ui.sidebarOpen {
                        Spacer()
                            .frame(width: sidebarWidth + 6) // sidebar + handle
                    } else {
                        Spacer()
                            .frame(width: 6) // just handle
                    }

                    FilePreviewView(file: file, onClose: closeFilePreview)
                        .frame(width: filePreviewWidth)
                        .background(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 0)

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }

            // Overlay layer: Favorites drawer (slides up from bottom)
            if state.ui.favoritesDrawerOpen {
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Handle on TOP of drawer
                        HorizontalPanelHandle(isOpen: Binding(
                            get: { state.ui.favoritesDrawerOpen },
                            set: { state.ui.favoritesDrawerOpen = $0 }
                        ))

                        FavoritesDrawerView()
                            .frame(height: favoritesDrawerHeight)
                            .background(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: -5)
                    .padding(.horizontal, 20)

                    // Space for command bar
                    Spacer()
                        .frame(height: commandBarHeight + 10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .animation(.easeInOut(duration: 0.25), value: state.ui.sidebarOpen)
        .animation(.easeInOut(duration: 0.25), value: state.ui.sessionsPanelOpen)
        .animation(.easeInOut(duration: 0.2), value: state.ui.filePreviewOpen)
        .animation(.easeInOut(duration: 0.2), value: state.ui.favoritesDrawerOpen)
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            state.ui.sidebarOpen.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSessionsPanel)) { _ in
            state.ui.sessionsPanelOpen.toggle()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    state.ui.sidebarOpen.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar (Cmd+B)")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()

                // Favorites toggle
                Button {
                    state.ui.favoritesDrawerOpen.toggle()
                } label: {
                    Image(systemName: state.ui.favoritesDrawerOpen ? "star.fill" : "star")
                }
                .help("Toggle Favorites (Cmd+Shift+F)")

                // Display mode toggle
                Picker("Display Mode", selection: Binding(
                    get: { state.ui.displayMode },
                    set: { state.ui.displayMode = $0 }
                )) {
                    Image(systemName: "terminal")
                        .tag(DisplayMode.interactive)
                    Image(systemName: "square.stack.3d.up")
                        .tag(DisplayMode.blocks)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .help("Interactive Terminal / Block View")

                Button {
                    state.ui.sessionsPanelOpen.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help("Toggle Sessions (Cmd+0)")
            }
        }
    }

    // MARK: - File Preview

    private func openFilePreview(_ file: URL) {
        state.ui.previewingFile = file
        state.ui.filePreviewOpen = true
    }

    private func closeFilePreview() {
        state.ui.filePreviewOpen = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            state.ui.previewingFile = nil
        }
    }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable {
    case interactive
    case blocks
}

// MARK: - Vertical Panel Handle

/// Vertical clickable handle for opening/closing side panels
struct PanelHandle: View {
    @Binding var isOpen: Bool
    let edge: Edge

    @State private var isHovered = false

    var body: some View {
        Rectangle()
            .fill(isHovered ? Color.accentColor.opacity(0.4) : Color(nsColor: .separatorColor).opacity(0.3))
            .frame(width: 20)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOpen.toggle()
                }
            }
            .overlay {
                // Grip indicator lines
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isHovered ? Color.accentColor : Color(nsColor: .separatorColor))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .help(isOpen ? "Close panel" : "Open panel")
    }

    enum Edge {
        case leading, trailing
    }
}

// MARK: - Horizontal Panel Handle

/// Horizontal clickable handle for opening/closing top/bottom panels
struct HorizontalPanelHandle: View {
    @Binding var isOpen: Bool

    @State private var isHovered = false

    var body: some View {
        Rectangle()
            .fill(isHovered ? Color.accentColor.opacity(0.4) : Color(nsColor: .separatorColor).opacity(0.3))
            .frame(height: 20)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOpen.toggle()
                }
            }
            .overlay {
                // Grip indicator lines
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isHovered ? Color.accentColor : Color(nsColor: .separatorColor))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .help(isOpen ? "Close drawer" : "Open favorites")
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
        .frame(width: 1400, height: 900)
}
