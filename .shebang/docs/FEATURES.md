# Shebang! Features

**Master inventory of all features with git history and status tracking.**

---

## How to Read This Document

- **Status**: ✅ Completed | 🟡 In Progress | ⭕ Planned
- **Commit**: Git SHA linking to implementation
- **Category**: CORE (infrastructure) | FEATURE (user-facing) | DOCS (documentation) | REFACTOR (reorganization)
- **Phase**: When this was/will be delivered

---

## CORE: Infrastructure & Guardrails

### Guardrails System

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| PreToolUse: `validate_edit.py` | ✅ | 3aa1761 | Foundation | Block writes to `.env`, `.git/`, credentials, keys |
| PreToolUse: `validate_secrets.py` | ✅ | 3aa1761 | Foundation | Detect 40+ secret patterns (API keys, tokens, connection strings) |
| PreToolUse: `validate_command.py` | ✅ | 3aa1761 | Foundation | Block dangerous commands (`rm -rf /`, force push, `chmod 777`) |
| PreToolUse: `validate_quality.py` | ✅ | 869dc86 | Foundation | Catch anti-patterns (silent exceptions, `any` types, junk drawers) |
| PostToolUse: `post_write.py` | ✅ | 3aa1761 | Foundation | Auto-format with ruff/prettier, add copyright headers |
| Central Config: `config.yaml` | ✅ | 3aa1761 | Foundation | All patterns centralized (secrets, commands, anti-patterns, junk drawers) |
| Python Quality Enforcement | ✅ | 3aa1761 | Foundation | ruff, mypy, radon integration with pre-commit hooks |
| TypeScript Quality Enforcement | ✅ | ffc92e6 | Foundation | ESLint, Prettier, strict mode with pre-commit hooks |
| Security Sweep Script | ✅ | 3aa1761 | Foundation | `security-sweep.sh` for detecting secrets in codebase |
| Copyright Management | ✅ | 3aa1761 | Foundation | `check_copyright.py`, `update_copyright.py` for headers |

**Git History:**
- 3aa1761: Initial guardrails system (validate_edit, validate_secrets, validate_command, post_write)
- 869dc86: Added validate_quality.py for anti-pattern detection
- ffc92e6: TypeScript pre-commit hooks (pre-commit-ts.sh)

---

### Hookify Rules (Content-Based Blocking)

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| `.env` File Protection | ✅ | 30ac2f1 | Foundation | Block commits containing `.env` files |
| Secrets Detection | ✅ | 30ac2f1 | Foundation | Block API keys, tokens in code |
| Password Detection | ✅ | 30ac2f1 | Foundation | Block hardcoded passwords |
| Hardcoded URLs | ✅ | 30ac2f1 | Foundation | Warn on hardcoded Modal/production URLs |
| Python Copyright Headers | ✅ | 30ac2f1 | Foundation | Enforce copyright on all `.py` files |
| Silent Exceptions | ✅ | 869dc86 | Foundation | Block `except: pass` patterns |
| TypeScript `any` Type | ✅ | 869dc86 | Foundation | Block usage of `any` type |
| Junk Drawer Directories | ✅ | 869dc86 | Foundation | Block `utils/`, `helpers/` directories |
| No Fallback Defaults | ✅ | 869dc86 | Foundation | Block environment variable fallbacks with hardcoded values |
| Console Statements | ✅ | 869dc86 | Foundation | Warn on `console.log` in production code |

**Git History:**
- 30ac2f1: Initial 5 hookify rules (env-files, secrets, passwords, hardcoded-urls, quality-python)
- 869dc86: Added 5 more rules (any-type, console-statements, junk-drawers, no-fallbacks, silent-exceptions)

---

