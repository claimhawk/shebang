// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

/// Drawer showing favorited folders, slides up from bottom
struct FavoritesDrawerView: View {
    private var state: AppState { AppState.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Favorites")
                    .font(.headline)
                Spacer()

                Text("Type /favorite to add current folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Favorites grid
            if state.ui.favoriteFolders.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(state.ui.favoriteFolders, id: \.self) { folder in
                            FavoriteCard(folder: folder)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "star")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No favorites yet")
                .foregroundStyle(.secondary)
            Text("Use /favorite to save the current folder")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favorite Card

struct FavoriteCard: View {
    let folder: URL
    private var state: AppState { AppState.shared }

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)

                Spacer()

                // Remove button (on hover)
                if isHovered {
                    Button {
                        state.ui.removeFavorite(folder)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(folder.lastPathComponent)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Text(shortenedPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 160, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            // Navigate to this folder
            if let session = state.sessions.activeSession,
               let index = state.sessions.sessions.firstIndex(where: { $0.id == session.id }) {
                state.sessions.sessions[index].workingDirectory = folder
                state.sessions.saveToDisk()
            }
        }
    }

    private var shortenedPath: String {
        let path = folder.deletingLastPathComponent().path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    FavoritesDrawerView()
        .frame(height: 200)
        .onAppear {
            // Add sample favorites for preview
            AppState.shared.ui.favoriteFolders = [
                URL(fileURLWithPath: "/Users/demo/Projects/ShebangApp"),
                URL(fileURLWithPath: "/Users/demo/Development/MyProject"),
                URL(fileURLWithPath: "/Users/demo/Code/OpenSource")
            ]
        }
}
