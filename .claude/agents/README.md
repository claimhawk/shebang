# Shebang! Agent System

Specialized agents that automate common development workflows. These agents are invoked automatically or via commands.

## Available Agents

| Agent | Trigger | Purpose |
|-------|---------|---------|
| `document-sync` | Brand/tagline changes | Updates text across all relevant files |
| `commit-quality` | Before git commit | Runs quality checks, formats commit message |
| `kanban-sync` | Task completion | Updates kanban board, moves tasks |
| `best-practices` | New tech detected | Generates tech-specific best practices |
| `docs-generator` | New feature complete | Updates FEATURES.md, ROADMAP.md |
| `project-setup` | `/new` command | Creates new project with templates |

## How Agents Work

Each agent is defined by a markdown file that specifies:
1. **Trigger** - When to invoke the agent
2. **Inputs** - What data the agent needs
3. **Workflow** - Steps the agent follows
4. **Outputs** - What the agent produces

Agents can be:
- **Automatic** - Triggered by hooks or file changes
- **Manual** - Invoked via slash commands
- **Background** - Run asynchronously via Task tool

## Agent Files

```
.claude/agents/
├── README.md              # This file
├── document-sync.md       # Multi-file text updates
├── commit-quality.md      # Pre-commit quality checks
├── kanban-sync.md         # Task board management
├── best-practices.md      # Tech-specific guidance
├── docs-generator.md      # Documentation updates
└── project-setup.md       # New project creation
```

## Invoking Agents

### Via Task Tool
```
Task tool with subagent_type="general-purpose":
  prompt: "Follow the workflow in .claude/agents/<agent-name>.md to..."
```

### Via Slash Commands
```
/new         → project-setup agent
/commit      → commit-quality agent
/sync-docs   → document-sync agent
```

### Automatically
Agents can be triggered by:
- File changes detected
- Git operations
- Explicit user request
