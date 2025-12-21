---
name: commit-quality
description: Run quality checks and create properly formatted git commits. Use before committing code to ensure quality standards are met and commit messages follow project conventions.
---

# Commit Quality

Ensures code quality before commits and formats commit messages according to project standards.

## When to Use

- Before any git commit
- When user says "commit", "save my work", "push changes"
- After completing a feature or fix

## Pre-Commit Checks

Run these checks before committing:

### Python Files Changed
```bash
./scripts/pre-commit.sh
```

### TypeScript Files Changed
```bash
./scripts/pre-commit-ts.sh
```

### Security Check (Always)
```bash
./scripts/security-sweep.sh
```

## Commit Message Format

```
<type>: <short description>

<detailed description if needed>

Michael O'Neal + Shebang!
```

### Types
- `Add` - New feature or file
- `Fix` - Bug fix
- `Update` - Enhancement to existing feature
- `Remove` - Deleted code or feature
- `Refactor` - Code restructure without behavior change
- `Docs` - Documentation only

## Workflow

1. **Check status** - `git status` to see changes
2. **Run quality checks** - Appropriate pre-commit script
3. **Fix issues** - If checks fail, fix before proceeding
4. **Stage files** - `git add` relevant files
5. **Draft message** - Create commit message following format
6. **Commit** - Create the commit

## Example

```
User: commit my changes

Agent:
1. git status → Shows 3 modified Python files
2. ./scripts/pre-commit.sh → All checks pass
3. ./scripts/security-sweep.sh → No secrets found
4. git add -A
5. Compose message based on changes
6. git commit -m "Add user authentication..."
```

## Important

- Never commit if quality checks fail
- Never commit files containing secrets
- Always include attribution line
- Use present tense in commit messages
