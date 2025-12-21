# Language-Specific Testing Guide

This document provides comprehensive testing guidance for the primary languages used in Shebang!: Python, Swift/SwiftUI, and TypeScript.

---

## Table of Contents

- [Python Testing with pytest](#python-testing-with-pytest)
- [Swift/SwiftUI Testing with XCTest](#swiftswiftui-testing-with-xctest)
- [TypeScript Testing with Vitest/Jest](#typescript-testing-with-vitestjest)

---

## Python Testing with pytest

### Overview

pytest is the de facto testing framework for Python, offering powerful features like fixtures, parametrization, and plugin architecture. All tests must pass `pytest` before committing.

### Installation

```bash
pip install pytest pytest-asyncio pytest-mock
```

### Basic Test Structure

```python
# test_calculator.py

def add(a: int, b: int) -> int:
    return a + b

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
    assert add(0, 0) == 0
```

### Fixtures and conftest.py

Fixtures provide reusable test setup. The `conftest.py` file automatically makes fixtures available to all tests in its directory and subdirectories.

**conftest.py example:**

```python
# tests/conftest.py
import pytest
from pathlib import Path
from typing import Generator

@pytest.fixture
def temp_directory(tmp_path: Path) -> Path:
    """Provide a temporary directory for tests."""
    return tmp_path

@pytest.fixture
def sample_config() -> dict[str, str]:
    """Provide sample configuration for tests."""
    return {
        "api_key": "test-key-123",
        "base_url": "https://api.example.com",
        "timeout": "30"
    }

@pytest.fixture(scope="session")
def database_connection() -> Generator[Connection, None, None]:
    """Session-scoped fixture for database connection."""
    conn = create_connection("test_db")
    yield conn
    conn.close()

@pytest.fixture(scope="module")
def expensive_resource():
    """Module-scoped fixture runs once per test file."""
    resource = setup_expensive_resource()
    yield resource
    resource.cleanup()
```

**Using fixtures in tests:**

```python
# test_config.py

def test_config_loading(sample_config):
    """Fixtures are injected via function parameters."""
    assert sample_config["api_key"] == "test-key-123"
    assert "base_url" in sample_config

def test_config_validation(sample_config, temp_directory):
    """Multiple fixtures can be combined."""
    config_file = temp_directory / "config.json"
    save_config(config_file, sample_config)
    assert config_file.exists()
```

**Fixture scopes** control lifetime:
- `function` (default): New instance per test
- `class`: Shared across test class methods
- `module`: Shared across test file
- `session`: Shared across entire test session

### Parametrized Tests

Parametrization runs the same test with different inputs, reducing code duplication.

**Basic parametrization:**

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
    (-2, 4),
])
def test_square(input: int, expected: int):
    assert input ** 2 == expected
```

**Multiple parameters:**

```python
@pytest.mark.parametrize("x,y,result", [
    (1, 1, 2),
    (2, 3, 5),
    (10, -5, 5),
])
def test_addition(x: int, y: int, result: int):
    assert x + y == result
```

**Parametrizing fixtures:**

```python
@pytest.fixture(params=["chrome", "firefox", "safari"])
def browser(request):
    """Run tests with multiple browsers."""
    driver = create_driver(request.param)
    yield driver
    driver.quit()

def test_login(browser):
    """This test runs 3 times (once per browser)."""
    browser.get("https://example.com/login")
    assert browser.title == "Login"
```

**Named parameters for clarity:**

```python
@pytest.mark.parametrize("input,expected", [
    pytest.param(2, 4, id="positive"),
    pytest.param(-2, 4, id="negative"),
    pytest.param(0, 0, id="zero"),
])
def test_square_with_names(input: int, expected: int):
    assert input ** 2 == expected
```

### Mocking with unittest.mock

Mocking isolates units under test from external dependencies.

**Basic mocking with pytest-mock:**

```python
# service.py
import requests

def fetch_user(user_id: int) -> dict[str, str]:
    response = requests.get(f"https://api.example.com/users/{user_id}")
    response.raise_for_status()
    return response.json()

# test_service.py
def test_fetch_user(mocker):
    """Use mocker fixture from pytest-mock."""
    mock_get = mocker.patch("requests.get")
    mock_get.return_value.json.return_value = {"id": 1, "name": "Alice"}
    mock_get.return_value.status_code = 200

    result = fetch_user(1)

    assert result["name"] == "Alice"
    mock_get.assert_called_once_with("https://api.example.com/users/1")
```

**Using autospec for type safety:**

```python
from unittest.mock import create_autospec

# database.py
class DatabaseClient:
    def query(self, sql: str, params: tuple) -> list[dict]:
        pass

# test_database.py
def test_query_execution():
    """autospec ensures mock respects original signature."""
    mock_db = create_autospec(DatabaseClient, instance=True)
    mock_db.query.return_value = [{"id": 1, "name": "Alice"}]

    result = mock_db.query("SELECT * FROM users", ())
    assert len(result) == 1

    # This would raise TypeError due to autospec:
    # mock_db.query("wrong", "signature", "too many args")
```

**Patching in the correct namespace:**

```python
# utils.py
import os

def get_temp_dir() -> str:
    return os.path.expanduser("~/.temp")

# test_utils.py - WRONG
def test_get_temp_dir_wrong(mocker):
    """This won't work - patching where defined, not used."""
    mocker.patch("os.path.expanduser", return_value="/mock/temp")
    assert get_temp_dir() == "/mock/temp"  # FAILS

# test_utils.py - CORRECT
def test_get_temp_dir_correct(mocker):
    """Patch where the name is looked up."""
    mocker.patch("utils.os.path.expanduser", return_value="/mock/temp")
    assert get_temp_dir() == "/mock/temp"  # PASSES
```

**Using side_effect for complex behaviors:**

```python
def test_retry_logic(mocker):
    """side_effect can simulate failures then success."""
    mock_api = mocker.patch("service.api_call")
    mock_api.side_effect = [
        Exception("Network error"),  # First call fails
        Exception("Timeout"),         # Second call fails
        {"status": "success"}         # Third call succeeds
    ]

    result = retry_api_call(max_attempts=3)
    assert result["status"] == "success"
    assert mock_api.call_count == 3
```

**Mock vs Spy:**

```python
def test_with_mock(mocker):
    """Mock replaces the entire function."""
    mock_log = mocker.patch("logging.info")
    process_data([1, 2, 3])
    mock_log.assert_called()

def test_with_spy(mocker):
    """Spy wraps the real function, allowing observation."""
    spy_log = mocker.spy(logging, "info")
    process_data([1, 2, 3])  # Real logging still happens
    assert spy_log.call_count == 3
```

### Async Testing

pytest-asyncio enables testing async/await code.

```python
import pytest
import asyncio
from typing import AsyncIterator

# service.py
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

# test_service.py
@pytest.mark.asyncio
async def test_fetch_data(mocker):
    """Async tests are marked with @pytest.mark.asyncio."""
    mock_session = mocker.AsyncMock()
    mock_response = mocker.AsyncMock()
    mock_response.json.return_value = {"key": "value"}

    mock_session.get.return_value.__aenter__.return_value = mock_response
    mocker.patch("aiohttp.ClientSession", return_value=mock_session)

    result = await fetch_data("https://api.example.com/data")
    assert result["key"] == "value"
```

**Async fixtures:**

```python
@pytest.fixture
async def async_database() -> AsyncIterator[AsyncDatabase]:
    """Async fixture with setup and teardown."""
    db = await AsyncDatabase.connect("test_db")
    yield db
    await db.disconnect()

@pytest.mark.asyncio
async def test_database_query(async_database):
    result = await async_database.query("SELECT 1")
    assert result == [{"value": 1}]
```

**Testing concurrent operations:**

```python
@pytest.mark.asyncio
async def test_concurrent_requests():
    """Test multiple async operations."""
    urls = [
        "https://api.example.com/1",
        "https://api.example.com/2",
        "https://api.example.com/3"
    ]

    results = await asyncio.gather(*[fetch_data(url) for url in urls])
    assert len(results) == 3
    assert all(isinstance(r, dict) for r in results)
```

### Best Practices

1. **Use `autospec=True`** to ensure mocks respect original signatures
2. **Patch in the namespace where objects are used**, not where they're defined
3. **Prefer pytest-mock** over raw unittest.mock for cleaner fixture-based mocking
4. **Use parametrization** to reduce test duplication and improve readability
5. **Keep fixtures in conftest.py** for reusability across test files
6. **Scope fixtures appropriately** to balance performance and isolation
7. **Avoid over-mocking** - integration tests are still crucial
8. **Use dependency injection** to make code more testable
9. **Name parametrized tests** with `id=` for clear test output

### Resources

- [pytest fixtures documentation](https://docs.pytest.org/en/stable/how-to/fixtures.html)
- [pytest parametrization guide](https://docs.pytest.org/en/stable/how-to/parametrize.html)
- [pytest-mock tutorial](https://www.datacamp.com/tutorial/pytest-mock)
- [Common mocking problems and solutions](https://pytest-with-eric.com/mocking/pytest-common-mocking-problems/)

---

## Swift/SwiftUI Testing with XCTest

### Overview

XCTest is Apple's built-in testing framework for Swift and SwiftUI. With Swift 6+, XCTest has native support for async/await, making asynchronous testing seamless.

### Installation

XCTest is included with Xcode. For additional SwiftUI testing capabilities:

```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0")
]
```

### Basic Test Structure

```swift
import XCTest
@testable import MyApp

