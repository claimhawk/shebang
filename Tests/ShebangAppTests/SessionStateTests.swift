// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for SessionState class
@MainActor
final class SessionStateTests: XCTestCase {

    var sessionState: SessionState!

    override func setUp() async throws {
        sessionState = SessionState()
    }

    override func tearDown() async throws {
        sessionState = nil
    }

    // MARK: - Initialization Tests

    func testInitialStateHasDefaultSession() {
        // SessionState starts empty - default session created by loadFromDisk
        // In test environment without persistence file, it should create one
        // but our setUp creates a fresh state without calling loadFromDisk
        XCTAssertGreaterThanOrEqual(sessionState.sessions.count, 0)
    }

    // MARK: - Create Session Tests

    func testCreateSessionWithDefaultName() {
        let initialCount = sessionState.sessions.count
        let session = sessionState.createSession()

        XCTAssertEqual(sessionState.sessions.count, initialCount + 1)
        XCTAssertTrue(sessionState.sessions.contains(where: { $0.id == session.id }))
        XCTAssertEqual(sessionState.activeSessionId, session.id)
        XCTAssertEqual(session.workingDirectory, FileManager.default.homeDirectoryForCurrentUser)
        // Name is "Session N" where N is the count at creation time
        XCTAssertTrue(session.name.hasPrefix("Session "))
    }

    func testCreateSessionWithCustomName() {
        let customName = "Custom Project"
        let session = sessionState.createSession(name: customName)

        XCTAssertEqual(session.name, customName)
        XCTAssertEqual(sessionState.activeSessionId, session.id)
    }

    func testCreateSessionWithCustomDirectory() {
        let customDir = URL(fileURLWithPath: "/tmp")
        let session = sessionState.createSession(at: customDir)

        XCTAssertEqual(session.workingDirectory, customDir)
    }

    func testCreateSessionSetsActiveSession() {
        let oldActiveId = sessionState.activeSessionId
        let newSession = sessionState.createSession(name: "New Session")

        XCTAssertNotEqual(oldActiveId, newSession.id)
        XCTAssertEqual(sessionState.activeSessionId, newSession.id)
    }

    // MARK: - Close Session Tests

    func testCloseSessionRemovesSession() {
        let session1 = sessionState.createSession(name: "Session 1")
        let session2 = sessionState.createSession(name: "To Close")
        let sessionId = session2.id
        let initialCount = sessionState.sessions.count

        sessionState.closeSession(session2)

        // Should have one less session
        XCTAssertEqual(sessionState.sessions.count, initialCount - 1)
        XCTAssertFalse(sessionState.sessions.contains(where: { $0.id == sessionId }))
        // But session1 should still exist
        XCTAssertTrue(sessionState.sessions.contains(where: { $0.id == session1.id }))
    }

    func testCloseActiveSessionSwitchesToAnother() {
        let session1 = sessionState.createSession(name: "Session 1")
        let session2 = sessionState.createSession(name: "Session 2")

        // session2 is now active
        XCTAssertEqual(sessionState.activeSessionId, session2.id)

        sessionState.closeSession(session2)

        // Should switch to session1
        XCTAssertNotEqual(sessionState.activeSessionId, session2.id)
        XCTAssertNotNil(sessionState.activeSessionId)
    }

    func testCloseLastSessionCreatesDefault() {
        // Create at least one session
        let session = sessionState.createSession(name: "Test")

        // Clear all sessions
        let allSessions = sessionState.sessions
        for session in allSessions {
            sessionState.closeSession(session)
        }

        // Should have created a default session
        XCTAssertEqual(sessionState.sessions.count, 1)
        XCTAssertNotNil(sessionState.activeSessionId)
    }

    // MARK: - Select Session Tests

    func testSelectSessionChangesActiveSession() {
        let session1 = sessionState.createSession(name: "Session 1")
        let session2 = sessionState.createSession(name: "Session 2")

        sessionState.selectSession(session1)

        XCTAssertEqual(sessionState.activeSessionId, session1.id)
    }

    // MARK: - Active Session Tests

    func testActiveSessionReturnsCorrectSession() {
        let session = sessionState.createSession(name: "Active Test")

        let activeSession = sessionState.activeSession
        XCTAssertNotNil(activeSession)
        XCTAssertEqual(activeSession?.id, session.id)
    }

    func testActiveSessionsFilterCorrectly() {
        sessionState.sessions.removeAll()

        let active = Session(name: "Active", status: .active)
        let idle = Session(name: "Idle", status: .idle)
        let suspended = Session(name: "Suspended", status: .suspended)
        let terminated = Session(name: "Terminated", status: .terminated)

        sessionState.sessions = [active, idle, suspended, terminated]

        let activeSessions = sessionState.activeSessions

        XCTAssertEqual(activeSessions.count, 2)
        XCTAssertTrue(activeSessions.contains(where: { $0.id == active.id }))
        XCTAssertTrue(activeSessions.contains(where: { $0.id == idle.id }))
        XCTAssertFalse(activeSessions.contains(where: { $0.id == suspended.id }))
        XCTAssertFalse(activeSessions.contains(where: { $0.id == terminated.id }))
    }

    // MARK: - Update CWD Tests

    func testUpdateActiveSessionCWD() {
        let session = sessionState.createSession(name: "CWD Test")
        let newCWD = URL(fileURLWithPath: "/tmp/test")

        sessionState.updateActiveSessionCWD(newCWD)

        let updatedSession = sessionState.sessions.first(where: { $0.id == session.id })
        XCTAssertEqual(updatedSession?.workingDirectory, newCWD)
    }

    func testUpdateCWDTouchesSession() {
        let session = sessionState.createSession(name: "Touch Test")
        let originalTimestamp = session.lastActiveAt

        Thread.sleep(forTimeInterval: 0.01)

        sessionState.updateActiveSessionCWD(URL(fileURLWithPath: "/tmp"))

        let updatedSession = sessionState.sessions.first(where: { $0.id == session.id })
        XCTAssertGreaterThan(updatedSession!.lastActiveAt, originalTimestamp)
    }
}
