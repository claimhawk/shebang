# /new - Create a New Shebang Project

When the user types `/new`, follow this workflow to create a new project in their current working directory.

## Workflow

### Step 1: Gather Project Information

Use the AskUserQuestion tool to ask these questions:

1. **Project Name** (required) - What should the project be called?
   - This will be used as the folder name (converted to kebab-case)
   - Examples: "My Awesome App", "client-website", "side-project"

2. **Project Description** (optional) - Brief description of what the project is about
   - Used in the project's config.yaml and README

**Technology Stack** - Don't ask unless the user volunteers it. Most users should just let the agent decide.
   - If user specifies tech (e.g., "this is a Python project"), use it
   - Otherwise, agent will detect from files and adapt automatically

### Step 2: Create Project Structure

Run the project creation script:

```bash
python3 $SHEBANG_ROOT/scripts/new-project.py \
  --name "<project-name>" \
  --description "<description>" \
  --type "<project-type>" \
  --tech "<technology-stack>" \
  --path "$(pwd)"
```

The script will:
1. Create `<project-name>/` folder in the current directory
2. Create `<project-name>/.shebang/` subdirectory
3. Copy template files:
   - `kanban.json` - Empty kanban board
   - `metrics.json` - Zeroed metrics
   - `config.yaml` - Project configuration
4. Initialize the config with name, description, tech stack, and tags
5. Create README.md and .gitignore

### Step 3: Launch Best Practices Agent

After creating the project, launch a background agent using the Task tool to collect best practices for the technology stack:

```
Task tool with subagent_type="general-purpose":
  prompt: "Research and document best practices and anti-patterns for <technology-stack> development.

  Create the following files in <project-path>/.shebang/:

  1. best-practices.md - Curated best practices including:
     - Code organization patterns
     - Testing strategies
     - Error handling conventions
     - Performance considerations
     - Security practices

  2. anti-patterns.md - Common mistakes to avoid including:
     - Code smells for this language/framework
     - Performance anti-patterns
     - Security vulnerabilities
     - Testing anti-patterns

  Focus on practical, actionable guidance specific to <technology-stack>.
  Include code examples where helpful.
  Reference the existing testing docs in docs/testing/ for testing guidance."
```

This runs in the background while the user starts working on their project.

### Step 4: Confirm Success

After creation, inform the user:
- Project created at `./<project-name>/`
- They can `cd <project-name>` to start working
- The `.shebang/` folder contains their project data
- They can open http://localhost:8080 to see their project dashboard

## Template Files

The templates are sourced from `$SHEBANG_ROOT/templates/project/.shebang/`:

- **kanban.json** - Empty 4-column kanban (Backlog, In Progress, Review, Done)
- **metrics.json** - Zeroed productivity and codebase metrics
- **config.yaml** - Project metadata template

## Important Notes

- The project folder is created in the **current working directory**
- Project name is converted to kebab-case for the folder name
- The `.shebang/` folder is where all project data lives
- This is separate from Shebang's own development data in `projects/shebang-dev/`

## Example Session

```
User: /new

Claude: I'll help you create a new Shebang project. Let me ask a few questions:

[AskUserQuestion: What should the project be called?]

User: My E-commerce App

[AskUserQuestion: Brief description?]

User: Full-stack e-commerce platform with React and Node.js

[AskUserQuestion: Project type?]

User: Client Work

Claude: Creating project structure...
[Runs new-project.py script]

Project "my-e-commerce-app" created successfully!

Created:
- ./my-e-commerce-app/
- ./my-e-commerce-app/.shebang/kanban.json
- ./my-e-commerce-app/.shebang/metrics.json
- ./my-e-commerce-app/.shebang/config.yaml

To start working:
  cd my-e-commerce-app

To view the dashboard:
  python3 .shebang/web/server.py
  Open http://localhost:8080
```
