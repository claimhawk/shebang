// Copyright 2024 Shebang - Automated Development Environment
// SPDX-License-Identifier: MIT

import Foundation

/// Represents a terminal/agent session
struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var workingDirectory: URL
    var createdAt: Date
    var lastActiveAt: Date
    var status: SessionStatus

    init(
        id: UUID = UUID(),
        name: String = "New Session",
        workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        status: SessionStatus = .active
    ) {
        self.id = id
        self.name = name
        self.workingDirectory = workingDirectory
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.status = status
    }

    /// Update last active timestamp
    mutating func touch() {
        lastActiveAt = Date()
    }
}

// MARK: - Session Status

enum SessionStatus: String, Codable, CaseIterable {
    case active      // Currently running
    case idle        // Running but no recent activity
    case suspended   // Paused/backgrounded
    case terminated  // Ended but preserved for history
}

// MARK: - Session Display

extension Session {
    /// Formatted creation time for display
    var createdAtFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Short directory name for display
    var directoryName: String {
        workingDirectory.lastPathComponent
    }

    /// Status indicator symbol
    var statusSymbol: String {
        switch status {
        case .active: return "circle.fill"
        case .idle: return "circle"
        case .suspended: return "pause.circle"
        case .terminated: return "xmark.circle"
        }
    }
}
