// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for TerminalState class
@MainActor
final class TerminalStateTests: XCTestCase {

    var terminalState: TerminalState!

    override func setUp() async throws {
        terminalState = TerminalState()
    }

    override func tearDown() async throws {
        terminalState = nil
    }

    // MARK: - Initialization Tests

    func testInitialStateIsEmpty() {
        XCTAssertEqual(terminalState.rawOutput.count, 0)
        XCTAssertEqual(terminalState.blocks.count, 0)
        XCTAssertEqual(terminalState.currentCommand, "")
        XCTAssertNil(terminalState.lastExitCode)
        XCTAssertNil(terminalState.pendingCommand)
        XCTAssertNil(terminalState.pendingControlChar)
        XCTAssertFalse(terminalState.isClaudeRunning)
    }

    // MARK: - Send Command Tests

    func testSendCommandSetsupPendingCommand() {
        terminalState.sendCommand("ls -la")

        XCTAssertEqual(terminalState.pendingCommand, "ls -la\n")
    }

    func testSendCommandAddsNewlineIfMissing() {
        terminalState.sendCommand("git status")

        XCTAssertEqual(terminalState.pendingCommand, "git status\n")
    }

    func testSendCommandPreservesExistingNewline() {
        terminalState.sendCommand("echo test\n")

        XCTAssertEqual(terminalState.pendingCommand, "echo test\n")
    }

    // MARK: - Control Character Tests

    func testSendInterruptSetsControlChar() {
        terminalState.sendInterrupt()

        XCTAssertEqual(terminalState.pendingControlChar, 0x03)
        XCTAssertFalse(terminalState.isClaudeRunning)
    }

    func testSendEOFSetsControlChar() {
        terminalState.sendEOF()

        XCTAssertEqual(terminalState.pendingControlChar, 0x04)
        XCTAssertFalse(terminalState.isClaudeRunning)
    }

    func testSendSuspendSetsControlChar() {
        terminalState.sendSuspend()

        XCTAssertEqual(terminalState.pendingControlChar, 0x1A)
    }

    func testSendControlCharacter() {
        terminalState.sendControlCharacter(0x05)

        XCTAssertEqual(terminalState.pendingControlChar, 0x05)
    }

    // MARK: - Claude Running State Tests

    func testInterruptClearsClaudeRunningState() {
        terminalState.isClaudeRunning = true

        terminalState.sendInterrupt()

        XCTAssertFalse(terminalState.isClaudeRunning)
    }

    func testEOFClearsClaudeRunningState() {
        terminalState.isClaudeRunning = true

        terminalState.sendEOF()

        XCTAssertFalse(terminalState.isClaudeRunning)
    }

    // MARK: - Output Management Tests

    func testAppendOutputAddsData() {
        let data = "test output".data(using: .utf8)!

        terminalState.appendOutput(data)

        XCTAssertEqual(terminalState.rawOutput, data)
    }

    func testAppendOutputAccumulatesData() {
        let data1 = "first ".data(using: .utf8)!
        let data2 = "second".data(using: .utf8)!

        terminalState.appendOutput(data1)
        terminalState.appendOutput(data2)

        let expected = "first second".data(using: .utf8)!
        XCTAssertEqual(terminalState.rawOutput, expected)
    }

    func testClearOutputResetsState() {
        let data = "test output".data(using: .utf8)!
        terminalState.appendOutput(data)

        terminalState.clearOutput()

        XCTAssertEqual(terminalState.rawOutput.count, 0)
        XCTAssertEqual(terminalState.blocks.count, 0)
    }

    // MARK: - Current Command Tests

    func testCurrentCommandCanBeSet() {
        terminalState.currentCommand = "test command"

        XCTAssertEqual(terminalState.currentCommand, "test command")
    }

    // MARK: - Exit Code Tests

    func testLastExitCodeCanBeSet() {
        terminalState.lastExitCode = 0

        XCTAssertEqual(terminalState.lastExitCode, 0)
    }

    func testLastExitCodeCanBeNonZero() {
        terminalState.lastExitCode = 127

        XCTAssertEqual(terminalState.lastExitCode, 127)
    }
}
