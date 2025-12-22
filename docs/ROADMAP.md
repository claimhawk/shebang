# Shebang! Roadmap

**Tracking completed work, active development, and future vision.**

---

## Overview

This roadmap organizes Shebang! development into three phases:

1. **COMPLETED** — Features shipped and documented
2. **IN PROGRESS** — Current development focus
3. **PLANNED** — Future vision aligned with [PHILOSOPHY.md](../PHILOSOPHY.md)

---

## Phase 1: Foundation (COMPLETED)

### Core Infrastructure

- ✅ **Guardrails System** (3aa1761, 30ac2f1, 869dc86, ffc92e6)
  - PreToolUse hooks: `validate_edit.py`, `validate_secrets.py`, `validate_command.py`, `validate_quality.py`
  - PostToolUse hooks: `post_write.py` (auto-format, copyright)
  - Central config: `scripts/guardrails/config.yaml`
  - **Dependencies**: None
  - **Enables**: Safe autonomous agent operation

- ✅ **Hookify Rules** (30ac2f1, 869dc86)
  - Content-based blocking: secrets, silent exceptions, `any` types, junk drawers
  - Environment file protection
  - Password detection
  - **Dependencies**: Guardrails system
  - **Enables**: Proactive code quality enforcement

- ✅ **Agent Protocol** (7cafb1d, c7c213e, 884bbb0)
  - `system.md` with startup actions and git workflow
  - `CLAUDE.md` as agent operating manual
  - `agent/` directory for tool-agnostic knowledge base
  - **Dependencies**: None
  - **Enables**: Multi-agent collaboration

- ✅ **Code Quality Standards** (3aa1761, ffc92e6, bddf430)
  - Python: ruff, mypy, radon, PEP 8
  - TypeScript: ESLint, Prettier, strict mode
  - Anti-patterns documentation (65 years of LISP wisdom)
  - Testing documentation (practices, anti-patterns, language guides)
  - **Dependencies**: None
  - **Enables**: Production-grade code output

### Documentation

- ✅ **Philosophy & Vision** (5c5cd4b, 1898f81, 8c146d3, bddf430)
  - [PHILOSOPHY.md](../PHILOSOPHY.md): 8 core principles
  - Terminal as Single Source of Truth architecture
  - Sandboxed shell customization
  - Heritage tracing to LISP, Haskell, Erlang
  - **Dependencies**: None
  - **Enables**: Consistent decision-making

- ✅ **Brand Identity** (e0281df, 4b5dd3f)
  - "Shebang!" (with exclamation) as canonical name
  - [BRAND.md](BRAND.md): Logo, colors, voice, typography
  - [VOICE.md](VOICE.md): Writing guidelines
  - **Dependencies**: None
  - **Enables**: Public release readiness

- ✅ **Metrics & Tracking** (c7c213e, 4b5dd3f, 8c146d3)
  - [METRICS.md](METRICS.md): Productivity tracking
  - ASCII charts from git history via `generate-charts.py`
  - 8x developer productivity claim (185 lines/hour vs 20)
  - **Dependencies**: Git history
  - **Enables**: Evidence-based velocity claims

- ✅ **User Guides** (e9782b6)
  - [USER_GUIDE.md](USER_GUIDE.md): Getting started
  - [POWER_USER_GUIDE.md](POWER_USER_GUIDE.md): Advanced features
  - [docs/index.md](index.md): Documentation hub
  - **Dependencies**: macOS application
  - **Enables**: User onboarding

### macOS Application (Alpha)

- ✅ **Three-Panel Layout** (dbdc0a6, 1efcc32)
  - File browser (reactive, follows `cd`)
  - Terminal canvas (SwiftTerm integration)
  - Session panel (tab-like workspace switching)
  - **Dependencies**: None
  - **Enables**: Visual development environment

- ✅ **Command Bar** (dbdc0a6)
  - Natural language input
  - Git-aware prompt (✓2 ●3 +1)
  - CWD breadcrumb navigation
  - **Dependencies**: Terminal canvas
  - **Enables**: Agentic interface

- ✅ **File Browser** (dbdc0a6, bddf430)
  - Derives state from `ls` command (not FileManager API)
  - Auto-sync with terminal `cd`
  - Favorites drawer for quick navigation
  - **Dependencies**: Terminal as Single Source of Truth
  - **Enables**: Reactive workspace

- ✅ **Session Management** (dbdc0a6)
  - Multiple parallel workspaces
  - Persistence across restarts
  - Hot reload framework (`/reload` command)
  - **Dependencies**: None
  - **Enables**: Multi-project workflows

