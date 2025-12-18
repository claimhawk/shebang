# Claude Autonomous Code Starter Kit

A comprehensive starter kit for building projects with Claude Code that includes:

- **Guardrails System** - Pre/Post tool use hooks for security and automation
- **Code Quality Standards** - Python and TypeScript linting, type checking, complexity analysis
- **Three-Phase Protocol** - Research → Plan → Implement workflow with documentation
- **Inter-Agent Communication** - File-based messaging between autonomous agents
- **Automation Scripts** - Pre-commit hooks, security sweeps, copyright management

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
├── CODE_QUALITY.md            # Quality standards
├── CLAUDE.md                  # Your project's Claude guidance
├── system.md                  # Your agent workflow protocol
└── COPYRIGHT.txt              # Your copyright header
```

## Guardrails System

The guardrails system uses Claude Code hooks to intercept tool operations:

### PreToolUse Hooks

1. **validate_edit.py** - Blocks writes to sensitive files (.env, .git/, credentials, etc.)
2. **validate_secrets.py** - Detects API keys, tokens, and secrets in content
3. **validate_command.py** - Blocks dangerous shell commands (rm -rf /, force push, etc.)

### PostToolUse Hooks

1. **post_write.py** - Auto-formats Python files with ruff and adds copyright headers

### Configuration

All patterns are defined in `scripts/guardrails/config.yaml`:

```yaml
# Block writes to these files
protected_paths:
  block:
    - '\.env($|\.).*'
    - '^\.git/'
    - 'credentials\.json'

# Detect these secret patterns
secrets:
  - pattern: 'sk-ant-[a-zA-Z0-9\-]{20,}'
    name: Anthropic API Key

# Block these commands
commands:
  block:
    - 'rm\s+-rf\s+/'
    - 'git\s+push.*--force'
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

### Running Quality Checks

```bash
# Check staged files
./scripts/pre-commit.sh

# Check all tracked files
./scripts/pre-commit.sh --all

# Security sweep
./scripts/security-sweep.sh
```

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
