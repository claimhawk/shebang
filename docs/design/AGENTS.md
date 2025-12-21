# Agents Design Document

## Overview

**Agents** are specialized Claude Code instances with job-specific context, designed to work on focused, long-running tasks within Shebang. An agent is a **folder** (not just a file) that contains all the information needed for an autonomous task: goals, research, plans, progress tracking, and terminal session state.

Agents replace and extend the concept of "sessions" in Shebang. Where a session is just a terminal tab with a working directory, an agent is a **complete autonomous workspace** that knows what it's supposed to do and can work independently.

### Core Philosophy

Agents embody Shebang's "repo as single source of truth" principle:

- All agent state lives in the repository (`.agents/` directory)
- Git tracks agent history, progress, and outcomes
- Agents communicate via files, not ephemeral messages
- Everything is auditable, reproducible, and transparent

### Key Concepts

1. **Agent as Folder** - Each agent is a self-contained directory with all context
2. **Hierarchical Agents** - A top-level "general wizard" can spawn specialized agents
3. **Session + Specialization** - Every agent HAS a terminal session plus task-specific data
4. **File-Based Communication** - Agents coordinate by writing to each other's directories
5. **Git-Tracked Progress** - All work is versioned and auditable

---

## Motivation

### Why Agents?

Traditional development tools treat the terminal as a dumb command executor. Shebang treats it as an intelligent workspace. But sessions alone aren't enough for complex workflows:

**Sessions provide:**
- Working directory context
- Terminal history
- PTY process state

**Agents add:**
- Clear goals and definition of done
- Research and planning artifacts
- Todo lists and progress tracking
- Specialized context per task
- Coordination between multiple parallel workstreams

### Use Cases

**Single Agent (Specialist)**
```
User: "Implement OAuth authentication for the API"
→ Creates agent: .agents/oauth-implementation/
→ Agent researches existing auth code
→ Agent plans the implementation
→ Agent tracks progress in TODO.md
→ Agent commits when done
```

**Multi-Agent (Orchestrated)**
```
User: "Refactor the entire frontend to use TypeScript"
→ General wizard creates:
   - .agents/wizard/              (orchestrator)
   - .agents/convert-components/  (UI components)
   - .agents/type-definitions/    (type system)
   - .agents/migration-testing/   (validation)
→ Wizard coordinates the work
→ Each specialist reports progress
→ Wizard integrates results
```

**Long-Running (Background Work)**
```
User: "Monitor and optimize database queries over the next week"
→ Agent runs in background
→ Agent logs findings to RESEARCH.md
→ Agent creates issues in TODO.md
→ Agent commits improvements incrementally
→ User checks progress anytime via git log
```

---

## Architecture

### Folder Structure

```
.agents/
├── wizard/                      # Top-level orchestrator agent
│   ├── GOAL.md                 # What this agent is trying to achieve
│   ├── RESEARCH.md             # Investigation and findings
│   ├── PLAN.md                 # Implementation strategy
│   ├── TODO.md                 # Task list with status
│   ├── DONE.md                 # Definition of done checklist
│   ├── CONTEXT.md              # Relevant files, snippets, decisions
│   ├── COMMS/                  # Communication with other agents
│   │   ├── to-specialist-1.md
│   │   └── from-specialist-2.md
│   ├── session/                # Terminal session state
│   │   ├── session.json        # Session metadata
│   │   ├── history.txt         # Command history
│   │   └── env.json            # Environment variables
│   └── artifacts/              # Generated files, logs, etc.
│
├── oauth-implementation/        # Specialist agent example
│   ├── GOAL.md
│   ├── RESEARCH.md
│   ├── PLAN.md
│   ├── TODO.md
│   ├── DONE.md
│   ├── CONTEXT.md
│   ├── COMMS/
│   ├── session/
│   └── artifacts/
│
└── README.md                    # Agent system overview
```

### File Specifications

#### GOAL.md

**Purpose:** Single source of truth for what this agent is supposed to accomplish.

**Format:**
```markdown
# Agent Goal

## Primary Objective
[One sentence description of what this agent must achieve]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Constraints
- Must maintain backward compatibility
- Cannot modify files in src/core/
- Must complete within 3 days

## Context
[Why this work is needed, business value, related work]
```