### Agent Protocol & Knowledge Base

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| `system.md` Agent Protocol | ✅ | 7cafb1d | Foundation | Startup actions, git workflow, execution order |
| `CLAUDE.md` Operating Manual | ✅ | 7cafb1d, c7c213e | Foundation | Agent entry point with quick reference table |
| `agent/` Knowledge Directory | ✅ | 884bbb0 | Foundation | Tool-agnostic knowledge base at project root |
| Three-Phase Workflow | ✅ | 3aa1761 | Foundation | Research → Planning → Implementation |
| `.claude/implementation/progress.md` | ✅ | 3aa1761 | Foundation | Implementation tracking template |
| Multi-Agent Message Watcher | ✅ | 7cafb1d | Foundation | Background process for inter-agent communication |
| Git Workflow Rules | ✅ | 7cafb1d | Foundation | Fetch & rebase (never pull), branch ownership |

**Git History:**
- 3aa1761: Initial CLAUDE.md with three-phase workflow
- 7cafb1d: Restructured system.md with priority indicators and startup actions
- c7c213e: Rewrote CLAUDE.md as "Agent Operating Manual"
- 884bbb0: Created `agent/` directory, moved knowledge base from `.claude/context/`

---

### Code Quality Standards

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Python Standards (PEP 8) | ✅ | 3aa1761 | Foundation | Four-space indent, type hints required |
| Python Complexity Limits | ✅ | 3aa1761 | Foundation | Cyclomatic complexity max 10, function max 50-60 lines |
| TypeScript Strict Mode | ✅ | ffc92e6 | Foundation | No `any`, max nesting 3 levels |
| Anti-Patterns Documentation | ✅ | ffc92e6 | Foundation | 14-section guide (65 years of LISP wisdom) |
| Best Practices Guide | ✅ | 869dc86 | Foundation | 30 years of engineering wisdom consolidated |
| Testing Documentation | ✅ | bddf430 | Foundation | TESTING.md, practices, anti-patterns, language guides |
| Testing Practices | ✅ | bddf430 | Foundation | Red-green-refactor, arrange-act-assert, isolation |
| Testing Anti-Patterns | ✅ | bddf430 | Foundation | 1119 lines documenting what NOT to do |
| Language-Specific Testing | ✅ | bddf430 | Foundation | Python, JavaScript, TypeScript, Go, Rust, Java |

**Git History:**
- 3aa1761: Initial CODE_QUALITY.md with Python/TypeScript standards
- ffc92e6: Added ANTI_PATTERNS.md (1447 lines)
- 869dc86: Added BEST_PRACTICES.md (399 lines)
- bddf430: Added comprehensive testing docs (3000+ lines)

---

### Project Templates

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Python Project Template | ✅ | 3aa1761 | Foundation | pyproject.toml, pre-commit config, example calculator |
| TypeScript Project Template | ✅ | 3aa1761 | Foundation | package.json, tsconfig.json |
| CLAUDE.md Template | ✅ | 3aa1761 | Foundation | Project-specific agent instructions |
| system.md Template | ✅ | 7cafb1d | Foundation | Agent protocol for any project |

**Git History:**
- 3aa1761: Initial templates in `templates/` directory
- 884bbb0: Moved to `agent/templates/`

---

## FEATURE: macOS Application

### Core UI Components

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Three-Panel Layout | ✅ | dbdc0a6 | Foundation | File browser, terminal canvas, session panel |
| Favorites Drawer | ✅ | dbdc0a6 | Foundation | Quick access to common directories |
| File Browser (Reactive) | ✅ | dbdc0a6, bddf430 | Foundation | Follows `cd`, derives from `ls` command, auto-refreshes on filesystem changes |
| Terminal Canvas | ✅ | dbdc0a6 | Foundation | SwiftTerm integration with dtach session persistence |
| Session Panel | ✅ | dbdc0a6 | Foundation | Tab-like workspace switching |
| Interactive vs Block Mode | ✅ | dbdc0a6 | Foundation | Toggle between live terminal and organized blocks |

**Git History:**
- dbdc0a6: Initial macOS app (2878 lines of Swift)
- bddf430: Refactored SidebarView to use `ls` instead of FileManager

---

