# Agents Directory

This is an example agent workspace demonstrating the **agent folder structure** for autonomous development workflows in Shebang.

## Overview

Agents are specialized Claude Code instances with job-specific context, designed to work on focused, long-running tasks. Each agent is a **folder** containing all information needed for autonomous work: goals, research, plans, progress tracking, and terminal session state.

## Agent Types

### Wizard Agent (Orchestrator)
- **Purpose:** Coordinate multiple specialist agents
- **Responsibilities:** Break down complex tasks, spawn specialists, manage dependencies, integrate results
- **Example:** `.agents/wizard/` - Coordinates OAuth implementation and UI migration

### Specialist Agent (Worker)
- **Purpose:** Execute focused, domain-specific tasks
- **Responsibilities:** Implement specific features, report progress, communicate blockers
- **Example:** `.agents/oauth-implementation/` - Implements OAuth backend

## Folder Structure

Every agent has the same structure:

```
.agents/
└── {agent-name}/
    ├── GOAL.md           # What this agent must achieve
    ├── RESEARCH.md       # Investigation and findings
    ├── PLAN.md           # Implementation strategy
    ├── TODO.md           # Task list with status
    ├── DONE.md           # Definition of done checklist
    ├── CONTEXT.md        # Relevant files, snippets, decisions
    ├── COMMS/            # Inter-agent communication
    │   ├── to-{agent}.md
    │   └── from-{agent}.md
    ├── session/          # Terminal session state
    │   ├── session.json
    │   └── history.txt
    └── artifacts/        # Generated files, logs, etc.
```

## File Specifications

### GOAL.md
**Purpose:** Single source of truth for what this agent must accomplish.

**Contents:**
- Primary objective (one sentence)
- Success criteria (checkboxes)
- Constraints (technical/business limits)
- Context (why this work is needed)
- Parent agent (if specialist)

### RESEARCH.md
**Purpose:** All investigation, exploration, and analysis.

**Contents:**
- Current state analysis
- Alternatives considered (decision tables)
- Code exploration (file paths, functions)
- Dependencies and risks
- References (docs, issues, threads)

**Rules:**
- No code (only snippets for illustration)
- Date-stamped findings
- Link to specific files/lines

### PLAN.md
**Purpose:** Step-by-step implementation strategy.

**Contents:**
- Architecture changes
- Modules to create/modify
- Data flow diagrams
- Test strategy
- Rollout steps
- Edge cases

**Rules:**
- Detailed enough for implementation
- No actual code
- Must address testing and deployment

### TODO.md
**Purpose:** Live task tracker with status updates.

**Contents:**
- In Progress (current work)
- Pending (upcoming work)
- Blocked (waiting on dependencies)
- Completed (finished work)

**Rules:**
- Update frequently (after every work session)
- Use checkboxes
- Note blockers with context
- Link to commits when complete

### DONE.md
**Purpose:** Definition of done - checklist for completion.

**Contents:**
- Functional requirements
- Code quality checks
- Testing requirements
- Documentation requirements
- Deployment requirements
- Cleanup checklist

**Rules:**
- Created at agent initialization
- Must be exhaustive
- Agent cannot close until all items checked

### CONTEXT.md
**Purpose:** Centralized reference for all relevant information.

**Contents:**
- Relevant files (with paths)
- Key functions (with signatures)
- Important code snippets
- Decisions made (date-stamped)
- Related work (PRs, issues)
- External resources

**Rules:**
- Link to files with line numbers
- Keep snippets short
- Date-stamp all decisions

### COMMS/ Directory
**Purpose:** Inter-agent communication for coordinated workflows.

**Message Format:**
```markdown
# Message to: {target-agent}
**From:** {source-agent}
**Date:** YYYY-MM-DD HH:MM
**Type:** Request | Response | Notification

## Request
[What you need]

## Context
[Why it's needed]

## Acceptance Criteria
[How to verify completion]

## Urgency
- [ ] Blocking
- [ ] High
- [x] Normal
- [ ] Low
```

**Processing:**
1. Target agent reads message
2. Executes work
3. Creates response in `to-{source-agent}.md`
4. Renames request to `{filename}.processed`

### session/ Directory
**Purpose:** Terminal session state for agent workspace.

**Files:**
- `session.json` - Metadata (name, CWD, type, parent)
- `history.txt` - Command history
- `env.json` - Agent-specific environment variables (optional)

## Agent Lifecycle

### 1. Creation
```
User: "Implement OAuth for the API"
→ System creates .agents/oauth-implementation/
→ Agent populates GOAL, RESEARCH, PLAN, TODO, DONE
→ Git commit: "Create agent: oauth-implementation"
```