**Examples:**
- "Implement OAuth 2.0 authentication for the REST API"
- "Refactor database layer to use connection pooling"
- "Investigate and fix memory leak in session management"

#### RESEARCH.md

**Purpose:** All investigation, exploration, and analysis. This is the agent's "thinking space."

**Format:**
```markdown
# Research Notes

## Date: YYYY-MM-DD

### Current State Analysis
[What exists today]

### Alternatives Considered
| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| A | ... | ... | Rejected |
| B | ... | ... | **Selected** |

### Code Exploration
[Relevant file paths, function signatures, patterns discovered]

### Dependencies & Risks
[External libraries needed, potential blockers, edge cases]

### References
- [Link to docs]
- [Related issues]
- [Stack Overflow threads]
```

**Rules:**
- No code in this file (only code snippets for illustration)
- Update as new information is discovered
- Date-stamp all major findings
- Link to specific files and line numbers when referencing code

#### PLAN.md

**Purpose:** The step-by-step implementation strategy.

**Format:**
```markdown
# Implementation Plan

## Architecture Changes
[High-level structural changes needed]

## Modules to Create/Modify
1. `src/auth/oauth-provider.ts` - New file
   - createOAuthClient()
   - validateToken()
   - refreshToken()

2. `src/api/middleware/auth.ts` - Modify
   - Add OAuth flow
   - Integrate with existing JWT auth

## Data Flow
[Diagrams or text describing how data moves through the system]

## Test Strategy
- Unit tests for each OAuth function
- Integration test for full auth flow
- Manual testing with Google/GitHub providers

## Rollout Steps
1. Implement core OAuth logic
2. Add middleware integration
3. Write tests
4. Update documentation
5. Deploy to staging
6. Monitor for 24h
7. Deploy to production

## Edge Cases
- Token expiration during request
- Provider downtime
- Invalid redirect URIs
```

**Rules:**
- Must be detailed enough for implementation
- No actual code (save that for implementation phase)
- Must address testing and deployment
- Updated when plan changes

#### TODO.md

**Purpose:** Live task tracker with status updates.

**Format:**
```markdown
# Task List

## In Progress
- [ ] Implement OAuthClient class
  - [x] Constructor with config
  - [ ] Token exchange method
  - [ ] Token refresh method

## Pending
- [ ] Add middleware to Express app
- [ ] Write unit tests
- [ ] Update API documentation

## Blocked
- [ ] Deploy to staging (waiting for infra team)
  - Blocker: Need staging OAuth credentials
  - Owner: @devops-team
  - ETA: 2024-01-15

## Completed
- [x] Research OAuth 2.0 spec
- [x] Evaluate oauth2-server vs passport-oauth2
- [x] Set up development OAuth app with Google
```

**Rules:**
- Update frequently (after every work session)
- Use checkboxes for tracking
- Note blockers with context
- Move completed tasks to bottom
- Link to commits when tasks complete

#### DONE.md

**Purpose:** Definition of done - the checklist that determines if this agent's work is complete.

**Format:**
```markdown
# Definition of Done

## Functional Requirements
- [ ] OAuth login flow works end-to-end
- [ ] Users can authenticate with Google
- [ ] Users can authenticate with GitHub
- [ ] Tokens refresh automatically before expiration
- [ ] Invalid tokens return 401 with clear error message

## Code Quality
- [ ] All code passes linting (ESLint)
- [ ] All code passes type checking (TypeScript strict mode)
- [ ] Cyclomatic complexity ≤ 10 for all functions
- [ ] No code duplication (DRY violations)

## Testing
- [ ] Unit test coverage ≥ 80%
- [ ] All integration tests pass
- [ ] Manual testing completed on 3 providers
- [ ] Security review completed

## Documentation
- [ ] API endpoints documented in OpenAPI spec
- [ ] README updated with OAuth setup instructions
- [ ] Environment variables documented
- [ ] Migration guide written

## Deployment
- [ ] Deployed to staging without errors
- [ ] Staging tests pass for 24h
- [ ] Performance impact measured (< 50ms latency added)
- [ ] Deployed to production
- [ ] Production monitoring shows no errors

## Cleanup
- [ ] All debug logging removed
- [ ] Temporary files deleted
- [ ] Branch merged to main
- [ ] Agent folder archived
```

**Rules:**
- Created at agent initialization
- Based on project standards + task-specific requirements
- Must be exhaustive (if it's not on this list, it's not required)
- Agent cannot close until all items checked

