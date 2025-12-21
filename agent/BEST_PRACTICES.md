# Best Practices: 30 Years of Engineering Wisdom

This document consolidates hard-won lessons from decades of software engineering, distilled into actionable guardrails for autonomous agents and human developers alike.

**See also:** `ANTI_PATTERNS.md` for the full 14-section guide with LISP-inspired principles.

---

## Philosophy

> "The best code is code that teaches you something every time you read it."

Your job when writing code is to be a **good ancestor**. The future maintainer is probably not you—write code that:
- You could understand after six months away
- A new team member could navigate in a day
- Makes the codebase better, not just bigger

---

## The Three Commandments

1. **Code must be obvious** - Intent should be clear from reading
2. **Architecture must reflect the business domain** - Structure mirrors reality
3. **Every file must have maximal context** - Name, purpose, and place

---

## I. Anti-Patterns to Avoid

### 1. Hidden Mutation

**Bad:**
```python
def process_users(users):
    for user in users:
        user['processed'] = True  # Mutates input!
    return users
```

**Good:**
```python
def process_users(users: list[dict]) -> list[dict]:
    return [
        {**user, 'processed': True}
        for user in users
    ]
```

**Why:** Mutation causes reference aliasing bugs, isn't thread-safe, breaks memoization, and makes debugging painful.

---

### 2. Imperative Collection Processing

**Bad:**
```python
result = []
i = 0
while i < len(products):
    if products[i].get('in_stock'):
        result.append(transform(products[i]))
    i += 1
```

**Good:**
```python
result = [
    transform(product)
    for product in products
    if product.get('in_stock')
]
```

**Why:** Index tracking is error-prone, accumulator mutation obscures intent, nested loops are hard to follow, and the code is 3x longer than necessary.

---

### 3. Hidden Dependencies

**Bad:**
```python
_db_connection = None

def get_user(user_id):
    return _db_connection.query("SELECT * FROM users WHERE id = ?", [user_id])
```

**Good:**
```python
def get_user(db: DatabaseConnection, user_id: str) -> User | None:
    return db.query("SELECT * FROM users WHERE id = ?", [user_id])
```

**Why:** Hidden dependencies are invisible to callers, require complex mocking for tests, can't be reused with different implementations, and create initialization order bugs.

---

### 4. Class for Single Behavior ("Kingdom of Nouns")

**Bad:**
```python
class LengthValidator(ABC):
    def validate(self, value: str) -> bool:
        return self.min <= len(value) <= self.max
```

**Good:**
```python
def length_validator(min_len: int, max_len: int) -> Callable[[str], bool]:
    return lambda value: min_len <= len(value) <= max_len
```

**Why:** Classes add boilerplate, abstract base classes add no value for single behaviors, and composition is easier with functions.

---

### 5. Junk Drawer Directories

**Forbidden:**
- `utils/`, `helpers/`, `common/`, `misc/`, `shared/`
- Generic `index.ts` exports without domain context

**Instead:** Name everything for what it IS:
```
domain/users/services/create-user.service.ts
domain/orders/value-objects/order-total.ts
libs/date/date-range.ts
```

---

### 6. Silent Failures

**Bad:**
```python
try:
    process_data(data)
except Exception:
    pass  # Silently swallow errors
```

**Good:**
```python
try:
    process_data(data)
except DataValidationError as e:
    logger.error("Data validation failed", error=str(e), data_id=data.id)
    raise
```

**Why:** Silent failures hide bugs, make debugging impossible, and violate the principle of failing fast.

---

### 7. Catch-All Exception Handlers

**Bad:**
```python
except Exception as e:
    return None
```

**Good:**
```python
except (ConnectionError, TimeoutError) as e:
    logger.warning("Network error, retrying", error=str(e))
    return retry_with_backoff(operation)
```

**Why:** Catch-all handlers hide programming errors, prevent proper error propagation, and make systems unreliable.

---

## II. Code Quality Standards

### Python Standards

| Metric | Limit |
|--------|-------|
| Cyclomatic complexity | ≤ 10 per function |
| Nesting depth | ≤ 3 levels |
| Function length | ≤ 50-60 lines |
| Parameters | ≤ 5 (excluding self/cls) |
| File length | ~400 lines (soft limit) |

**Required:**
- Type hints on all functions
- Copyright headers on all files
- Pass ruff, mypy, and radon checks

### TypeScript Standards

| Metric | Limit |
|--------|-------|
| Cyclomatic complexity | ≤ 10 per function |
| Max nesting | 3 levels |
| Function length | 50 lines |
| Parameters | 5 (group with objects) |
| File length | ~400 lines |
| JSX nesting | ≤ 4 levels |

**Required:**
- TypeScript strict mode
- No `any` type
- No unchecked type assertions
- ESLint passing

---

## III. Functional Design Principles

### 3.1 Data Transformations Over Imperative Steps

