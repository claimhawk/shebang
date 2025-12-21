---
name: kanban-sync
description: Manage kanban board tasks - create, move, and update tasks. Use when tracking work progress, completing features, or organizing project tasks.
---

# Kanban Sync

Manages the project kanban board via API calls to keep task status synchronized with actual work.

## When to Use

- Starting work on a task
- Completing a task
- Adding new tasks to backlog
- Moving tasks between columns
- Updating task details

## API Endpoints

### Get Current Board
```bash
curl http://localhost:8080/api/kanban
```

### Add Task
```bash
curl -X POST http://localhost:8080/api/kanban/task \
  -H "Content-Type: application/json" \
  -d '{"title": "Task name", "description": "Details", "category": "feature"}'
```

### Move Task
```bash
curl -X POST http://localhost:8080/api/kanban/move \
  -H "Content-Type: application/json" \
  -d '{"taskId": "task-id", "targetColumn": "done"}'
```

### Update Task
```bash
curl -X POST http://localhost:8080/api/kanban/update \
  -H "Content-Type: application/json" \
  -d '{"taskId": "task-id", "updates": {"title": "New title"}}'
```

## Columns

| Column | ID | When to Use |
|--------|-----|-------------|
| Backlog | `backlog` | New tasks, future work |
| In Progress | `in_progress` | Currently being worked on |
| Review | `review` | Ready for review/testing |
| Done | `done` | Completed |

## Categories

- `feature` - New functionality
- `core` - Infrastructure/architecture
- `docs` - Documentation
- `research` - Investigation/learning
- `platform` - Platform-specific work

## Workflow

### When Starting Work
1. Move task from backlog to in_progress
2. Note the task ID for later

### When Completing Work
1. Move task to done
2. Add completion timestamp
3. Add artifact link if applicable

### When Adding New Work
1. Create task in backlog
2. Set appropriate category
3. Add description

## Example

```
User: I finished the authentication feature

Agent:
1. Find task ID for authentication work
2. POST /api/kanban/move with taskId and targetColumn: "done"
3. Optionally add commit hash to task
4. Report: "Moved 'Authentication' to Done"
```

## Important

- Keep task titles concise (under 50 chars)
- Add artifact links when work produces documents
- Update tasks in real-time as work progresses
