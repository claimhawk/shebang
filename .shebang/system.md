# Agent System Protocol

A structured workflow protocol for autonomous AI coding agents.

---

## Table of Contents

| # | Section | Priority |
|---|---------|----------|
| 1 | [Git Workflow](#1-git-workflow) | 🔴 CRITICAL |
| 2 | [Development Workflow](#2-development-workflow) | 🟠 HIGH |
| 3 | [Inter-Agent Communication](#3-inter-agent-communication) | 🟠 HIGH |
| 4 | [Context Engineering](#4-context-engineering) | 🟡 MEDIUM |
| 5 | [Code Quality](#5-code-quality) | 🟡 MEDIUM |

---

## 1. Git Workflow

**🔴 CRITICAL — Follow these rules for all git operations.**

### 1.1 Branch Strategy

- **Never commit directly to `main`** — Use feature branches
- Use descriptive branch names: `{feature-type}/{description}`
- Examples: `feature/add-auth`, `fix/login-validation`, `refactor/api-client`

### 1.2 The Golden Rule: Fetch & Rebase

**Prefer `git rebase` over `git merge`** for a clean linear history.

```bash
# Update local main without switching branches
git fetch origin main:main

# Rebase your branch onto updated main
git rebase main
```

### 1.3 Standard Workflows

**Starting new work:**
```bash
git fetch origin main:main
git checkout -b feature/my-feature main
```

**Keeping your branch updated:**
```bash
git fetch origin main:main
git rebase main
# If conflicts: resolve them, then `git add . && git rebase --continue`
```

**Before creating a PR:**
```bash
git fetch origin main:main
git rebase main
git push origin feature/my-feature --force-with-lease
```

### 1.4 Quick Reference

| Action | Command |
|--------|---------|
| Update local main | `git fetch origin main:main` |
| Rebase current branch | `git rebase main` |
| Abort a bad rebase | `git rebase --abort` |
| Push after rebase | `git push --force-with-lease` |
| Check current branch | `git branch --show-current` |

### 1.5 Commit Attribution

**DO NOT add AI co-author trailers or attribution.** All commits are attributed solely to the developer:

- ❌ No `Co-Authored-By: Claude` or similar trailers
- ❌ No `🤖 Generated with Claude Code` footers
- ❌ No AI tool attribution in commit messages

---

## 2. Development Workflow

**🟠 HIGH — Your standard work process.**

### 2.1 Three-Phase Protocol

All coding tasks follow a structured workflow:

#### Phase 1: Research → `.claude/research/{task}.md`

- Gather context, analyze requirements
- Explore existing code and patterns
- Document alternatives and trade-offs
- **No code in this phase**

#### Phase 2: Plan → `.claude/plans/{task}.md`

- Define implementation steps
- List modules, functions, data flows
- Identify edge cases and test strategies
- **No code in this phase**

#### Phase 3: Implement → `.claude/implementation/progress.md`

- Log each action as you work
- Record blockers and decisions
- Update research/plan files as needed
- **Coding happens here**

### 2.2 Task Tracking with TodoWrite

**Use the TodoWrite tool to track your work.** This creates a visible todo list that shows the user your progress.

#### When to Use TodoWrite

- **Multi-step tasks** — Break down work into trackable items
- **Complex features** — Plan before implementing
- **Bug fixes** — Track what you're investigating and fixing
- **Any task with 3+ steps** — Make progress visible

#### How to Use It

```
1. Create todos at the start of a task
2. Mark ONE item as "in_progress" at a time
3. Mark items "completed" immediately when done
4. Add new items as you discover them
5. Remove items that are no longer relevant
```

#### Task States

| State | Meaning |
|-------|---------|
| `pending` | Not started yet |
| `in_progress` | Currently working on (only ONE at a time) |
| `completed` | Finished |

#### Example

```
User: "Add dark mode to the app"

You create:
1. [pending] Research existing theme system
2. [pending] Add dark mode CSS variables
3. [pending] Create theme toggle component
4. [pending] Persist theme preference
5. [pending] Test across all pages

Then work through them one at a time, marking each
in_progress → completed as you go.
```

**Key rule:** Mark tasks complete immediately. Don't batch completions.

### 2.3 Required Reading

Before starting work, read:
- `CODE_QUALITY.md` — Quality standards
- `BEST_PRACTICES.md` — Engineering guidelines

---

## 3. Inter-Agent Communication

**🟠 HIGH — How to communicate with other agents.**

Agents communicate by writing files to each other's `.claude/communication/` directories.

### 3.1 Sending Messages

Write a file to the target project's communication directory:

```
TARGET_PROJECT/.claude/communication/from-{your-project}-{timestamp}.md
```

Include:
- What you need changed
- Why it's needed
- How to verify the change works
- Whether you need a response

### 3.2 Receiving Messages

Monitor your `.claude/communication/` directory for new files:

1. **Read** the message file completely
2. **Understand** what the requesting agent needs
3. **Execute** using your standard workflow
4. **Mark processed** by renaming to `{filename}.processed`
5. **Respond** if requested

---

## 4. Context Engineering

**🟡 MEDIUM — Keep context clean and manageable.**

### 4.1 Rules

- Run all tools in background subagents when possible
- Run debugging and log reading in subagents
- Update workflow documents with completed work
- Document everything in files — do not rely on memory
- Break complex tasks into smaller, focused subagent operations

### 4.2 Subagent Model

For complex tasks:

1. **Decompose** the task into atomic sub-tasks
2. **Run subagents independently** — each with clear inputs/outputs
3. **Compose results** — integrate subagent outputs in the main context

---

## 5. Code Quality

**🟡 MEDIUM — Quality standards for all code.**

### 5.1 Python

| Metric | Limit |
|--------|-------|
| Cyclomatic complexity | ≤ 10 per function |
| Nesting depth | ≤ 3 levels |
| Function length | ≤ 50-60 lines |
| Parameters | ≤ 5 (excluding self/cls) |

Required tools:
- `ruff check` — Linting
- `ruff format` — Formatting
- `mypy` — Type checking

### 5.2 TypeScript

| Metric | Limit |
|--------|-------|
| Cyclomatic complexity | ≤ 10 per function |
| Nesting depth | ≤ 3 levels |
| Function length | ≤ 50 lines |
| JSX nesting | ≤ 4 levels |

Required:
- TypeScript strict mode
- No `any` types
- ESLint and Prettier passing

### 5.3 Pre-Commit Checks

```bash
# Python
./scripts/pre-commit.sh

# TypeScript
./scripts/pre-commit-ts.sh
```

---

## Philosophy

> Write code that future maintainers will thank you for.

- **Correctness first** — Small correct solutions beat clever incomplete ones
- **Functional at the core** — Data in → data out, side effects at the edges
- **Strict typing** — Type errors are build failures
- **Low complexity** — Small functions, shallow nesting
- **Good ancestor** — Write code you'd be proud to inherit
