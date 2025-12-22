// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for Session model
final class SessionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultSessionCreation() {
        let session = Session()

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.name, "New Session")
        XCTAssertEqual(session.workingDirectory, FileManager.default.homeDirectoryForCurrentUser)
        XCTAssertEqual(session.status, .active)
        XCTAssertNotNil(session.createdAt)
        XCTAssertNotNil(session.lastActiveAt)
    }

    func testCustomSessionCreation() {
        let customDir = URL(fileURLWithPath: "/tmp")
        let customName = "My Project"
        let customDate = Date(timeIntervalSince1970: 1000000)

        let session = Session(
            name: customName,
            workingDirectory: customDir,
            createdAt: customDate,
            status: .idle
        )

        XCTAssertEqual(session.name, customName)
        XCTAssertEqual(session.workingDirectory, customDir)
        XCTAssertEqual(session.createdAt, customDate)
        XCTAssertEqual(session.status, .idle)
    }

    // MARK: - Touch Method Tests

    func testTouchUpdatesLastActiveTimestamp() {
        var session = Session()
        let originalTimestamp = session.lastActiveAt

        // Wait a small amount to ensure timestamp differs
        Thread.sleep(forTimeInterval: 0.01)

        session.touch()

        XCTAssertNotEqual(session.lastActiveAt, originalTimestamp)
        XCTAssertGreaterThan(session.lastActiveAt, originalTimestamp)
    }

    // MARK: - Computed Properties Tests

    func testDirectoryNameExtractedCorrectly() {
        let testPath = "/Users/test/Documents/Projects"
        let session = Session(workingDirectory: URL(fileURLWithPath: testPath))

        XCTAssertEqual(session.directoryName, "Projects")
    }

    func testStatusSymbolsCorrect() {
        let activeSession = Session(status: .active)
        XCTAssertEqual(activeSession.statusSymbol, "circle.fill")

        let idleSession = Session(status: .idle)
        XCTAssertEqual(idleSession.statusSymbol, "circle")

        let suspendedSession = Session(status: .suspended)
        XCTAssertEqual(suspendedSession.statusSymbol, "pause.circle")

        let terminatedSession = Session(status: .terminated)
        XCTAssertEqual(terminatedSession.statusSymbol, "xmark.circle")
    }

    // MARK: - Codable Tests

    func testSessionEncodingDecoding() throws {
        let originalSession = Session(
            name: "Test Session",
            workingDirectory: URL(fileURLWithPath: "/tmp/test"),
            status: .active
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSession)

        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(decodedSession.id, originalSession.id)
        XCTAssertEqual(decodedSession.name, originalSession.name)
        XCTAssertEqual(decodedSession.workingDirectory, originalSession.workingDirectory)
        XCTAssertEqual(decodedSession.status, originalSession.status)
    }

    // MARK: - Equatable Tests

    func testSessionEquality() {
        let id = UUID()
        let date = Date()

        let session1 = Session(
            id: id,
            name: "Test",
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            createdAt: date,
            lastActiveAt: date,
            status: .active
        )

        let session2 = Session(
            id: id,
            name: "Test",
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            createdAt: date,
            lastActiveAt: date,
            status: .active
        )

        XCTAssertEqual(session1, session2)
    }

    func testSessionInequality() {
        let session1 = Session(name: "Session 1")
        let session2 = Session(name: "Session 2")

        XCTAssertNotEqual(session1, session2)
    }

    // MARK: - SessionStatus Tests

    func testAllSessionStatusCases() {
        let allCases = SessionStatus.allCases

        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.idle))
        XCTAssertTrue(allCases.contains(.suspended))
        XCTAssertTrue(allCases.contains(.terminated))
    }

    func testSessionStatusRawValues() {
        XCTAssertEqual(SessionStatus.active.rawValue, "active")
        XCTAssertEqual(SessionStatus.idle.rawValue, "idle")
        XCTAssertEqual(SessionStatus.suspended.rawValue, "suspended")
        XCTAssertEqual(SessionStatus.terminated.rawValue, "terminated")
    }
}
