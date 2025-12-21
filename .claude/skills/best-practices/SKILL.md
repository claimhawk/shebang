---
name: best-practices
description: Generate technology-specific best practices and anti-patterns documentation. Use when setting up a new project or when the user asks about coding standards for a specific language or framework.
---

# Best Practices Generator

Creates customized best practices and anti-patterns documentation based on the project's technology stack.

## When to Use

- After `/new` creates a project
- When user asks about best practices for a language
- When detecting a new technology in the project
- When user wants coding standards documented

## Detection

Detect technology from:
- File extensions (`.py`, `.ts`, `.swift`, `.go`, `.rs`)
- Config files (`package.json`, `pyproject.toml`, `Cargo.toml`)
- Framework markers (`next.config.js`, `vite.config.ts`)

## Output Files

Create in `.shebang/` directory:

### best-practices.md
```markdown
# Best Practices: [Technology]

## Code Organization
- [Patterns for this technology]

## Error Handling
- [Error patterns for this language]

## Testing
- [Testing strategies]

## Performance
- [Performance considerations]

## Security
- [Security practices]
```

### anti-patterns.md
```markdown
# Anti-Patterns: [Technology]

## Code Smells
- [Common mistakes]

## Performance Anti-Patterns
- [Things that hurt performance]

## Security Vulnerabilities
- [Common security issues]

## Testing Anti-Patterns
- [Testing mistakes]
```

## Technology-Specific Content

### Python
- Type hints everywhere
- Use dataclasses/Pydantic
- Avoid bare except
- Use context managers
- pytest over unittest

### TypeScript
- Strict mode always
- No `any` types
- Prefer interfaces
- Use discriminated unions
- Proper error boundaries in React

### Swift
- Use optionals properly
- Avoid force unwrapping
- Protocol-oriented design
- Structured concurrency

### Go
- Error handling patterns
- Context propagation
- Interface composition
- Goroutine management

### Rust
- Ownership patterns
- Error handling with Result
- Lifetime management
- Unsafe usage guidelines

## Workflow

1. **Detect tech** - Scan project files
2. **Load base template** - From docs/testing/ if available
3. **Customize** - Add project-specific patterns
4. **Write files** - Create in .shebang/
5. **Report** - Tell user what was created

## Example

```
Agent detects: Python + FastAPI + PostgreSQL

Creates:
- .shebang/best-practices.md (Python/FastAPI patterns)
- .shebang/anti-patterns.md (Common FastAPI mistakes)

Includes:
- Async/await patterns
- Dependency injection
- Database session handling
- Request validation
```
