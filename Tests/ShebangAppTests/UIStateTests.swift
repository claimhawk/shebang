// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for UIState class
@MainActor
final class UIStateTests: XCTestCase {

    var uiState: UIState!

    override func setUp() async throws {
        uiState = UIState()
    }

    override func tearDown() async throws {
        uiState = nil
    }

    // MARK: - Initialization Tests

    func testInitialPanelVisibility() {
        XCTAssertTrue(uiState.sidebarOpen)
        XCTAssertTrue(uiState.sessionsPanelOpen)
        XCTAssertFalse(uiState.filePreviewOpen)
        XCTAssertFalse(uiState.favoritesDrawerOpen)
    }

    func testInitialCommandState() {
        XCTAssertEqual(uiState.commandInput, "")
        XCTAssertEqual(uiState.commandHistory.count, 0)
        XCTAssertNil(uiState.historyIndex)
    }

    func testInitialFavoritesState() {
        XCTAssertEqual(uiState.favoriteFolders.count, 0)
    }

    // MARK: - Panel Toggle Tests

    func testToggleSidebar() {
        uiState.sidebarOpen = false
        XCTAssertFalse(uiState.sidebarOpen)

        uiState.sidebarOpen = true
        XCTAssertTrue(uiState.sidebarOpen)
    }

    func testToggleSessionsPanel() {
        uiState.sessionsPanelOpen = false
        XCTAssertFalse(uiState.sessionsPanelOpen)
    }

    func testToggleFilePreview() {
        uiState.filePreviewOpen = true
        XCTAssertTrue(uiState.filePreviewOpen)
    }

    func testToggleFavoritesDrawer() {
        uiState.favoritesDrawerOpen = true
        XCTAssertTrue(uiState.favoritesDrawerOpen)
    }

    // MARK: - Command History Tests

    func testCommandHistoryAppend() {
        uiState.commandHistory.append("ls -la")
        uiState.commandHistory.append("git status")

        XCTAssertEqual(uiState.commandHistory.count, 2)
        XCTAssertEqual(uiState.commandHistory[0], "ls -la")
        XCTAssertEqual(uiState.commandHistory[1], "git status")
    }

    func testHistoryIndexTracking() {
        uiState.historyIndex = 5
        XCTAssertEqual(uiState.historyIndex, 5)

        uiState.historyIndex = nil
        XCTAssertNil(uiState.historyIndex)
    }

    // MARK: - Favorites Tests

    func testAddFavorite() {
        let testURL = URL(fileURLWithPath: "/tmp/test")

        uiState.addFavorite(testURL)

        XCTAssertEqual(uiState.favoriteFolders.count, 1)
        XCTAssertEqual(uiState.favoriteFolders[0], testURL)
    }

    func testAddDuplicateFavoriteIgnored() {
        let testURL = URL(fileURLWithPath: "/tmp/test")

        uiState.addFavorite(testURL)
        uiState.addFavorite(testURL)

        XCTAssertEqual(uiState.favoriteFolders.count, 1)
    }

    func testRemoveFavorite() {
        let testURL = URL(fileURLWithPath: "/tmp/test")
        uiState.addFavorite(testURL)

        uiState.removeFavorite(testURL)

        XCTAssertEqual(uiState.favoriteFolders.count, 0)
    }

    func testRemoveNonExistentFavorite() {
        let url1 = URL(fileURLWithPath: "/tmp/test1")
        let url2 = URL(fileURLWithPath: "/tmp/test2")

        uiState.addFavorite(url1)
        uiState.removeFavorite(url2)

        XCTAssertEqual(uiState.favoriteFolders.count, 1)
        XCTAssertEqual(uiState.favoriteFolders[0], url1)
    }

    // MARK: - File Preview Tests

    func testPreviewingFileTracking() {
        let testFile = URL(fileURLWithPath: "/tmp/test.swift")

        uiState.previewingFile = testFile

        XCTAssertEqual(uiState.previewingFile, testFile)
    }

    func testClearPreviewingFile() {
        uiState.previewingFile = URL(fileURLWithPath: "/tmp/test.swift")
        uiState.previewingFile = nil

        XCTAssertNil(uiState.previewingFile)
    }

    // MARK: - Display Mode Tests

    func testDisplayModeDefault() {
        XCTAssertEqual(uiState.displayMode, .interactive)
    }

    func testChangeDisplayMode() {
        uiState.displayMode = .interactive

        XCTAssertEqual(uiState.displayMode, .interactive)
    }
}