### Session Management

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Multiple Sessions | ✅ | dbdc0a6 | Foundation | Parallel workspaces with independent state |
| Session Persistence (dtach) | ✅ | - | Foundation | Sessions persist via dtach sockets, survive app restarts |
| Working Directory per Session | ✅ | - | Foundation | Each session has independent `cwd` |
| Terminal History per Session | ✅ | - | Foundation | Session-scoped command history |
| File Browser State per Session | 🟡 | - | Alpha | Session-scoped navigation state |

**Git History:**
- dbdc0a6: Session model (70 lines) with persistence framework
- Migrated from tmux to dtach for simpler session persistence

---

### Terminal Integration

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| SwiftTerm Integration | ✅ | dbdc0a6 | Foundation | VT100 terminal emulation with native scrolling |
| dtach Session Persistence | ✅ | - | Foundation | Sessions survive app restarts via dtach sockets |
| Terminal as Single Source of Truth | ✅ | bddf430 | Foundation | All UI state derives from terminal commands |
| `ls` for File Browser | ✅ | bddf430 | Foundation | File browser uses `ls`, not FileManager API |
| Git Status from `git` | ✅ | bddf430 | Foundation | Use git binary, not libgit2 |
| File Drag as Path | ✅ | - | Foundation | Dragging files from sidebar inserts path as text |
| Binary File Path Prefix | ✅ | - | Foundation | Binary files prefixed with "binary:" to prevent auto-attachment |
| Sandboxed Shell Customization | ⭕ | - | Planned | In-app aliases/functions, never touch dotfiles |

**Git History:**
- dbdc0a6: SwiftTermView (190 lines), TerminalCanvasView (333 lines)
- bddf430: Philosophy documented, SidebarView refactored
- Migrated from tmux to dtach for simpler session persistence

---

### Build System

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Swift Package Manager Layout | ✅ | 1efcc32 | Foundation | Package.swift with ShebangApp target |
| Build Script (`build.sh`) | ✅ | dbdc0a6 | Foundation | Release configuration, artifact output |
| Xcode 16+ Requirement | ✅ | dbdc0a6 | Foundation | SwiftUI 6, macOS 15+ |
| SwiftTerm Dependency | ✅ | dbdc0a6 | Foundation | GitHub package for terminal emulation |

**Git History:**
- dbdc0a6: Initial build.sh (75 lines)
- 1efcc32: Restructured to Swift Package Manager

---

## DOCS: Documentation & Brand

### Philosophy & Vision

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| PHILOSOPHY.md | ✅ | 5c5cd4b, bddf430 | Foundation | 8 core principles, 264 lines |
| Terminal as Single Source of Truth | ✅ | bddf430 | Foundation | Architecture principle with ASCII diagram |
| Sandboxed Shell Customization | ✅ | bddf430 | Foundation | Never touch system dotfiles |
| Reactive vs Project-Rooted | ✅ | 5c5cd4b | Foundation | Environment follows you, not config file |
| Knowledge Becomes Infrastructure | ✅ | 5c5cd4b | Foundation | 60 years of wisdom automated |
| Agentic by Design | ✅ | 5c5cd4b | Foundation | Built for AI agents from ground up |
| Claude Code First-Class Citizen | ✅ | b7a2e70 | Foundation | Integration at deepest level |
| Pluggable AI Backends | ✅ | b7a2e70 | Foundation | Gemini, Copilot, Amazon Q roadmap |
| Built With Itself | ✅ | 5c5cd4b | Foundation | Dogfooding as forcing function |
| Heritage (LISP, Haskell, Erlang) | ✅ | 5c5cd4b, 1898f81 | Foundation | Credibility via programming history |

**Git History:**
- 5c5cd4b: Initial PHILOSOPHY.md
- 1898f81: Reframed "hard-fought wisdom" (not gatekeeping)
- bddf430: Added Terminal as Single Source of Truth, sandboxed shell
- b7a2e70: Added pluggable AI backends roadmap

