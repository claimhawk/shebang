# Multi-Project Architecture

Shebang supports managing multiple projects within a single installation. Each project has its own kanban board, metrics, and configuration, allowing you to organize different development efforts independently.

## Architecture Overview

```
Shebang/
├── projects/                      # All user projects
│   ├── shebang-dev/               # Shebang's own development
│   │   └── .shebang/
│   │       ├── kanban.json        # Project-specific kanban board
│   │       ├── metrics.json       # Project-specific metrics
│   │       └── config.yaml        # Project configuration
│   └── [your-projects]/           # Your custom projects
│       └── .shebang/
│           ├── kanban.json
│           ├── metrics.json
│           └── config.yaml
├── templates/
│   └── project/                   # Template for new projects
│       └── .shebang/
│           ├── kanban.json        # Empty kanban template
│           ├── metrics.json       # Zeroed metrics template
│           └── config.yaml        # Config template
└── web/
    ├── data/
    │   └── active_project.txt     # Currently active project ID
    ├── server.py                  # Updated with project management
    └── index.html                 # Dashboard with project selector
```

## Creating a New Project

### Via Dashboard UI

1. Open the dashboard at `http://localhost:8080`
2. Click the **"+ New Project"** button in the header
3. Enter a project name and description
4. Click **"Create Project"**
5. The new project will be created and automatically selected

### Via API

```bash
curl -X POST http://localhost:8080/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name": "My Project", "description": "Project description"}'
```

### Manually

1. Create a new directory in `projects/`
2. Create a `.shebang/` subdirectory
3. Copy template files from `templates/project/.shebang/`:
   - `kanban.json`
   - `metrics.json`
   - `config.yaml`
4. Edit `config.yaml` with your project details

## Switching Projects

### Via Dashboard UI

Use the project selector dropdown in the header to switch between projects. All data (kanban, metrics) will reload automatically.

### Via API

```bash
curl -X POST http://localhost:8080/api/projects/select \
  -H "Content-Type: application/json" \
  -d '{"projectId": "my-project"}'
```

## Project Configuration

Each project's `config.yaml` contains:

```yaml
name: "Project Name"
description: "Brief description"
created: "2025-12-21T10:00:00Z"
tags:
  - tag1
  - tag2
```

## API Endpoints

### GET /api/projects

List all available projects and the currently active project.

**Response:**
```json
{
  "projects": [
    {
      "id": "shebang-dev",
      "name": "Shebang Development",
      "description": "Core development",
      "created": "2025-12-18T14:03:00Z",
      "tags": ["internal", "framework"]
    }
  ],
  "active": "shebang-dev"
}
```

### POST /api/projects

Create a new project.

**Request:**
```json
{
  "name": "My Awesome Project",
  "description": "Optional description"
}
```

**Response:**
```json
{
  "success": true,
  "projectId": "my-awesome-project"
}
```

### POST /api/projects/select

Switch the active project.

**Request:**
```json
{
  "projectId": "my-awesome-project"
}
```

**Response:**
```json
{
  "success": true
}
```

### GET /api/kanban

Get the kanban board for the active project.

### GET /api/metrics

Get the metrics for the active project.

## Project Naming Rules

- Project IDs are automatically generated from the project name
- Converted to lowercase
- Spaces replaced with hyphens
- Special characters removed
- Example: "My Awesome Project" → "my-awesome-project"

## Default Project

If no project is explicitly selected, Shebang defaults to the `shebang-dev` project, which contains Shebang's own development data.

## Migration from Single Project

When upgrading from a previous version:

1. Existing data in `web/data/kanban.json` and `web/data/metrics.json` has been moved to `projects/shebang-dev/.shebang/`
2. The `active_project.txt` file is created with `shebang-dev` as the default
3. No manual migration is needed

## Use Cases

### Consulting / Freelancing

Create a project for each client:

```
projects/
├── client-acme/
├── client-globex/
└── client-initech/
```

### Multiple Product Lines

Organize by product:

```
projects/
├── product-web-app/
├── product-mobile-app/
└── product-api-service/
```

### Personal vs Work

Separate personal and professional projects:

```
projects/
├── personal-side-project/
└── work-main-product/
```

## Best Practices

1. **Meaningful Names**: Use descriptive project names that clearly identify the work
2. **Tags**: Use tags in `config.yaml` to categorize projects (client, internal, research, etc.)
3. **Regular Backups**: Back up your `projects/` directory regularly
4. **Archive Completed Projects**: Move completed projects to an `archived/` directory outside `projects/`

## Troubleshooting

### Project Not Showing in Selector

- Ensure the project directory has a `.shebang/` subdirectory
- Verify `config.yaml` exists and is valid YAML
- Check server console for errors

### Can't Switch Projects

- Verify the project ID is correct (check `projects/` directory names)
- Ensure all required files exist (`kanban.json`, `metrics.json`, `config.yaml`)

### Data Not Loading

- Check browser console for API errors
- Verify the active project file: `cat web/data/active_project.txt`
- Restart the server: `python3 web/server.py`
