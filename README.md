# Claude Autonomous Code Starter Kit

A comprehensive starter kit for building projects with Claude Code that enforces **30 years of software engineering best practices** through automated guardrails.

## Features

- **Multi-Layer Guardrails** - PreToolUse/PostToolUse hooks + Hookify rules
- **Code Quality Enforcement** - Python and TypeScript anti-pattern detection
- **Secret Protection** - 50+ secret patterns detected and blocked
- **Anti-Pattern Detection** - Prevents silent exceptions, `any` types, junk drawer dirs
- **Three-Phase Protocol** - Research → Plan → Implement workflow
- **Auto-Formatting** - Ruff (Python) and Prettier (TypeScript) on save
- **Inter-Agent Communication** - File-based messaging between autonomous agents

## Quick Start

### 1. Copy the starter kit to your project

```bash
cp -r projects/claude-autonomous-code-starter/* /path/to/your/project/
```

### 2. Install dependencies

For Python projects:
```bash
pip install pyyaml ruff mypy radon pytest
```

For TypeScript projects:
```bash
npm install
```

### 3. Set up git hooks (optional)

```bash
chmod +x scripts/pre-commit.sh
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
```

### 4. Create your COPYRIGHT.txt

```bash
cat > COPYRIGHT.txt << 'EOF'
# Copyright (c) 2025 Your Name. All rights reserved.
EOF
```

## Directory Structure

```
your-project/
├── .claude/
│   ├── settings.json          # Claude hooks configuration
│   ├── commands/              # Custom slash commands
│   ├── communication/         # Inter-agent messaging
│   ├── plans/                 # Implementation plans (no code)
│   ├── research/              # Research documents (no code)
│   ├── todos/                 # Task tracking files
│   └── implementation/
│       └── progress.md        # Implementation log
├── scripts/
│   ├── guardrails/
│   │   ├── config.yaml        # Security patterns configuration
│   │   ├── utils.py           # Shared utilities
│   │   ├── validate_edit.py   # PreToolUse: file path validation
│   │   ├── validate_secrets.py # PreToolUse: secret detection
│   │   ├── validate_command.py # PreToolUse: command validation
│   │   └── post_write.py      # PostToolUse: formatting & copyright
│   ├── pre-commit.sh          # Pre-commit quality checks
│   ├── check_copyright.py     # Copyright header validation
│   ├── update_copyright.py    # Copyright header insertion
│   └── security-sweep.sh      # Secret scanning
├── templates/
│   ├── python/
│   │   ├── pyproject.toml     # Python project template
│   │   └── .pre-commit-config.yaml
│   ├── typescript/
│   │   ├── package.json       # TypeScript project template
│   │   └── tsconfig.json
│   ├── CLAUDE.md              # Project guidance template
│   └── system.md              # Agent workflow protocol template
├── examples/
│   └── python-example/        # Working example project
├── ANTI_PATTERNS.md           # 14-section LISP-inspired guide
├── BEST_PRACTICES.md          # Quick reference for best practices
├── CODE_QUALITY.md            # Python quality standards
├── CLAUDE.md                  # Your project's Claude guidance
├── system.md                  # Your agent workflow protocol
└── COPYRIGHT.txt              # Your copyright header
```

## Guardrails System

The guardrails system uses **three layers of defense** to enforce best practices:

### Layer 1: PreToolUse Hooks (Preventive)

| Hook | Purpose |
|------|---------|
| `validate_edit.py` | Blocks writes to sensitive files (.env, .git/, credentials, keys) |
| `validate_secrets.py` | Detects 50+ secret patterns (API keys, tokens, connection strings) |
| `validate_command.py` | Blocks dangerous commands (rm -rf, force push, chmod 777) |
| `validate_quality.py` | Detects code anti-patterns (silent exceptions, `any` types, junk drawers) |

### Layer 2: PostToolUse Hooks (Automatic Maintenance)

| Hook | Purpose |
|------|---------|
| `post_write.py` | Auto-formats Python (ruff) and TypeScript (prettier), adds copyright headers |

### Layer 3: Hookify Rules (Content-Based Blocking)

| Rule | Purpose |
|------|---------|
| `hookify.secrets-detection.local.md` | Blocks API keys in code |
| `hookify.env-files.local.md` | Prevents committing .env files |
| `hookify.hardcoded-urls.local.md` | Blocks hardcoded deployment URLs |
| `hookify.password-detection.local.md` | Detects hardcoded passwords |
| `hookify.quality-python.local.md` | Enforces Python quality standards |
| `hookify.any-type.local.md` | Blocks TypeScript `any` type usage |
| `hookify.silent-exceptions.local.md` | Blocks silent exception handlers |
| `hookify.junk-drawers.local.md` | Blocks utils/helpers/common directories |
| `hookify.console-statements.local.md` | Warns on console.log/print statements |