- ✅ **Terminal Integration** (dbdc0a6)
  - SwiftTerm for VT100 emulation
  - Read-only display (input via command bar)
  - Interactive vs block mode toggle
  - **Dependencies**: SwiftTerm
  - **Enables**: Terminal-first workflow

### Project Infrastructure

- ✅ **Build System** (dbdc0a6, 1efcc32)
  - Swift Package Manager layout
  - `build.sh` script with release configuration
  - Xcode 16+ / macOS 15+ requirements
  - **Dependencies**: None
  - **Enables**: Native macOS compilation

- ✅ **Licensing** (5c5cd4b, 1efcc32)
  - The Unlicense (public domain)
  - No CLA, no corporate approval
  - **Dependencies**: None
  - **Enables**: Maximum freedom

- ✅ **Git History Documentation** (9a0f6b0)
  - `reconcile-history.sh`: AI-powered commit message enrichment
  - Operates in isolated worktree
  - Preserves timestamps during rewrite
  - **Dependencies**: Claude CLI
  - **Enables**: Living documentation from git history

---

## Phase 2: Alpha Refinement (IN PROGRESS)

### Current Focus

- 🟡 **Dogfooding Shebang! for Shebang! development**
  - Using the environment to build itself
  - Identifying pain points in real-world usage
  - Iterating on UX based on developer experience

- 🟡 **Documentation Polish**
  - This roadmap (ROADMAP.md)
  - Feature inventory (FEATURES.md)
  - API documentation for Swift codebase

### Near-Term Goals

- 🔵 **Terminal State Synchronization**
  - Git status reactive updates
  - Branch switching detection
  - Working directory change events
  - **Dependencies**: Terminal as Single Source of Truth
  - **Enables**: True reactive environment

- 🔵 **Command Parser**
  - Natural language → shell command translation
  - Intent classification (git, file ops, build, test)
  - Fallback to direct shell execution
  - **Dependencies**: Command bar
  - **Enables**: "Tell it what you want" interface

- 🔵 **Session Persistence**
  - Save/restore working directory
  - Terminal history preservation
  - File browser state
  - **Dependencies**: Session management
  - **Enables**: Resume workflows across app restarts

---

## Phase 3: Claude Code Integration (PLANNED)

### Claude Code as First-Class Citizen

- ⭕ **MCP Server Integration** (like `--chrome` for browsers)
  - Background MCP server for Claude Code to control Shebang
  - Tools: `send_command`, `read_terminal`, `get_session`, `navigate_to`
  - UI state control: panels, previews, display mode
  - Enable with `claude --mcp shebang://localhost:PORT`
  - **Dependencies**: None (standalone TCP server)
  - **Enables**: Claude Code as the "driver" of Shebang IDE

- ⭕ **Direct Claude Code Execution**
  - Route natural language commands to `claude` CLI
  - Session-aware context management
  - `system.md` configuration per project
  - **Dependencies**: Command parser, Claude Code CLI
  - **Enables**: Agentic development workflow

- ⭕ **Multi-Agent Orchestration**
  - Message watcher for inter-agent communication
  - Parallel session execution
  - Conflict resolution for concurrent edits
  - **Dependencies**: Session management, Claude Code
  - **Enables**: Team of agents working together

- ⭕ **Agent Memory & Context**
  - Research phase → `.claude/research/`
  - Planning phase → `.claude/plans/`
  - Implementation → `.claude/implementation/progress.md`
  - **Dependencies**: Claude Code integration
  - **Enables**: Three-phase workflow

### Pluggable AI Backends

- ⭕ **Backend Abstraction Layer**
  - Unified interface for AI CLIs
  - Provider detection and routing
  - Capability negotiation
  - **Dependencies**: Claude Code integration
  - **Enables**: Tool-agnostic agentic development

- ⭕ **Additional Provider Support**
  - Gemini CLI integration
  - GitHub Copilot CLI (`gh copilot`)
  - Amazon Q integration
  - Custom agents via MCP servers
  - **Dependencies**: Backend abstraction layer
  - **Enables**: User choice of AI assistant

---

## Phase 4: Advanced Features (PLANNED)

### Sandboxed Shell Customization

- ⭕ **In-App Alias System**
  - User-created aliases (Shebang-only, never touch dotfiles)
  - Agent-generated shortcuts
  - Session-scoped environment
  - **Dependencies**: Terminal integration
  - **Enables**: Evolving vocabulary of commands

- ⭕ **Agent Function Generation**
  - AI creates functions as it works
  - Portable across sessions
  - Auto-documentation
  - **Dependencies**: Claude Code integration, alias system
  - **Enables**: Self-improving environment

### Git Integration

