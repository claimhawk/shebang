// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for TerminalBlock struct
final class TerminalBlockTests: XCTestCase {

    // MARK: - Initialization Tests

    func testTerminalBlockCreation() {
        let block = TerminalBlock(
            type: .command,
            content: "ls -la",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertNotNil(block.id)
        XCTAssertEqual(block.type, .command)
        XCTAssertEqual(block.content, "ls -la")
        XCTAssertTrue(block.isComplete)
    }

    // MARK: - Block Type Tests

    func testAllBlockTypes() {
        let types: [TerminalBlock.BlockType] = [
            .command,
            .output,
            .toolCall,
            .agentResponse,
            .error,
            .system
        ]

        for type in types {
            let block = TerminalBlock(
                type: type,
                content: "test",
                timestamp: Date(),
                isComplete: true
            )
            XCTAssertEqual(block.type, type)
        }
    }

    func testBlockTypeRawValues() {
        XCTAssertEqual(TerminalBlock.BlockType.command.rawValue, "command")
        XCTAssertEqual(TerminalBlock.BlockType.output.rawValue, "output")
        XCTAssertEqual(TerminalBlock.BlockType.toolCall.rawValue, "toolCall")
        XCTAssertEqual(TerminalBlock.BlockType.agentResponse.rawValue, "agentResponse")
        XCTAssertEqual(TerminalBlock.BlockType.error.rawValue, "error")
        XCTAssertEqual(TerminalBlock.BlockType.system.rawValue, "system")
    }

    // MARK: - Equatable Tests

    func testTerminalBlockEquality() {
        let date = Date()

        let block1 = TerminalBlock(
            type: .command,
            content: "test",
            timestamp: date,
            isComplete: true
        )

        let block2 = TerminalBlock(
            type: .command,
            content: "test",
            timestamp: date,
            isComplete: true
        )

        // Blocks are equal if all fields match (except id which is unique)
        XCTAssertNotEqual(block1, block2)  // Different IDs
    }

    // MARK: - Identifiable Tests

    func testTerminalBlockHasUniqueID() {
        let block1 = TerminalBlock(
            type: .command,
            content: "test",
            timestamp: Date(),
            isComplete: true
        )

        let block2 = TerminalBlock(
            type: .command,
            content: "test",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertNotEqual(block1.id, block2.id)
    }

    // MARK: - Content Modification Tests

    func testBlockContentCanBeModified() {
        var block = TerminalBlock(
            type: .output,
            content: "initial",
            timestamp: Date(),
            isComplete: false
        )

        block.content = "updated"

        XCTAssertEqual(block.content, "updated")
    }

    func testBlockCompletionCanBeToggled() {
        var block = TerminalBlock(
            type: .output,
            content: "test",
            timestamp: Date(),
            isComplete: false
        )

        block.isComplete = true

        XCTAssertTrue(block.isComplete)
    }

    // MARK: - Use Case Tests

    func testCommandBlock() {
        let block = TerminalBlock(
            type: .command,
            content: "git status",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .command)
        XCTAssertEqual(block.content, "git status")
    }

    func testOutputBlock() {
        let block = TerminalBlock(
            type: .output,
            content: "On branch main\nnothing to commit",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .output)
        XCTAssertTrue(block.content.contains("branch main"))
    }

    func testErrorBlock() {
        let block = TerminalBlock(
            type: .error,
            content: "fatal: not a git repository",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .error)
        XCTAssertTrue(block.content.contains("fatal"))
    }

    func testToolCallBlock() {
        let block = TerminalBlock(
            type: .toolCall,
            content: "Read(/path/to/file.swift)",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .toolCall)
        XCTAssertTrue(block.content.contains("Read"))
    }

    func testAgentResponseBlock() {
        let block = TerminalBlock(
            type: .agentResponse,
            content: "I'll help you with that task.",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .agentResponse)
    }

    func testSystemBlock() {
        let block = TerminalBlock(
            type: .system,
            content: "Session started",
            timestamp: Date(),
            isComplete: true
        )

        XCTAssertEqual(block.type, .system)
    }
}