```python
# Prefer functions that:
- Receive all inputs through parameters
- Return new data instead of mutating arguments
- Have outputs that depend only on inputs
```

### 3.2 Side-Effect Boundaries

Centralize side effects in clearly named layers:
- `infrastructure/` or `adapters/` - network, filesystem, databases
- `services/` - orchestrates pure functions + side-effecting adapters

**Rule of thumb:** Most unit tests should not require network, filesystem, or environment variables.

### 3.3 Immutability Bias

- Prefer immutable data structures (tuples, frozensets)
- Avoid in-place mutation unless clearly local and performance-critical
- Shared data should be treated as immutable; copy before modifying

---

## IV. Naming Conventions

### Universal Rules

- Files & folders: **kebab-case**
- Components, classes, types: **PascalCase**
- Functions & variables: **camelCase**
- Constants: **UPPER_SNAKE_CASE**
- No abbreviations for domain names

### Parameterized Filenames

Include domain + responsibility + artifact type:
```
create-user.service.ts
validate-order-total.service.ts
user-email.value-object.ts
date-range.lib.ts
user-avatar.component.tsx
use-order-history.hook.ts
```

### Forbidden Names

- `utils.ts`, `helpers.ts`, `misc.ts`, `common.ts`
- `index.ts` (unless it's a domain public API)
- `component.tsx`, `useData.ts`, `handler.py`

---

## V. Error Handling

### Principles

1. **Fail fast on invalid state** - Validate inputs at boundaries
2. **Prefer explicit exceptions** - With clear, contextual messages
3. **Never silently pass** - At minimum, log with context
4. **Don't use exceptions for control flow** - They're for exceptional cases

### Logging Rules

- Log at appropriate levels (debug, info, warning, error)
- Log structured data, not just free-form strings
- **NEVER log sensitive data** (tokens, passwords, PII)

---

## VI. Security Guardrails

### Protected Files (NEVER modify)

- `.env`, `.env.*` - Environment secrets
- `.git/` - Git internals
- `secrets.yaml`, `credentials.json` - Secret stores
- `*.pem`, `*.key`, `id_rsa`, `id_ed25519` - Private keys
- `.htpasswd`, `shadow` - Password files

### Blocked Commands

- `rm -rf /` or `~` - Recursive deletion of critical paths
- `git push --force` - Data loss risk
- `chmod 777` - World-writable permissions
- `curl | sh` - Piping untrusted code to shell
- `dd if=... of=/dev` - Direct disk writes

### Secret Detection

Patterns that trigger blocking:
- `sk-[a-zA-Z0-9]{48}` - OpenAI API keys
- `ghp_[a-zA-Z0-9]{36}` - GitHub PATs
- `AKIA[0-9A-Z]{16}` - AWS Access Keys
- `-----BEGIN PRIVATE KEY-----` - Private keys
- `mongodb+srv://[^:]+:[^@]+@` - Connection strings with passwords

---

## VII. Architecture Guidelines

### Domain-Driven Structure

```
src/
  app/              # Next.js routing (if applicable)
  domain/           # Core business logic
    users/
      models/
      services/
      repositories/
      value-objects/
    orders/
      ...
  ui/               # Rendering & interaction
    users/
      components/
      hooks/
  infra/            # External system adapters
    db/
    queue/
    cache/
  libs/             # Pure, reusable primitives
    http/
    date/
```

### Principles

1. **Everything lives in a bounded context** (a domain)
2. **Names convey meaning, not placement**
3. **No junk drawers**
4. **Every module declares a single intention**

---

## VIII. Testing Philosophy

- Most unit tests should not require network, filesystem, or env vars
- If a function is hard to test without heavy mocking, it likely mixes concerns
- Test behavior, not implementation
- One assertion per test (logical grouping allowed)

---

## IX. Cultural Rules

- No unreviewed "quick hacks" - if it's worth merging, it's worth doing properly
- Prefer "make it simple first" over "optimize prematurely"
- Code must tell a story
- When in doubt, extract a domain module
- When unsure, choose the simplest pattern possible

---

## X. Pre-Commit Checklist

Before every commit, ensure:

```bash
# Python
./scripts/pre-commit.sh

# TypeScript
npm run lint && npm run type-check
```

Checks include:
1. ✓ Code formatting (ruff format / prettier)
2. ✓ Linting (ruff check / eslint)
3. ✓ Type checking (mypy / tsc)
4. ✓ Copyright headers
5. ✓ Complexity analysis (radon)
6. ✓ No secrets in code

---

## Enforcement

These practices are enforced through:

1. **PreToolUse Hooks** - Block dangerous operations before they happen
2. **PostToolUse Hooks** - Auto-fix formatting and add headers
3. **Hookify Rules** - Content-based pattern blocking
4. **Pre-commit Scripts** - Comprehensive quality checks
5. **Security Sweeps** - Secret detection across the codebase

Violations are blocked at the tool level, not caught after the fact.