#### CONTEXT.md

**Purpose:** Centralized reference for all relevant information.

**Format:**
```markdown
# Context

## Relevant Files
- `src/api/middleware/auth.ts` - Current auth middleware
- `src/models/User.ts` - User model with auth fields
- `.env.example` - OAuth config template

## Key Functions
```typescript
// src/auth/jwt.ts:24
function verifyToken(token: string): User | null
```

## Important Snippets
```typescript
// Current JWT-based auth pattern
router.use(async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  const user = verifyToken(token);
  if (!user) return res.status(401).json({ error: 'Unauthorized' });
  req.user = user;
  next();
});
```

## Decisions Made
- **2024-01-10:** Using `passport-oauth2` instead of `oauth2-server` (simpler API)
- **2024-01-11:** Storing refresh tokens in Redis (not database) for faster access
- **2024-01-12:** Supporting only Google and GitHub initially (expand later)

## Related Work
- PR #234 - JWT authentication foundation
- Issue #189 - User request for OAuth support
- Slack thread: https://...

## External Resources
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Passport.js OAuth Guide](https://www.passportjs.org/tutorials/oauth/)
```

**Rules:**
- Link to files with line numbers when possible
- Keep snippets short (full code goes in actual files)
- Date-stamp all decisions
- Update when context changes

#### COMMS/ Directory

**Purpose:** Inter-agent communication for coordinated workflows.

**Message Format:**
```markdown
# Message to: {target-agent}
**From:** {source-agent}
**Date:** YYYY-MM-DD HH:MM
**Type:** Request | Response | Notification

## Request
[What you need from the other agent]

## Context
[Why this is needed]

## Acceptance Criteria
[How to verify the work is done]

## Urgency
- [ ] Blocking (I cannot proceed without this)
- [ ] High (Needed within 24h)
- [x] Normal (Needed within 3 days)
- [ ] Low (Nice to have)
```

**Examples:**

`.agents/wizard/COMMS/to-oauth-agent.md`:
```markdown
# Message to: oauth-implementation

**From:** wizard
**Date:** 2024-01-10 14:30
**Type:** Request

## Request
Please implement OAuth token refresh in the background worker.

## Context
Main auth flow is complete, but tokens expire after 1 hour. We need
automatic refresh to prevent user disruption.

## Acceptance Criteria
- Refresh tokens 5 minutes before expiration
- Handle refresh failures gracefully (log out user)
- No user-facing impact

## Urgency
- [x] Blocking
```

**Processing:**
1. Target agent reads `COMMS/` directory
2. Target agent creates `to-{source-agent}.md` with response
3. Target agent renames request to `{filename}.processed`
4. Source agent reads response

#### session/ Directory

**Purpose:** Terminal session state for agent's workspace.

**Files:**
- `session.json` - Metadata (name, CWD, creation date, etc.)
- `history.txt` - Command history
- `env.json` - Agent-specific environment variables

**Example session.json:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "OAuth Implementation",
  "workingDirectory": "/Users/dev/myproject",
  "createdAt": "2024-01-10T14:00:00Z",
  "lastActiveAt": "2024-01-12T09:30:00Z",
  "status": "active",
  "agentType": "specialist",
  "parentAgent": "wizard"
}
```

**Integration with Existing Session Model:**

The agent session extends the current `Session` struct:

```swift
// Current Session struct remains the same
struct Session: Identifiable, Codable {
    let id: UUID
    var name: String
    var workingDirectory: URL
    var createdAt: Date
    var lastActiveAt: Date
    var status: SessionStatus
}

// New Agent struct builds on Session
struct Agent: Identifiable, Codable {
    let id: UUID
    var name: String
    var agentDirectory: URL           // .agents/{agent-name}/
    var session: Session              // Embedded session
    var agentType: AgentType
    var parentAgentId: UUID?          // For hierarchical agents

