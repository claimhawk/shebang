# Agent Hierarchy and Inheritance Model

This document explains how agents inherit structure and behavior in the Shebang agent system.

## Base Agent Structure

All agents, regardless of type, inherit from the same base structure:

```
BaseAgent/
├── GOAL.md           # What to achieve
├── RESEARCH.md       # Investigation
├── PLAN.md           # Strategy
├── TODO.md           # Task tracking
├── DONE.md           # Completion criteria
├── CONTEXT.md        # Relevant information
├── COMMS/            # Communication
│   ├── to-{agent}.md
│   └── from-{agent}.md
├── session/          # Terminal session
│   ├── session.json
│   └── history.txt
└── artifacts/        # Generated files
```

This structure is **universal** - every agent has these files. The difference between agent types is in **behavior**, not structure.

## Agent Type Hierarchy

```
                    ┌──────────────┐
                    │  BaseAgent   │
                    │              │
                    │ Structure:   │
                    │ - GOAL.md    │
                    │ - RESEARCH   │
                    │ - PLAN       │
                    │ - TODO       │
                    │ - DONE       │
                    │ - CONTEXT    │
                    │ - COMMS/     │
                    │ - session/   │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
     ┌────────▼────────┐       ┌───────▼────────┐
     │  WizardAgent    │       │ SpecialistAgent│
     │                 │       │                │
     │ Behavior:       │       │ Behavior:      │
     │ - Orchestrate   │       │ - Execute      │
     │ - Spawn agents  │       │ - Focus deeply │
     │ - Coordinate    │       │ - Report up    │
     │ - Integrate     │       │ - Single task  │
     └─────────────────┘       └────────────────┘
```

## Inheritance by Example

### Wizard Agent: auth-modernization

**Inherited Structure:**
```
.agents/wizard/
├── GOAL.md           ✓ From BaseAgent
├── RESEARCH.md       ✓ From BaseAgent
├── PLAN.md           ✓ From BaseAgent
├── TODO.md           ✓ From BaseAgent
├── DONE.md           ✓ From BaseAgent
├── CONTEXT.md        ✓ From BaseAgent
├── COMMS/            ✓ From BaseAgent
├── session/          ✓ From BaseAgent
└── artifacts/        ✓ From BaseAgent
```

**Wizard-Specific Behavior:**

**GOAL.md** includes:
- High-level objective (OAuth + UI modernization)
- Success criteria for entire project
- **Strategy section** (how to coordinate specialists)

**PLAN.md** includes:
- Specialist agent creation plan
- Coordination protocol
- Integration strategy
- **Phase-based timeline** with specialist dependencies

**TODO.md** tracks:
- Specialist creation
- Inter-agent coordination
- Integration testing
- **Specialist progress** (not detailed work)