final class CalculatorTests: XCTestCase {
    func testAddition() {
        let result = Calculator.add(2, 3)
        XCTAssertEqual(result, 5)
    }

    func testDivisionByZero() {
        XCTAssertThrowsError(try Calculator.divide(10, 0)) { error in
            XCTAssertEqual(error as? CalculatorError, .divisionByZero)
        }
    }
}
```

### Testing SwiftUI Views

**Approach 1: Extract logic to ViewModels (Recommended)**

```swift
// LoginViewModel.swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func login() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.login(username: username, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// LoginViewModelTests.swift
@MainActor
final class LoginViewModelTests: XCTestCase {
    var sut: LoginViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = LoginViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    func testSuccessfulLogin() async {
        // Given
        sut.username = "alice@example.com"
        sut.password = "password123"
        mockAuthService.loginResult = .success(())

        // When
        await sut.login()

        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(mockAuthService.loginCalled)
    }

    func testFailedLogin() async {
        // Given
        sut.username = "alice@example.com"
        sut.password = "wrongpassword"
        mockAuthService.loginResult = .failure(AuthError.invalidCredentials)

        // When
        await sut.login()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }
}
```

**Approach 2: ViewInspector for view hierarchy testing**

```swift
import XCTest
import SwiftUI
import ViewInspector
@testable import MyApp