    enum AgentType {
        case wizard                   // Top-level orchestrator
        case specialist               // Focused task agent
    }
}
```

---

## Agent Lifecycle

### 1. Creation

**User-Initiated:**
```
User: "Implement OAuth for the API"
```

**System Actions:**
1. Create `.agents/oauth-implementation/` directory
2. Generate `GOAL.md` from user request
3. Create empty `RESEARCH.md`, `PLAN.md`, `TODO.md`, `DONE.md`, `CONTEXT.md`
4. Initialize `session/` with new session
5. Create `COMMS/` directory
6. Git commit: "Create agent: oauth-implementation"

**Agent Actions:**
1. Read existing codebase context
2. Populate `RESEARCH.md` with findings
3. Create `PLAN.md` based on research
4. Generate `TODO.md` from plan
5. Define `DONE.md` checklist

### 2. Execution

**Agent Work Loop:**
```
while not done():
    1. Check TODO.md for next task
    2. Execute task (read code, write code, run tests)
    3. Update TODO.md with progress
    4. Check COMMS/ for messages
    5. Respond to messages if needed
    6. Commit incremental work
    7. Update RESEARCH.md with new findings
    8. Adjust PLAN.md if needed
```

**Progress Tracking:**
- Agent commits after each meaningful change
- Commit messages reference TODO items
- `.claude/implementation/progress.md` logs major milestones
- Git log provides complete audit trail

### 3. Communication

**Requesting Help from Another Agent:**
```
1. Write COMMS/to-{target-agent}.md
2. Wait for COMMS/from-{target-agent}.md
3. Continue work with response context
```

**Responding to Requests:**
```
1. Poll COMMS/ directory for new messages
2. Read message, understand request
3. Execute work
4. Write COMMS/to-{source-agent}.md with results
5. Mark original message as .processed
```

### 4. Completion

**Agent Self-Check:**
```
1. Read DONE.md
2. Verify all checkboxes are complete
3. Run final validation (tests, linting, etc.)
4. If all pass:
   - Update TODO.md with "✓ All tasks complete"
   - Notify parent agent (if hierarchical)
   - Wait for user approval
```

**User Approval:**
```
User: "Check agent oauth-implementation"
→ System shows DONE.md with all items checked
→ User reviews git log, tests, documentation
User: "Approve and close agent"
→ Agent commits final state
→ Agent moves to .agents/.archive/oauth-implementation/
→ Session is terminated
```

### 5. Archival

**Post-Completion:**
- Agent folder moved to `.agents/.archive/{agent-name}/`
- Session terminated and removed from active sessions
- All files preserved in git history
- README.md updated with completion date and outcome

**Future Reference:**
- Archived agents remain in git history
- Can be referenced by future agents
- Useful for understanding past decisions

---

## Hierarchical Agents

### Wizard Agent (Orchestrator)

**Responsibilities:**
- Break down complex tasks into sub-tasks
- Spawn specialist agents for each sub-task
- Coordinate work between specialists
- Integrate results
- Ensure consistency across agents

**Example Workflow:**

```
User: "Migrate frontend from JavaScript to TypeScript"
```

**Wizard Agent Creates:**

```
.agents/
├── wizard/                       # Orchestrator
│   ├── GOAL.md                  # "Migrate entire frontend to TypeScript"
│   ├── PLAN.md                  # High-level migration strategy
│   ├── TODO.md                  # Track sub-agent progress
│   ├── COMMS/
│   │   ├── to-components.md     # "Convert React components"
│   │   ├── to-types.md          # "Create type definitions"
│   │   └── to-tests.md          # "Update test files"
│   └── session/
│
├── migrate-components/           # Specialist for UI components
│   ├── GOAL.md                  # "Convert all .jsx to .tsx"
│   ├── TODO.md                  # List of components to convert
│   └── ...
│
├── create-types/                 # Specialist for type system
│   ├── GOAL.md                  # "Create TypeScript interfaces"
│   ├── TODO.md                  # List of types to define
│   └── ...
│
└── update-tests/                 # Specialist for test migration
    ├── GOAL.md                  # "Migrate Jest tests to TS"
    ├── TODO.md                  # List of test files
    └── ...
