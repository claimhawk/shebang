# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

---

## Project Overview

**Claude Code Guardrails** — Production-grade guardrails for Claude Code projects. This toolkit provides automated enforcement of code quality, secret detection, and best practices through Claude Code's hook system.

## Quick Start

```bash
# Install dependencies
pip install pyyaml ruff mypy radon

# Run quality checks
./scripts/pre-commit.sh

# Security sweep
./scripts/security-sweep.sh
```

## Architecture

```
scripts/guardrails/     # Hook validators (PreToolUse/PostToolUse)
├── config.yaml         # All patterns centralized here
├── utils.py            # Shared utilities
├── validate_edit.py    # Block protected file paths
├── validate_secrets.py # Detect secrets in content
├── validate_command.py # Block dangerous shell commands
├── validate_quality.py # Detect code anti-patterns
└── post_write.py       # Auto-format and add copyright

templates/              # Project templates
├── python/             # Python project setup
├── typescript/         # TypeScript project setup
├── CLAUDE.md           # CLAUDE.md template
└── system.md           # Agent workflow template

.claude/                # Claude configuration
├── settings.json       # Hook configuration
└── hookify.*.local.md  # Content-based blocking rules
```

## Guardrails System

The guardrails use **three layers of defense**:

### Layer 1: PreToolUse Hooks (Preventive)

| Hook | Purpose |
|------|---------|
| `validate_edit.py` | Block writes to `.env`, `.git/`, credentials, keys |
| `validate_secrets.py` | Detect 40+ secret patterns (API keys, tokens, connection strings) |
| `validate_command.py` | Block dangerous commands (`rm -rf /`, force push, `chmod 777`) |
| `validate_quality.py` | Catch anti-patterns (silent exceptions, `any` types, junk drawers) |

### Layer 2: PostToolUse Hooks (Automatic Maintenance)

| Hook | Purpose |
|------|---------|
| `post_write.py` | Auto-format with ruff/prettier, add copyright headers |

### Layer 3: Hookify Rules (Content-Based Blocking)

| Rule | Purpose |
|------|---------|
| `hookify.secrets-detection.local.md` | Block API keys in code |
| `hookify.silent-exceptions.local.md` | Block `except: pass` patterns |
| `hookify.any-type.local.md` | Block TypeScript `any` type |
| `hookify.junk-drawers.local.md` | Block `utils/`, `helpers/` directories |

## Code Quality Standards

### Python Requirements

- Python 3.12+
- Four-space indentation, PEP 8
- All code must pass `ruff check`, `ruff format`, and `mypy`
- Maximum cyclomatic complexity: 10
- Maximum function length: 50-60 lines
- All functions require type hints
- Copyright headers required

### TypeScript Requirements

- TypeScript strict mode
- No `any` types
- ESLint and Prettier passing
- Maximum nesting: 3 levels
- JSX nesting: 4 levels max

## Development Workflow

### Three-Phase Protocol (Recommended)

1. **Research Phase** → `.claude/research/<task>.md`
   - Gather context, analyze requirements
   - No code in this phase

2. **Planning Phase** → `.claude/plans/<task>.md`
   - Define implementation steps
   - No code in this phase

3. **Implementation** → `.claude/implementation/progress.md`
   - Log each action as you work
   - Coding happens here

## Commands

```bash
# Python quality checks (staged files)
./scripts/pre-commit.sh

# Python quality checks (all files)
./scripts/pre-commit.sh --all

# TypeScript quality checks
./scripts/pre-commit-ts.sh

# Security sweep for secrets
./scripts/security-sweep.sh
```

## Configuration

All patterns are centralized in `scripts/guardrails/config.yaml`:

- `protected_paths` — Files that cannot be modified
- `secrets` — Patterns for API keys, tokens, credentials
- `commands` — Dangerous shell commands to block
- `anti_patterns` — Code quality anti-patterns by language
- `junk_drawers` — Forbidden directory names

## Git Commits

**DO NOT CO-AUTHOR COMMITS** — Only use the developer's name when committing. Do not add co-author trailers or attribute commits to AI assistants.
