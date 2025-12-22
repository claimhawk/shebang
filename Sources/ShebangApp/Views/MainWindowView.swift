// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

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

    var body: some View {
        ZStack {
            // Base layer: HStack layout (panels resize terminal)
            HStack(spacing: 0) {
                // Left sidebar (resizes terminal when open/closed)
                if state.ui.sidebarOpen {
                    SidebarView(onFileSelect: openFilePreview)
                        .frame(width: sidebarWidth)
                        .background(Color.Shebang.bgSecondary)

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

                // Center: Terminal + Favorites + Command bar (takes remaining space)
                VStack(spacing: 0) {
                    // Terminal area with file preview overlay
                    ZStack(alignment: .leading) {
                        TerminalCanvasView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // File preview overlays the terminal (not the whole center column)
                        if state.ui.filePreviewOpen, let file = state.ui.previewingFile {
                            FilePreviewView(file: file, onClose: closeFilePreview)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }

                    // Favorites drawer (above command bar)
                    if state.ui.favoritesDrawerOpen {
                        VStack(spacing: 0) {
                            HorizontalPanelHandle(isOpen: Binding(
                                get: { state.ui.favoritesDrawerOpen },
                                set: { state.ui.favoritesDrawerOpen = $0 }
                            ))
                            FavoritesDrawerView()
                                .frame(height: favoritesDrawerHeight)
                                .background(.ultraThinMaterial)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        // Just the handle when closed
                        HorizontalPanelHandle(isOpen: Binding(
                            get: { state.ui.favoritesDrawerOpen },
                            set: { state.ui.favoritesDrawerOpen = $0 }
                        ))
                    }

                    // Command bar at bottom
                    // Note: Stays visible but disabled during interactive mode
                    CommandBarView()
                        .frame(minHeight: commandBarHeight)
                        .background(Color.Shebang.bgSecondary)
                        .opacity(state.terminal.isClaudeRunning ? 0.5 : 1.0)
                        .allowsHitTesting(!state.terminal.isClaudeRunning)
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
                        .background(Color.Shebang.bgSecondary)
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
        }
        .frame(minWidth: 900, minHeight: 600)
        .animation(.easeInOut(duration: 0.25), value: state.ui.sidebarOpen)
        .animation(.easeInOut(duration: 0.25), value: state.ui.sessionsPanelOpen)
        .animation(.easeInOut(duration: 0.2), value: state.ui.filePreviewOpen)
        .animation(.easeInOut(duration: 0.2), value: state.ui.favoritesDrawerOpen)
        .animation(.easeInOut(duration: 0.25), value: state.terminal.isClaudeRunning)
        .onChange(of: state.ui.sidebarOpen) { _, isOpen in
            // Close file preview when sidebar closes
            if !isOpen {
                state.ui.filePreviewOpen = false
            }
        }
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
            .fill(isHovered ? Color.Shebang.accentPrimary.opacity(0.3) : Color.Shebang.bgElevated)
            .frame(width: 6)
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
                withAnimation(.easeInOut(duration: 0.25)) {
                    isOpen.toggle()
                }
            }
            .overlay {
                Rectangle()
                    .fill(isHovered ? Color.Shebang.accentPrimary : Color.Shebang.bgElevated)
                    .frame(width: 1)
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
            .fill(isHovered ? Color.Shebang.accentPrimary.opacity(0.3) : Color.Shebang.bgElevated)
            .frame(height: 6)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOpen.toggle()
                }
            }
            .overlay {
                Rectangle()
                    .fill(isHovered ? Color.Shebang.accentPrimary : Color.Shebang.bgElevated)
                    .frame(height: 1)
            }
            .help(isOpen ? "Close drawer" : "Open favorites")
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
        .frame(width: 1400, height: 900)
}