**COMMS/** contains:
- Messages **TO** specialists (task assignments)
- Messages **FROM** specialists (progress updates)
- **Coordination messages** (unblocking, clarifications)

**session/session.json** includes:
```json
{
  "agentType": "wizard",
  "parentAgent": null,
  "specialists": [
    {"id": "oauth-implementation", "status": "in_progress"},
    {"id": "ui-migration", "status": "blocked"}
  ]
}
```

### Specialist Agent: oauth-implementation

**Inherited Structure:**
```
.agents/oauth-implementation/
├── GOAL.md           ✓ From BaseAgent
├── RESEARCH.md       ✓ From BaseAgent
├── PLAN.md           ✓ From BaseAgent
├── TODO.md           ✓ From BaseAgent
├── DONE.md           ✓ From BaseAgent
├── CONTEXT.md        ✓ From BaseAgent
├── COMMS/            ✓ From BaseAgent
├── session/          ✓ From BaseAgent
└── artifacts/        ✓ From BaseAgent
```

**Specialist-Specific Behavior:**

**GOAL.md** includes:
- Focused objective (OAuth backend only)
- **Parent agent reference** (wizard)
- **Downstream dependents** (ui-migration blocked on this)

**RESEARCH.md** includes:
- Deep technical investigation
- Library comparisons
- **Specific implementation details** (not high-level strategy)

**PLAN.md** includes:
- Detailed module breakdown
- Function signatures
- **Concrete implementation steps** (not coordination)

**TODO.md** tracks:
- Granular development tasks
- Specific files to create/modify
- **Detailed progress** (every function, every test)

**COMMS/** contains:
- Messages **FROM** wizard (task assignments, unblocking)
- Messages **TO** wizard (progress, blockers, completion)
- **No cross-specialist messages** (go through wizard)

**session/session.json** includes:
```json
{
  "agentType": "specialist",
  "parentAgent": "wizard",
  "specialists": null
}
```

## Key Differences

| Aspect | Wizard | Specialist |
|--------|--------|------------|
| **Scope** | Broad, multi-domain | Narrow, single-domain |
| **Depth** | Strategic, high-level | Tactical, deep technical |
| **Coordination** | Spawns and manages agents | Reports to parent |
| **GOAL.md** | "Modernize auth system" | "Implement OAuth backend" |
| **PLAN.md** | Agent creation + integration | Module implementation |
| **TODO.md** | Specialist progress | Task-level granularity |
| **COMMS/** | Many to/from specialists | Only to/from wizard |
| **Can spawn agents?** | Yes | No |
| **Session** | `specialists: [...]` array | `parentAgent: "wizard"` |

## Communication Flow

```
User Request
    ↓
┌───────────────┐
│ Wizard Agent  │
│               │
│ Analyzes      │
│ Creates plan  │
│ Spawns agents │
└───────┬───────┘
        │
        │ Creates + assigns tasks via COMMS
        │
        ├─────────────────┬─────────────────┐
        ↓                 ↓                 ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Specialist 1 │  │ Specialist 2 │  │ Specialist 3 │
│              │  │              │  │              │
│ Works        │  │ Works        │  │ Works        │
│ Reports via  │  │ Reports via  │  │ Reports via  │
│ COMMS        │  │ COMMS        │  │ COMMS        │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │ Progress updates via COMMS        │
       │                 │                 │
       └─────────────────┴─────────────────┘
                         │
                    ┌────▼─────┐
                    │ Wizard   │
                    │          │
                    │ Monitors │
                    │ Integrates│
                    └──────────┘
```

**Rules:**
1. Specialists **never** communicate directly with each other
2. All cross-agent coordination goes **through wizard**
3. Wizard is the **single source of truth** for project state
4. Specialists are **autonomous** within their scope

## File Inheritance Details

### Same Across All Agents

**GOAL.md format:**
```markdown
# Agent Goal: {Title}

## Primary Objective
[One sentence]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Constraints
[Limits]

## Context
[Why needed]
```

Every agent uses this format. Wizard has broader objectives, specialists have narrower ones.

### Specialized by Agent Type

**GOAL.md additions:**

Wizard adds:
```markdown
## Strategy
This wizard will coordinate:
1. specialist-1 - Description
2. specialist-2 - Description
```

Specialist adds:
```markdown
## Parent Agent
- **Wizard:** {wizard-name}
- **Communication:** Via COMMS
- **Dependencies:** {what blocks this agent}
- **Dependents:** {what this agent blocks}
```

**session/session.json:**

Wizard:
```json
{
  "agentType": "wizard",
  "parentAgent": null,
  "specialists": [...]
}
```

Specialist:
```json
{
  "agentType": "specialist",
  "parentAgent": "wizard-name",
  "specialists": null
}
```

## Code Perspective

If agents were TypeScript classes:

```typescript
// Base structure (all agents have this)
interface BaseAgent {
  files: {
    goal: GoalFile;
    research: ResearchFile;
    plan: PlanFile;
    todo: TodoFile;
    done: DoneFile;
    context: ContextFile;
  };
  directories: {
    comms: CommsDirectory;
    session: SessionDirectory;
    artifacts: ArtifactsDirectory;
  };
}

// Wizard-specific behavior
interface WizardAgent extends BaseAgent {
  session: {
    agentType: "wizard";
    parentAgent: null;
    specialists: SpecialistReference[];
  };

  behavior: {
    spawnSpecialist(goal: string): SpecialistAgent;
    coordinateWork(): void;
    integrateResults(): void;
  };
}

// Specialist-specific behavior
interface SpecialistAgent extends BaseAgent {
  session: {
    agentType: "specialist";
    parentAgent: string;
    specialists: null;
  };

  behavior: {
    executeTask(): void;
    reportProgress(): void;
    requestHelp(): void;
  };
}
```

## Practical Implications

### When creating a new agent:

**For Wizard:**
1. Create base structure (GOAL, RESEARCH, etc.)
2. In GOAL.md: Define high-level objective + specialist strategy
3. In PLAN.md: Define agent creation plan
4. In session.json: Set `agentType: "wizard"`, init `specialists: []`
5. Spawn specialists by creating their directories
6. Coordinate via COMMS

**For Specialist:**
1. Created by wizard (or user for single-agent tasks)
2. Create base structure (GOAL, RESEARCH, etc.)
3. In GOAL.md: Define focused objective + parent reference
4. In PLAN.md: Define detailed implementation
5. In session.json: Set `agentType: "specialist"`, `parentAgent: "wizard"`
6. Report progress via COMMS to parent

### During execution:

**Wizard:**
- Monitors specialist COMMS and TODO.md
- Sends coordination messages
- Does high-level work (integration, docs, deployment)
- Doesn't write specialist code directly

**Specialist:**
- Executes granular tasks
- Updates TODO.md frequently
- Sends progress updates to wizard
- Asks wizard for help when blocked

## Real-World Analogy

**Wizard = Project Manager**
- Sees the big picture
- Assigns work to team members
- Coordinates dependencies
- Integrates deliverables
- Doesn't write code directly (usually)

**Specialist = Software Engineer**
- Focuses on specific task
- Deep technical work
- Reports to PM
- Asks for help when blocked
- Doesn't coordinate with other engineers directly

**Same office (repo), same furniture (file structure), different roles (behavior).**

## Summary

**Agent inheritance is about behavior, not structure.**

- **Structure:** All agents have GOAL, RESEARCH, PLAN, TODO, DONE, CONTEXT, COMMS, session
- **Wizard behavior:** Orchestrate, spawn, coordinate, integrate
- **Specialist behavior:** Execute, focus, report, request help

This creates a **flexible, composable system** where complex work can be broken down into manageable pieces, each with full context and auditability.

---

**See the example agents in this directory for concrete implementations:**
- `.agents/wizard/` - Full wizard agent example
- `.agents/oauth-implementation/` - Full specialist agent example
- `.agents/ui-migration/` - Second specialist (for reference)
