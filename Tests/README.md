# Shebang Tests

Comprehensive unit tests for the Shebang macOS application.

## Running Tests

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test suite
swift test --filter SessionTests
swift test --filter CommandRouterTests
```

## Test Coverage

**Total: 107 tests across 8 test suites**

### Test Suites

| Suite | Tests | Coverage |
|-------|-------|----------|
| **SessionTests** | 10 | Session model, status, serialization |
| **SessionStateTests** | 13 | Session management, creation, deletion |
| **CommandRouterTests** | 20 | Slash commands, shell detection, image paths |
| **TerminalStateTests** | 16 | Terminal I/O, command queuing, control chars |
| **UIStateTests** | 17 | Panel visibility, favorites, command history |
| **FileStateTests** | 9 | File selection, folder expansion, content cache |
| **TerminalBlockTests** | 13 | Terminal block types, parsing, equality |
| **AttachedImageTests** | 9 | Image attachment handling |

## Key Test Areas

### 1. Session Management (SessionTests, SessionStateTests)
- Session creation with default and custom parameters
- Working directory updates (reactive to terminal `cd`)
- Session status lifecycle (active, idle, suspended, terminated)
- Session persistence and serialization
- Active session switching
- Closing sessions and automatic default session creation

### 2. Command Routing (CommandRouterTests)
- **Slash command detection**: `/help`, `/fav`, `/reload`, `/new`, `/ask`, `/claude`
- **Shell command detection**: `ls`, `git`, `npm`, `docker`, etc.
- **Image path detection**: Absolute paths, tilde paths, quoted paths
- **Natural language detection**: Questions and statements for Claude
- **Path normalization**: Handling quotes, newlines, whitespace

### 3. Terminal State (TerminalStateTests)
- Command queuing with automatic newline handling
- Control character sending (Ctrl+C, Ctrl+D, Ctrl+Z)
- Claude Code running state management
- Output buffering and block parsing
- Exit code tracking

### 4. UI State (UIStateTests)
- Panel visibility management (sidebar, sessions, preview, favorites)
- Command history tracking and navigation
- Favorites management (add, remove, deduplication)
- File preview tracking
- Display mode switching

### 5. File State (FileStateTests)
- Folder expansion/collapse
- File selection
- File content caching

### 6. Terminal Blocks (TerminalBlockTests)
- Block types: command, output, toolCall, agentResponse, error, system
- Block equality and identity
- Content modification
- Completion state tracking

### 7. Image Attachments (AttachedImageTests)
- Image path parsing
- Filename extraction from paths
- Unique ID generation
- Edge cases: spaces, unicode, multiple extensions

## Test Patterns

All tests follow XCTest conventions:

```swift
@MainActor  // For Observable classes
final class MyTests: XCTestCase {
    var state: MyState!

    override func setUp() async throws {
        state = MyState()
    }

    override func tearDown() async throws {
        state = nil
    }

    func testFeature() {
        // Given
        let input = "test"

        // When
        let result = state.process(input)

        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

## Continuous Integration

Tests run automatically on:
- Pull requests
- Commits to main branch
- Pre-commit hooks (if configured)

All tests must pass before merging.

## Adding New Tests

1. Create test file in `Tests/ShebangAppTests/`
2. Follow naming convention: `<Feature>Tests.swift`
3. Add copyright header (Public Domain)
4. Import `@testable import ShebangApp`
5. Use descriptive test names: `test<Feature><Scenario>`
6. Run tests to verify: `swift test`

## Test Philosophy

- **Fast**: Unit tests should run in milliseconds
- **Isolated**: Each test is independent
- **Deterministic**: Same input = same output
- **Focused**: One assertion per test when possible
- **Readable**: Test names describe behavior

## Coverage Goals

- All models: 100% coverage
- State management: 100% coverage
- Command parsing: 100% coverage
- View models: 80%+ coverage
- UI views: Tested via integration tests