---

### Brand Identity

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Name: "Shebang!" | ✅ | e0281df | Foundation | Rebrand from "Claude Code Guardrails" |
| BRAND.md | ✅ | 4b5dd3f | Foundation | Logo, colors, voice, typography (207 lines) |
| VOICE.md | ✅ | 4b5dd3f | Foundation | Writing guidelines for consistency |
| Tagline: "1 hour = 1 day" | ✅ | 8c146d3 | Foundation | 8x productivity claim |
| Logo Design | ⭕ | - | Planned | Visual identity for app icon |
| Color Palette | ✅ | 4b5dd3f | Foundation | Terminal green, deep background, warm accents |
| Typography | ✅ | 4b5dd3f | Foundation | SF Mono for code, SF Pro for UI |

**Git History:**
- e0281df: Rebrand to "Shebang!"
- 4b5dd3f: Created BRAND.md and VOICE.md
- 8c146d3: Promoted "1 hour = 1 day" headline

---

### User Documentation

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| README.md | ✅ | 5c5cd4b, e3334cf, e9782b6 | Foundation | Quick start, philosophy, features |
| USER_GUIDE.md | ✅ | e9782b6 | Foundation | Getting started, basic usage |
| POWER_USER_GUIDE.md | ✅ | e9782b6 | Foundation | Advanced features, customization |
| docs/index.md | ✅ | e9782b6 | Foundation | Documentation hub |
| API Documentation (Swift) | ✅ | - | Foundation | docs/api/swift.md (auto-generated) |
| Contributing Guidelines | ✅ | 3f7f204 | Foundation | Dogfood for a week, match philosophy |
| ROADMAP.md | ✅ | Current | Alpha | This document |
| FEATURES.md | ✅ | Current | Alpha | Master feature inventory |

**Git History:**
- 5c5cd4b: Rewrote README for public release
- e3334cf, ab24c8c: Added ClaimHawk hiring section
- e9782b6: Synced docs/index.md with README
- 3f7f204: Updated contributing guidelines

---

### Metrics & Tracking

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| METRICS.md | ✅ | c7c213e, 4b5dd3f | Foundation | Productivity tracking, charts |
| ASCII Charts from Git | ✅ | 4b5dd3f | Foundation | `generate-charts.py` extracts data |
| 8x Productivity Claim | ✅ | 8c146d3 | Foundation | 185 lines/hour vs 20 baseline |
| BUILD_LOG.md | ✅ | 5ee5337 | Foundation | Evidence of building with Shebang! |
| Development History | ✅ | 5ee5337 | Foundation | Elapsed times per phase |
| Metrics Generation Script | ✅ | c7c213e | Foundation | `generate-metrics.sh` |

**Git History:**
- c7c213e: Initial METRICS.md and generate-metrics.sh
- 4b5dd3f: Added generate-charts.py (347 lines)
- 8c146d3: Promoted 8x claim to headline
- 5ee5337: Added BUILD_LOG.md with timelines

---

### MkDocs Infrastructure

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| mkdocs.yml Configuration | ✅ | - | Foundation | Site structure, theme |
| build-docs.sh | ✅ | - | Foundation | Build script for documentation |
| docs/ Directory Structure | ✅ | 884bbb0 | Foundation | Organized by category |
| GitHub Pages Deployment | ⭕ | - | Planned | Auto-deploy on push |

**Git History:**
- 884bbb0: Reorganized docs/ structure

---

## REFACTOR: Code Organization

### Repository Structure

| Change | Status | Commit | Phase | Description |
|--------|--------|--------|-------|-------------|
| Swift Package Manager Layout | ✅ | 1efcc32 | Foundation | Top-level Package.swift |
| ShebangApp → Sources/ShebangApp/ | ✅ | 1efcc32 | Foundation | Standard SPM structure |
| Templates → agent/templates/ | ✅ | 884bbb0 | Foundation | Centralized agent knowledge |
| Examples → agent/examples/ | ✅ | 884bbb0 | Foundation | Moved to agent directory |
| .claude/context/ → agent/ | ✅ | 884bbb0 | Foundation | Tool-agnostic location |
| VOICE.md → agent/VOICE.md | ✅ | 884bbb0 | Foundation | Agent writing guidelines |
| system.md → .shebang/system.md | ✅ | 884bbb0 | Foundation | Universal agent protocol |