```

**Coordination Flow:**

1. **Wizard creates specialists:**
   ```bash
   git commit -m "wizard: Spawn specialist agents for TS migration"
   ```

2. **Wizard sends initial tasks:**
   ```
   .agents/wizard/COMMS/to-components.md: "Convert Button.jsx first"
   .agents/wizard/COMMS/to-types.md: "Define ButtonProps interface"
   ```

3. **Specialists work independently:**
   ```bash
   # migrate-components agent
   git commit -m "Convert Button.jsx to Button.tsx"

   # create-types agent
   git commit -m "Add ButtonProps interface"
   ```

4. **Specialists report progress:**
   ```
   .agents/migrate-components/COMMS/to-wizard.md: "Button complete, moving to Input"
   ```

5. **Wizard monitors and adjusts:**
   ```
   wizard TODO.md:
   - [x] Button component
   - [~] Input component (in progress)
   - [ ] Form component
   ```

6. **Wizard integrates results:**
   ```bash
   git commit -m "wizard: Integrate all specialist work"
   ```

7. **Wizard closes when done:**
   ```
   wizard DONE.md: ✓ All checkboxes complete
   → Archive all agents
   ```

### Specialist Agent

**Characteristics:**
- Focused on single domain or task
- No sub-agents (leaf nodes in tree)
- Reports progress to parent wizard
- Works autonomously within scope

**Communication Protocol:**

```
Wizard → Specialist: "Here's what I need"
Specialist → Wizard: "I'm working on it"
Specialist → Wizard: "Blocked on X"
Wizard → Specialist: "Here's how to unblock"
Specialist → Wizard: "Task complete"
```

---

## Integration with Shebang

### UI Integration

**Session Panel Enhancement:**

Current session panel shows:
```
Sessions:
  ○ Session 1 (~/projects/myapp)
  ● Session 2 (~/projects/other) [active]
```

Enhanced with agents:
```
Sessions & Agents:
  ○ Session 1 (~/projects/myapp)
  ⊕ Agent: oauth-implementation (~/projects/myapp/.agents/oauth-implementation)
     ├─ Status: In Progress (12/20 tasks done)
     └─ Last active: 5 minutes ago
  ⊕ Agent: wizard (~/projects/myapp/.agents/wizard)
     ├─ Status: Coordinating
     ├─ Sub-agents: 3 active
     └─ Last active: 2 minutes ago
  ● Session 2 (~/projects/other) [active]
```

**Agent Details View:**

When user clicks on an agent in the session panel:
```
┌─────────────────────────────────────────────────────────┐
│ Agent: OAuth Implementation                             │
├─────────────────────────────────────────────────────────┤
│ Goal: Implement OAuth 2.0 for REST API                 │
│ Status: In Progress (60% complete)                      │
│ Created: 2 days ago                                      │
│ Last commit: 5 minutes ago                               │
├─────────────────────────────────────────────────────────┤
│ Progress:                                                │
│  ✓ Research completed                                   │
│  ✓ Plan finalized                                       │
│  ~ Implementation (12/20 tasks)                         │
│    ✓ OAuthClient class                                  │
│    ✓ Token exchange                                     │
│    ○ Token refresh (in progress)                        │
│    ○ Middleware integration                             │
│    ○ Testing                                            │
│  ○ Documentation                                        │
│  ○ Deployment                                           │
├─────────────────────────────────────────────────────────┤
│ [View Goal] [View Plan] [View TODO] [Check Status]     │
│ [Send Message] [Pause Agent] [Archive Agent]           │
└─────────────────────────────────────────────────────────┘
```

### Command Bar Integration

**Creating Agents:**
```
> create agent "implement OAuth"
→ Creates .agents/oauth-implementation/ with scaffolding

> create wizard "migrate to TypeScript"
→ Creates wizard agent that will spawn specialists
```

**Managing Agents:**
```
> show agents
→ Lists all active agents with status

> agent status oauth-implementation
→ Shows detailed status of specific agent

> agent todo oauth-implementation
→ Opens TODO.md in editor

> send to oauth-implementation "prioritize GitHub provider"
→ Creates message in agent's COMMS/ directory
```

**Monitoring:**
```
> agent progress
→ Shows git log for all agent commits

> agent diff oauth-implementation
→ Shows what agent has changed since creation
```

### Git Integration

**Automatic Commits:**

Agents commit frequently with structured messages:
```
[agent:oauth-implementation] Implement token exchange method

- Add exchangeCodeForToken() to OAuthClient
- Handle errors for invalid authorization codes
- Update TODO.md (3 tasks completed)

Refs: .agents/oauth-implementation/TODO.md
```

**Branch Strategy:**

Option 1: **Agent Per Branch**
```
main
  └─ agent/oauth-implementation
       └─ agent/wizard
            ├─ agent/migrate-components
            ├─ agent/create-types
            └─ agent/update-tests
