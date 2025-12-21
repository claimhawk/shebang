// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import SwiftUI

/// File preview panel that displays file contents in a read-only scrollable text view.
/// Uses monospaced font for code files and caches content via AppState.shared.files.
struct FilePreviewView: View {
    // Access global app state (survives hot reload)
    private var state: AppState { AppState.shared }

    let file: URL
    let onClose: () -> Void

    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with file name and close button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(file.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Close preview")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            // Content area
            if isLoading {
                VStack {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let content = state.files.fileContents[file] {
                ScrollView([.horizontal, .vertical]) {
                    Text(content)
                        .font(fontForFile(file))
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(Color(nsColor: .textBackgroundColor))
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Failed to load file")
                        .font(.headline)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadContent()
        }
    }

    // MARK: - Content Loading

    private func loadContent() async {
        await state.files.loadFileContent(file)
        isLoading = false
    }

    // MARK: - File Type Detection

    private func fontForFile(_ url: URL) -> Font {
        let ext = url.pathExtension.lowercased()

        // Code file extensions that benefit from monospaced font
        let codeExtensions: Set<String> = [
            // Programming languages
            "swift", "kt", "java", "c", "cpp", "h", "hpp",
            "py", "rb", "go", "rs", "js", "ts", "jsx", "tsx",
            "php", "cs", "m", "mm", "scala", "clj",
            // Scripting
            "sh", "bash", "zsh", "fish", "ps1",
            // Config and data
            "json", "yaml", "yml", "toml", "xml", "html", "css", "scss",
            "sql", "graphql", "proto",
            // Documentation
            "md", "markdown", "rst", "txt", "log",
            // Build files
            "gradle", "make", "cmake", "dockerfile"
        ]

        if codeExtensions.contains(ext) || url.lastPathComponent.hasPrefix(".") {
            return .system(.body, design: .monospaced)
        }

        return .body
    }
}

// MARK: - Preview

#Preview("Swift File") {
    FilePreviewView(
        file: URL(fileURLWithPath: "/example/MyView.swift"),
        onClose: {}
    )
    .frame(width: 500, height: 600)
}

#Preview("Markdown File") {
    FilePreviewView(
        file: URL(fileURLWithPath: "/example/README.md"),
        onClose: {}
    )
    .frame(width: 500, height: 600)
}
