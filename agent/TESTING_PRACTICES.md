# Testing Best Practices

A comprehensive guide to software testing principles, practices, and patterns drawn from decades of Test-Driven Development (TDD), Behavior-Driven Development (BDD), and software testing wisdom.

---

## Table of Contents

1. [The TDD Cycle](#the-tdd-cycle)
2. [Test Pyramid](#test-pyramid)
3. [FIRST Principles](#first-principles)
4. [Test Naming Conventions](#test-naming-conventions)
5. [Test Structure Patterns](#test-structure-patterns)
6. [Testing Different Code Types](#testing-different-code-types)
7. [Property-Based Testing](#property-based-testing)
8. [Smoke Testing and Sanity Checks](#smoke-testing-and-sanity-checks)
9. [Code Coverage](#code-coverage)
10. [Best Practices Summary](#best-practices-summary)

---

## The TDD Cycle

### Red-Green-Refactor

The TDD cycle is a disciplined approach to writing tests before implementation:

1. **Red** — Write a failing test that defines desired functionality
2. **Green** — Write minimal code to make the test pass
3. **Refactor** — Improve code quality while keeping tests green

### When to Use TDD

**Use TDD when:**
- Building new features with clear requirements
- Fixing bugs (write test that reproduces, then fix)
- Refactoring existing code (tests provide safety net)
- Working on critical business logic
- Learning a new API or framework

**Consider alternatives when:**
- Prototyping or exploring solution space
- Working with legacy code without tests (characterization tests first)
- UI/UX experimentation (design first, test later)
- Performance optimization (profile first, optimize, then test)

### TDD Benefits

- **Design feedback** — Tests reveal API design issues early
- **Regression safety** — Changes don't break existing functionality
- **Living documentation** — Tests show how code should be used
- **Confidence** — Refactor fearlessly with comprehensive test suite

---

## Test Pyramid

The test pyramid describes the ideal distribution of different test types in a healthy test suite.

```
        /\
       /  \
      / E2E \         10% — End-to-End Tests
     /______\
    /        \
   /Integration\     20% — Integration Tests
  /____________\
 /              \
/   Unit Tests   \   70% — Unit Tests
/__________________\
```

### Unit Tests (70%)

**Purpose:** Test individual functions, methods, or classes in isolation

**Characteristics:**
- Fast (milliseconds per test)
- No external dependencies (databases, APIs, file systems)
- Use mocks/stubs for dependencies
- Test single responsibility

**Example:**
```python
def test_calculate_discount():
    """Should apply 10% discount for orders over $100."""
    result = calculate_discount(amount=150.00, threshold=100.00)
    assert result == 135.00
```

### Integration Tests (20%)

**Purpose:** Test interactions between components, modules, or external systems

**Characteristics:**
- Slower (seconds per test)
- Test real integrations (database queries, API calls)
- Verify components work together correctly
- May require test databases or containers

**Example:**
```python
def test_user_repository_saves_to_database():
    """Should persist user to database and retrieve by ID."""
    repo = UserRepository(db_connection)
    user = User(name="Alice", email="alice@example.com")

    saved_id = repo.save(user)
    retrieved = repo.get_by_id(saved_id)

    assert retrieved.name == "Alice"
    assert retrieved.email == "alice@example.com"
```

### End-to-End Tests (10%)

**Purpose:** Test complete user workflows through the entire system

**Characteristics:**
- Slowest (seconds to minutes per test)
- Test from user perspective (UI to database)
- Cover critical business paths only
- Fragile and expensive to maintain

**Example:**
```python
def test_complete_checkout_workflow():
    """Should allow user to add item, checkout, and receive confirmation."""
    browser.navigate_to("/products")
    browser.click("Add to Cart")
    browser.click("Checkout")
    browser.fill_form({"card": "4111111111111111"})
    browser.click("Place Order")

    assert browser.page_contains("Order Confirmed")
```

### Why This Ratio?

- **Speed** — Fast unit tests enable quick feedback loops
- **Reliability** — Unit tests are stable; E2E tests are brittle
- **Maintenance** — Unit tests are easy to update; E2E tests require significant effort
- **Coverage** — Unit tests cover edge cases; E2E tests cover happy paths

---

## FIRST Principles

Good tests follow the FIRST principles:

### Fast

Tests should run quickly to enable rapid feedback.

**Good:**
```python
def test_hash_password():
    """Completes in milliseconds."""
    hashed = hash_password("secret123")
    assert len(hashed) == 64
```

**Bad:**
```python
def test_hash_password():
    """Takes 5 seconds due to excessive iterations."""
    hashed = hash_password_with_10000_rounds("secret123")
    assert len(hashed) == 64
```

### Isolated

Tests should not depend on each other or shared state.

**Good:**
```python
def test_add_item_to_empty_cart():
    cart = ShoppingCart()  # Fresh instance
    cart.add_item("apple")
    assert cart.item_count() == 1

def test_remove_item_from_cart():
    cart = ShoppingCart()  # Independent instance
    cart.add_item("apple")
    cart.remove_item("apple")
    assert cart.item_count() == 0
```

**Bad:**
```python
shared_cart = ShoppingCart()  # Shared state

def test_add_item():
    shared_cart.add_item("apple")
    assert shared_cart.item_count() == 1

def test_add_another_item():
    # Depends on previous test running first!
    shared_cart.add_item("banana")
    assert shared_cart.item_count() == 2
```

### Repeatable

Tests should produce the same results every time.

**Good:**
```python
def test_format_date():
    """Uses fixed date for repeatability."""
    fixed_date = datetime(2024, 1, 15, 10, 30)
    result = format_date(fixed_date)
    assert result == "2024-01-15"
```

**Bad:**
```python
def test_format_date():
    """Uses current time - results change every run."""
    result = format_date(datetime.now())
    assert "2024" in result  # Breaks next year!
```

### Self-Validating

Tests should clearly pass or fail without manual inspection.

**Good:**
```python
def test_user_age_calculation():
    user = User(birth_year=1990)
    assert user.age() == 34
```

**Bad:**
```python
def test_user_age_calculation():
    user = User(birth_year=1990)
    print(f"Age: {user.age()}")  # Requires manual verification
```

### Timely

Tests should be written at the right time.

**TDD approach:** Write tests before implementation
**Bug fix approach:** Write test that reproduces bug, then fix
**Legacy code approach:** Add characterization tests before refactoring

---

## Test Naming Conventions

### Method Name Patterns

Choose a convention and use it consistently:

**Pattern 1: Should/When Style**
```python
def test_should_return_empty_list_when_no_items_found():
def test_should_throw_error_when_user_not_authenticated():
def test_should_calculate_tax_when_amount_exceeds_threshold():
```

**Pattern 2: Given-When-Then Style**
```python
def test_given_empty_cart_when_adding_item_then_count_is_one():
def test_given_invalid_email_when_registering_then_raises_error():
```

**Pattern 3: Descriptive Sentence Style**
```python
def test_calculate_discount_applies_ten_percent_over_hundred():
def test_user_registration_requires_valid_email():
def test_password_must_be_at_least_eight_characters():
```

### Naming Best Practices

1. **Be descriptive** — Name should explain what is being tested
2. **Include context** — Describe the scenario/condition
3. **State expected outcome** — What should happen?
4. **Avoid abbreviations** — Clarity over brevity
5. **Use underscores** — `test_user_login_success` not `testUserLoginSuccess`

### Examples by Language

**Python:**
```python
def test_user_repository_returns_none_when_user_not_found():
def test_order_total_includes_tax_and_shipping():
```

**JavaScript/TypeScript:**
```typescript
describe('UserRepository', () => {
  it('should return null when user not found', () => {});
  it('should throw error when database connection fails', () => {});
});
```

**Java:**
```java
@Test
public void shouldReturnNullWhenUserNotFound() {}

@Test
public void shouldThrowExceptionWhenDatabaseConnectionFails() {}
```

---

## Test Structure Patterns

### Arrange-Act-Assert (AAA)

The AAA pattern structures tests into three clear phases:

```python
def test_withdraw_from_account():
    # Arrange — Set up test data and conditions
    account = BankAccount(balance=100.00)
    withdrawal_amount = 30.00

    # Act — Execute the behavior being tested
    result = account.withdraw(withdrawal_amount)

    # Assert — Verify the outcome
    assert result == True
    assert account.balance == 70.00
```

**Benefits:**
- Clear test structure
- Easy to read and understand
- Separates setup from verification

**When to use:** All unit tests and most integration tests

### Given-When-Then (BDD)

The Given-When-Then pattern describes behavior in business terms:

```gherkin
Scenario: Withdraw money from account with sufficient funds
  Given a bank account with balance of $100
  When the user withdraws $30
  Then the withdrawal should succeed
  And the account balance should be $70
```

**In code:**
```python
def test_withdraw_from_account_with_sufficient_funds():
    # Given a bank account with balance of $100
    account = BankAccount(balance=100.00)

    # When the user withdraws $30
    result = account.withdraw(30.00)

    # Then the withdrawal should succeed
    assert result == True
    # And the account balance should be $70
    assert account.balance == 70.00
```

**Benefits:**
- Focuses on behavior, not implementation
- Non-technical stakeholders can understand
- Documents business requirements

**When to use:** Acceptance tests, behavior specifications, business-critical logic

### Comparison

| Aspect | AAA | Given-When-Then |
|--------|-----|-----------------|
| Focus | Technical correctness | Business behavior |
| Audience | Developers | Developers + stakeholders |
| Verbosity | Concise | More verbose |
| Use case | Unit/integration tests | Acceptance/BDD tests |

---

## Testing Different Code Types

### Testing Pure Functions

Pure functions (same input always produces same output, no side effects) are the easiest to test.

```python
def test_add_numbers():
    """Pure function: deterministic, no side effects."""
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
    assert add(0, 0) == 0
```

**Best practices:**
- Test edge cases (zero, negative, max values)
- Test boundary conditions
- No mocking needed
- Fast and reliable

### Testing Side Effects

Functions with side effects (I/O, state changes, external calls) require different strategies.

**Strategy 1: Dependency Injection**
```python
def test_save_user_to_database():
    """Inject mock database to avoid real I/O."""
    mock_db = Mock(spec=Database)
    service = UserService(database=mock_db)

    service.save_user(User(name="Alice"))

    mock_db.insert.assert_called_once()
```

**Strategy 2: Verify Side Effects**
```python
def test_write_log_file():
    """Verify file was created with correct content."""
    logger = FileLogger("/tmp/test.log")

    logger.write("Error occurred")

    assert os.path.exists("/tmp/test.log")
    with open("/tmp/test.log") as f:
        assert "Error occurred" in f.read()
```

**Strategy 3: Use Test Doubles**
- **Mock** — Verify interactions (method calls)
- **Stub** — Return predefined responses
- **Spy** — Record calls for later verification
- **Fake** — Simplified working implementation

### Testing Stateful Objects

```python
def test_shopping_cart_state_transitions():
    """Test object state changes over multiple operations."""
    cart = ShoppingCart()

    # Initial state
    assert cart.is_empty() == True

    # Add item
    cart.add_item("apple")
    assert cart.is_empty() == False
    assert cart.item_count() == 1

    # Remove item
    cart.remove_item("apple")
    assert cart.is_empty() == True
```

### Testing Asynchronous Code

**Python (async/await):**
```python
@pytest.mark.asyncio
async def test_fetch_user_data():
    """Test async function with pytest-asyncio."""
    service = UserService()
    user = await service.fetch_user(user_id=123)
    assert user.name == "Alice"
```

**JavaScript (Promises):**
```javascript
test('should fetch user data', async () => {
  const service = new UserService();
  const user = await service.fetchUser(123);
  expect(user.name).toBe('Alice');
});
```

### Testing Error Conditions

```python
def test_withdraw_insufficient_funds_raises_error():
    """Verify exceptions are raised correctly."""
    account = BankAccount(balance=10.00)

    with pytest.raises(InsufficientFundsError):
        account.withdraw(50.00)
```

---

## Property-Based Testing

Property-based testing generates random inputs to verify properties that should always hold true.

### Traditional Example-Based Testing

```python
def test_reverse_list():
    assert reverse([1, 2, 3]) == [3, 2, 1]
    assert reverse([]) == []
    assert reverse([1]) == [1]
```

### Property-Based Testing

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_reverse_list_properties(lst):
    """Properties that should hold for ANY list."""
    reversed_list = reverse(lst)

    # Property 1: Reversing twice returns original
    assert reverse(reversed_list) == lst

    # Property 2: Length is preserved
    assert len(reversed_list) == len(lst)

    # Property 3: All elements are present
    assert sorted(reversed_list) == sorted(lst)
```

### When to Use Property-Based Testing

**Good candidates:**
- Mathematical functions (sorting, parsing, encoding)
- Data transformations (serialization, compression)
- Invariants (properties that always hold)
- Roundtrip operations (encode/decode, serialize/deserialize)

**Common properties to test:**
- **Idempotence** — `f(f(x)) == f(x)`
- **Inverse operations** — `decode(encode(x)) == x`
- **Invariants** — `sort(x).length == x.length`
- **Commutativity** — `add(a, b) == add(b, a)`

### Example: Testing JSON Serialization

```python
from hypothesis import given, strategies as st

@given(st.dictionaries(st.text(), st.integers()))
def test_json_roundtrip(data):
    """Any dict should survive JSON encode/decode."""
    serialized = json.dumps(data)
    deserialized = json.loads(serialized)
    assert deserialized == data
```

---

## Smoke Testing and Sanity Checks

### Smoke Tests

**Purpose:** Verify critical functionality works after deployment or build

**Characteristics:**
- Quick (complete in minutes)
- Cover essential features only
- Run before full test suite
- Gate for further testing

**Example:**
```python
def test_smoke_application_starts():
    """Application should start without crashing."""
    app = Application()
    assert app.is_running() == True

def test_smoke_database_connection():
    """Database should be accessible."""
    db = Database()
    assert db.ping() == True

def test_smoke_critical_endpoint():
    """Health check endpoint should respond."""
    response = requests.get("http://localhost/health")
    assert response.status_code == 200
```

### Sanity Checks

**Purpose:** Quick rationality check after minor changes

**Characteristics:**
- Faster than smoke tests
- Narrow focus on changed area
- Verify build isn't fundamentally broken
- Run before committing code

**Example:**
```python
def test_sanity_imports():
    """Core modules should import without errors."""
    import myapp.core
    import myapp.models
    import myapp.services

def test_sanity_config_loads():
    """Configuration file should be valid."""
    config = load_config("config.yaml")
    assert config.get("database_url") is not None
```

### Comparison

| Aspect | Smoke Tests | Sanity Tests |
|--------|-------------|--------------|
| Scope | Critical paths | Recently changed areas |
| Depth | Shallow | Very shallow |
| Goal | Basic functionality | Nothing broken |
| When | After deploy/build | After small change |
| Duration | Minutes | Seconds |

---

## Code Coverage

### What Code Coverage Measures

Code coverage measures which lines/branches of code are executed during tests.

**Types of coverage:**
- **Line coverage** — Percentage of code lines executed
- **Branch coverage** — Percentage of decision branches taken
- **Function coverage** — Percentage of functions called
- **Statement coverage** — Percentage of statements executed

### Example

```python
def calculate_discount(amount, customer_type):
    if amount > 100:
        if customer_type == "premium":
            return amount * 0.8  # 20% discount
        else:
            return amount * 0.9  # 10% discount
    return amount

# Test with 50% branch coverage
def test_premium_discount():
    assert calculate_discount(150, "premium") == 120.0
    # Covers: amount > 100 (True), customer_type == "premium" (True)
    # Misses: amount > 100 (False), customer_type == "premium" (False)
```

### What Coverage Means

**High coverage (80%+) suggests:**
- Most code paths are tested
- Changes are less likely to break things
- Tests exercise the codebase

**BUT coverage does NOT guarantee:**
- Tests are good quality
- Tests verify correct behavior
- Edge cases are covered
- Tests are meaningful

### What Coverage Doesn't Mean

**100% coverage does NOT mean:**
- Code is bug-free
- All scenarios are tested
- Tests are valuable

**Example of useless 100% coverage:**
```python
def add(a, b):
    return a + b

def test_add():
    add(2, 3)  # 100% coverage, but NO assertions!
```

### Good Coverage Targets

| Project Type | Target Coverage |
|--------------|----------------|
| Critical systems (medical, financial) | 90-100% |
| Business applications | 80-90% |
| Web applications | 70-80% |
| Prototypes/experiments | 50-70% |

### Best Practices

1. **Use coverage as a guide, not a goal** — Focus on test quality
2. **Identify untested code** — Coverage shows gaps
3. **Don't chase 100%** — Diminishing returns after 80-90%
4. **Combine with mutation testing** — Verify tests catch bugs
5. **Exclude generated code** — Focus on meaningful coverage

### Tools

- **Python:** `coverage.py`, `pytest-cov`
- **JavaScript:** `Istanbul`, `Jest --coverage`
- **Java:** `JaCoCo`, `Cobertura`
- **Go:** `go test -cover`

---

## Best Practices Summary

### Writing Tests

1. **Follow TDD when appropriate** — Red-Green-Refactor cycle
2. **Maintain the test pyramid** — 70% unit, 20% integration, 10% E2E
3. **Apply FIRST principles** — Fast, Isolated, Repeatable, Self-validating, Timely
4. **Use clear naming** — Tests should document behavior
5. **Structure with AAA** — Arrange, Act, Assert for clarity
6. **Test behavior, not implementation** — Tests should survive refactoring

### Test Quality

7. **One assertion per concept** — Tests should verify one thing
8. **Avoid test interdependence** — Each test runs independently
9. **Keep tests simple** — Test code should be simpler than production code
10. **Use test doubles appropriately** — Mock external dependencies, not domain logic
11. **Test edge cases** — Zero, negative, null, empty, max values
12. **Verify error conditions** — Test failure paths

### Maintenance

13. **Treat tests as first-class code** — Refactor, review, maintain
14. **Delete obsolete tests** — Remove tests for removed features
15. **Keep tests fast** — Slow tests won't be run
16. **Run tests frequently** — Catch bugs early
17. **Fix broken tests immediately** — Don't accumulate test debt
18. **Review coverage trends** — Watch for coverage decreases

### Anti-Patterns to Avoid

- **Testing implementation details** — Tests break on refactoring
- **Excessive mocking** — Tests become brittle
- **Large test fixtures** — Hard to understand what's being tested
- **Shared state between tests** — Tests affect each other
- **Testing framework code** — Don't test libraries you depend on
- **Assertion-free tests** — Tests that don't verify anything
- **Sleeps in tests** — Use proper async handling or mocks

---

## Additional Resources

### Books

- **Test Driven Development: By Example** — Kent Beck
- **Growing Object-Oriented Software, Guided by Tests** — Steve Freeman, Nat Pryce
- **The Art of Unit Testing** — Roy Osherove
- **Working Effectively with Legacy Code** — Michael Feathers
- **Continuous Delivery** — Jez Humble, David Farley

### Frameworks

- **Python:** pytest, unittest, hypothesis
- **JavaScript:** Jest, Mocha, Cypress
- **Java:** JUnit, TestNG, Mockito
- **Go:** testing package, testify
- **Ruby:** RSpec, Minitest

### Concepts to Explore

- **Mutation testing** — Verify tests catch bugs
- **Contract testing** — Test API contracts
- **Characterization testing** — Test legacy code behavior
- **Approval testing** — Compare outputs to approved baselines
- **Fuzz testing** — Random input generation for security

---

**Remember:** The goal of testing is not perfect coverage, but confidence that your software works correctly. Write tests that provide value, catch bugs, and enable fearless refactoring.
