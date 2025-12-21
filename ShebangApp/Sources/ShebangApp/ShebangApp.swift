// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

@main
struct ShebangApp: App {
    // AppState is a singleton that survives hot reloads
    // Views access it via AppState.shared

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .onAppear {
                    // Load favorites on first launch
                    AppState.shared.ui.loadFavorites()
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1400, height: 900)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    AppState.shared.sessions.createSession()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // View menu - toggle panels
            CommandMenu("Panels") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Toggle Sessions Panel") {
                    NotificationCenter.default.post(name: .toggleSessionsPanel, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button("Toggle Favorites") {
                    withAnimation {
                        AppState.shared.ui.favoritesDrawerOpen.toggle()
                    }
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            // Development menu
            CommandMenu("Development") {
                Button("Hot Reload") {
                    // TODO: Implement hot reload
                    print("Hot reload requested via menu")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Interactive Mode") {
                    AppState.shared.ui.displayMode = .interactive
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Block Mode") {
                    AppState.shared.ui.displayMode = .blocks
                }
                .keyboardShortcut("2", modifiers: .command)
            }

            // Tools menu - background installations
            CommandMenu("Tools") {
                Button("Install Git & Dependencies...") {
                    Task {
                        await ToolsInstaller.installDependencies()
                    }
                }

                Button("Install Claude Code...") {
                    Task {
                        await ToolsInstaller.installClaudeCode()
                    }
                }

                Divider()

                Button("Check Environment...") {
                    Task {
                        await ToolsInstaller.checkEnvironment()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let toggleSessionsPanel = Notification.Name("toggleSessionsPanel")
}
