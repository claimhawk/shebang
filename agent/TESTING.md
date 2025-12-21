# Testing — The Non-Negotiable

**No code ships without tests. Period.**

This is not optional. This is not "if we have time." Tests are part of the definition of done.

---

## The Rule

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   If you write code, you write tests.                    ║
║   If you can't test it, you can't ship it.               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## Quick Reference

| Topic | Document |
|-------|----------|
| **What NOT to do** | `TESTING_ANTIPATTERNS.md` |
| **Best practices** | `TESTING_PRACTICES.md` |
| **Language-specific** | `TESTING_BY_LANGUAGE.md` |

---

## The TDD Cycle

```
   ┌─────────────────┐
   │                 │
   │   1. RED        │  Write a failing test
   │                 │
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │                 │
   │   2. GREEN      │  Write minimal code to pass
   │                 │
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐
   │                 │
   │   3. REFACTOR   │  Clean up, tests still pass
   │                 │
   └────────┬────────┘
            │
            └──────────► Back to RED
```

---

## The Test Pyramid

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E╲        Few, slow, expensive
                 ╱──────╲
                ╱        ╲
               ╱Integration╲    Some, medium speed
              ╱────────────╲
             ╱              ╲
            ╱   Unit Tests   ╲  Many, fast, cheap
           ╱──────────────────╲
```

**Ratios:**
- 70% Unit tests
- 20% Integration tests
- 10% E2E tests

---

## What Makes a Good Test (FIRST)

| Principle | Meaning |
|-----------|---------|
| **F**ast | Milliseconds, not seconds |
| **I**solated | No dependencies between tests |
| **R**epeatable | Same result every time |
| **S**elf-validating | Pass or fail, no manual checking |
| **T**imely | Written before or with the code |

---

## Test Structure (AAA)

```python
def test_user_can_login():
    # Arrange - Set up the test data
    user = create_user(email="test@example.com", password="secure123")

    # Act - Perform the action
    result = login(email="test@example.com", password="secure123")

    # Assert - Verify the outcome
    assert result.success is True
    assert result.user.id == user.id
```

---

## Naming Convention

**Pattern:** `test_<what>_<condition>_<expected>`

```python
# Good
def test_login_with_valid_credentials_returns_user():
def test_login_with_invalid_password_raises_error():
def test_cart_with_items_calculates_total():

# Bad
def test_login():
def test1():
def test_it_works():
```

---

## What to Test

### Always Test
- Business logic / domain rules
- Edge cases (empty, null, max values)
- Error conditions
- State transitions
- Public APIs

### Don't Test
- Framework code (React, SwiftUI, Django)
- Third-party libraries
- Private implementation details
- Trivial getters/setters

---

## Coverage Guidelines

| Coverage | Meaning |
|----------|---------|
| < 50% | Unacceptable |
| 50-70% | Minimum viable |
| 70-85% | Good |
| 85-95% | Excellent |
| 100% | Suspicious (probably testing wrong things) |

**Remember:** Coverage measures lines executed, not correctness. High coverage with bad tests is worse than moderate coverage with good tests.

---

## Before You Commit

```bash
# Run tests
pytest                    # Python
swift test               # Swift
npm test                 # TypeScript/JavaScript

# Check coverage
pytest --cov             # Python
swift test --enable-code-coverage  # Swift
npm test -- --coverage   # TypeScript
```

---

## The Testing Mindset

> "Tests are not about finding bugs. Tests are about preventing bugs."

Tests are:
- **Documentation** — They show how code should be used
- **Safety net** — They catch regressions
- **Design feedback** — Hard to test = bad design
- **Confidence** — Ship without fear

---

## See Also

- `TESTING_ANTIPATTERNS.md` — Common mistakes to avoid
- `TESTING_PRACTICES.md` — Deep dive on best practices
- `TESTING_BY_LANGUAGE.md` — Python, Swift, TypeScript specifics

---

*Tests are not overhead. Tests are the only way to ship with confidence.*