**Git History:**
- 1efcc32: Restructured to Swift Package Manager
- 884bbb0: Created agent/ directory hierarchy

---

### Licensing

| Change | Status | Commit | Phase | Description |
|--------|--------|--------|-------|-------------|
| MIT License | ✅ | 5c5cd4b | Foundation | Initial open source license |
| The Unlicense (Public Domain) | ✅ | 1efcc32 | Foundation | Maximum freedom, no restrictions |

**Git History:**
- 5c5cd4b: Added MIT license
- 1efcc32: Changed to The Unlicense (public domain)

---

## Planned Features (Not Yet Implemented)

### Claude Code Integration

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Direct Claude Code Execution | ⭕ | - | Claude Code | Route commands to `claude` CLI |
| Multi-Agent Orchestration | ⭕ | - | Claude Code | Parallel sessions, conflict resolution |
| Agent Memory & Context | ⭕ | - | Claude Code | Research/Planning/Implementation phases |
| Backend Abstraction Layer | ⭕ | - | Claude Code | Unified interface for AI CLIs |
| Gemini CLI Support | ⭕ | - | Claude Code | Google's agentic terminal |
| GitHub Copilot CLI Support | ⭕ | - | Claude Code | `gh copilot` integration |
| Amazon Q Support | ⭕ | - | Claude Code | AWS development assistant |
| Custom MCP Agents | ⭕ | - | Claude Code | Bring your own via MCP servers |

---

### Advanced Features

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| In-App Alias System | ⭕ | - | Advanced | User/agent-created shortcuts |
| Agent Function Generation | ⭕ | - | Advanced | AI creates functions as it works |
| Visual Git Status | ⭕ | - | Advanced | Inline diff, branch graph, stash UI |
| Natural Language Git | ⭕ | - | Advanced | "undo that" → smart reset/revert |
| Continuous Testing | ⭕ | - | Advanced | Auto-run tests on file save |
| Smart Build System | ⭕ | - | Advanced | Detect tool, incremental builds |
| Tab Completion | ⭕ | - | Advanced | File paths, command history |
| File Preview | ⭕ | - | Advanced | Syntax highlighting, markdown render |
| Search & Replace | ⭕ | - | Advanced | Natural language bulk operations |

---

### 100x Developer Vision

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| Auto-Documentation | ⭕ | - | Vision | AI generates docs from code |
| Code Review Automation | ⭕ | - | Vision | Pre-commit AI review, security scan |
| Deployment Pipelines | ⭕ | - | Vision | Natural language: "deploy to staging" |
| Shared Sessions | ⭕ | - | Vision | Pair programming, real-time collab |
| Knowledge Transfer | ⭕ | - | Vision | Onboarding assistant, codebase explanation |
| Linux Support | ⭕ | - | Vision | GTK or Qt UI, package manager integration |
| Windows Support | ⭕ | - | Vision | WinUI, PowerShell, WSL2 compatibility |

---

## Git History Tools

| Feature | Status | Commit | Phase | Description |
|---------|--------|--------|-------|-------------|
| reconcile-history.sh | ✅ | 9a0f6b0 | Foundation | AI-powered commit message enrichment |
| Worktree Isolation | ✅ | 9a0f6b0 | Foundation | Safe history rewrite without touching main |
| Timestamp Preservation | ✅ | 9a0f6b0 | Foundation | Maintain original author/committer times |
| Claude CLI Integration | ✅ | 9a0f6b0 | Foundation | `--print` flag for non-interactive mode |

**Git History:**
- 9a0f6b0: Added reconcile-history.sh (424 lines)