- ⭕ **Visual Git Status**
  - Inline diff preview
  - Branch graph visualization
  - Stash management UI
  - **Dependencies**: Terminal as Single Source of Truth
  - **Enables**: Git without memorization

- ⭕ **Natural Language Git**
  - "undo that" → smart reset/revert/checkout
  - "show what changed" → diff with context
  - "fix the merge" → conflict resolution wizard
  - **Dependencies**: Command parser, git integration
  - **Enables**: Git without headaches

### Build & Test Automation

- ⭕ **Continuous Testing**
  - Auto-run tests on file save
  - Failure notifications
  - Coverage tracking
  - **Dependencies**: Terminal integration
  - **Enables**: Instant feedback loop

- ⭕ **Smart Build System**
  - Detect build tool (make, swift build, npm, cargo)
  - Incremental builds
  - Build artifact caching
  - **Dependencies**: Terminal integration
  - **Enables**: Fast iteration

### Developer Experience

- ⭕ **Tab Completion**
  - File path completion
  - Command history search
  - Project-specific commands
  - **Dependencies**: Command bar
  - **Enables**: Efficiency without memorization

- ⭕ **File Preview**
  - Syntax highlighting
  - Markdown rendering
  - Image preview
  - **Dependencies**: File browser
  - **Enables**: Browse without opening

- ⭕ **Search & Replace**
  - Natural language: "replace X with Y in all JS files"
  - Regex support for power users
  - Preview before apply
  - **Dependencies**: Command parser
  - **Enables**: Bulk operations without fear

---

## Phase 5: 100x Developer (VISION)

### Knowledge Infrastructure

- ⭕ **Auto-Documentation**
  - AI generates docs from code structure
  - API reference from type signatures
  - Architecture diagrams from imports
  - **Dependencies**: Claude Code integration
  - **Enables**: Documentation that's always current

- ⭕ **Code Review Automation**
  - Pre-commit AI review
  - Security vulnerability scanning
  - Performance regression detection
  - **Dependencies**: Guardrails system, Claude Code
  - **Enables**: Quality without manual review

- ⭕ **Deployment Pipelines**
  - Natural language: "deploy to staging"
  - Environment-aware configuration
  - Rollback on failure
  - **Dependencies**: Command parser
  - **Enables**: DevOps without YAML

### Team Collaboration

- ⭕ **Shared Sessions**
  - Pair programming mode
  - Session sharing via URL
  - Real-time collaboration
  - **Dependencies**: Session management
  - **Enables**: Remote pairing

- ⭕ **Knowledge Transfer**
  - Onboarding assistant
  - Codebase explanation on demand
  - Best practices enforcement
  - **Dependencies**: Claude Code, agent protocol
  - **Enables**: Instant productivity for new hires

### Platform Expansion

- ⭕ **Linux Support**
  - Native GTK or Qt UI
  - Terminal compatibility
  - Package manager integration
  - **Dependencies**: macOS application maturity
  - **Enables**: Cross-platform development

- ⭕ **Windows Support**
  - Native WinUI or Avalonia UI
  - PowerShell integration
  - WSL2 compatibility
  - **Dependencies**: Linux support
  - **Enables**: Universal developer tool

---

## Feature Dependencies Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                     FOUNDATION (COMPLETED)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐          ┌─────────────────┐          │
│  │  Guardrails     │          │  Agent Protocol │          │
│  │  System         │          │  (system.md)    │          │
│  └────────┬────────┘          └────────┬────────┘          │
│           │                            │                   │
│           ▼                            ▼                   │
│  ┌─────────────────┐          ┌─────────────────┐          │
│  │  Hookify Rules  │          │  macOS App      │          │
│  └─────────────────┘          │  Three-Panel    │          │
│                               └────────┬────────┘          │
│                                        │                   │
│                                        ▼                   │
│                               ┌─────────────────┐          │
│                               │  Terminal as    │          │
│                               │  Single Source  │          │
│                               │  of Truth       │          │
│                               └────────┬────────┘          │
└────────────────────────────────────────┼──────────────────┘
                                         │
┌────────────────────────────────────────┼──────────────────┐
│                  ALPHA REFINEMENT (IN PROGRESS)            │
├────────────────────────────────────────┼──────────────────┤
│                                        │                   │
│                                        ▼                   │
│                               ┌─────────────────┐          │
│                               │  Command Parser │          │
│                               └────────┬────────┘          │
│                                        │                   │
│           ┌────────────────────────────┼───────┐          │
│           │                            │        │          │
│           ▼                            ▼        ▼          │
│  ┌─────────────────┐          ┌─────────────────┐          │
│  │  State Sync     │          │  Session        │          │
│  │  (git, cwd)     │          │  Persistence    │          │
│  └─────────────────┘          └─────────────────┘          │
└────────────────────────────────────────┼──────────────────┘
                                         │