final class ContentViewTests: XCTestCase {
    func testButtonExists() throws {
        let view = ContentView()
        let button = try view.inspect().find(button: "Submit")
        XCTAssertNotNil(button)
    }

    func testTextContent() throws {
        let view = WelcomeView(username: "Alice")
        let text = try view.inspect().find(text: "Welcome, Alice!")
        XCTAssertNotNil(text)
    }

    func testButtonAction() throws {
        var actionCalled = false
        let view = Button("Tap Me") {
            actionCalled = true
        }

        try view.inspect().button().tap()
        XCTAssertTrue(actionCalled)
    }
}
```

**Testing state-dependent views with ViewInspector:**

```swift
// ContentView.swift
struct ContentView: View {
    @State private var counter = 0
    internal let inspection = Inspection<Self>()

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") {
                counter += 1
            }
        }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
}

// ContentViewTests.swift
final class ContentViewTests: XCTestCase {
    func testCounterIncrement() async throws {
        let view = ContentView()
        let exp = view.inspection.inspect { view in
            try view.find(button: "Increment").tap()
            let text = try view.find(text: "Count: 1")
            XCTAssertNotNil(text)
        }

        ViewHosting.host(view: view)
        await fulfillment(of: [exp], timeout: 1.0)
    }
}
```

### Testing Async/Await Code

Swift 6+ and XCTest provide native async/await support - no expectations or callbacks needed.

**Simple async test:**

```swift
func testAsyncDataFetch() async throws {
    let service = DataService()
    let data = try await service.fetchData(for: "test-id")

    XCTAssertEqual(data.id, "test-id")
    XCTAssertFalse(data.items.isEmpty)
}
```

**Testing error handling:**

```swift
func testAsyncErrorHandling() async {
    let service = DataService()

    do {
        _ = try await service.fetchData(for: "invalid-id")
        XCTFail("Expected error to be thrown")
    } catch {
        XCTAssertEqual(error as? DataServiceError, .notFound)
    }
}
```

**Testing concurrent operations:**

```swift
func testConcurrentFetches() async throws {
    let service = DataService()

    async let fetch1 = service.fetchData(for: "id-1")
    async let fetch2 = service.fetchData(for: "id-2")
    async let fetch3 = service.fetchData(for: "id-3")

    let results = try await [fetch1, fetch2, fetch3]

    XCTAssertEqual(results.count, 3)
    XCTAssertEqual(results[0].id, "id-1")
    XCTAssertEqual(results[1].id, "id-2")
    XCTAssertEqual(results[2].id, "id-3")
}
```

**Testing actors:**

```swift
actor DataCache {
    private var cache: [String: Data] = [:]

    func store(_ data: Data, for key: String) {
        cache[key] = data
    }

    func retrieve(for key: String) -> Data? {
        cache[key]
    }
}

