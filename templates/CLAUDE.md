# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

{{PROJECT_DESCRIPTION}}

## Commands

### Setup

```bash
# Python projects
pip install -e ".[dev]"

# TypeScript projects
npm install
```

### Development

```bash
# Python: Run quality checks
./scripts/pre-commit.sh

# Python: Run tests
pytest

# TypeScript: Start dev server
npm run dev

# TypeScript: Type check
npm run type-check
```

## Architecture

Describe the architecture of your project here:

```
src/
├── domain/      # Core business logic (pure functions)
├── services/    # Application services (orchestration)
├── adapters/    # External integrations (DB, HTTP, etc.)
└── interfaces/  # CLI, API endpoints, UI integration
```

## Subagent Execution Model (REQUIRED)

All AI assistants **must decompose complex tasks into explicit sub-tasks** and assign each sub-task to an isolated **subagent**. This is mandatory to:

- Prevent uncontrolled context growth
- Ensure deterministic, auditable reasoning
- Preserve repository-wide clarity and focus
- Enforce separation of concerns

### Subagent Requirements

Every non-trivial request (multi-step, multi-file, or multi-decision) must:

1. **Produce a task plan**
   - Break the task into atomic sub-tasks
   - Each sub-task must correspond to a subagent
   - Each subagent must have a clear contract: inputs, outputs, constraints

2. **Run subagents independently**
   - Subagents do not share context except the explicit inputs passed to them
   - Subagents must not add new unrelated context
   - Only the orchestrator (main agent) sees the entire plan

3. **Return a composed final output**
   - The orchestrator integrates the subagents' outputs
   - No subagent should assume global repository state

## Three-Step Implementation Protocol (MANDATORY)

All coding tasks must follow a strict three-stage workflow:

### 1. Research Phase → `./.claude/research/<file>`

This file contains all initial thinking, exploration, reasoning, alternatives considered, risks, constraints, and relevant contextual evaluation.

- This stage is for raw cognitive work
- No code allowed
- Subagents may be used to analyze sub-problems
- Output must be structured and comprehensive

### 2. Planning Phase → `./.claude/plans/<file>`

This file contains the **implementation plan only**.

- No code allowed
- Must list steps, modules, functions, structures, data flows, edge cases, test strategies
- The plan must be deterministic and complete

### 3. Implementation Progress Log → `./.claude/implementation/progress.md`

This file is your "life update" journal for the maintainer.

- Every commit-sized action must be logged
- Summaries of what was done, blockers, decisions
- Subagent invocations must be recorded as separate, timestamped entries

**Coding may only begin after these three steps are complete.**

## Code Quality

- Python 3.12+, four-space indentation, PEP 8
- All code must pass ruff, mypy, and radon checks
- Maximum cyclomatic complexity: 10
- Maximum function length: 50-60 lines
- All functions require type hints

## Git Commits

**DO NOT CO-AUTHOR COMMITS** - only use the GitHub user's name when committing. Do not add co-author trailers or attribute commits to AI assistants.