```

Option 2: **All Agents on Feature Branch**
```
main
  └─ feature/oauth-implementation
       ├─ .agents/oauth-implementation/
       └─ [commits from agent]
```

**Recommended:** Option 2 (simpler, cleaner git history)

**Git Hooks:**

Pre-commit hook enforces agent file structure:
```python
# .git/hooks/pre-commit
if files_changed_in(".agents/"):
    verify_agent_structure()
    verify_todo_format()
    verify_goal_exists()
```

---

## Implementation Roadmap

### Phase 1: Basic Agent Structure

**Goal:** Enable single-agent workflows

**Tasks:**
1. Create `.agents/` directory structure
2. Implement agent scaffolding (GOAL.md, RESEARCH.md, etc.)
3. Extend `Session` model to support agents
4. Update session persistence to include agent metadata
5. Add "Create Agent" command to CLI
6. Basic agent status display in session panel

**Success Criteria:**
- User can create an agent
- Agent has session + context files
- Agent shows in session panel
- Agent state persists across app restart

### Phase 2: Agent-Session Integration

**Goal:** Agents work like enhanced sessions

**Tasks:**
1. Agent working directory syncs with session CWD
2. Agent command history saved to `session/history.txt`
3. Agent can execute shell commands
4. Agent TODO.md updates automatically as work progresses
5. Agent commits are automatic with structured messages

**Success Criteria:**
- Agent feels like a smart session
- All work is tracked in git
- Progress is visible in UI

### Phase 3: Inter-Agent Communication

**Goal:** Enable multi-agent workflows

**Tasks:**
1. Implement COMMS/ directory polling
2. Create message format specification
3. Add "Send to Agent" command
4. Add COMMS/ message viewer in UI
5. Agent-to-agent request/response cycle

**Success Criteria:**
- One agent can request help from another
- Messages are tracked and processed
- Communication visible in UI

### Phase 4: Hierarchical Agents (Wizard)

**Goal:** Enable orchestrated multi-agent workflows

**Tasks:**
1. Implement wizard agent type
2. Wizard can spawn specialist agents
3. Wizard can coordinate multiple specialists
4. Wizard UI shows sub-agent tree
5. Wizard integrates specialist results

**Success Criteria:**
- User can create a wizard
- Wizard spawns specialists autonomously
- Wizard coordinates work
- All results integrate cleanly

### Phase 5: Advanced Features

**Goal:** Production-ready agent system

**Tasks:**
1. Agent templates (OAuth agent, refactor agent, etc.)
2. Agent pausing/resuming
3. Agent archival system
4. Agent analytics (time spent, commits made, etc.)
5. Agent debugging tools

**Success Criteria:**
- Agents are reliable for real work
- Easy to create, monitor, and manage
- Full git integration

---

## Open Questions

### 1. Agent Persistence

**Question:** Should agent state live in git or in a database?

**Options:**
- **Git-based (recommended):** All files in `.agents/`, versioned in git
  - Pros: Single source of truth, auditable, portable
  - Cons: Large repos if many agents

- **Hybrid:** Metadata in DB, artifacts in git
  - Pros: Fast queries, smaller repo
  - Cons: Two sources of truth, harder to sync

**Recommendation:** Git-based. Aligns with Shebang philosophy.

### 2. Agent Naming

**Question:** How are agents named?

**Options:**
- User-provided names (e.g., "oauth-implementation")
- Auto-generated from goal (e.g., "implement-oauth-20-for-rest-api")
- UUIDs with aliases (e.g., "agent-550e8400" aliased to "oauth")

**Recommendation:** User-provided names (kebab-case), with auto-generation as fallback.

### 3. Session vs Agent

**Question:** Are agents a superset of sessions, or separate concepts?

**Options:**
- **Agents extend sessions** (every agent HAS a session)
- **Agents replace sessions** (sessions are deprecated)
- **Parallel concepts** (sessions for quick work, agents for projects)

**Recommendation:** Agents extend sessions. A session is a terminal tab; an agent is a session plus context.

### 4. Agent Termination

**Question:** What happens when an agent finishes?

**Options:**
- **Archive:** Move to `.agents/.archive/`, preserve in git
- **Delete:** Remove from filesystem (still in git history)
- **Keep active:** Mark as "completed" but leave in place

**Recommendation:** Archive to `.agents/.archive/`. Preserves context, keeps workspace clean.

### 5. Inter-Agent Coordination

**Question:** How do agents avoid conflicts when modifying the same files?

**Options:**
- **No protection:** Agents can conflict (resolved via git)
- **File locking:** Agents declare file ownership
- **Coordination protocol:** Agents request permission before modifying shared files

**Recommendation:** No protection initially. Git handles conflicts. Add coordination protocol in Phase 5 if needed.

---

## Security Considerations

### Protected Files

Agents must never modify:
- `.git/` directory
- `.env` files
- Private keys
- Credentials

Use existing guardrails system to enforce.

### Secret Detection

All agent commits pass through secret detection:
- API keys
- Tokens
- Connection strings
- Passwords

Violations block the commit.

### Code Quality

All agent code passes quality checks:
- Linting (ruff, ESLint)
- Type checking (mypy, TypeScript)
- Complexity limits
- Test coverage thresholds

Violations block the commit or create TODO items.

---

## Performance Considerations

### Git Repo Size

**Problem:** Many agents = many commits = large repo

**Solutions:**
1. Squash agent commits when archiving
2. Use git worktrees for agent isolation
3. Periodic cleanup of archived agents (user consent)

### File System Polling

**Problem:** Polling COMMS/ directories can be expensive

**Solutions:**
1. Use file system watchers (FSEvents on macOS)
2. Poll only active agents
3. Rate-limit polling (every 5 seconds, not every 100ms)

### UI Responsiveness

**Problem:** Many agents could slow down session panel

**Solutions:**
1. Lazy-load agent details
2. Virtual scrolling for large agent lists
3. Cache agent status computations

---

## Future Enhancements

### Agent Templates

Pre-built agent templates for common tasks:
- **oauth-agent:** Implement OAuth authentication
- **refactor-agent:** Code refactoring tasks
- **test-agent:** Write tests for existing code
- **docs-agent:** Generate documentation
- **migration-agent:** Migrate between frameworks/languages

Usage:
```
> create agent from template oauth
→ Scaffolds OAuth agent with pre-filled GOAL, RESEARCH, PLAN
```

### Agent Metrics

Track agent productivity:
- Time to completion
- Number of commits
- Lines of code changed
- Test coverage added
- Bugs introduced vs bugs fixed

Display in UI:
```
Agent Metrics:
  Duration: 2 days 4 hours
  Commits: 47
  Files changed: 23
  Tests added: 18
  Coverage: +12%
  Bugs: 0 introduced