final class DataCacheTests: XCTestCase {
    func testConcurrentAccess() async {
        let cache = DataCache()
        let testData = Data([1, 2, 3])

        await cache.store(testData, for: "key1")
        let retrieved = await cache.retrieve(for: "key1")

        XCTAssertEqual(retrieved, testData)
    }
}
```

### UI Testing vs Unit Testing

**Unit testing** (XCTest):
- Fast execution
- Tests business logic in isolation
- Uses mocks and stubs
- No UI rendering

**UI testing** (XCUITest):
- Tests user interactions end-to-end
- Slower execution
- Runs in separate process
- Tests actual UI rendering

```swift
// UI Test Example
final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLoginFlow() {
        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.exists)
        usernameField.tap()
        usernameField.typeText("alice@example.com")

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText("password123")

        let loginButton = app.buttons["loginButton"]
        loginButton.tap()

        let welcomeText = app.staticTexts["Welcome, Alice!"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
    }
}
```

### Mocking and Dependency Injection

**Protocol-based mocking:**

```swift
protocol AuthServiceProtocol {
    func login(username: String, password: String) async throws
    func logout() async throws
}

final class MockAuthService: AuthServiceProtocol {
    var loginCalled = false
    var logoutCalled = false
    var loginResult: Result<Void, Error> = .success(())

    func login(username: String, password: String) async throws {
        loginCalled = true
        try loginResult.get()
    }

    func logout() async throws {
        logoutCalled = true
    }
}
```

**Dependency injection in views:**

```swift
struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(authService: AuthServiceProtocol = AuthService()) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(authService: authService))
    }

    var body: some View {
        // View implementation
    }
}

