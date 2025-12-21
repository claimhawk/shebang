# CLAUDE.md — Agent Operating Manual

This is the primary instruction file for AI agents (Claude Code, Gemini CLI, etc.) working in this repository.

**Read this first. Follow it always. The hooks will enforce it.**

---

## Quick Reference

| What | Where |
|------|-------|
| **What to do** | `.claude/context/BEST_PRACTICES.md` |
| **What NOT to do** | `.claude/context/ANTI_PATTERNS.md` |
| **Python standards** | `.claude/context/CODE_QUALITY.md` |
| **Why we build this way** | `PHILOSOPHY.md` |
| **Communication style** | `VOICE.md` |
| **Hook configuration** | `.claude/settings.json` |

---

## The Contract

1. **Write correct code the first time** — Use the wisdom in `.claude/context/`
2. **If you mess up, hooks will block you** — Read the error, fix the issue
3. **Learn from corrections** — Don't repeat the same mistake

The hooks enforce:
- No secrets in code
- No silent exceptions
- No `any` types in TypeScript
- No junk drawer directories (`utils/`, `helpers/`)
- No dangerous shell commands

---

## Before You Code

### 1. Understand the Philosophy
Read `PHILOSOPHY.md`. This isn't just documentation — it's the design contract. Features that don't align with the philosophy won't be accepted.

### 2. Know the Anti-Patterns
Read `.claude/context/ANTI_PATTERNS.md`. 65 years of LISP wisdom distilled. These patterns will get blocked by hooks anyway, so learn them upfront.

### 3. Follow the Standards
Read `.claude/context/CODE_QUALITY.md` for language-specific requirements:
- Python: Type hints, ruff, mypy, max complexity 10
- TypeScript: Strict mode, no `any`, ESLint + Prettier
- Swift: SwiftLint, proper optionals

---

## Development Workflow

### Three-Phase Protocol

```
1. RESEARCH  → .claude/research/<task>.md
   - Gather context, analyze requirements
   - NO CODE in this phase

2. PLANNING  → .claude/plans/<task>.md
   - Define implementation steps
   - NO CODE in this phase

3. IMPLEMENT → .claude/implementation/progress.md
   - Log each action as you work
   - Code happens HERE
```

### Commands

```bash
# Quality checks
./scripts/pre-commit.sh          # Python (staged files)
./scripts/pre-commit.sh --all    # Python (all files)
./scripts/pre-commit-ts.sh       # TypeScript

# Security
./scripts/security-sweep.sh      # Scan for secrets

# Build
./build.sh                       # Build the macOS app

# Docs
./scripts/build-docs.sh          # Build HTML documentation
```

---

## Hook System

### Layer 1: PreToolUse (Preventive)

| Hook | Blocks |
|------|--------|
| `validate_edit.py` | Writes to `.env`, `.git/`, credentials |
| `validate_secrets.py` | API keys, tokens, passwords in code |
| `validate_command.py` | `rm -rf /`, force push, `chmod 777` |
| `validate_quality.py` | Silent exceptions, `any` types, junk drawers |

### Layer 2: PostToolUse (Auto-Fix)

| Hook | Does |
|------|------|
| `post_write.py` | Runs ruff/prettier, adds copyright headers |

### Layer 3: Hookify (Content-Based)

Rules in `.claude/hookify.*.local.md` that scan your output and block on match.

---

## Git Protocol

**Attribution format:** `<dev name> + Shebang`

```bash
# Commit message format
git commit -m "Add feature X

Michael O'Neal + Shebang"

# Or in author field for PRs:
# Author: Michael O'Neal + Shebang
```

This credits both the human developer and the AI-assisted environment that made it possible.

---

## Project Structure

```
Sources/ShebangApp/           # macOS app (Swift/SwiftUI)
├── Models/                   # State management
├── Views/                    # UI components
└── Services/                 # Business logic

scripts/guardrails/           # Hook validators
├── config.yaml               # All patterns centralized
├── validate_*.py             # PreToolUse hooks
└── post_*.py                 # PostToolUse hooks

.claude/                      # Agent configuration
├── settings.json             # Hook config
├── context/                  # Agent reference docs
└── hookify.*.local.md        # Content-based rules

docs/                         # Human documentation
templates/                    # Project templates
```

---

## Metrics

Development metrics are tracked in `BUILD_LOG.md` and `METRICS.md`.

Run `./scripts/generate-metrics.sh` to update charts from git history.

---

## Remember

> The hooks embody 60 years of hard-won wisdom. They're not obstacles — they're guardrails that encode what took decades to learn.
>
> Write code that would make a good ancestor. The future maintainer will thank you.