### 2. Execution
```
while not done():
    1. Check TODO.md for next task
    2. Execute task
    3. Update TODO.md
    4. Check COMMS/ for messages
    5. Respond to messages
    6. Commit incremental work
    7. Update RESEARCH/PLAN as needed
```

### 3. Communication
```
Request help:
  1. Write COMMS/to-{target}.md
  2. Wait for COMMS/from-{target}.md
  3. Continue work

Respond to request:
  1. Read COMMS/ messages
  2. Execute work
  3. Write COMMS/to-{requester}.md
  4. Mark original .processed
```

### 4. Completion
```
1. Verify all DONE.md items checked
2. Run final validation
3. Notify parent agent (if specialist)
4. Wait for user approval
5. Archive to .agents/.archive/
```

## Example Workflow

### Scenario: Authentication Modernization

**Step 1: Wizard Created**
```
User: "Add OAuth and modernize login UI"
→ Create wizard agent
→ Wizard analyzes requirements
→ Wizard creates GOAL, RESEARCH, PLAN
```

**Step 2: Wizard Spawns Specialists**
```
Wizard creates:
  - oauth-implementation (backend OAuth)
  - ui-migration (frontend UI)

Wizard sends initial tasks via COMMS
```

**Step 3: Specialists Work**
```
oauth-implementation:
  - Implements Google provider
  - Implements GitHub provider
  - Runs tests
  - Notifies wizard when ready

ui-migration:
  - Blocked on oauth-implementation
  - Wizard unblocks when OAuth endpoints ready
  - Implements new login UI
  - Integrates with OAuth endpoints
```

**Step 4: Wizard Integrates**
```
Wizard:
  - Integration testing (full flow)
  - Documentation
  - Deployment
  - Closes specialist agents
  - Closes self
```

## Hierarchical Agent Model

```
┌─────────────────────────────────────────┐
│         Wizard Agent                    │
│  (auth-modernization)                   │
│                                         │
│  Responsibilities:                      │
│  - Break down complex task              │
│  - Spawn specialists                    │
│  - Coordinate work                      │
│  - Integrate results                    │
│  - Ensure quality                       │
└─────────┬───────────────┬───────────────┘
          │               │
  ┌───────▼──────┐   ┌───▼──────────┐
  │ oauth-impl   │   │ ui-migration │
  │ (Backend)    │   │ (Frontend)   │
  │              │   │              │
  │ Focus:       │   │ Focus:       │
  │ - OAuth 2.0  │   │ - Login UI   │
  │ - Providers  │   │ - OAuth btns │
  │ - Tokens     │   │ - Linking UI │
  └──────────────┘   └──────────────┘
     Specialist         Specialist
```

**Agent Inheritance:**
- **Wizard** extends base agent with coordination capabilities
- **Specialist** extends base agent with focused execution
- Both share same file structure (GOAL, RESEARCH, PLAN, etc.)
- Specialists report to wizard via COMMS
- Wizard manages dependencies and integration

## Git Integration

### Commit Messages
```
[agent:oauth-implementation] Implement Google OAuth provider

- Added GoogleOAuthProvider class
- Token exchange and refresh logic
- User info fetching
- Unit tests (15 tests, 94% coverage)

Refs: .agents/oauth-implementation/TODO.md
```

### Branch Strategy
```
main
  └─ feature/auth-modernization
       ├─ .agents/wizard/
       ├─ .agents/oauth-implementation/
       └─ .agents/ui-migration/

All agents work on the same feature branch.
```

## Benefits

### For Developers
- Clear separation of concerns
- Transparent progress tracking
- Auditable decision history
- Git-versioned context

### For AI Agents
- Focused, manageable scope
- Clear success criteria
- Structured communication
- Context persistence across sessions

### For Teams
- Understand what AI did and why
- Review decisions and trade-offs
- Learn from agent workflows
- Reproduce results

## Best Practices

### Do
✅ Update TODO.md after every work session
✅ Date-stamp all decisions in CONTEXT.md
✅ Commit frequently with descriptive messages
✅ Use COMMS/ for all inter-agent communication
✅ Keep GOAL.md focused (one primary objective)
✅ Make DONE.md exhaustive (if not listed, not required)

### Don't
❌ Skip research phase (go straight to coding)
❌ Let TODO.md become stale
❌ Make decisions without documenting them
❌ Modify another agent's files directly
❌ Close agent before all DONE.md items checked
❌ Keep completed agents in active directory

## See Also

- **Design Document:** `/docs/design/AGENTS.md` - Full specification
- **Philosophy:** `/PHILOSOPHY.md` - Why we build this way
- **Agent System Protocol:** `/.shebang/system.md` - Workflow template
- **Example Project:** `/agent/examples/python-example/` - Complete project structure

---

**This agent structure transforms autonomous development from opaque to transparent, from ephemeral to permanent, and from individual to coordinated.**