// In tests:
let mockService = MockAuthService()
let view = ContentView(authService: mockService)
```

### Best Practices

1. **Mark async tests with `async` and `throws`** - no need for expectations
2. **Disable animations during tests** with `UIView.setAnimationsEnabled(false)`
3. **Extract view logic to ViewModels** for easier testing
4. **Use protocol-based dependency injection** for mockability
5. **Prefer unit tests over UI tests** for speed and reliability
6. **Use ViewInspector cautiously** - it's powerful but can be fragile
7. **Test edge cases** including timeouts and errors
8. **Use accessibility identifiers** for UI testing targets
9. **Consider snapshot testing** for visual regression testing

### Resources

- [Unit testing async/await code](https://www.avanderlee.com/concurrency/unit-testing-async-await/)
- [Testing SwiftUI views with XCTest](https://medium.com/@thakurneeshu280/testing-swiftui-views-with-xctest-the-definitive-guide-dbc78596fc65)
- [ViewInspector GitHub repository](https://github.com/nalexn/ViewInspector)
- [Writing testable SwiftUI code](https://www.swiftbysundell.com/articles/writing-testable-code-when-using-swiftui/)

---

## TypeScript Testing with Vitest/Jest

### Overview

Vitest is the modern, faster alternative to Jest with native TypeScript and ESM support. Choose Vitest for new projects using Vite, or Jest for React Native and legacy codebases.

### Installation

**Vitest:**

```bash
npm install -D vitest @vitest/ui
```

**Jest:**

```bash
npm install -D jest @types/jest ts-jest
```

### Basic Test Structure

```typescript
// calculator.ts
export function add(a: number, b: number): number {
    return a + b;
}

export function divide(a: number, b: number): number {
    if (b === 0) throw new Error("Division by zero");
    return a / b;
}

// calculator.test.ts
import { describe, it, expect } from 'vitest';
import { add, divide } from './calculator';

describe('Calculator', () => {
    it('adds two numbers', () => {
        expect(add(2, 3)).toBe(5);
        expect(add(-1, 1)).toBe(0);
    });

    it('throws error on division by zero', () => {
        expect(() => divide(10, 0)).toThrow('Division by zero');
    });
});
```

### Testing React Components

**Using Vitest with React Testing Library:**

```bash
npm install -D @testing-library/react @testing-library/user-event @testing-library/jest-dom
```

```typescript
// LoginForm.tsx
import { useState } from 'react';

interface LoginFormProps {
    onSubmit: (username: string, password: string) => Promise<void>;
}

export function LoginForm({ onSubmit }: LoginFormProps) {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        setError(null);

        try {
            await onSubmit(username, password);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Unknown error');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            <input
                type="text"
                placeholder="Username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                data-testid="username-input"
            />
            <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                data-testid="password-input"
            />
            <button type="submit" disabled={isLoading}>
                {isLoading ? 'Loading...' : 'Login'}
            </button>
            {error && <div role="alert">{error}</div>}
        </form>
    );
}

// LoginForm.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
    it('renders form fields', () => {
        const mockSubmit = vi.fn();
        render(<LoginForm onSubmit={mockSubmit} />);

        expect(screen.getByPlaceholderText('Username')).toBeInTheDocument();
        expect(screen.getByPlaceholderText('Password')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
    });

    it('calls onSubmit with username and password', async () => {
        const user = userEvent.setup();
        const mockSubmit = vi.fn().mockResolvedValue(undefined);
        render(<LoginForm onSubmit={mockSubmit} />);

        await user.type(screen.getByTestId('username-input'), 'alice');
        await user.type(screen.getByTestId('password-input'), 'password123');
        await user.click(screen.getByRole('button', { name: /login/i }));

        await waitFor(() => {
            expect(mockSubmit).toHaveBeenCalledWith('alice', 'password123');
        });
    });

    it('displays error message on failure', async () => {
        const user = userEvent.setup();
        const mockSubmit = vi.fn().mockRejectedValue(new Error('Invalid credentials'));
        render(<LoginForm onSubmit={mockSubmit} />);

        await user.type(screen.getByTestId('username-input'), 'alice');
        await user.type(screen.getByTestId('password-input'), 'wrong');
        await user.click(screen.getByRole('button', { name: /login/i }));

        expect(await screen.findByRole('alert')).toHaveTextContent('Invalid credentials');
    });

    it('disables button during submission', async () => {
        const user = userEvent.setup();
        const mockSubmit = vi.fn(() => new Promise(resolve => setTimeout(resolve, 100)));
        render(<LoginForm onSubmit={mockSubmit} />);

        const button = screen.getByRole('button', { name: /login/i });
        await user.click(button);

        expect(button).toBeDisabled();
        expect(button).toHaveTextContent('Loading...');
    });
});
```

### Mocking Modules

**Vitest module mocking:**

```typescript
// api.ts
export async function fetchUser(id: string): Promise<User> {
    const response = await fetch(`https://api.example.com/users/${id}`);
    if (!response.ok) throw new Error('Failed to fetch user');
    return response.json();
}