┌────────────────────────────────────────┼──────────────────┐
│            CLAUDE CODE INTEGRATION (PLANNED)               │
├────────────────────────────────────────┼──────────────────┤
│                                        │                   │
│                                        ▼                   │
│                               ┌─────────────────┐          │
│                               │  Claude Code    │          │
│                               │  Execution      │          │
│                               └────────┬────────┘          │
│                                        │                   │
│           ┌────────────────────────────┼────────────┐     │
│           │                            │             │     │
│           ▼                            ▼             ▼     │
│  ┌─────────────────┐          ┌─────────────────┐  │     │
│  │  Multi-Agent    │          │  Backend        │  │     │
│  │  Orchestration  │          │  Abstraction    │  │     │
│  └─────────────────┘          └────────┬────────┘  │     │
│                                        │             │     │
│                                        ▼             │     │
│                               ┌─────────────────┐  │     │
│                               │  Gemini, Copilot│  │     │
│                               │  Amazon Q, MCP  │  │     │
│                               └─────────────────┘  │     │
│                                                     │     │
│                                        ┌────────────┘     │
│                                        │                   │
│                                        ▼                   │
│                               ┌─────────────────┐          │
│                               │  Sandboxed      │          │
│                               │  Shell (alias,  │          │
│                               │  functions)     │          │
│                               └─────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                                         │
┌────────────────────────────────────────┼──────────────────┐
│              ADVANCED FEATURES (PLANNED)                   │
├────────────────────────────────────────┼──────────────────┤
│                                        │                   │
│           ┌────────────────────────────┼────────────┐     │
│           │                            │             │     │
│           ▼                            ▼             ▼     │
│  ┌─────────────────┐          ┌─────────────────┐         │
│  │  Visual Git     │          │  Natural Lang   │         │
│  │  Status         │          │  Git Commands   │         │
│  └─────────────────┘          └─────────────────┘         │
│                                                             │
│           ┌─────────────────────────────────────┐         │
│           │                                      │         │
│           ▼                                      ▼         │
│  ┌─────────────────┐                   ┌─────────────────┐│
│  │  Continuous     │                   │  Smart Build    ││
│  │  Testing        │                   │  System         ││
│  └─────────────────┘                   └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                         │
┌────────────────────────────────────────┼──────────────────┐
│                100x DEVELOPER (VISION)                     │
├────────────────────────────────────────┼──────────────────┤
│                                        │                   │
│           ┌────────────────────────────┼────────────┐     │
│           │                            │             │     │
│           ▼                            ▼             ▼     │
│  ┌─────────────────┐          ┌─────────────────┐         │
│  │  Auto-          │          │  Code Review    │         │
│  │  Documentation  │          │  Automation     │         │
│  └─────────────────┘          └─────────────────┘         │
│                                                             │
│                                        ▼                   │
│                               ┌─────────────────┐          │
│                               │  Deployment     │          │
│                               │  Pipelines      │          │
│                               └─────────────────┘          │
│                                                             │
│                               ┌─────────────────┐          │
│                               │  Platform       │          │
│                               │  Expansion      │          │
│                               │  (Linux, Win)   │          │
│                               └─────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## Success Metrics

### Current (v0.0.2)

- **Development velocity**: 185 lines/hour (8x baseline)
- **Commits**: 23 commits in 73.6 hours
- **Net lines**: 13,664 lines of production code
- **Dogfooding**: Building Shebang! using Shebang!

### Target (v1.0.0)

- **Onboarding time**: < 5 minutes to first contribution
- **Productivity**: 10x 2020 developer baseline
- **Agent autonomy**: 80% of tasks completed without human intervention
- **Cross-platform**: macOS, Linux, Windows support

---

## Contributing to the Roadmap

**Before proposing features, read [PHILOSOPHY.md](../PHILOSOPHY.md).**

Your feature must align with:

1. **Terminal as Single Source of Truth**
2. **The interface gets out of your way**
3. **Knowledge becomes infrastructure**
4. **Agentic by design**

**Process:**

1. Fork the repo
2. Add your feature to the PLANNED section with:
   - Description
   - Dependencies
   - "Enables" statement (what does this unlock?)
3. Implement using Shebang! (dogfood it)
4. Use it for a week in real-world scenarios
5. Submit PR only after living with it

No CLA. No corporate approval. Just code that embodies the vision.

---

*Built using Shebang! — This roadmap is evidence of dogfooding.*
