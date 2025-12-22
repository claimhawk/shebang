# Agent Example: OAuth Authentication Modernization

This directory contains a **complete working example** of the Shebang agent system, demonstrating hierarchical multi-agent workflows.

## What This Example Shows

This is a realistic example of how agents would implement a feature: "Add OAuth authentication and modernize the login UI."

**Scenario:**
- User requests OAuth support for Google and GitHub
- System creates a wizard agent to orchestrate the work
- Wizard spawns two specialist agents:
  - `oauth-implementation` - Backend OAuth integration
  - `ui-migration` - Frontend login UI modernization
- Specialists work autonomously and report progress
- Wizard coordinates, integrates, and deploys

## Directory Structure

```
agent-example/
├── README.md                    # This file
├── AGENT_HIERARCHY.md           # Inheritance model explanation
│
└── .agents/                     # Agent workspace
    ├── README.md                # Agent system overview
    │
    ├── wizard/                  # Orchestrator agent
    │   ├── GOAL.md              # Modernize auth system
    │   ├── RESEARCH.md          # High-level analysis
    │   ├── PLAN.md              # Multi-agent strategy
    │   ├── TODO.md              # Specialist coordination
    │   ├── DONE.md              # Project completion criteria
    │   ├── CONTEXT.md           # Project-wide context
    │   ├── COMMS/               # Messages to/from specialists
    │   │   ├── to-oauth-implementation.md
    │   │   └── from-oauth-implementation.md
    │   └── session/             # Wizard session state
    │       ├── session.json
    │       └── history.txt
    │
    ├── oauth-implementation/    # Backend specialist
    │   ├── GOAL.md              # Implement OAuth backend
    │   ├── RESEARCH.md          # OAuth technical research
    │   ├── PLAN.md              # Module-level implementation
    │   ├── TODO.md              # Granular task tracking
    │   ├── DONE.md              # Backend completion criteria
    │   ├── CONTEXT.md           # Backend-specific context
    │   ├── COMMS/               # Messages to/from wizard
    │   └── session/             # Specialist session state
    │       └── session.json
    │
    └── ui-migration/            # Frontend specialist (stub)
        └── ...                  # Similar structure to oauth-implementation
```

## How to Explore

### 1. Start with the Wizard

Read in this order to understand the orchestration layer:

1. **`.agents/wizard/GOAL.md`** - High-level project objective
2. **`.agents/wizard/RESEARCH.md`** - How the wizard analyzed the problem
3. **`.agents/wizard/PLAN.md`** - How the wizard decomposed work
4. **`.agents/wizard/TODO.md`** - How the wizard tracks specialist progress

### 2. Follow a Specialist

Read in this order to see focused execution:

1. **`.agents/oauth-implementation/GOAL.md`** - Focused backend objective
2. **`.agents/oauth-implementation/RESEARCH.md`** - Deep technical investigation
3. **`.agents/oauth-implementation/PLAN.md`** - Detailed implementation strategy
4. **`.agents/oauth-implementation/TODO.md`** - Task-level granularity
5. **`.agents/oauth-implementation/CONTEXT.md`** - All relevant code snippets

### 3. Observe Communication

Read the COMMS files to see agent coordination:

1. **`.agents/wizard/COMMS/to-oauth-implementation.md`** - Task assignment from wizard
2. **`.agents/oauth-implementation/COMMS/from-oauth-implementation.md`** - Progress report to wizard

### 4. Understand Inheritance

Read **`AGENT_HIERARCHY.md`** to understand:
- How wizard and specialist agents inherit from base structure
- What makes them different (behavior, not structure)
- Communication protocols
- Real-world analogies

## Key Concepts Demonstrated

### Agent as Folder
Every agent is a **complete workspace** with all context in files:
- Goals, research, plans (design artifacts)
- Todo lists, progress tracking (execution artifacts)
- Communication logs (coordination artifacts)
- Session state (terminal artifacts)

### Hierarchical Agents
- **Wizard** orchestrates multiple specialists
- **Specialists** focus on single domains
- Communication via file-based COMMS
- Git tracks all work and decisions

### File-Based Context
Everything is in files, nothing is ephemeral:
- AI agents read files to understand what to do
- AI agents write files to record what they did
- Humans read files to understand AI reasoning
- Git versions all decisions and progress

### Research → Plan → Implement
Every agent follows the three-phase protocol:
1. **Research** - Gather context, analyze options
2. **Plan** - Define strategy, break down work
3. **Implement** - Execute tasks, track progress

## Real-World Parallels

| Agent System | Software Team |
|--------------|---------------|
| Wizard agent | Project manager |
| Specialist agent | Software engineer |
| GOAL.md | Project charter |
| RESEARCH.md | Design doc |
| PLAN.md | Technical spec |
| TODO.md | JIRA board |
| DONE.md | Definition of done |
| COMMS/ | Slack messages |
| Git commits | Daily standups |

## Benefits of This Approach

### Transparency
- Every decision documented
- Every trade-off explained
- Every change committed to git

### Auditability
- Full history in git log
- Understand why AI made choices
- Reproduce results from history

### Coordination
- Multiple agents work in parallel
- Clear communication protocol
- No conflicts (wizard mediates)

### Context Preservation
- Agents can pause and resume
- New agents learn from archived agents
- Nothing lost between sessions

## Try It Yourself

To use this pattern in your own project:

1. Create `.agents/` directory
2. For single-task work: Create one specialist agent
3. For complex work: Create wizard + specialists
4. Follow the file structure from this example
5. Use the templates in `/agent/templates/`

## Related Documentation

- **Design Document:** `/docs/design/AGENTS.md` - Full 1300+ line specification
- **Base Agent Protocol:** `/agent/system.md` - Workflow template for all agents
- **Philosophy:** `/PHILOSOPHY.md` - Why we build this way
- **Example Project:** `/agent/examples/python-example/` - Project with agent integration

## Status of This Example

This is a **realistic example** showing what agent workflows would look like:
- File structure is complete ✅
- Content is realistic (based on actual OAuth implementation) ✅
- Shows mid-workflow state (not started, not finished) ✅
- Demonstrates communication patterns ✅
- Illustrates decision-making and context ✅

This is **not executable code** - it's documentation showing agent structure and behavior.

## Questions?

Read the files in order:
1. `.agents/README.md` - Agent system overview
2. `AGENT_HIERARCHY.md` - Inheritance model
3. `.agents/wizard/GOAL.md` - Start of wizard workflow
4. `.agents/oauth-implementation/GOAL.md` - Start of specialist workflow

Then explore the other files to see how agents think, plan, and work.

---

**This example demonstrates the future of autonomous development: transparent, auditable, and reproducible AI-assisted software engineering.**