---

## Feature Statistics

### By Category

| Category | Completed | In Progress | Planned | Total |
|----------|-----------|-------------|---------|-------|
| **CORE** | 50 | 0 | 0 | 50 |
| **FEATURE** | 24 | 6 | 26 | 56 |
| **DOCS** | 28 | 2 | 1 | 31 |
| **REFACTOR** | 8 | 0 | 0 | 8 |
| **TOTAL** | **110** | **8** | **27** | **145** |

### By Phase

| Phase | Features | Commits |
|-------|----------|---------|
| **Foundation (v0.0.2)** | 110 | 23 |
| **Alpha Refinement** | 8 | TBD |
| **Claude Code Integration** | 8 (planned) | - |
| **Advanced Features** | 9 (planned) | - |
| **100x Developer** | 7 (planned) | - |

### Code Statistics

| Metric | Value |
|--------|-------|
| **Total Commits** | 23 |
| **Total Lines** | 13,664 net lines |
| **Lines/Hour** | 185 (8x baseline) |
| **Active Coding Time** | ~8 hours |
| **Elapsed Calendar Time** | 73.6 hours (3 days) |
| **Fastest Feature** | Brand guidelines (207 lines, ~1 hour) |
| **Largest Feature** | macOS app (2878 lines, ~3 hours) |

---

## Commit Timeline

```
2025-12-18 14:03  3aa1761  Initial commit: guardrails + templates
2025-12-21 10:20  30ac2f1  Hookify quality control rules (5 rules)
2025-12-21 10:29  869dc86  No-fallbacks rule + 5 more hookify rules
2025-12-21 11:13  ffc92e6  Anti-patterns documentation (1447 lines)
2025-12-21 12:33  7cafb1d  system.md agent protocol
2025-12-21 13:18  5c5cd4b  Public release documentation
2025-12-21 13:20  ab24c8c  ClaimHawk hiring section
2025-12-21 13:43  e0281df  Rebrand to "Shebang!"
2025-12-21 14:28  dbdc0a6  macOS application (2878 lines)
2025-12-21 15:32  1efcc32  Swift Package Manager + public domain
2025-12-21 15:32  e3334cf  ClaimHawk hiring in README
2025-12-21 15:32  e9782b6  Sync docs/index.md
2025-12-21 15:33  5ee5337  Development history changelog
2025-12-21 15:35  b7a2e70  Claude Code + pluggable AI backends
2025-12-21 15:36  3f7f204  Contributing guidelines
2025-12-21 15:39  e60a589  Release v0.0.2
2025-12-21 15:41  1898f81  Reframe: hard-fought wisdom
2025-12-21 15:44  c7c213e  Agent docs reorganization + metrics
2025-12-21 15:46  4b5dd3f  Brand guidelines + ASCII charts
2025-12-21 15:49  884bbb0  agent/ folder reorganization
2025-12-21 15:51  8c146d3  "1 hour = 1 day" headline
2025-12-21 15:57  bddf430  Terminal as Single Source of Truth
2025-12-21 16:02  9a0f6b0  reconcile-history.sh
```

---

## Feature Dependencies (Quick Reference)

**Foundation Complete:**
- Guardrails System → Hookify Rules
- Agent Protocol → Multi-Agent
- macOS App → All UI Features
- Terminal Integration → All Reactive Features

**Alpha Focus:**
- Command Parser ← macOS App
- State Sync ← Terminal Integration
- Session Persistence ← Session Management

**Planned Chain:**
- Command Parser → Claude Code Execution
- Claude Code → Multi-Agent → Backend Abstraction
- Backend Abstraction → Gemini/Copilot/Amazon Q
- Claude Code → Sandboxed Shell → Agent Functions
- Terminal as Single Source → Visual Git → Natural Language Git
- Command Parser → Search/Replace, Deployment

---

*This document is auto-generated from git history. See [ROADMAP.md](ROADMAP.md) for strategic planning.*