```

### Agent Collaboration Tools

Enhanced coordination:
- Real-time agent status dashboard
- Dependency graph visualization
- Conflict detection and resolution
- Shared context between related agents

### Agent Learning

Agents learn from past work:
- Analyze archived agents for patterns
- Suggest improvements based on previous mistakes
- Reuse successful strategies

Example:
```
Agent: "I notice the last OAuth agent had issues with token refresh.
        I'll add extra error handling proactively."
```

---

## Conclusion

Agents transform Shebang from a smart terminal into an **autonomous development environment**. By combining:

- Terminal sessions (execution context)
- Structured workflows (research → plan → implement)
- Git integration (auditable, reproducible)
- Multi-agent coordination (hierarchical workflows)
- File-based communication (transparent, persistent)

...we create a system where complex development tasks can run autonomously, with full transparency and human oversight.

The key insight: **Agents are folders, not files**. Everything an agent needs—goals, research, plans, progress, communication—lives in the repository. Git is the audit log. The terminal is the execution engine. And Claude Code is the intelligence layer.

This is Shebang's vision realized: **60 years of programming knowledge, available to everyone, with the work tracked and reproducible in git.**

---

## Appendix: Example Agent Walkthrough

### Scenario: Implement OAuth Authentication

**Step 1: User creates agent**
```
User: "Create agent to implement OAuth for the API"
```

**System:**
```bash
mkdir -p .agents/oauth-implementation/{COMMS,session,artifacts}
touch .agents/oauth-implementation/{GOAL,RESEARCH,PLAN,TODO,DONE,CONTEXT}.md
git add .agents/oauth-implementation/
git commit -m "Create agent: oauth-implementation"
```

**GOAL.md:**
```markdown
# Agent Goal: Implement OAuth 2.0 Authentication

