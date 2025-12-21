# Testing Anti-Patterns & Common Mistakes

A comprehensive guide to TDD anti-patterns, test code smells, and testing mistakes that undermine software quality.

---

## Table of Contents

1. [TDD Anti-Patterns](#tdd-anti-patterns)
2. [Test Code Smells](#test-code-smells)
3. [Mocking Anti-Patterns](#mocking-anti-patterns)
4. [Integration vs Unit Test Mistakes](#integration-vs-unit-test-mistakes)
5. [Flaky Tests](#flaky-tests)
6. [Test Maintenance Problems](#test-maintenance-problems)

---

## TDD Anti-Patterns

### The Liar

**Problem:** A test that passes even though the system under test is broken, giving a false sense of security.

**Indicators:**
- Green tests when code is clearly wrong
- Tests that don't actually verify behavior
- Assertions that always pass regardless of code state

**Example:**
```python
def test_user_creation():
    user = create_user("john@example.com")
    # Liar: Always passes, doesn't verify anything
    assert True
```

**Solution:** Ensure tests actually verify expected behavior and use meaningful assertions.

---

### Excessive Setup

**Ranked:** 3rd most popular TDD anti-pattern

**Problem:** Tests require extensive setup with many dependencies, obscuring the testing goal and making tests brittle.

**Indicators:**
- Dozens of lines of setup code
- Multiple class instantiations before testing
- Complex database or filesystem setup
- Difficulty understanding what's being tested

**Example:**
```typescript
test('user can checkout', () => {
    // Excessive setup: 30+ lines
    const database = new TestDatabase();
    const cache = new MockCache();
    const emailService = new MockEmailService();
    const paymentGateway = new MockPaymentGateway();
    const logger = new MockLogger();
    const eventBus = new MockEventBus();
    const userRepo = new UserRepository(database);
    const orderRepo = new OrderRepository(database);
    const cart = new ShoppingCart(cache);
    // ... 20 more lines

    // Actual test is buried
    const result = checkout(user, cart);
    expect(result).toBeTruthy();
});
```

**Solution:** Extract setup to factory methods, use test builders, or reconsider design to reduce dependencies.

---

### The Giant

**Ranked:** 5th most popular TDD anti-pattern

**Problem:** A massive test that tries to verify too much functionality in one test method.

**Indicators:**
- Test methods with 50+ lines
- Multiple unrelated assertions
- Testing entire object lifecycle
- Test name matches class name

**Related:** "The One" - a single test method that tests all functionality of an object.

**Solution:** Break into focused, single-purpose tests following the Single Responsibility Principle.

---

### The Slow Poke

**Problem:** Tests that run so slowly developers have time for coffee breaks or run them overnight.

**Indicators:**
- Individual tests taking seconds or minutes
- Heavy I/O operations (database, filesystem, network)
- Sleep statements with long delays
- Unoptimized test data setup

**Impact:** Destroys TDD red-green-refactor rhythm, discourages running tests frequently.

**Solution:**
- Mock expensive operations
- Use in-memory databases
- Optimize test data creation
- Separate slow integration tests from fast unit tests

---

### The Mockery

**Problem:** So many mocks, stubs, and fakes that you're testing the mocks instead of the system.

**Indicators:**
- More mock setup than actual test code
- Mocking everything including simple data structures
- Tests that pass but production code fails
- Refactoring breaks all tests due to mock coupling

**Solution:** Only mock external dependencies and I/O boundaries. Use real objects for simple collaborators.

---

### The Inspector

**Problem:** Tests that violate encapsulation to achieve 100% code coverage.

**Indicators:**
- Using reflection to access private methods
- `InternalsVisibleTo` or test-only public methods
- Tests that know too much about internal implementation
- Tests break on every refactoring

**Impact:** Creates brittle tests tied to implementation details.

**Solution:** Test behavior through public APIs. If you must test private methods, they might deserve their own class.

---

### The Secret Catcher

**Problem:** Tests that catch and hide exceptions, making failures silent.

**Example:**
```python
def test_user_deletion():
    try:
        delete_user(user_id)
        assert True
    except Exception:
        # Secret Catcher: Swallows real errors
        assert True
```

**Solution:** Let exceptions bubble up or explicitly assert expected exceptions.

---

### The Peeping Tom

**Problem:** Tests that spy on other tests' data due to shared resources.

**Indicators:**
- Tests pass individually but fail in suite
- Test execution order matters
- Shared global state or singletons
- Database records leaking between tests

**Solution:** Proper test isolation, setup/teardown, and avoiding shared mutable state.

---

### The Local Hero

**Problem:** Tests that pass on one machine but fail on others.

**Causes:**
- Hard-coded file paths
- Environment-specific configurations
- Timezone dependencies
- OS-specific behavior

**Solution:** Use relative paths, inject configuration, mock time-dependent code.

---

### The Dodger

**Problem:** Tests that don't actually test anything meaningful, dodging real verification.

**Indicators:**
- Empty test bodies
- Comments like "TODO: implement test"
- Tests that only exercise code without assertions
- Placeholder tests to boost coverage metrics

---

### The Sequencer

**Problem:** Tests that must run in a specific order.

**Impact:** Brittle test suite, hard to debug, prevents parallel execution.

**Solution:** Make each test independent with proper setup/teardown.

---

### Lost in the Details

**Problem:** Focusing on implementation mechanics rather than behavior and intent.

**Indicators:**
- Test names describe "how" not "what"
- Tests change when refactoring identical behavior
- Verifying internal method calls instead of outcomes

**Example:**
```python
# Lost in details
def test_save_calls_database_insert():
    user_repo.save(user)
    assert mock_db.insert.called_once()

# Better: test behavior
def test_saved_user_can_be_retrieved():
    user_repo.save(user)
    retrieved = user_repo.find_by_id(user.id)
    assert retrieved.email == user.email
```

---

### Aimless Tests

**Problem:** Tests that seem random, lacking coherent narrative or structure.

**Indicators:**
- No clear test organization
- Random mix of scenarios
- Missing edge cases while testing trivial ones
- No apparent testing strategy

**Solution:** Use BDD-style naming (Given-When-Then), organize tests by feature/behavior.

---

## Test Code Smells

### Code Smells vs Behavior Smells

**Code Smells:** Anti-patterns visible when reading/writing test code (structure, clarity).

**Behavior Smells:** Issues affecting test execution outcomes (flakiness, false positives).

---

### Inappropriate Intimacy

**Problem:** Tests coupled to internal implementation details.

**Indicators:**
- Testing private methods through reflection
- Using `InternalsVisibleTo`
- Knowledge of internal data structures
- Tests break on refactoring without behavior change

**Impact:** Brittle tests that resist refactoring.

**Solution:** Test through public interfaces (black-box testing). Internal details change more than public APIs.

---

### Fragile Tests (Brittle Tests)

**Problem:** Tests break easily with minor, unrelated code changes.

**Causes:**
- Testing implementation details (white-box testing)
- Over-reliance on mocks
- Tight coupling to DOM structure (UI tests)
- XPath locators in web tests

**Solution:**
- Prefer black-box testing
- Test behavior, not implementation
- Use stable selectors (data attributes, roles)
- Minimize coupling

---

### Obscure Tests

**Problem:** Tests that are hard to understand.

**Indicators:**
- Unclear test names
- Complex setup without explanation
- Magic numbers and strings
- No comments for complex scenarios

**Solution:** Use descriptive names, extract helper methods, add clarifying comments.

---

### Conditional Test Logic

**Problem:** Tests containing if statements, loops, or complex logic.

**Impact:** Tests become harder to debug, may have bugs themselves.

**Solution:** Keep tests simple and linear. Use parameterized tests for variations.

---

### Hard-Coded Test Data

**Problem:** Tests littered with magic numbers and strings.

**Example:**
```typescript
test('user registration', () => {
    const user = register('john@example.com', 'pass123', 25, 'male');
    // What do these values represent? Why these specific values?
});
```

**Solution:** Use named constants, test data builders, or fixtures with clear intent.

---

### Duplicate Test Code

**Problem:** Copy-paste test code across multiple tests.

**Impact:** Changes require updating multiple tests, violating DRY.

**Caveat:** Some duplication is acceptable for test clarity. Balance DRY with readability.

**Solution:** Extract common setup to helper methods, but keep test logic explicit.

---

### Testing the Framework

**Problem:** Tests that verify framework behavior instead of your code.

**Example:**
```python
def test_django_saves_to_database():
    # Don't test Django's ORM
    obj = MyModel(name="test")
    obj.save()
    assert MyModel.objects.count() == 1
```

**Solution:** Trust your framework. Test your business logic.

---

### Who Called Who?

**Problem:** Testing which methods were called and in what order, rather than outcomes.

**Indicators:**
- Excessive use of `verify()` or `assert_called_with()`
- Mocking every collaborator
- Tests that specify exact method call order

**Impact:** Tests don't survive refactoring even when behavior is unchanged.

**Solution:** Focus on observable outcomes and state changes, not method calls.

---

## Mocking Anti-Patterns

### Over-Mocking

**Problem:** Mocking everything, including simple data structures and value objects.

**Indicators:**
- More mock setup than actual test logic
- Mocking POJOs/DTOs
- Every collaborator is a mock
- Tests pass but production code fails

**Impact:**
- False sense of security
- Tests that don't catch real bugs
- Maintenance nightmare

**Example:**
```typescript
// Over-mocking
test('calculate total', () => {
    const mockItem1 = mock<CartItem>();
    when(mockItem1.getPrice()).thenReturn(10);
    const mockItem2 = mock<CartItem>();
    when(mockItem2.getPrice()).thenReturn(20);
    // Just use real CartItem objects!
});
```

**Solution:** Use real objects for simple collaborators. Mock only external dependencies (databases, APIs, file systems).

---

### Testing Mocks Instead of Code

**Problem:** Mocking removes the actual integration you need to test.

**Key Insight:** "The bugs of the IO code you want to test arise from the interaction with the service. If you mock that, you don't test the reason for your bugs."

**Example:**
```python
# Testing the mock, not the integration
def test_api_call():
    mock_api.get.return_value = {"status": "success"}
    result = service.fetch_data()
    assert result["status"] == "success"
    # What if the real API returns different structure?
```

**Solution:** Use integration tests with real services (or test doubles that actually implement the interface).

---

### Leaky Mocks

**Problem:** Mock configuration leaks between tests due to shared state.

**Indicators:**
- Mocks not reset between tests
- Static mock configurations
- Test execution order affects results

**Solution:** Reset mocks in teardown, use fresh mock instances per test.

---

### Mocking Value Objects

**Problem:** Mocking simple data structures that have no behavior.

**Example:**
```java
// Don't mock value objects
Mock<User> mockUser = mock(User.class);
when(mockUser.getName()).thenReturn("John");
// Just use: new User("John")
```

**Solution:** Use real instances of value objects, DTOs, and data classes.

---

### False Positives from Outdated Mocks

**Problem:** Mocks return outdated contracts after dependency updates.

**Example:**
- Method signature changes from returning `null` to returning empty array
- Mock still configured for old contract
- Tests pass, production breaks

**Solution:**
- Keep mocks synchronized with dependencies
- Use contract tests
- Consider integration tests for critical paths

---

### Testing Implementation with Mocks

**Problem:** Mocking forces tests to verify implementation details.

**Impact:** Refactoring requires rewriting all mocks.

**Solution:** If mocking feels painful, it's a design smell. Consider refactoring to separate business logic from I/O.

---

### The Mockist vs Classicist Debate

**Mockist:** Mock all collaborators, test in isolation.

**Classicist:** Use real objects when possible, mock only external dependencies.

**Modern Consensus:** Classicist approach preferred. "Mockists Are Dead. Long Live Classicists."

---

## Integration vs Unit Test Mistakes

### Test Level Confusion

**Problem:** Testing the same condition at multiple levels.

**Impact:** Redundant tests, wasted effort.

**Solution:** Choose the lowest/cheapest test level that can verify the condition.

---

### Wrong Test for the Job

**Unit Test Misuse:**
- Testing integration between multiple systems
- Testing external API interactions
- Testing database queries

**Integration Test Misuse:**
- Testing simple business logic
- Testing edge cases (better in unit tests)
- Testing every permutation (combinatorial explosion)

---

### Mocking in Integration Tests

**Problem:** Using mocks for external resources in integration tests.

**Impact:** Defeats the purpose of integration testing—you're not testing the integration!

**Example:**
```typescript
// This is NOT an integration test
test('user registration integration', () => {
    const mockDatabase = new MockDatabase();
    const mockEmailService = new MockEmailService();
    // You're testing mocks, not integration!
});
```

**Solution:** Use real databases (in-memory or Docker), real services, or contract testing.

---

### Non-Deterministic Unit Tests

**Problem:** Unit tests that fail randomly.

**Causes:**
- Depending on other tests
- External dependencies (network, database)
- Time-based logic without mocking
- Random number generation

**Rule:** A unit test must be deterministic. If it fails, it must continue failing until code changes.

---

### Test Pyramid Violations

**Anti-Pattern:** Inverted pyramid with more E2E tests than unit tests.

**Impact:**
- Slow test suite
- Difficult to debug failures
- High maintenance cost
- Flaky tests

**Solution:** Follow the test pyramid:
- 70% unit tests (fast, focused)
- 20% integration tests (medium speed)
- 10% E2E tests (slow, high-level)

---

### Ignoring Test Costs

**Reality:**
- Unit tests: cheap to write, cheap to maintain, fast execution
- Integration tests: medium cost, medium speed
- E2E tests: expensive to write/maintain, slow execution

**Mistake:** Treating all tests equally without considering cost.

**Solution:** Optimize for the right mix based on cost-benefit analysis.

---

### Difficulty Pinpointing Failures

**Integration Test Problem:** When a test fails, which component is broken?

**Solution:**
- Ensure solid unit test coverage first
- Use clear test names that indicate components involved
- Implement good logging and error messages
- Consider component-level integration tests

---

### Manual Complex Test Execution

**Problem:** Sophisticated integration tests that must be run manually.

**Impact:** Error-prone, slow, inconsistent.

**Solution:** Automate all tests, including integration and E2E.

---

## Flaky Tests

### Definition

**Flaky Test:** A test that produces inconsistent results (pass/fail) without code changes.

**Impact:**
- Destroys trust in test suite
- Delays CI/CD pipelines
- Wastes debugging time
- False positives hide real issues

---

### Causes of Flakiness

#### 1. Timing and Async Issues

**Problem:** Tests use hard-coded sleep statements that are sometimes too short.

**Example:**
```javascript
await clickButton();
await sleep(1000); // Sometimes not enough!
const result = getResult();
```

**Solution:** Use smart waits that poll for conditions:
```javascript
await clickButton();
await waitFor(() => expect(getResult()).toBeDefined(), { timeout: 5000 });
```

---

#### 2. Race Conditions and Concurrency

**Problem:** Tests compete for shared resources when run in parallel.

**Causes:**
- Shared database records
- Shared files
- Global state
- Singleton objects

**Solution:**
- Isolate test data (unique IDs per test)
- Use transaction rollbacks
- Reset global state in setup/teardown

---

#### 3. Test Data Problems

**Problem:** Stale, inconsistent, or shared test data.

**Causes:**
- Not resetting data between tests
- Hardcoded IDs that conflict
- Relying on data from previous tests

**Solution:** Always reset test data to known baseline before each test.

---

#### 4. Environment Instability

**Causes:**
- Network slowness
- Slow servers
- Resource constraints
- Service outages

**Solution:**
- Use local/containerized environments
- Mock unreliable external services
- Implement proper retry logic

---

#### 5. External Dependencies

**Problem:** APIs, databases, and third-party services have variable response times.

**Solution:**
- Mock external services in unit tests
- Use contract tests for integration
- Implement timeout and retry strategies

---

#### 6. Element Locator Issues (UI Tests)

**Problem:** XPath and CSS selectors break when DOM changes.

**Example:**
```javascript
// Fragile
await page.click('/html/body/div[1]/div[2]/button[3]');

// Better
await page.click('[data-testid="submit-button"]');
```

**Solution:**
- Use semantic selectors (roles, labels)
- Add `data-testid` attributes
- Avoid position-based selectors

---

#### 7. Time-Dependent Tests

**Problem:** Tests that depend on current date/time.

**Example:**
```python
def test_subscription_active():
    subscription = Subscription(expires=datetime.now() + timedelta(days=1))
    assert subscription.is_active()  # Fails tomorrow!
```

**Solution:** Mock time or use relative dates in tests.

---

### Solutions and Prevention

#### Test Isolation

**Strategy:** Each test should be completely independent.

**Implementation:**
- Fresh test data per test
- No shared mutable state
- Proper setup and teardown
- Reset singletons and globals

---

#### Smart Waits

**Instead of:**
```python
time.sleep(5)  # Arbitrary wait
```

**Use:**
```python
WebDriverWait(driver, 10).until(
    EC.element_to_be_clickable((By.ID, "submit"))
)
```

---

#### Mocking and Stubbing

**Strategy:** Remove non-deterministic dependencies.

**What to Mock:**
- External APIs
- Current time
- Random number generation
- File system operations
- Network calls

---

#### Proper Retry Strategies

**Anti-Pattern:** Unlimited retries hiding real issues.

**Better Approach:**
- Limit retries (2-3 max)
- Only retry on known transient failures
- Log retry attempts
- Alert on frequent retries

---

#### Detection and Tracking

**Tools:**
- Jenkins flaky test plugins
- GitLab CI/CD flaky test detection
- Pytest flaky plugin
- Custom test run analysis

**Process:**
- Track flaky tests in issue tracker
- Document patterns and resolutions
- Regular flaky test triage meetings

---

#### Quarantine Strategy

**Approach:**
1. Identify flaky tests
2. Move to quarantine suite
3. Don't block CI/CD
4. Fix or delete flaky tests
5. Restore when stable

**Warning:** Quarantine is temporary. Fix or delete, don't ignore.

---

## Test Maintenance Problems

### What is Test Debt?

**Definition:** The extra time needed for testing activities that should have already been completed. A form of technical debt specific to testing.

**Impact:**
- Increased maintenance costs
- Higher bug risk
- Lower team productivity
- Decreased test suite confidence
- Slower development velocity

---

### Common Maintenance Issues

#### Missing Test Documentation

**Problem:** No documentation for test cases, making maintenance difficult.

**Impact:** New team members can't understand test intent, tests are deleted rather than fixed.

**Solution:**
- Clear, descriptive test names
- Comments for complex scenarios
- Documentation of test data requirements
- Diagrams for integration test flows

---

#### Lack of Coding Standards

**Problem:** Tests don't follow consistent coding standards.

**Impact:**
- Harder to read and maintain
- Inconsistent patterns confuse developers
- Higher effort for modifications

**Solution:**
- Apply same standards as production code
- Code review for test code
- Linters and formatters for tests
- Test code style guide

---

#### Broken/Unfixed Tests

**Problem:** Tests that fail but aren't fixed or are skipped.

**Impact:**
- Reduced confidence in test suite
- Decreased quality
- Increased maintenance burden
- "Broken window" effect

**Solution:**
- Fix or delete broken tests immediately
- Never commit failing tests
- "Zero tolerance" policy for broken tests

---

#### Outdated Tests

**Problem:** Tests not updated when functionality changes.

**Example:**
```python
# Old test for removed feature
def test_premium_feature():
    # Feature was removed 6 months ago
    # Test still exists and fails
    pass
```

**Solution:**
- Review tests during feature changes
- Delete tests for removed features
- Update tests as part of feature work

---

#### Maintenance Cost Accumulation

**The Snowball Effect:**
1. Skip test updates "just this once"
2. More tests become outdated
3. Test suite becomes unreliable
4. Developers stop trusting tests
5. Tests become ignored
6. Quality degrades

**Prevention:**
- Treat test code with same care as production code
- Include test updates in definition of done
- Regular test suite health reviews

---

#### Test Automation Technical Debt

**Research Finding:** Test automation commonly encounters problems due to unforeseen maintenance issues.

**Common Issues:**
- Hard-coded values scattered throughout
- Duplicate test setup code
- Tight coupling to UI structure
- No abstraction layers (Page Object Pattern)
- Framework-specific code in tests

**Solution:**
- Refactor test code regularly
- Extract reusable components
- Use design patterns (Page Objects, Builder, Factory)
- Abstract framework details

---

### Managing Test Debt

#### Treat as "Now" Problem

**Strategy:** Address test debt continuously, not "later."

**Tactics:**
- Allocate time in each sprint
- Track test debt in backlog
- Regular refactoring sessions
- "Boy Scout Rule": leave tests better than you found them

---

#### Proper Test Planning

**Include Time For:**
- Test design
- Test execution
- Test documentation
- Regression testing
- Automation creation
- **Automation maintenance** (often forgotten)
- Test closure activities

---

#### Early and Frequent Testing

**Benefit:** Catch issues early, reduce need for quick fixes, minimize technical debt accumulation.

**Practice:**
- Shift-left testing
- TDD/BDD practices
- Continuous testing in CI/CD
- Automated quality gates

---

#### Refactoring Tests

**When to Refactor:**
- Tests become hard to understand
- High duplication
- Brittle tests breaking often
- Slow test execution
- Adding new tests is painful

**Techniques:**
- Extract common setup to fixtures
- Use test data builders
- Apply design patterns
- Consolidate duplicate assertions
- Remove unnecessary tests

---

#### Track Test Suite Health Metrics

**Key Metrics:**
- Test execution time trends
- Flaky test percentage
- Test failure rate
- Code coverage trends
- Test maintenance time
- Test-to-code ratio

**Tools:**
- SonarQube for test metrics
- CI/CD platform analytics
- Test coverage tools (Coverage.py, Istanbul, JaCoCo)
- Custom dashboards

---

## Summary: Key Principles

### Test Quality Principles

1. **Test Behavior, Not Implementation:** Focus on what the code does, not how it does it.

2. **Isolation:** Each test should be independent and not rely on other tests or shared state.

3. **Determinism:** Tests should always produce the same result for the same code.

4. **Clarity:** Tests should be easy to read and understand. They're documentation.

5. **Speed:** Unit tests should run in milliseconds. Slow tests kill productivity.

6. **Maintenance:** Treat test code with the same care as production code.

### Mocking Guidelines

- **Mock external dependencies:** Databases, APIs, file systems, network calls.
- **Don't mock value objects:** Use real instances of simple data structures.
- **Don't over-mock:** More mocks ≠ better tests.
- **Prefer real objects:** Only mock when necessary.
- **Keep mocks synchronized:** Update mocks when dependencies change.

### Test Organization

- **Follow the test pyramid:** Mostly unit tests, some integration, few E2E.
- **Choose the right level:** Test at the lowest level that proves correctness.
- **Separate fast and slow:** Run fast tests frequently, slow tests less often.
- **Organize by behavior:** Group tests by feature/behavior, not by class.

### Flaky Test Strategy

- **Zero tolerance:** Fix or delete, never ignore.
- **Smart waits:** Never use arbitrary sleep statements.
- **Isolate tests:** No shared state or data between tests.
- **Mock time:** Don't depend on current date/time.
- **Track patterns:** Document and learn from flaky test causes.

### Technical Debt Prevention

- **Continuous maintenance:** Refactor tests regularly.
- **Documentation:** Clear test names and comments.
- **Coding standards:** Apply same standards as production code.
- **Fix immediately:** Don't commit broken or failing tests.
- **Include in DoD:** Test updates are part of feature completion.

---

## Resources

### Books
- "Growing Object-Oriented Software, Guided by Tests" by Steve Freeman & Nat Pryce
- "Test Driven Development: By Example" by Kent Beck
- "xUnit Test Patterns" by Gerard Meszaros
- "Working Effectively with Legacy Code" by Michael Feathers

### Online Resources
- [Software Testing Anti-patterns - Codepipes Blog](https://blog.codepipes.com/testing/software-testing-antipatterns.html)
- [TDD Anti-patterns - Codurance](https://www.codurance.com/publications/tdd-anti-patterns-chapter-1)
- [Test Smells Catalog](https://testsmells.org/)
- [Martin Fowler on Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)

### Tools
- **Flaky Test Detection:** Jenkins Flaky Test Plugin, GitLab CI/CD, Pytest-flaky
- **Test Metrics:** SonarQube, Coverage.py, Istanbul, JaCoCo
- **Test Smell Detection:** TestSmellDetector (Java/JUnit)

---

## Contributing

This is a living document. Common testing anti-patterns evolve as languages, frameworks, and best practices change. Please contribute:

- New anti-patterns you've discovered
- Better solutions to existing problems
- Real-world examples
- Tool recommendations

---

**Last Updated:** 2025-12-21

**Sources:**
- [Learn Go with Tests - Anti-patterns](https://quii.gitbook.io/learn-go-with-tests/meta/anti-patterns)
- [TDD Anti-patterns - Codurance Chapter 1](https://www.codurance.com/publications/tdd-anti-patterns-chapter-1)
- [Software Testing Anti-patterns - Codepipes Blog](https://blog.codepipes.com/testing/software-testing-antipatterns.html)
- [TDD Anti-patterns - Marabesi](https://marabesi.com/tdd/tdd-anti-patterns.html)
- [Unit Testing Smells - Cprime](https://www.cprime.com/resources/blog/unit-testing-smells/)
- [Software Unit Test Smells](https://testsmells.org/)
- [Mocking is a Code Smell - Medium](https://medium.com/javascript-scene/mocking-is-a-code-smell-944a70c90a6a)
- [Is Your Test Suite Brittle? Maybe It's Too DRY - InfoQ](https://www.infoq.com/articles/brittle-test-suite-maybe-too-dry/)
- [Mocking is an Anti-Pattern - Amazing CTO](https://www.amazingcto.com/mocking-is-an-antipattern-how-to-test-without-mocking/)
- [Unit Testing Anti-Patterns - Yegor256](https://www.yegor256.com/2018/12/11/unit-testing-anti-patterns.html)
- [Mockists Are Dead. Long Live Classicists - Thoughtworks](https://www.thoughtworks.com/insights/blog/mockists-are-dead-long-live-classicists)
- [Flaky Tests - LambdaTest](https://www.lambdatest.com/learning-hub/flaky-test)
- [Flaky Tests - TestRail](https://www.testrail.com/blog/flaky-tests/)
- [Flaky Tests - Datadog](https://www.datadoghq.com/knowledge-center/flaky-tests/)
- [How to Reduce Flaky Test Failures - CircleCI](https://circleci.com/blog/reducing-flaky-test-failures/)
- [Integration Testing Common Mistakes - TestQuality](https://www.testquality.com/blog/tpost/limrj90n51-failing-at-integration-testing-common-mi)
- [Unit Testing vs Integration Testing - CircleCI](https://circleci.com/blog/unit-testing-vs-integration-testing/)
- [Technical Debt in Testing - Magic Pod](https://blog.magicpod.com/technical-debt-in-testing-understanding-its-cost-and-managing-it)
- [Test Debt Fundamentals - QE Unit](https://qeunit.com/blog/test-debt-fundamentals-what-why-warning-signs/)
