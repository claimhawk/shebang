# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚡ FIRST: Read system.md

**Before doing anything else**, read and execute the startup actions in [`system.md`](./system.md).

That file contains:
- **REQUIRED** background processes you must start immediately
- Git workflow rules (fetch & rebase, never pull)
- Inter-agent communication protocol
- Your role and identity as an autonomous agent

**Do not skip this step.**

---

## Project Overview

Claude Autonomous Code Starter Kit - a comprehensive starter template for building projects with Claude Code that includes guardrails, code quality enforcement, and autonomous agent workflow protocols.

## Commands

### Setup

```bash
# Install Python dependencies
pip install pyyaml ruff mypy radon pytest

# Install TypeScript dependencies (for TS projects)
npm install
```

### Quality Checks

```bash
# Run pre-commit checks on staged files
./scripts/pre-commit.sh

# Run checks on all tracked files
./scripts/pre-commit.sh --all

# Security sweep for secrets
./scripts/security-sweep.sh
```

## Architecture

```
scripts/guardrails/     # Hook validators (PreToolUse/PostToolUse)
templates/              # Project templates (Python, TypeScript)
examples/               # Working example projects
.claude/                # Claude workflow directories
```

## Subagent Execution Model (REQUIRED)

All AI assistants **must decompose complex tasks into explicit sub-tasks** and assign each sub-task to an isolated **subagent**. This is mandatory to:

- Prevent uncontrolled context growth
- Ensure deterministic, auditable reasoning
- Preserve repository-wide clarity and focus
- Enforce separation of concerns

### Subagent Requirements

Every non-trivial request (multi-step, multi-file, or multi-decision) must:

1. **Produce a task plan** - Break the task into atomic sub-tasks with clear contracts
2. **Run subagents independently** - Subagents don't share context except explicit inputs
3. **Return a composed final output** - Orchestrator integrates subagent outputs

## Three-Step Implementation Protocol (MANDATORY)

All coding tasks must follow a strict three-stage workflow:

### 1. Research Phase → `./.claude/research/<file>`

- All initial thinking, exploration, reasoning
- No code allowed
- Output must be structured and comprehensive

### 2. Planning Phase → `./.claude/plans/<file>`

- Implementation plan only
- No code allowed
- Must list steps, modules, functions, edge cases

### 3. Implementation Progress Log → `./.claude/implementation/progress.md`

- Every commit-sized action must be logged
- Summaries of what was done, blockers, decisions

**Coding may only begin after these three steps are complete.**

## Code Quality

- Python 3.12+, four-space indentation, PEP 8
- All code must pass ruff, mypy checks
- Maximum cyclomatic complexity: 10
- All functions require type hints

## Git Commits

**DO NOT CO-AUTHOR COMMITS** - only use the GitHub user's name when committing. Do not add co-author trailers or attribute commits to AI assistants.