// userService.ts
import { fetchUser } from './api';

export async function getUserName(id: string): Promise<string> {
    const user = await fetchUser(id);
    return user.name;
}

// userService.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getUserName } from './userService';
import * as api from './api';

vi.mock('./api');

describe('userService', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('returns user name', async () => {
        vi.mocked(api.fetchUser).mockResolvedValue({
            id: '123',
            name: 'Alice',
            email: 'alice@example.com'
        });

        const name = await getUserName('123');

        expect(name).toBe('Alice');
        expect(api.fetchUser).toHaveBeenCalledWith('123');
    });

    it('handles errors', async () => {
        vi.mocked(api.fetchUser).mockRejectedValue(new Error('Network error'));

        await expect(getUserName('123')).rejects.toThrow('Network error');
    });
});
```

**Partial module mocking with importActual:**

```typescript
import { describe, it, expect, vi } from 'vitest';

vi.mock('./utils', async (importActual) => {
    const actual = await importActual<typeof import('./utils')>();
    return {
        ...actual,
        dangerousFunction: vi.fn(() => 'mocked'),
    };
});

import { dangerousFunction, safeFunction } from './utils';

describe('Partial mock', () => {
    it('mocks dangerous function but keeps safe function real', () => {
        expect(dangerousFunction()).toBe('mocked');
        expect(safeFunction()).toBe('real implementation');
    });
});
```

**Mocking with spies:**

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Spy example', () => {
    it('spies on console.log', () => {
        const spy = vi.spyOn(console, 'log');

        console.log('test message');

        expect(spy).toHaveBeenCalledWith('test message');
        spy.mockRestore();
    });

    it('spies on object methods', () => {
        const calculator = {
            add: (a: number, b: number) => a + b,
        };

        const spy = vi.spyOn(calculator, 'add');

        calculator.add(2, 3);

        expect(spy).toHaveBeenCalledWith(2, 3);
        expect(spy).toHaveReturnedWith(5);
    });
});
```

### Type-Safe Testing

**Using vitest-mock-extended for complete type safety:**

```bash
npm install -D vitest-mock-extended
```

```typescript
import { describe, it, expect } from 'vitest';
import { mock, mockDeep } from 'vitest-mock-extended';

interface Database {
    query<T>(sql: string, params: unknown[]): Promise<T[]>;
    execute(sql: string): Promise<void>;
}

describe('Type-safe mocking', () => {
    it('creates fully typed mock', async () => {
        const mockDb = mock<Database>();
        mockDb.query.mockResolvedValue([{ id: 1, name: 'Alice' }]);

        const result = await mockDb.query('SELECT * FROM users', []);

        expect(result).toHaveLength(1);
        expect(result[0]).toEqual({ id: 1, name: 'Alice' });
    });

    it('creates deep mock for nested objects', () => {
        interface UserService {
            database: Database;
            cache: {
                get(key: string): string | null;
                set(key: string, value: string): void;
            };
        }

        const mockService = mockDeep<UserService>();
        mockService.cache.get.mockReturnValue('cached-value');

        expect(mockService.cache.get('key')).toBe('cached-value');
    });
});
```

### Testing Async Code

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Async tests', () => {
    it('waits for promise to resolve', async () => {
        const result = await Promise.resolve(42);
        expect(result).toBe(42);
    });

    it('tests async/await functions', async () => {
        async function fetchData(): Promise<string> {
            return new Promise(resolve => {
                setTimeout(() => resolve('data'), 100);
            });
        }

        const data = await fetchData();
        expect(data).toBe('data');
    });

    it('tests rejected promises', async () => {
        async function failingFunction(): Promise<void> {
            throw new Error('Failed');
        }

        await expect(failingFunction()).rejects.toThrow('Failed');
    });

    it('uses fake timers for time-based code', async () => {
        vi.useFakeTimers();

        const callback = vi.fn();
        setTimeout(callback, 1000);

        vi.advanceTimersByTime(1000);

        expect(callback).toHaveBeenCalled();

        vi.useRealTimers();
    });
});
```

### Setup and Teardown

```typescript
import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from 'vitest';

