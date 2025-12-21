---
name: docs-generator
description: Generate and update project documentation including FEATURES.md, ROADMAP.md, and architecture diagrams. Use when completing features, planning work, or documenting the codebase.
---

# Documentation Generator

Automatically generates and updates project documentation based on code changes and completed work.

## When to Use

- After completing a significant feature
- When planning a new phase of work
- When user asks for documentation
- During project reviews

## Documents Generated

### FEATURES.md
Complete inventory of project features with:
- Feature name and description
- Implementation status
- Git commit references
- File locations

### ROADMAP.md
Development plan with:
- Phases and milestones
- Feature dependencies
- Success metrics
- Timeline (without time estimates)

### ARCHITECTURE.md
System architecture with:
- Component diagrams (ASCII)
- Data flow descriptions
- API documentation
- Directory structure

## Workflow

### Update FEATURES.md
1. Scan git log for recent commits
2. Identify new features added
3. Update feature list with status
4. Add commit hashes and dates

### Update ROADMAP.md
1. Review kanban board status
2. Move completed items to "Done" section
3. Update phase progress
4. Revise upcoming work based on learnings

### Generate ARCHITECTURE.md
1. Scan directory structure
2. Identify main components
3. Document APIs and data flows
4. Create ASCII diagrams

## Templates

### Feature Entry
```markdown
### Feature Name
**Status:** Complete | In Progress | Planned
**Commit:** abc123
**Files:** path/to/files

Description of what it does.
```

### Roadmap Phase
```markdown
## Phase N: Name

### Completed
- [x] Feature 1
- [x] Feature 2

### In Progress
- [ ] Feature 3

### Planned
- [ ] Feature 4
```

### Architecture Component
```markdown
## Component Name

**Purpose:** What it does
**Location:** path/to/component
**Dependencies:** What it uses

### API
- `function()` - Description
```

## Example

```
User: Update the docs after this feature

Agent:
1. Read recent git commits
2. Identify new feature: "User Authentication"
3. Add to FEATURES.md with commit hash
4. Update ROADMAP.md to mark complete
5. Add authentication flow to ARCHITECTURE.md
6. Report: "Updated 3 documentation files"
```

## Important

- Always include commit references
- Keep descriptions concise
- Use consistent formatting
- Update all related docs together
