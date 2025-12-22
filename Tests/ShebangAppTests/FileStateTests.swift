// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for FileState class
@MainActor
final class FileStateTests: XCTestCase {

    var fileState: FileState!

    override func setUp() async throws {
        fileState = FileState()
    }

    override func tearDown() async throws {
        fileState = nil
    }

    // MARK: - Initialization Tests

    func testInitialStateIsEmpty() {
        XCTAssertEqual(fileState.expandedFolders.count, 0)
        XCTAssertNil(fileState.selectedFile)
        XCTAssertEqual(fileState.fileContents.count, 0)
    }

    // MARK: - Folder Expansion Tests

    func testToggleFolderExpands() {
        let folder = URL(fileURLWithPath: "/tmp/test")

        fileState.toggleFolder(folder)

        XCTAssertTrue(fileState.expandedFolders.contains(folder))
    }

    func testToggleFolderCollapses() {
        let folder = URL(fileURLWithPath: "/tmp/test")

        fileState.toggleFolder(folder)
        fileState.toggleFolder(folder)

        XCTAssertFalse(fileState.expandedFolders.contains(folder))
    }

    func testMultipleFoldersCanBeExpanded() {
        let folder1 = URL(fileURLWithPath: "/tmp/test1")
        let folder2 = URL(fileURLWithPath: "/tmp/test2")

        fileState.toggleFolder(folder1)
        fileState.toggleFolder(folder2)

        XCTAssertEqual(fileState.expandedFolders.count, 2)
        XCTAssertTrue(fileState.expandedFolders.contains(folder1))
        XCTAssertTrue(fileState.expandedFolders.contains(folder2))
    }

    // MARK: - File Selection Tests

    func testSelectFile() {
        let file = URL(fileURLWithPath: "/tmp/test.swift")

        fileState.selectedFile = file

        XCTAssertEqual(fileState.selectedFile, file)
    }

    func testClearFileSelection() {
        fileState.selectedFile = URL(fileURLWithPath: "/tmp/test.swift")
        fileState.selectedFile = nil

        XCTAssertNil(fileState.selectedFile)
    }

    // MARK: - File Content Cache Tests

    func testFileContentCacheStartsEmpty() {
        XCTAssertEqual(fileState.fileContents.count, 0)
    }

    func testFileContentCanBeAdded() {
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        let content = "test content"

        fileState.fileContents[url] = content

        XCTAssertEqual(fileState.fileContents[url], content)
    }

    func testMultipleFileContentsCanBeCached() {
        let url1 = URL(fileURLWithPath: "/tmp/test1.txt")
        let url2 = URL(fileURLWithPath: "/tmp/test2.txt")

        fileState.fileContents[url1] = "content 1"
        fileState.fileContents[url2] = "content 2"

        XCTAssertEqual(fileState.fileContents.count, 2)
        XCTAssertEqual(fileState.fileContents[url1], "content 1")
        XCTAssertEqual(fileState.fileContents[url2], "content 2")
    }
}