describe('Lifecycle hooks', () => {
    beforeAll(() => {
        // Runs once before all tests in this describe block
        console.log('Setting up test suite');
    });

    afterAll(() => {
        // Runs once after all tests in this describe block
        console.log('Tearing down test suite');
    });

    beforeEach(() => {
        // Runs before each test
        console.log('Setting up test');
    });

    afterEach(() => {
        // Runs after each test
        console.log('Cleaning up test');
    });

    it('first test', () => {
        expect(true).toBe(true);
    });

    it('second test', () => {
        expect(1 + 1).toBe(2);
    });
});
```

### Configuration

**vitest.config.ts:**

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [react()],
    test: {
        globals: true,
        environment: 'jsdom',
        setupFiles: './src/test/setup.ts',
        coverage: {
            provider: 'v8',
            reporter: ['text', 'json', 'html'],
            exclude: [
                'node_modules/',
                'src/test/',
            ],
        },
    },
});
```

**setup.ts:**

```typescript
import { expect, afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import * as matchers from '@testing-library/jest-dom/matchers';

expect.extend(matchers);

afterEach(() => {
    cleanup();
});
```

### Best Practices

1. **Choose Vitest for new projects** using Vite for faster execution and native TypeScript support
2. **Use Jest for React Native** or legacy codebases with extensive Jest infrastructure
3. **Focus on user interactions** - test what users see and do, not implementation details
4. **Mock external dependencies** to isolate units under test
5. **Use `data-testid` sparingly** - prefer accessible queries (role, label, text)
6. **Handle async operations** with async/await, not callbacks
7. **Test edge cases** including errors, loading states, and empty states
8. **Use vitest-mock-extended** for complete TypeScript type safety in mocks
9. **Clear mocks between tests** with `beforeEach(() => vi.clearAllMocks())`
10. **Prefer `vi.spyOn` for integration tests** to verify interactions without breaking real behavior

### Vitest vs Jest Comparison

| Feature | Vitest | Jest |
|---------|--------|------|
| TypeScript | Native support | Requires ts-jest |
| ESM | Native support | Experimental |
| Speed (watch mode) | 10-20x faster | Slower |
| Memory usage | Lower (~800MB) | Higher (~1.2GB) |
| React Native | Not supported | Full support |
| API compatibility | 95% Jest-compatible | N/A |
| Browser testing | Stable in v4+ | Limited |
| Setup complexity | Minimal | Requires babel/ts-jest |

### Resources

- [Vitest official guide](https://vitest.dev/guide/)
- [Vitest vs Jest comparison](https://www.speakeasy.com/blog/vitest-vs-jest)
- [React component testing best practices](https://www.codingeasypeasy.com/blog/react-component-testing-best-practices-with-vitest-and-jest-2025-guide)
- [Mocking modules in Vitest](https://www.bitovi.com/blog/more-mocks-mocking-modules-in-vitest)
- [vitest-mock-extended package](https://www.npmjs.com/package/vitest-mock-extended)

---

## Summary

This guide covers testing fundamentals for the three primary languages in Shebang!:

**Python (pytest):**
- Fixture-based test organization with conftest.py
- Parametrization for reducing test duplication
- Type-safe mocking with autospec
- Native async/await testing support

**Swift/SwiftUI (XCTest):**
- ViewModel extraction for testable business logic
- ViewInspector for view hierarchy inspection
- Native async/await support in Swift 6+
- Protocol-based dependency injection for mocking

**TypeScript (Vitest/Jest):**
- Vitest for modern projects, Jest for React Native
- React Testing Library for component testing
- Type-safe mocking with vitest-mock-extended
- Fast execution with HMR and native ESM support

All testing approaches emphasize isolation, type safety, and testing user-facing behavior over implementation details.
