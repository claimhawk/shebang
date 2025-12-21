# Multi-Project Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                            │
│                     http://localhost:8080                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ HTTP Requests
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     web/server.py (Flask-like)                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  API Endpoints:                                           │  │
│  │  • GET  /api/projects         → List all projects        │  │
│  │  • POST /api/projects         → Create new project       │  │
│  │  • POST /api/projects/select  → Switch active project    │  │
│  │  • GET  /api/kanban           → Get active kanban        │  │
│  │  • GET  /api/metrics          → Get active metrics       │  │
│  │  • POST /api/kanban/task      → Add task                 │  │
│  │  • POST /api/kanban/move      → Move task                │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Helper Functions:                                        │  │
│  │  • get_active_project()       → Read active_project.txt  │  │
│  │  • set_active_project(name)   → Write active_project.txt │  │
│  │  • get_project_path(name)     → Resolve project path     │  │
│  │  • discover_projects()        → Scan projects/ dir       │  │
│  │  • create_project(...)        → Copy from template       │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ File System Access
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        File System                              │
│                                                                 │
│  web/data/                                                      │
│  └── active_project.txt ─────► "shebang-dev"                   │
│                                                                 │
│  projects/                                                      │
│  ├── shebang-dev/                                              │
│  │   └── .shebang/                                            │
│  │       ├── kanban.json    ◄──── Active kanban data         │
│  │       ├── metrics.json   ◄──── Active metrics data        │
│  │       └── config.yaml    ◄──── Project config             │
│  │                                                            │
│  └── [user-projects]/                                         │
│      └── .shebang/                                            │
│          ├── kanban.json                                      │
│          ├── metrics.json                                     │
│          └── config.yaml                                      │
│                                                                │
│  templates/                                                    │
│  └── project/                                                 │
│      └── .shebang/                                            │
│          ├── kanban.json   ◄──── Empty template              │
│          ├── metrics.json  ◄──── Zeroed template             │
│          └── config.yaml   ◄──── Config template             │
└─────────────────────────────────────────────────────────────────┘
```

## Request Flow Examples

### Creating a New Project

```
Browser                 Server                  File System
   │                      │                         │
   │  POST /api/projects  │                         │
   ├─────────────────────►│                         │
   │  {name: "My App"}    │                         │
   │                      │                         │
   │                      │  create_project()       │
   │                      │  • Generate ID          │
   │                      │  • Create directory     │
   │                      ├────────────────────────►│
   │                      │  mkdir projects/my-app/ │
   │                      │                         │
   │                      │  Copy templates         │
   │                      ├────────────────────────►│
   │                      │  cp template files      │
   │                      │                         │
   │                      │  Write config.yaml      │
   │                      ├────────────────────────►│
   │                      │                         │
   │  {success: true}     │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
```

### Switching Projects

```
Browser                 Server                  File System
   │                      │                         │
   │ POST /projects/select│                         │
   ├─────────────────────►│                         │
   │ {projectId: "my-app"}│                         │
   │                      │                         │
   │                      │  set_active_project()   │
   │                      ├────────────────────────►│
   │                      │  Write "my-app" to      │
   │                      │  active_project.txt     │
   │                      │                         │
   │  {success: true}     │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
   │  GET /api/kanban     │                         │
   ├─────────────────────►│                         │
   │                      │  get_active_project()   │
   │                      ├────────────────────────►│
   │                      │  Read active_project.txt│
   │                      │  → "my-app"             │
   │                      │                         │
   │                      │  get_project_path()     │
   │                      │  → projects/my-app/     │
   │                      │     .shebang/           │
   │                      │                         │
   │                      │  Read kanban.json       │
   │                      ├────────────────────────►│
   │                      │                         │
   │  {kanban data}       │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
```

### Loading Dashboard

```
Browser                 Server                  File System
   │                      │                         │
   │  GET /               │                         │
   ├─────────────────────►│                         │
   │                      │  Serve index.html       │
   │  HTML                │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
   │  GET /api/projects   │                         │
   ├─────────────────────►│                         │
   │                      │  discover_projects()    │
   │                      ├────────────────────────►│
   │                      │  Scan projects/ dir     │
   │                      │  Read each config.yaml  │
   │                      │                         │
   │                      │  get_active_project()   │
   │                      ├────────────────────────►│
   │                      │  Read active_project.txt│
   │                      │                         │
   │  {projects: [...],   │                         │
   │   active: "..."}     │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
   │  Populate dropdown   │                         │
   │                      │                         │
   │  GET /api/kanban     │                         │
   ├─────────────────────►│                         │
   │  {kanban data}       │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
   │  GET /api/metrics    │                         │
   ├─────────────────────►│                         │
   │  {metrics data}      │                         │
   │◄─────────────────────┤                         │
   │                      │                         │
   │  Render dashboard    │                         │
   │                      │                         │
```

## Data Flow

### Project Creation Flow
```
User Input → API → create_project() → File System
    ↓
Project ID generated (name → slug)
    ↓
Directory created: projects/{id}/.shebang/
    ↓
Template files copied
    ↓
config.yaml written with metadata
    ↓
Success response → Browser
```

### Project Selection Flow
```
User Selection → API → set_active_project() → active_project.txt
    ↓
Browser reloads data
    ↓
get_active_project() → read active_project.txt
    ↓
get_project_path(active) → projects/{active}/.shebang/
    ↓
Load kanban.json, metrics.json
    ↓
Render updated dashboard
```

## Key Components

### Server Functions
- **get_active_project()**: Single source of truth for active project
- **discover_projects()**: Scans filesystem, reads configs, builds project list
- **create_project()**: Validates name, creates structure, copies templates
- **get_project_path()**: Resolves active project's .shebang directory

### File System Layout
- **projects/**: User-created projects (one per customer/product/context)
- **templates/**: Pristine templates for new projects
- **web/data/**: Transient state (active project tracking)

### API Design
- RESTful endpoints for CRUD operations
- JSON request/response
- Active project determined server-side from active_project.txt
- All kanban/metrics operations implicitly use active project

## Security Considerations

- Project IDs sanitized (lowercase, alphanumeric + hyphens only)
- All file operations within projects/ directory
- No path traversal (uses Path objects, validated project IDs)
- YAML/JSON parsing with safe loaders
