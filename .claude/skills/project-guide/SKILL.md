---
name: project-guide
description: Guide users through the Shebang workflow - kanban, skills, commands, and development process. Use when users are new, confused, or ask how to use Shebang features.
---

# Project Guide

Helps users understand and navigate the Shebang development workflow.

## When to Use

- User is new to Shebang
- User asks "how do I..."
- User seems confused about workflow
- User asks about available features

## Key Concepts to Explain

### The Kanban Board

Access at http://localhost:8080 after running `python3 .shebang/web/server.py`

**Columns:**
- **Backlog** - Future work, ideas, planned features
- **In Progress** - Currently being worked on
- **Review** - Ready for testing/review
- **Done** - Completed work

**How to use:**
1. Add tasks via dashboard or API
2. Drag cards between columns as work progresses
3. Click cards to see details and artifacts
4. Tasks link to related documents

### Available Commands

| Command | What It Does |
|---------|--------------|
| `/new` | Create a new project in current directory |
| `/commit` | Run quality checks and commit with proper format |

### Available Skills

Skills are automatically invoked based on context:

| Skill | When Used |
|-------|-----------|
| `document-sync` | Updating text across multiple files |
| `commit-quality` | Before git commits |
| `kanban-sync` | Managing task board |
| `best-practices` | Setting up new projects |
| `docs-generator` | Updating documentation |

### The Development Flow

```
1. Add task to Backlog (or use /new for new projects)
       ↓
2. Move to In Progress when starting work
       ↓
3. Write code (guardrails enforce quality)
       ↓
4. Move to Review when ready
       ↓
5. Use /commit to commit with quality checks
       ↓
6. Move to Done when complete
       ↓
7. docs-generator updates documentation
```

### Guardrails

Automatic protections that run on every action:
- **Secrets Detection** - Blocks API keys, passwords
- **Quality Checks** - Blocks anti-patterns
- **Command Safety** - Blocks dangerous shell commands

### Project Structure

```
your-project/
├── .shebang/           # Project data
│   ├── kanban.json     # Your task board
│   ├── metrics.json    # Productivity tracking
│   └── config.yaml     # Project config
├── .gitignore
└── README.md
```

## Common Questions

### "How do I start a new project?"
```
Type /new and answer the questions.
A new folder is created with everything set up.
```

### "How do I see my tasks?"
```
Run: python3 .shebang/web/server.py
Open: http://localhost:8080
```

### "How do I add a task?"
```
Click "+ Add Task" in the dashboard
Or use the API:
curl -X POST http://localhost:8080/api/kanban/task \
  -d '{"title": "My task", "description": "Details"}'
```

### "How do I commit my work?"
```
Type /commit
Quality checks run automatically.
Commit message is formatted properly.
```

### "What if a guardrail blocks me?"
```
Read the error message - it explains what's wrong.
Fix the issue (remove secret, fix anti-pattern, etc.)
Try again.
```

## Onboarding Flow

For new users, walk through:

1. **Start the dashboard** - Show them the kanban
2. **Create a task** - Add something to backlog
3. **Write some code** - Let guardrails demonstrate
4. **Commit** - Show the /commit flow
5. **Complete task** - Move to done, see docs update

## Example Session

```
User: I'm new, how does this work?

Agent: Welcome to Shebang! Here's the quick tour:

1. Your project dashboard is at localhost:8080
   Run: python3 .shebang/web/server.py

2. Add tasks to the Backlog column

3. Move tasks to "In Progress" when you start work

4. Write code - guardrails automatically:
   - Block secrets
   - Enforce quality
   - Catch anti-patterns

5. Type /commit when ready to save

6. Move tasks to Done - documentation updates automatically

Want me to walk you through any of these?
```