## Primary Objective
Add OAuth 2.0 authentication to the REST API, supporting Google and GitHub providers.

## Success Criteria
- [ ] Users can log in with Google
- [ ] Users can log in with GitHub
- [ ] Tokens refresh automatically
- [ ] All tests pass
- [ ] Documentation complete

## Constraints
- Must integrate with existing JWT auth system
- Cannot break existing username/password login
- Must complete within 1 week
```

**Step 2: Agent researches**

Agent reads existing auth code, explores OAuth libraries, documents findings in `RESEARCH.md`.

```markdown
# Research Notes

## Current Auth System
- JWT-based with `src/auth/jwt.ts`
- User model in `src/models/User.ts`
- Middleware in `src/api/middleware/auth.ts`

## Libraries Evaluated
| Library | Pros | Cons | Decision |
|---------|------|------|----------|
| passport-oauth2 | Simple, popular | Requires Express | **Selected** |
| oauth2-server | Full-featured | Complex | Rejected |

## Integration Strategy
1. Add OAuth routes alongside existing /login
2. Store OAuth tokens in Redis (fast access)
3. Fallback to JWT for non-OAuth users
```

**Step 3: Agent plans**

Agent creates detailed implementation plan in `PLAN.md`.

```markdown
# Implementation Plan

## Modules to Create
1. `src/auth/oauth/oauth-client.ts`
   - createOAuthClient(provider)
   - exchangeCodeForToken(code)
   - refreshToken(refreshToken)

2. `src/auth/oauth/providers/`
   - google.provider.ts
   - github.provider.ts

## Changes to Existing Code
- `src/api/routes/auth.ts` - Add /oauth/google, /oauth/github
- `src/models/User.ts` - Add oauthProvider field

## Test Strategy
- Unit tests for each OAuth function
- Integration test for full login flow
- Manual test with real Google/GitHub apps
```

**Step 4: Agent implements**

Agent executes plan, updating `TODO.md` as tasks complete.

```bash
# Agent commits as work progresses
git commit -m "[agent:oauth-implementation] Create OAuthClient class"
git commit -m "[agent:oauth-implementation] Add Google provider"
git commit -m "[agent:oauth-implementation] Add GitHub provider"
git commit -m "[agent:oauth-implementation] Integrate with auth middleware"
git commit -m "[agent:oauth-implementation] Write unit tests"
git commit -m "[agent:oauth-implementation] Update documentation"
```

**TODO.md updates:**
```markdown
# Task List

## Completed
- [x] Create OAuthClient class
- [x] Add Google provider
- [x] Add GitHub provider
- [x] Integrate with auth middleware
- [x] Write unit tests
- [x] Update documentation

## In Progress
- [ ] Deploy to staging

## Pending
- [ ] Monitor staging for 24h
- [ ] Deploy to production
```

**Step 5: Agent verifies completion**

Agent checks `DONE.md`:

```markdown
# Definition of Done

## Functional Requirements
- [x] Users can log in with Google
- [x] Users can log in with GitHub
- [x] Tokens refresh automatically
- [x] Invalid tokens return 401
- [x] All tests pass

## Code Quality
- [x] ESLint passing
- [x] TypeScript strict mode
- [x] Complexity ≤ 10
- [x] No duplication

## Testing
- [x] Unit test coverage ≥ 80%
- [x] Integration tests pass
- [x] Manual testing complete
- [x] Security review done

## Documentation
- [x] API docs updated
- [x] README updated
- [x] Environment vars documented

## Deployment
- [x] Staging deployed
- [x] Staging stable 24h
- [ ] Production deployed  ← Waiting on this

## Cleanup
- [ ] Debug logging removed
- [ ] Agent archived
```

**Step 6: User approves and closes**

```
User: "Check agent oauth-implementation"
→ System shows DONE.md with 1 item remaining
User: "Deploy to production and close agent"
→ Agent deploys, completes final checklist
→ Agent archives itself to .agents/.archive/oauth-implementation/
```

**Final git log:**
```
[agent:oauth-implementation] Deploy to production
[agent:oauth-implementation] Remove debug logging
[agent:oauth-implementation] Archive agent - work complete

Agent oauth-implementation completed successfully.
Duration: 3 days
Commits: 23
Files changed: 12
Tests added: 18
```

---

**This is the future of development: autonomous, transparent, and reproducible.**