### Configuration

All patterns are centralized in `scripts/guardrails/config.yaml`:

```yaml
# Block writes to these files
protected_paths:
  block:
    - '\.env($|\.).*'
    - '^\.git/'
    - 'credentials\.json'
    - '\.npmrc$'               # NPM credentials
    - 'kubeconfig'             # Kubernetes secrets

# Detect these secret patterns (50+ patterns)
secrets:
  - pattern: 'sk-ant-[a-zA-Z0-9\-]{20,}'
    name: Anthropic API Key
  - pattern: 'ghp_[a-zA-Z0-9]{36}'
    name: GitHub Personal Access Token
  # ... and many more

# Block these commands
commands:
  block:
    - 'rm\s+-rf\s+/'
    - 'git\s+push.*--force'
    - 'curl.*\|\s*(ba)?sh'     # Piping to shell

# Anti-patterns by language
anti_patterns:
  python:
    - pattern: 'except.*:\s*\n\s*pass'
      name: Silent exception handler
  typescript:
    - pattern: ':\s*any\b'
      name: any type usage

# Forbidden directories
junk_drawers:
  - 'utils/'
  - 'helpers/'
  - 'common/'
```

## Three-Phase Protocol

All coding tasks follow this workflow:

### 1. Research Phase → `.claude/research/<filename>`

- Gather context, analyze requirements
- Explore existing code and patterns
- Document alternatives and trade-offs
- **No code in this phase**

### 2. Planning Phase → `.claude/plans/<filename>`

- Define implementation steps
- List modules, functions, data flows
- Identify edge cases and test strategies
- **No code in this phase**

### 3. Implementation → `.claude/implementation/progress.md`

- Log each action as you work
- Record blockers and decisions
- Update research/plan files as needed
- **Coding happens here**

## Inter-Agent Communication

Agents can communicate by writing files to each other's `.claude/communication/` directories:

```bash
# Send a message to another project
echo "Please update the shared API client..." > \
  ../other-project/.claude/communication/from-my-project-$(date +%s).md
```

The receiving agent watches for new messages and executes the requested work.

## Code Quality

### Python Quality Gates

| Check | Tool | Threshold |
|-------|------|-----------|
| Lexical | ruff check | Zero errors |
| Formatting | ruff format | Enforced |
| Type checking | mypy --strict | Zero errors |
| Complexity | radon | Max CC: 10 |
| Function length | - | Max 50-60 lines |
| Nesting depth | - | Max 3 levels |

### TypeScript Quality Gates

| Check | Tool | Threshold |
|-------|------|-----------|
| Linting | ESLint | Zero warnings |
| Formatting | Prettier | Enforced |
| Type checking | tsc --noEmit | Zero errors |
| No `any` types | - | Blocked by guardrails |
| JSX nesting | - | Max 4 levels |

### Running Quality Checks

```bash
# Python: Check staged files
./scripts/pre-commit.sh

# Python: Check all tracked files
./scripts/pre-commit.sh --all

# TypeScript: Check staged files
./scripts/pre-commit-ts.sh

# TypeScript: Check all tracked files
./scripts/pre-commit-ts.sh --all

# Security sweep (both languages)
./scripts/security-sweep.sh
```

### Best Practices Guide

See `BEST_PRACTICES.md` for comprehensive guidelines including:
- Anti-patterns to avoid (with examples)
- Functional programming principles
- Domain-driven directory structure
- Naming conventions
- Error handling standards

## Templates

### Python Project

Copy `templates/python/pyproject.toml` and replace placeholders:

- `{{PROJECT_NAME}}` - Your project name
- `{{PROJECT_DESCRIPTION}}` - Short description
- `{{AUTHOR_NAME}}` - Your name
- `{{PACKAGE_NAME}}` - Python package name

### TypeScript Project

Copy `templates/typescript/package.json` and `tsconfig.json`.

### Claude Guidance

Copy `templates/CLAUDE.md` and `templates/system.md` to your project root.

## Customization

### Adding New Secret Patterns

Edit `scripts/guardrails/config.yaml`:

```yaml
secrets:
  - pattern: 'your_pattern_here'
    name: Your Secret Type
```

### Adding Protected Paths

```yaml
protected_paths:
  block:
    - 'your/sensitive/path'
  warn:
    - 'your/config/path'
```

### Adding Dangerous Commands

```yaml
commands:
  block:
    - 'dangerous_command'
  warn:
    - 'risky_command'
```

## License

MIT License - see LICENSE for details.
