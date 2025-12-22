// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for AttachedImage struct
final class AttachedImageTests: XCTestCase {

    // MARK: - Initialization Tests

    func testAttachedImageCreation() {
        let path = "/Users/test/screenshot.png"
        let image = AttachedImage(path: path)

        XCTAssertNotNil(image.id)
        XCTAssertEqual(image.path, path)
        XCTAssertEqual(image.filename, "screenshot.png")
    }

    func testFilenameExtractedFromPath() {
        let testCases: [(path: String, expected: String)] = [
            ("/Users/test/image.jpg", "image.jpg"),
            ("/tmp/screenshot.png", "screenshot.png"),
            ("/var/www/photo.jpeg", "photo.jpeg"),
            ("~/Desktop/pic.gif", "pic.gif"),
            ("/a/b/c/d/file.webp", "file.webp")
        ]

        for testCase in testCases {
            let image = AttachedImage(path: testCase.path)
            XCTAssertEqual(image.filename, testCase.expected,
                          "Failed for path: \(testCase.path)")
        }
    }

    // MARK: - Identifiable Tests

    func testEachImageHasUniqueID() {
        let image1 = AttachedImage(path: "/tmp/image1.png")
        let image2 = AttachedImage(path: "/tmp/image2.png")

        XCTAssertNotEqual(image1.id, image2.id)
    }

    func testSamePathCreatesUniqueImages() {
        let path = "/tmp/test.png"
        let image1 = AttachedImage(path: path)
        let image2 = AttachedImage(path: path)

        XCTAssertNotEqual(image1.id, image2.id)
    }

    // MARK: - Edge Cases

    func testPathWithoutDirectory() {
        let image = AttachedImage(path: "image.png")

        XCTAssertEqual(image.filename, "image.png")
    }

    func testPathWithTrailingSlash() {
        let image = AttachedImage(path: "/tmp/")

        // lastPathComponent of "/tmp/" returns "tmp"
        XCTAssertEqual(image.filename, "tmp")
    }

    func testPathWithMultipleExtensions() {
        let image = AttachedImage(path: "/tmp/file.tar.gz.png")

        XCTAssertEqual(image.filename, "file.tar.gz.png")
    }

    func testPathWithSpaces() {
        let image = AttachedImage(path: "/Users/test/My Screenshots/image 1.png")

        XCTAssertEqual(image.filename, "image 1.png")
    }

    func testPathWithUnicodeCharacters() {
        let image = AttachedImage(path: "/Users/test/スクリーンショット.png")

        XCTAssertEqual(image.filename, "スクリーンショット.png")
    }
}
